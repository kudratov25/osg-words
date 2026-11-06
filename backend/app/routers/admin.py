"""Admin API: login, word management, usage stats, device list.

Auth: either `Authorization: Bearer <token>` (from POST /admin/login, used
by the admin panel) or `X-Admin-Key: <ADMIN_API_KEY>` (for scripts/curl).
Word changes bump the affected content pack versions (see packs.py) so
phones re-download. User (app account) tokens are never accepted here."""

import secrets
from collections import Counter, defaultdict
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy import case, delete, func
from sqlmodel import Session, select

from .. import config, packs, security
from ..database import get_session
from ..languages import DEFAULT_SOURCE, DEFAULT_TARGET, PAIRS, SOURCES, TARGETS
from ..models import AdminCredential, DevicePing, User, Word, WordIssue, WordTranslation, utcnow
from ..schemas import (
    AdminMe,
    AdminWord,
    AdminWordInput,
    AdminWordPatch,
    CoverageRead,
    DeviceList,
    DeviceRow,
    ImportResult,
    ImportRequest,
    IssueStatus,
    LoginRequest,
    LoginResponse,
    PasswordChange,
    PairCoverage,
    StatsRead,
    TargetCoverage,
    WordIssuePatch,
    WordIssueRead,
)


def admin_credentials(session: Session) -> tuple[str, str]:
    """(username, password_hash): the one set from the panel, else .env."""
    row = session.get(AdminCredential, 1)
    if row:
        return row.username, row.password_hash
    return config.ADMIN_USERNAME, config.ADMIN_PASSWORD_HASH


def require_admin(
    authorization: str = Header(default=""),
    x_admin_key: str = Header(default=""),
    session: Session = Depends(get_session),
) -> str:
    """Returns the admin username, or raises 401."""
    username_cfg, password_hash = admin_credentials(session)
    if authorization.lower().startswith("bearer "):
        username = security.verify_token(authorization[7:].strip(), stamp=security.password_stamp(password_hash))
        if username:
            return username
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session expired or invalid, please log in again")
    if x_admin_key:
        if not config.ADMIN_API_KEY:
            raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Admin API key disabled: ADMIN_API_KEY not set")
        if secrets.compare_digest(x_admin_key.encode(), config.ADMIN_API_KEY.encode()):
            return "api-key"
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid admin key")
    if not config.ADMIN_API_KEY and not password_hash:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Admin API disabled: no credentials configured")
    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Not logged in")


# Login must be reachable without credentials, so it lives on its own router.
auth_router = APIRouter(prefix="/admin", tags=["admin"])
router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


def _client_ip(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _login_response(username: str, password_hash: str) -> LoginResponse:
    token, exp = security.create_token(username, stamp=security.password_stamp(password_hash))
    return LoginResponse(token=token, expires_at=datetime.fromtimestamp(exp, tz=timezone.utc), username=username)


@auth_router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, request: Request, session: Session = Depends(get_session)):
    username, password_hash = admin_credentials(session)
    if not password_hash:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Panel login disabled: ADMIN_PASSWORD_HASH not set")
    ip = _client_ip(request)
    if security.is_locked_out(ip):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many failed attempts. Try again in 15 minutes.")
    user_ok = secrets.compare_digest(payload.username.encode(), username.encode())
    pw_ok = security.verify_password(payload.password, password_hash)
    if not (user_ok and pw_ok):
        security.record_failure(ip)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Wrong username or password")
    security.clear_failures(ip)
    return _login_response(username, password_hash)


@router.post("/password", response_model=LoginResponse)
def change_password(payload: PasswordChange, request: Request, session: Session = Depends(get_session)):
    """Change the panel password. Every earlier session is logged out; the
    response carries a fresh token so the caller stays logged in."""
    username, password_hash = admin_credentials(session)
    ip = _client_ip(request)
    if security.is_locked_out(ip):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many failed attempts. Try again in 15 minutes.")
    if not password_hash or not security.verify_password(payload.current_password, password_hash):
        security.record_failure(ip)
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Current password is wrong")
    if payload.new_password == payload.current_password:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "New password must be different from the current one")
    security.clear_failures(ip)
    new_hash = security.hash_password(payload.new_password)
    row = session.get(AdminCredential, 1) or AdminCredential(id=1, username=username, password_hash=new_hash)
    row.password_hash = new_hash
    row.updated_at = utcnow()
    session.add(row)
    session.commit()
    return _login_response(username, new_hash)


@router.get("/me", response_model=AdminMe)
def me(username: str = Depends(require_admin)):
    return AdminMe(username=username)


def _get_word_or_404(session: Session, external_id: str) -> Word:
    word = session.exec(select(Word).where(Word.external_id == external_id)).first()
    if word is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"No word with external_id '{external_id}'")
    return word


def _admin_word(session: Session, word: Word) -> AdminWord:
    return packs.to_admin_word(word, packs.translations_by_word(session, [word.id])[word.id])


@router.get("/words", response_model=list[AdminWord])
def list_words(
    target: Optional[str] = Query(None, min_length=2, max_length=2),
    session: Session = Depends(get_session),
):
    query = select(Word).order_by(Word.id)
    if target:
        query = query.where(Word.lang == target)
    words = session.exec(query).all()
    trs = packs.translations_by_word(session, [w.id for w in words])
    return [packs.to_admin_word(w, trs[w.id]) for w in words]


@router.get("/words/{external_id}", response_model=AdminWord)
def get_word(external_id: str, session: Session = Depends(get_session)):
    return _admin_word(session, _get_word_or_404(session, external_id))


@router.post("/words", response_model=AdminWord, status_code=status.HTTP_201_CREATED)
def create_word(payload: AdminWordInput, session: Session = Depends(get_session)):
    lang = payload.lang or DEFAULT_TARGET
    err = packs.validate_word_fields(lang, payload.article, payload.category, payload.translations.keys())
    if err:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, err)
    exists = session.exec(select(Word.id).where(Word.external_id == payload.external_id)).first()
    if exists is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, f"external_id '{payload.external_id}' already exists")
    res = packs.upsert_word(session, payload, lang)
    packs.bump(session, res.bumped)
    session.commit()
    session.refresh(res.word)
    return _admin_word(session, res.word)


@router.patch("/words/{external_id}", response_model=AdminWord)
def update_word(external_id: str, payload: AdminWordPatch, session: Session = Depends(get_session)):
    word = _get_word_or_404(session, external_id)
    changes = payload.model_dump(exclude_unset=True)
    tr_changes = changes.pop("translations", None) or {}
    for field in ("term", "example", "category", "difficulty", "topics"):
        if field in changes and changes[field] is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"{field} can't be null")
    if "topics" in changes:
        changes["topics"] = packs.topics_to_db(changes["topics"])
    if changes.get("level"):
        changes["difficulty"] = packs.difficulty_for(changes["level"], word.difficulty)
    err = packs.validate_word_fields(word.lang, changes.get("article"), changes.get("category"), tr_changes.keys())
    if err:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, err)

    existing = packs.translations_by_word(session, [word.id])[word.id]
    tr_data = {}
    for lang, data in tr_changes.items():
        if data is None:
            tr_data[lang] = None
            continue
        fields = payload.translations[lang].model_dump(exclude_unset=True)
        if lang not in existing and not fields.get("translation"):
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT,
                                f"translations.{lang}.translation is required for a new language")
        if "translation" in fields and fields["translation"] is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"translations.{lang}.translation can't be null")
        tr_data[lang] = fields

    target_changed = False
    for key, value in changes.items():
        if getattr(word, key) != value:
            setattr(word, key, value)
            target_changed = True
    changed_langs = packs.apply_translations(session, word, existing, tr_data, partial=True)
    bumped = (packs.pairs_of_target(word.lang) if target_changed else set()) | {(s, word.lang) for s in changed_langs}
    if bumped:
        word.updated_at = utcnow()
        session.add(word)
        packs.bump(session, bumped)
        session.commit()
        session.refresh(word)
    return _admin_word(session, word)


@router.delete("/words/{external_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_word(external_id: str, session: Session = Depends(get_session)):
    word = _get_word_or_404(session, external_id)
    session.execute(delete(WordTranslation).where(WordTranslation.word_id == word.id))
    session.delete(word)
    packs.bump(session, packs.pairs_of_target(word.lang))
    session.commit()


MAX_IMPORT_WORDS = 2000


@router.post("/import", response_model=ImportResult)
def import_words(payload: ImportRequest, dry_run: bool = Query(True), session: Session = Depends(get_session)):
    """Upsert many words by external_id (content-file shape). dry_run
    (default true) validates and reports without writing anything."""
    if len(payload.words) > MAX_IMPORT_WORDS:
        raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, f"At most {MAX_IMPORT_WORDS} words per import")
    if payload.target is not None and payload.target not in TARGETS:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"target must be one of {', '.join(TARGETS)}")
    return packs.import_words(session, payload.words, default_target=payload.target, dry_run=dry_run)


@router.get("/coverage", response_model=CoverageRead)
def coverage(session: Session = Depends(get_session)):
    words = packs.target_word_counts(session)
    pair_counts = packs.pair_word_counts(session)
    targets = [
        TargetCoverage(
            target=t,
            words=words.get(t, 0),
            translations={s: pair_counts.get((s, t), 0) for s in SOURCES if s != t},
        )
        for t in TARGETS
    ]
    pairs = [
        PairCoverage(source=s, target=t, words=pair_counts.get((s, t), 0),
                     available=packs.is_available(s, t, pair_counts.get((s, t), 0)))
        for s, t in PAIRS
    ]
    return CoverageRead(targets=targets, pairs=pairs, min_pair_words=config.MIN_PAIR_WORDS)


# --- word issues ("Report a mistake") ---------------------------------------------

def _issue_read(issue: WordIssue, term: Optional[str]) -> WordIssueRead:
    return WordIssueRead(term=term, **issue.model_dump())


@router.get("/word-issues", response_model=list[WordIssueRead])
def list_word_issues(
    status_: Optional[IssueStatus] = Query(None, alias="status"),
    limit: int = Query(200, ge=1, le=1000),
    session: Session = Depends(get_session),
):
    query = (
        select(WordIssue, Word.term)
        .join(Word, Word.external_id == WordIssue.external_id, isouter=True)
        .order_by(WordIssue.id.desc())
        .limit(limit)
    )
    if status_:
        query = query.where(WordIssue.status == status_)
    return [_issue_read(issue, term) for issue, term in session.exec(query).all()]


@router.patch("/word-issues/{issue_id}", response_model=WordIssueRead)
def update_word_issue(issue_id: int, payload: WordIssuePatch, session: Session = Depends(get_session)):
    issue = session.get(WordIssue, issue_id)
    if issue is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"No word issue {issue_id}")
    issue.status = payload.status
    session.add(issue)
    session.commit()
    session.refresh(issue)
    term = session.exec(select(Word.term).where(Word.external_id == issue.external_id)).first()
    return _issue_read(issue, term)


# --- usage stats & devices --------------------------------------------------

def _utc(dt: datetime | None) -> datetime | None:
    """SQLite hands back naive datetimes; everything is stored in UTC."""
    if dt is None:
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _platform(os_version: str | None) -> str:
    return (os_version or "unknown").split(" ")[0].lower() or "unknown"


def _latest(column, non_null: bool = False):
    """Correlated subquery: this device's value from its most recent ping
    (optionally: the most recent ping where that value is set)."""
    p2 = DevicePing.__table__.alias("p2")
    query = select(p2.c[column]).where(p2.c.device_id == DevicePing.device_id)
    if non_null:
        query = query.where(p2.c[column].is_not(None))
    return query.order_by(p2.c.id.desc()).limit(1).scalar_subquery()


def _device_query():
    return select(
        DevicePing.device_id,
        func.min(DevicePing.created_at).label("first_seen"),
        func.max(DevicePing.created_at).label("last_seen"),
        func.count().label("pings"),
        func.sum(case((DevicePing.event_type == "app_open", 1), else_=0)).label("app_opens"),
        func.sum(case((DevicePing.event_type == "notif_tapped", 1), else_=0)).label("notif_taps"),
        _latest("os_version").label("os_version"),
        _latest("app_version").label("app_version"),
        _latest("pair", non_null=True).label("pair"),
    ).group_by(DevicePing.device_id)


@router.get("/stats", response_model=StatsRead)
def stats(session: Session = Depends(get_session)):
    now = datetime.now(timezone.utc)
    today = now.date()
    meta = packs.get_meta(session, DEFAULT_SOURCE, DEFAULT_TARGET)

    devices = session.exec(_device_query()).all()
    last_seen = {d.device_id: _utc(d.last_seen) for d in devices}
    first_seen = {d.device_id: _utc(d.first_seen) for d in devices}

    def active_since(days: int) -> int:
        cutoff = datetime.combine(today - timedelta(days=days - 1), datetime.min.time(), timezone.utc)
        return sum(1 for t in last_seen.values() if t >= cutoff)

    week_ago = now - timedelta(days=7)
    events = dict(
        session.exec(select(DevicePing.event_type, func.count()).group_by(DevicePing.event_type)).all()
    )

    # Daily series over the last 30 UTC days, every day present.
    start_day = today - timedelta(days=29)
    start = datetime.combine(start_day, datetime.min.time(), timezone.utc)
    rows = session.exec(
        select(DevicePing.device_id, DevicePing.event_type, DevicePing.created_at).where(
            DevicePing.created_at >= start  # tz-aware; sqlmodel stores/compares as UTC
        )
    ).all()
    day_devices: dict[date, set] = defaultdict(set)
    day_opens: Counter = Counter()
    day_taps: Counter = Counter()
    for device_id, event_type, created_at in rows:
        d = _utc(created_at).date()
        day_devices[d].add(device_id)
        if event_type == "app_open":
            day_opens[d] += 1
        elif event_type == "notif_tapped":
            day_taps[d] += 1
    daily = []
    for i in range(30):
        d = start_day + timedelta(days=i)
        daily.append({
            "date": d.isoformat(),
            "active_devices": len(day_devices[d]),
            "app_opens": day_opens[d],
            "notif_taps": day_taps[d],
        })

    platforms = Counter(_platform(d.os_version) for d in devices)
    versions = Counter(d.app_version or "unknown" for d in devices)
    pairs = Counter(d.pair for d in devices if d.pair)

    return StatsRead(
        words_total=session.exec(select(func.count()).select_from(Word)).one(),
        pack_version=meta.version if meta else 0,
        pack_updated_at=_utc(meta.updated_at) if meta else None,
        devices_total=len(devices),
        active_today=active_since(1),
        active_7d=active_since(7),
        active_30d=active_since(30),
        new_7d=sum(1 for t in first_seen.values() if t >= week_ago),
        pings_total=sum(events.values()),
        events={k: events.get(k, 0) for k in ("app_open", "notif_tapped", "notif_delivered")},
        daily=daily,
        platforms=[{"os": k, "devices": v} for k, v in platforms.most_common()],
        app_versions=[{"version": k, "devices": v} for k, v in versions.most_common()],
        pairs=[{"pair": k, "devices": v} for k, v in pairs.most_common()],
        users_total=session.exec(select(func.count()).select_from(User)).one(),
    )


@router.get("/devices", response_model=DeviceList)
def devices(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    q: str = Query("", max_length=64),
    session: Session = Depends(get_session),
):
    base = _device_query()
    if q:
        base = base.where(DevicePing.device_id.contains(q.strip()))
    total = session.exec(select(func.count()).select_from(base.subquery())).one()
    rows = session.exec(
        base.order_by(func.max(DevicePing.created_at).desc()).limit(limit).offset(offset)
    ).all()
    return DeviceList(
        total=total,
        items=[
            DeviceRow(
                device_id=r.device_id,
                first_seen=_utc(r.first_seen),
                last_seen=_utc(r.last_seen),
                os_version=r.os_version,
                app_version=r.app_version,
                pair=r.pair,
                pings=r.pings,
                app_opens=r.app_opens or 0,
                notif_taps=r.notif_taps or 0,
            )
            for r in rows
        ],
    )
