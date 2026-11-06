"""Content packs: pair availability, pack versions and word upserts.

Bump rules (SPEC-v2 s.4):
  - a change to a word's target-side fields (term, article, example,
    pronunciation, category, difficulty; also create/delete) bumps every
    pack of that target;
  - a change to a translation bumps only (target, that source).
Nothing is bumped when nothing actually changed.
"""

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable, Optional

from pydantic import ValidationError
from sqlalchemy import func
from sqlmodel import Session, select

from . import config
from .languages import (
    ARTICLES, CATEGORIES, DEFAULT_SOURCE, DEFAULT_TARGET, LEVEL_DIFFICULTY, PAIRS, SOURCES, TARGETS,
    pair_key,
)
from .models import PackMeta, Word, WordTranslation, utcnow
from .schemas import AdminWord, AdminWordInput, TranslationRead

log = logging.getLogger("osg.packs")

TARGET_FIELDS = ("term", "article", "example", "pronunciation", "category", "difficulty", "level", "topics")


def topics_to_db(topics: Iterable[str]) -> str:
    """Sorted, de-duplicated, comma-separated ("" = general word)."""
    return ",".join(sorted(set(topics)))


def topics_from_db(value: Optional[str]) -> list[str]:
    return [t for t in (value or "").split(",") if t]


def difficulty_for(level: Optional[str], difficulty: str) -> str:
    """A word's level decides its difficulty (read by app <= 2.0)."""
    return LEVEL_DIFFICULTY.get(level, difficulty) if level else difficulty

Pair = tuple[str, str]  # (source, target)


# --- pack versions -------------------------------------------------------------

def ensure_pack_meta(session: Session) -> None:
    """Make sure every known pair has a PackMeta row (version 1 when new)."""
    have = {(m.source, m.target) for m in session.exec(select(PackMeta)).all()}
    for source, target in PAIRS:
        if (source, target) not in have:
            session.add(PackMeta(source=source, target=target, version=1))
    session.commit()


def get_meta(session: Session, source: str, target: str) -> Optional[PackMeta]:
    return session.exec(
        select(PackMeta).where(PackMeta.source == source, PackMeta.target == target)
    ).first()


def pairs_of_target(target: str) -> set[Pair]:
    return {(s, t) for s, t in PAIRS if t == target}


def bump(session: Session, pairs: Iterable[Pair]) -> None:
    now = utcnow()
    for source, target in sorted(set(pairs)):
        meta = get_meta(session, source, target)
        if meta is None:
            meta = PackMeta(source=source, target=target, version=1, updated_at=now)
        else:
            meta.version += 1
            meta.updated_at = now
        session.add(meta)


def bumped_keys(pairs: Iterable[Pair]) -> list[str]:
    return sorted(pair_key(s, t) for s, t in set(pairs))


# --- availability ------------------------------------------------------------------

def pair_word_counts(session: Session, general_only: bool = False) -> dict[Pair, int]:
    """Words per (source, target) that have a translation in source.
    general_only: leave out job-area (topic) words, i.e. what app <= 2.0 gets."""
    query = (
        select(WordTranslation.lang, Word.lang, func.count())
        .join(Word, Word.id == WordTranslation.word_id)
        .group_by(WordTranslation.lang, Word.lang)
    )
    if general_only:
        query = query.where(Word.topics == "")
    rows = session.exec(query).all()
    return {(src, tgt): n for src, tgt, n in rows}


def target_word_counts(session: Session) -> dict[str, int]:
    return dict(session.exec(select(Word.lang, func.count()).group_by(Word.lang)).all())


def is_available(source: str, target: str, words: int) -> bool:
    """Known pair with enough words. The default pair is always served:
    app v1.0.x relies on it and the app bundles it offline."""
    if (source, target) not in PAIRS:
        return False
    if (source, target) == (DEFAULT_SOURCE, DEFAULT_TARGET):
        return True
    return words >= config.MIN_PAIR_WORDS


# --- serialisation ------------------------------------------------------------------

def translations_by_word(session: Session, word_ids: list[int]) -> dict[int, dict[str, WordTranslation]]:
    out: dict[int, dict[str, WordTranslation]] = {i: {} for i in word_ids}
    if not word_ids:
        return out
    for tr in session.exec(select(WordTranslation).where(WordTranslation.word_id.in_(word_ids))).all():
        out.setdefault(tr.word_id, {})[tr.lang] = tr
    return out


def to_admin_word(word: Word, translations: dict[str, WordTranslation]) -> AdminWord:
    return AdminWord(
        **{f: getattr(word, f) for f in ("external_id", "lang", *TARGET_FIELDS, "created_at", "updated_at")
           if f != "topics"},
        topics=topics_from_db(word.topics),
        translations={
            lang: TranslationRead(translation=t.translation, example_translation=t.example_translation)
            for lang, t in sorted(translations.items())
        },
    )


# --- validation ------------------------------------------------------------------------

def validate_word_fields(lang: str, article: Optional[str], category: Optional[str],
                         translation_langs: Iterable[str]) -> Optional[str]:
    """Rules not expressible in the schema. Returns an error message or None."""
    if lang not in TARGETS:
        return f"lang must be one of {', '.join(TARGETS)}"
    if article is not None:
        allowed = ARTICLES.get(lang, ())
        if article not in allowed:
            return (f"article for '{lang}' must be one of {', '.join(allowed)} or null"
                    if allowed else f"'{lang}' has no articles: article must be null")
    if category is not None and category not in CATEGORIES:
        return f"unknown category '{category}'"
    for tl in translation_langs:
        if tl not in SOURCES:
            return f"translation language '{tl}' must be one of {', '.join(SOURCES)}"
        if tl == lang:
            return f"a '{lang}' word can't have a '{tl}' translation"
    return None


# --- upsert ------------------------------------------------------------------------------

@dataclass
class UpsertResult:
    status: str  # created | updated | unchanged
    bumped: set[Pair] = field(default_factory=set)
    word: Optional[Word] = None


def apply_translations(session: Session, word: Word, existing: dict[str, WordTranslation],
                       changes: dict[str, Optional[dict]], partial: bool) -> set[str]:
    """Set/remove translations of `word`. `changes[lang]` is None (remove),
    or a dict of fields. With partial=True only the given fields change.
    Returns the languages that actually changed. Doesn't commit."""
    changed: set[str] = set()
    for lang, data in changes.items():
        current = existing.get(lang)
        if data is None:
            if current is not None:
                session.delete(current)
                existing.pop(lang)
                changed.add(lang)
            continue
        if current is None:
            current = WordTranslation(word_id=word.id, lang=lang, translation=data["translation"],
                                      example_translation=data.get("example_translation"))
            session.add(current)
            existing[lang] = current
            changed.add(lang)
            continue
        new = dict(data) if partial else {"example_translation": None, **data}
        diff = False
        for key in ("translation", "example_translation"):
            if key in new and getattr(current, key) != new[key]:
                setattr(current, key, new[key])
                diff = True
        if diff:
            session.add(current)
            changed.add(lang)
    return changed


def upsert_word(session: Session, item: AdminWordInput, lang: str, dry_run: bool = False) -> UpsertResult:
    """Create or fully update (target fields + listed translations) one word.
    Translations not listed are kept; a listed `null` removes one.
    Doesn't commit. With dry_run nothing is added to the session."""
    word = session.exec(select(Word).where(Word.external_id == item.external_id)).first()
    target_data = {f: getattr(item, f) for f in TARGET_FIELDS}
    target_data["topics"] = topics_to_db(item.topics)
    target_data["difficulty"] = difficulty_for(item.level, item.difficulty)
    tr_changes = {k: (v.model_dump() if v is not None else None) for k, v in item.translations.items()}

    if word is None:
        tr_langs = {k for k, v in tr_changes.items() if v is not None}
        result = UpsertResult("created", pairs_of_target(lang) | {(s, lang) for s in tr_langs})
        if dry_run:
            return result
        now = utcnow()
        word = Word(external_id=item.external_id, lang=lang, created_at=now, updated_at=now, **target_data)
        session.add(word)
        session.flush()
        apply_translations(session, word, {}, {k: v for k, v in tr_changes.items() if v is not None}, partial=False)
        result.word = word
        return result

    if word.lang != lang:
        raise ValueError(f"external_id '{item.external_id}' already exists as a '{word.lang}' word")

    existing = translations_by_word(session, [word.id])[word.id]
    target_changed = any(getattr(word, f) != v for f, v in target_data.items())
    if dry_run:
        changed_langs = set()
        for tl, data in tr_changes.items():
            cur = existing.get(tl)
            if data is None:
                if cur is not None:
                    changed_langs.add(tl)
            elif cur is None or cur.translation != data["translation"] \
                    or cur.example_translation != data.get("example_translation"):
                changed_langs.add(tl)
    else:
        if target_changed:
            for f, v in target_data.items():
                setattr(word, f, v)
        changed_langs = apply_translations(session, word, existing, tr_changes, partial=False)

    bumped: set[Pair] = set()
    if target_changed:
        bumped |= pairs_of_target(lang)
    bumped |= {(s, lang) for s in changed_langs}
    if not bumped:
        return UpsertResult("unchanged", set(), word)
    if not dry_run:
        word.updated_at = utcnow()
        session.add(word)
    return UpsertResult("updated", bumped, word)


def import_words(session: Session, items: list[Any], default_target: Optional[str] = None,
                 dry_run: bool = False, do_bump: bool = True) -> dict:
    """Validate + upsert many words (by external_id). Bad items are reported
    in `errors` and skipped; the rest is applied (unless dry_run) and
    committed together with the version bumps."""
    created = updated = unchanged = 0
    errors: list[dict] = []
    bumped: set[Pair] = set()
    seen: set[str] = set()

    for index, raw in enumerate(items):
        ext = raw.get("external_id") if isinstance(raw, dict) else None
        ext = ext if isinstance(ext, str) else None
        try:
            item = AdminWordInput.model_validate(raw)
        except ValidationError as e:
            errors.append({"index": index, "external_id": ext, "error": _short_validation_error(e)})
            continue
        lang = item.lang or default_target or DEFAULT_TARGET
        if default_target and item.lang and item.lang != default_target:
            errors.append({"index": index, "external_id": ext,
                           "error": f"lang '{item.lang}' doesn't match import target '{default_target}'"})
            continue
        err = validate_word_fields(lang, item.article, item.category, item.translations.keys())
        if err is None and item.external_id in seen:
            err = "duplicate external_id in this import"
        if err:
            errors.append({"index": index, "external_id": ext, "error": err})
            continue
        seen.add(item.external_id)
        try:
            res = upsert_word(session, item, lang, dry_run=dry_run)
        except ValueError as e:
            errors.append({"index": index, "external_id": ext, "error": str(e)})
            continue
        bumped |= res.bumped
        if res.status == "created":
            created += 1
        elif res.status == "updated":
            updated += 1
        else:
            unchanged += 1

    if dry_run:
        session.rollback()
    else:
        if do_bump:
            bump(session, bumped)
        session.commit()
    return {
        "dry_run": dry_run,
        "created": created,
        "updated": updated,
        "unchanged": unchanged,
        "errors": errors,
        "bumped": bumped_keys(bumped) if do_bump else [],
    }


def _short_validation_error(e: ValidationError) -> str:
    parts = []
    for err in e.errors()[:3]:
        loc = ".".join(str(p) for p in err.get("loc", ())) or "word"
        parts.append(f"{loc}: {err.get('msg')}")
    return "; ".join(parts)


# --- content files ------------------------------------------------------------------------

def load_content_file(path: Path) -> tuple[Optional[str], list[Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("target"), data.get("words", [])


def content_files(content_dir: Optional[Path] = None) -> list[Path]:
    d = content_dir or config.CONTENT_DIR
    general = [d / f"{t}.json" for t in TARGETS if (d / f"{t}.json").is_file()]
    # Job-area words (v2.1), same file shape: content/topics/<target>.json.
    topics = [d / "topics" / f"{t}.json" for t in TARGETS if (d / "topics" / f"{t}.json").is_file()]
    return general + topics


def seed_if_empty(session: Session) -> None:
    """First start on an empty database: load backend/content/*.json, or
    the built-in 60 German words if de.json isn't there. Versions stay 1."""
    ensure_pack_meta(session)
    if session.exec(select(Word.id)).first() is not None:
        return
    files = content_files()
    targets_loaded = set()
    for path in files:
        target, words = load_content_file(path)
        target = target or path.stem
        res = import_words(session, words, default_target=target, do_bump=False)
        targets_loaded.add(target)
        log.info("Seeded %s: %d words, %d errors", path.name, res["created"], len(res["errors"]))
        for err in res["errors"][:20]:
            log.warning("  %s #%s %s: %s", path.name, err["index"], err["external_id"], err["error"])
    if DEFAULT_TARGET not in targets_loaded:
        from .seed_words import SEED_WORDS

        res = import_words(session, SEED_WORDS, default_target=DEFAULT_TARGET, do_bump=False)
        log.info("Seeded built-in German words: %d", res["created"])
