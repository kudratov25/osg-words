""""Report a mistake" from the word card. Anonymous (device_id only)."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlmodel import Session, select

from ..database import get_session
from ..models import Word, WordIssue
from ..schemas import WordIssueCreate

router = APIRouter(prefix="/feedback", tags=["feedback"])

MAX_ISSUES_PER_DEVICE_PER_DAY = 20


@router.post("/word-issue", status_code=204)
def word_issue(payload: WordIssueCreate, session: Session = Depends(get_session)):
    now = datetime.now(timezone.utc)
    day_start = now.replace(hour=0, minute=0, second=0, microsecond=0)  # UTC day
    sent_today = session.exec(
        select(func.count()).select_from(WordIssue).where(
            WordIssue.device_id == payload.device_id, WordIssue.created_at >= day_start
        )
    ).one()
    if sent_today >= MAX_ISSUES_PER_DEVICE_PER_DAY:
        raise HTTPException(429, "Too many reports from this device today")
    if session.exec(select(Word.id).where(Word.external_id == payload.external_id)).first() is None:
        raise HTTPException(404, f"No word with external_id '{payload.external_id}'")
    session.add(WordIssue(**payload.model_dump(), status="open", created_at=now))
    session.commit()
