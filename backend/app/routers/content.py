"""Public content API. Without parameters it serves the en-de pack exactly
like v1 did (plus new fields), so app v1.0.x keeps working."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select

from .. import packs
from ..database import get_session
from ..languages import DEFAULT_SOURCE, DEFAULT_TARGET, PAIRS
from ..models import PackMeta, Word, WordTranslation
from ..schemas import ContentMetaRead, ContentPackRead, PairList, PairRead, WordRead

router = APIRouter(prefix="/content", tags=["content"])

_lang = dict(min_length=2, max_length=2)


@router.get("/pairs", response_model=PairList)
def get_pairs(
    topics: bool = Query(False, description="Count job-area (topic) words too. App >= 2.1."),
    session: Session = Depends(get_session),
):
    # `words` is shown to the user, so it must match what /content/words
    # sends with the same `topics` flag. Availability uses the full count.
    shown = packs.pair_word_counts(session, general_only=not topics)
    counts = packs.pair_word_counts(session)
    metas = {(m.source, m.target): m for m in session.exec(select(PackMeta)).all()}
    out = []
    for source, target in PAIRS:
        n = counts.get((source, target), 0)
        meta = metas.get((source, target))
        if meta is not None and packs.is_available(source, target, n):
            out.append(PairRead(source=source, target=target, words=shown.get((source, target), 0),
                                version=meta.version))
    return PairList(pairs=out)


def _available_meta(session: Session, source: str, target: str) -> PackMeta:
    if (source, target) not in PAIRS:
        raise HTTPException(404, f"Unknown language pair '{source}-{target}'")
    n = packs.pair_word_counts(session).get((source, target), 0)
    if not packs.is_available(source, target, n):
        raise HTTPException(404, f"Language pair '{source}-{target}' is not available yet")
    meta = packs.get_meta(session, source, target)
    if meta is None:
        raise HTTPException(503, "Content not initialized")
    return meta


@router.get("/meta", response_model=ContentMetaRead)
def get_meta(
    source: str = Query(DEFAULT_SOURCE, **_lang),
    target: str = Query(DEFAULT_TARGET, **_lang),
    session: Session = Depends(get_session),
):
    meta = _available_meta(session, source, target)
    return ContentMetaRead(version=meta.version, updated_at=meta.updated_at, source=source, target=target)


@router.get("/words", response_model=ContentPackRead)
def get_words(
    source: str = Query(DEFAULT_SOURCE, **_lang),
    target: str = Query(DEFAULT_TARGET, **_lang),
    topics: bool = Query(False, description="Also include job-area (topic) words. App >= 2.1."),
    session: Session = Depends(get_session),
):
    meta = _available_meta(session, source, target)
    query = (
        select(Word, WordTranslation)
        .join(WordTranslation, WordTranslation.word_id == Word.id)
        .where(Word.lang == target, WordTranslation.lang == source)
        .order_by(Word.id)
    )
    if not topics:
        # Apps <= 2.0 can't filter by topic: keep their daily words general.
        query = query.where(Word.topics == "")
    rows = session.exec(query).all()
    words = [
        WordRead(
            external_id=w.external_id,
            lang=w.lang,
            term=w.term,
            german=w.term,
            article=w.article,
            translation=t.translation,
            example=w.example,
            example_translation=t.example_translation,
            pronunciation=w.pronunciation,
            category=w.category,
            difficulty=w.difficulty,
            level=w.level,
            topics=packs.topics_from_db(w.topics),
            created_at=w.created_at,
        )
        for w, t in rows
    ]
    return ContentPackRead(version=meta.version, source=source, target=target, words=words)
