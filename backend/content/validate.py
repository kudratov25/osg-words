#!/usr/bin/env python3
"""Validate backend/content/de.json and en.json (general words) and
backend/content/topics/de.json and en.json (job-area words, v2.1) against
docs/SPEC-v2.md s.1-3 (levels and topics: v2.1).

    python3 backend/content/validate.py

Standard library only. Prints a report; exits 1 if there are errors.
Warnings (e.g. the example uses an inflected form of the term) don't fail.
"""

import ast
import collections
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEED_FILE = HERE.parent / "app" / "seed_words.py"

EXPECTED_COUNT = 500
CATEGORIES = {
    "Daily Life", "Work", "Food", "Common Verbs", "Travel", "Emotions", "Adjectives",
    "Time", "Money", "Health", "Weather", "Social", "Home", "Family", "Education",
    "Shopping", "Nature",
}
DIFFICULTIES = {"beginner", "intermediate", "advanced"}
ARTICLES = {"der", "die", "das"}
REQUIRED_SOURCES = {"de": ("en", "uz", "ru"), "en": ("uz", "ru")}
WORD_KEYS = {"external_id", "term", "article", "example", "category", "difficulty",
             "pronunciation", "translations", "level"}
OPTIONAL_KEYS = {"topics"}
LEVELS = ("A1", "A2", "B1", "B2", "C1")
LEVEL_DIFFICULTY = {"A1": "beginner", "A2": "beginner", "B1": "intermediate", "B2": "advanced", "C1": "advanced"}
TOPICS = {"retail", "it", "medicine", "hospitality", "construction", "logistics", "office", "care"}
MIN_TOPIC_WORDS = 60  # per topic and target
TARGET_DIFFICULTY_SHARE = {"beginner": 0.60, "intermediate": 0.30, "advanced": 0.10}
MAX_CATEGORY_SHARE = 0.15

CYRILLIC = re.compile(r"[Ѐ-ӿ]")
# Uzbek Latin must use the ASCII apostrophe: o' g' and the tutuq belgisi (ta'lim).
BAD_APOSTROPHES = re.compile(r"[‘’ʻʼ`´]")
UZ_ALLOWED = re.compile(r"^[A-Za-z0-9 '.,!?;:()\-/—–\"%]+$")


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, where, msg):
        self.errors.append(f"{where}: {msg}")

    def warn(self, where, msg):
        self.warnings.append(f"{where}: {msg}")


def de_slug(term):
    s = term.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss"), (" ", "_"), ("-", "")):
        s = s.replace(a, b)
    return s


def en_slug(term):
    return term.lower().replace(" ", "_").replace("-", "").replace("'", "")


def load_seed_words():
    tree = ast.parse(SEED_FILE.read_text(encoding="utf-8"))
    for node in tree.body:
        if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", None) == "SEED_WORDS":
            return ast.literal_eval(node.value)
    raise SystemExit(f"SEED_WORDS not found in {SEED_FILE}")


def fold(s):
    return s.lower().replace("ß", "ss")


def example_uses_term(term, example, target):
    """True if the term (or, for multiword terms, every content word) appears in
    the example; 'stem' if only a clear stem/inflection does; False otherwise."""
    ex = fold(example)
    t = fold(term)
    if t in ex:
        return True
    words = [w for w in re.split(r"[\s\-]+", t) if w and w not in ("sich", "to", "a", "an", "the")]
    if words and all(w in ex for w in words):
        return True

    def stem_hit(w):
        cands = [w]
        if target == "de":
            for suf in ("en", "n", "e", "ern", "eln"):
                if w.endswith(suf) and len(w) - len(suf) >= 3:
                    cands.append(w[: -len(suf)])
            # umlaut / ablaut-lite: compare without umlauts
            cands += [c.replace("ä", "a").replace("ö", "o").replace("ü", "u") for c in list(cands)]
            exn = ex.replace("ä", "a").replace("ö", "o").replace("ü", "u")
        else:
            for suf in ("e", "y"):
                if w.endswith(suf) and len(w) > 3:
                    cands.append(w[:-1])
            exn = ex
        cands += [c[:4] for c in cands if len(c) >= 6]  # separable/irregular verbs: weak hint
        return any(c and (c in ex or c in exn) for c in cands)

    if words and all(stem_hit(w) for w in words):
        return "stem"
    # separable verbs written apart: "aufstehen" -> "stehe ... auf"
    if target == "de" and len(words) == 1:
        w = words[0]
        for prefix in ("auf", "an", "ab", "aus", "ein", "mit", "um", "zu", "zurück", "vor", "weh", "kennen"):
            if w.startswith(prefix) and len(w) > len(prefix) + 3:
                rest = w[len(prefix):]
                if re.search(rf"\b{prefix}\b", ex) and stem_hit(rest):
                    return "stem"
    return False


def check_file(path, target, rep, all_ids, expected=EXPECTED_COUNT, topic_file=False):
    where_file = f"topics/{path.name}" if topic_file else path.name
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        rep.error(where_file, "file missing")
        return None
    except json.JSONDecodeError as e:
        rep.error(where_file, f"invalid JSON: {e}")
        return None
    if not isinstance(data, dict) or set(data) != {"target", "words"}:
        rep.error(where_file, "top level must be an object with exactly 'target' and 'words'")
        return None
    if data["target"] != target:
        rep.error(where_file, f"target is {data['target']!r}, expected {target!r}")
    words = data["words"]
    if not isinstance(words, list):
        rep.error(where_file, "'words' must be a list")
        return None
    if expected is not None and len(words) != expected:
        rep.error(where_file, f"{len(words)} words, expected exactly {expected}")

    terms = collections.defaultdict(list)
    for i, w in enumerate(words):
        where = f"{where_file}#{i}"
        if not isinstance(w, dict):
            rep.error(where, "word must be an object")
            continue
        eid = w.get("external_id")
        where = f"{where_file}#{i} {eid}"
        keys = set(w)
        if not (WORD_KEYS <= keys <= WORD_KEYS | OPTIONAL_KEYS):
            missing, extra = WORD_KEYS - keys, keys - WORD_KEYS - OPTIONAL_KEYS
            rep.error(where, f"keys: missing {sorted(missing)} extra {sorted(extra)}")
            continue
        if w["level"] not in LEVELS:
            rep.error(where, f"bad level {w['level']!r}")
        elif LEVEL_DIFFICULTY[w["level"]] != w["difficulty"]:
            rep.error(where, f"difficulty {w['difficulty']!r} doesn't match level {w['level']}")
        topics = w.get("topics", [])
        if not isinstance(topics, list) or any(t not in TOPICS for t in topics):
            rep.error(where, f"bad topics {topics!r}")
        elif topic_file and not topics:
            rep.error(where, "topic file word without topics")
        elif not topic_file and topics:
            rep.error(where, "general file word with topics (put it in topics/)")
        for k in ("external_id", "term", "example", "category", "difficulty"):
            if not isinstance(w[k], str) or not w[k].strip():
                rep.error(where, f"'{k}' must be a non-empty string")
        if any(not isinstance(w[k], str) for k in ("external_id", "term", "example")):
            continue
        term, example, article = w["term"], w["example"], w["article"]
        if term != term.strip() or example != example.strip():
            rep.error(where, "leading/trailing whitespace")
        if w["pronunciation"] is not None and not isinstance(w["pronunciation"], str):
            rep.error(where, "'pronunciation' must be a string or null")

        # ids
        if len(eid) > 64:
            rep.error(where, "external_id longer than 64 chars")
        if eid in all_ids:
            rep.error(where, f"external_id duplicated (first in {all_ids[eid]})")
        else:
            all_ids[eid] = where_file
        if target == "de":
            if not re.fullmatch(r"[a-z0-9_]+", eid):
                rep.error(where, "id must be lowercase [a-z0-9_]")
            expected = (f"{article}_" if article else "") + de_slug(term)
            if eid != expected:
                rep.error(where, f"id should be {expected!r}")
        else:
            if not re.fullmatch(r"en\.[a-z0-9_]+", eid):
                rep.error(where, "id must match en.[a-z0-9_]+")
            elif eid != "en." + en_slug(term):
                rep.error(where, f"id should be {'en.' + en_slug(term)!r}")

        # articles
        if target == "de":
            if term[:1].isupper():
                if article not in ARTICLES:
                    rep.error(where, f"capitalized term (noun) needs article der/die/das, got {article!r}")
            elif article is not None:
                rep.error(where, f"lowercase term (not a noun) must have article null, got {article!r}")
        elif article is not None:
            rep.error(where, "English words must have article null")

        if w["category"] not in CATEGORIES:
            rep.error(where, f"unknown category {w['category']!r}")
        if w["difficulty"] not in DIFFICULTIES:
            rep.error(where, f"bad difficulty {w['difficulty']!r}")

        # lengths
        if len(term) > 200:
            rep.error(where, "term longer than 200")
        if len(example) > 500:
            rep.error(where, "example longer than 500")
        n_words = len(example.split())
        if not 2 <= n_words <= 12:
            rep.warn(where, f"example has {n_words} words (aim for 4-10)")
        if not re.search(r"[.!?]$", example):
            rep.warn(where, "example doesn't end with . ! or ?")
        if CYRILLIC.search(term + example):
            rep.error(where, "Cyrillic characters in target-language term/example")

        # translations
        tr = w["translations"]
        if not isinstance(tr, dict):
            rep.error(where, "'translations' must be an object")
        else:
            for src in REQUIRED_SOURCES[target]:
                t = tr.get(src)
                if not isinstance(t, dict):
                    rep.error(where, f"missing translation '{src}'")
                    continue
                if set(t) != {"translation", "example_translation"}:
                    rep.error(where, f"{src}: keys must be translation, example_translation")
                tt, te = t.get("translation"), t.get("example_translation")
                if not isinstance(tt, str) or not tt.strip():
                    rep.error(where, f"{src}: empty translation")
                    continue
                if not isinstance(te, str) or not te.strip():
                    rep.error(where, f"{src}: empty example_translation")
                    continue
                if len(tt) > 200:
                    rep.error(where, f"{src}: translation longer than 200")
                if len(te) > 500:
                    rep.error(where, f"{src}: example_translation longer than 500")
                if len(re.split(r"\s*/\s*", tt)) > 3 or len(tt.split()) > 8:
                    rep.warn(where, f"{src}: translation looks long: {tt!r}")
                if src == "ru":
                    if not CYRILLIC.search(tt) or not CYRILLIC.search(te):
                        rep.error(where, "ru: translation must be in Cyrillic")
                else:
                    if CYRILLIC.search(tt + te):
                        rep.error(where, f"{src}: Cyrillic characters in a Latin-script translation")
                if src == "uz":
                    if BAD_APOSTROPHES.search(tt + te):
                        rep.error(where, "uz: use the ASCII apostrophe ' (o' g' ta'lim)")
                    for s in (tt, te):
                        if not UZ_ALLOWED.match(s):
                            bad = sorted(set(c for c in s if not UZ_ALLOWED.match(c)))
                            rep.error(where, f"uz: unexpected characters {bad}")
            extra = set(tr) - set(REQUIRED_SOURCES[target])
            if extra:
                rep.error(where, f"unexpected translation languages {sorted(extra)}")

        # example uses the term
        hit = example_uses_term(term, example, target)
        if hit == "stem":
            pass  # inflected form found; fine
        elif not hit:
            rep.warn(where, f"example may not contain the term {term!r}: {example!r}")

        terms[fold(term)].append(eid)

    for t, ids in terms.items():
        if len(ids) > 1:
            rep.error(where_file, f"duplicate term {t!r}: {ids}")
    return words


def check_seed(words, rep):
    by_id = {w.get("external_id"): w for w in words if isinstance(w, dict)}
    for s in load_seed_words():
        where = f"de.json seed {s['external_id']}"
        w = by_id.get(s["external_id"])
        if w is None:
            rep.error(where, "existing word missing")
            continue
        got = (w.get("term"), w.get("article"), w.get("example"), w.get("category"), w.get("difficulty"))
        exp = (s["german"], s["article"], s["example"], s["category"], s["difficulty"])
        if got != exp:
            rep.error(where, f"changed: {got} != {exp}")
        en = (w.get("translations") or {}).get("en") or {}
        if en.get("translation") != s["translation"]:
            rep.error(where, f"English translation changed: {en.get('translation')!r} != {s['translation']!r}")


def distribution(name, words, rep):
    n = len(words)
    if not n:
        return
    diff = collections.Counter(w.get("difficulty") for w in words)
    cats = collections.Counter(w.get("category") for w in words)
    print(f"\n{name}: {n} words")
    print("  difficulty: " + ", ".join(f"{k} {diff.get(k, 0)} ({diff.get(k, 0) / n:.0%})"
                                       for k in ("beginner", "intermediate", "advanced")))
    for k, share in TARGET_DIFFICULTY_SHARE.items():
        if abs(diff.get(k, 0) / n - share) > 0.05:
            rep.warn(name, f"{k} share {diff.get(k, 0) / n:.0%}, target ~{share:.0%}")
    print("  categories:")
    for k in sorted(CATEGORIES, key=lambda c: -cats.get(c, 0)):
        print(f"    {k:14s} {cats.get(k, 0):4d}")
        if cats.get(k, 0) == 0:
            rep.error(name, f"category {k!r} is empty")
        elif cats[k] / n > MAX_CATEGORY_SHARE:
            rep.error(name, f"category {k!r} has {cats[k] / n:.0%} > {MAX_CATEGORY_SHARE:.0%}")
    hits = collections.Counter()
    for w in words:
        if isinstance(w, dict) and isinstance(w.get("term"), str):
            hits[str(example_uses_term(w["term"], w.get("example", ""), name[:2]))] += 1
    print(f"  example contains term: exact {hits['True']}, inflected {hits['stem']}, unclear {hits['False']}")


def main():
    rep = Report()
    all_ids = {}
    de = check_file(HERE / "de.json", "de", rep, all_ids)
    en = check_file(HERE / "en.json", "en", rep, all_ids)
    if de is not None:
        check_seed(de, rep)
        distribution("de.json", de, rep)
    if en is not None:
        distribution("en.json", en, rep)

    for target in ("de", "en"):
        path = HERE / "topics" / f"{target}.json"
        if not path.is_file():
            continue
        tw = check_file(path, target, rep, all_ids, expected=None, topic_file=True)
        if tw is None:
            continue
        per_topic = collections.Counter(t for w in tw if isinstance(w, dict) for t in w.get("topics", []))
        levels = collections.Counter(w.get("level") for w in tw if isinstance(w, dict))
        print(f"\ntopics/{target}.json: {len(tw)} words")
        print("  topics: " + ", ".join(f"{t} {per_topic.get(t, 0)}" for t in sorted(TOPICS)))
        print("  levels: " + ", ".join(f"{lv} {levels.get(lv, 0)}" for lv in LEVELS))
        for t in TOPICS:
            if per_topic.get(t, 0) < MIN_TOPIC_WORDS:
                rep.error(f"topics/{target}.json", f"topic {t!r} has {per_topic.get(t, 0)} < {MIN_TOPIC_WORDS} words")

    print(f"\nunique external_ids across files: {len(all_ids)}")
    if rep.warnings:
        print(f"\nWARNINGS ({len(rep.warnings)}):")
        for w in rep.warnings:
            print("  - " + w)
    if rep.errors:
        print(f"\nERRORS ({len(rep.errors)}):")
        for e in rep.errors:
            print("  - " + e)
    print(f"\n{len(rep.errors)} errors, {len(rep.warnings)} warnings")
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
