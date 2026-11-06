#!/usr/bin/env python3
"""Build content/topics/<target>.json from the compact sources in src/.

    python3 backend/content/topics/build.py

Source files: src/<target>_<topic>.txt, one word per line, `|`-separated:
  de: term | article | level | category | example | en | en_example | uz | uz_example | ru | ru_example
  en: term | level | category | example | uz | uz_example | ru | ru_example
Blank lines and lines starting with # are ignored. Use `-` for no article.

Words whose term already exists as a general word (content/<target>.json)
are skipped (they're served to everyone already). The same term in two
topic files becomes one word with both topics.
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CONTENT = HERE.parent
LEVEL_DIFFICULTY = {"A1": "beginner", "A2": "beginner", "B1": "intermediate", "B2": "advanced", "C1": "advanced"}


def de_slug(term):
    s = term.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss"), (" ", "_"), ("-", ""), ("/", "_"), (".", ""), ("'", "")):
        s = s.replace(a, b)
    return s


def en_slug(term):
    s = term.lower()
    for a, b in ((" ", "_"), ("-", ""), ("'", ""), ("/", "_"), (".", "")):
        s = s.replace(a, b)
    return s


def key_of(term, article):
    return ((article or "") + " " + term).strip().lower()


def build(target):
    general = json.loads((CONTENT / f"{target}.json").read_text(encoding="utf-8"))["words"]
    taken_ids = {w["external_id"] for w in general}
    other = CONTENT / f"{'en' if target == 'de' else 'de'}.json"
    taken_ids |= {w["external_id"] for w in json.loads(other.read_text(encoding="utf-8"))["words"]}
    general_terms = {key_of(w["term"], w["article"]) for w in general} | {w["term"].lower() for w in general}
    words, by_key, skipped, problems = [], {}, [], []
    for src in sorted((HERE / "src").glob(f"{target}_*.txt")):
        topic = src.stem.split("_", 1)[1]
        for n, line in enumerate(src.read_text(encoding="utf-8").splitlines(), 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            f = [x.strip() for x in line.split("|")]
            where = f"{src.name}:{n}"
            if target == "de":
                if len(f) != 11:
                    problems.append(f"{where}: {len(f)} fields, expected 11")
                    continue
                term, article, level, cat, ex, en, en_ex, uz, uz_ex, ru, ru_ex = f
                article = None if article in ("-", "") else article
                if article and term.lower().startswith(article + " "):
                    term = term[len(article) + 1:]  # "der Kunde" -> "Kunde"
                trs = {"en": (en, en_ex), "uz": (uz, uz_ex), "ru": (ru, ru_ex)}
            else:
                if len(f) != 8:
                    problems.append(f"{where}: {len(f)} fields, expected 8")
                    continue
                term, level, cat, ex, uz, uz_ex, ru, ru_ex = f
                article = None
                trs = {"uz": (uz, uz_ex), "ru": (ru, ru_ex)}
            k = key_of(term, article)
            if k in general_terms or term.lower() in general_terms:
                skipped.append(f"{where}: {k} (general word)")
                continue
            if k in by_key:
                w = by_key[k]
                if topic not in w["topics"]:
                    w["topics"] = sorted(w["topics"] + [topic])
                continue
            if level not in LEVEL_DIFFICULTY:
                problems.append(f"{where}: bad level {level!r}")
                continue
            if target == "de":
                eid = f"{article}_{de_slug(term)}" if article else de_slug(term)
            else:
                eid = f"en.{en_slug(term)}"
            base, i = eid, 2
            while eid in taken_ids:
                eid = f"{base}_{i}"
                i += 1
            taken_ids.add(eid)
            w = {
                "external_id": eid, "term": term, "article": article, "example": ex,
                "category": cat, "difficulty": LEVEL_DIFFICULTY[level], "level": level,
                "pronunciation": None,
                "translations": {lang: {"translation": t, "example_translation": te} for lang, (t, te) in trs.items()},
                "topics": [topic],
            }
            by_key[k] = w
            words.append(w)
    out = CONTENT / "topics" / f"{target}.json"
    out.write_text(json.dumps({"target": target, "words": words}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{out.relative_to(CONTENT)}: {len(words)} words, {len(skipped)} skipped as general, {len(problems)} problems")
    for p in problems + skipped:
        print("  " + p)
    return not problems


if __name__ == "__main__":
    ok = all([build("de"), build("en")])
    sys.exit(0 if ok else 1)
