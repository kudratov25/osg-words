"""Minimal user accounts: sign in with a 6-digit code sent by email.

Only enabled when an email sender is configured (config.auth_enabled());
otherwise every /auth/* returns 503. /me keeps working for existing
sessions so an account can always be deleted.

Security notes:
  - codes are stored as HMAC-SHA256(AUTH_CODE_SECRET, email:code), compared
    in constant time; 10 min lifetime, 5 attempts, only the newest code of
    an email counts;
  - session tokens are random (`osgu_...`), only sha256(token) is stored;
    they are not admin tokens and are rejected by /admin/*;
  - rate limits: 3 codes per email per 15 min (DB), 10 per IP per 15 min
    (in memory, per process).
"""

import hashlib
import hmac
import re
import secrets
import time
from collections import defaultdict, deque
from datetime import timedelta

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy import delete, func, update
from sqlmodel import Session, select

from .. import config, emailer
from ..database import get_session
from ..models import AuthSession, DeviceLink, DevicePing, LoginCode, User, WordIssue, utcnow
from ..schemas import AuthConfigRead, AuthTokenRead, EmailStart, EmailVerify, UserRead

CODE_TTL = timedelta(minutes=10)
MAX_ATTEMPTS = 5
RATE_WINDOW = timedelta(minutes=15)
MAX_CODES_PER_EMAIL = 3
MAX_CODES_PER_IP = 10
TOKEN_PREFIX = "osgu_"
DELETED_DEVICE_ID = "deleted"  # word issues of deleted accounts keep this

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
_ip_starts: dict[str, deque] = defaultdict(deque)


def _require_enabled() -> None:
    if not config.auth_enabled():
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Accounts are not enabled on this server")


router = APIRouter(prefix="/auth", tags=["auth"], dependencies=[Depends(_require_enabled)])
config_router = APIRouter(prefix="/auth", tags=["auth"])
me_router = APIRouter(tags=["auth"])


def normalize_email(raw: str) -> str:
    email = raw.strip().lower()
    if not _EMAIL_RE.match(email):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Invalid email address")
    return email


def hash_code(email: str, code: str) -> str:
    return hmac.new(config.AUTH_CODE_SECRET.encode(), f"{email}:{code}".encode(), hashlib.sha256).hexdigest()


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _ip_allowed(ip: str) -> bool:
    now = time.time()
    q = _ip_starts[ip]
    while q and q[0] < now - RATE_WINDOW.total_seconds():
        q.popleft()
    if len(q) >= MAX_CODES_PER_IP:
        return False
    q.append(now)
    return True


@config_router.get("/config", response_model=AuthConfigRead)
def auth_config():
    enabled = config.auth_enabled()
    return AuthConfigRead(enabled=enabled, methods=["email_code"] if enabled else [])


@router.post("/email/start", status_code=204)
def email_start(payload: EmailStart, request: Request, session: Session = Depends(get_session)):
    email = normalize_email(payload.email)
    now = utcnow()
    recent = session.exec(
        select(func.count()).select_from(LoginCode).where(
            LoginCode.email == email, LoginCode.created_at >= now - RATE_WINDOW
        )
    ).one()
    if recent >= MAX_CODES_PER_EMAIL:
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many codes requested. Try again in 15 minutes.")
    ip = request.client.host if request.client else "unknown"
    if not _ip_allowed(ip):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many codes requested. Try again in 15 minutes.")

    # Housekeeping: old codes are useless.
    session.exec(delete(LoginCode).where(LoginCode.created_at < now - timedelta(days=1)))
    code = f"{secrets.randbelow(10**6):06d}"
    session.add(LoginCode(email=email, code_hash=hash_code(email, code), expires_at=now + CODE_TTL, created_at=now))
    session.commit()
    try:
        emailer.send_login_code(email, code)
    except emailer.EmailError:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Could not send the email. Try again later.")


@router.post("/email/verify", response_model=AuthTokenRead)
def email_verify(payload: EmailVerify, session: Session = Depends(get_session)):
    email = normalize_email(payload.email)
    now = utcnow()
    login = session.exec(
        select(LoginCode).where(LoginCode.email == email).order_by(LoginCode.id.desc())
    ).first()
    if login is None or login.used_at is not None:
        raise HTTPException(400, "No active code for this email. Request a new one.")
    if login.expires_at <= now:
        raise HTTPException(400, "Code expired. Request a new one.")
    if login.attempts >= MAX_ATTEMPTS:
        raise HTTPException(400, "Too many wrong attempts. Request a new code.")
    code = re.sub(r"\s", "", payload.code)
    if not hmac.compare_digest(hash_code(email, code), login.code_hash):
        login.attempts += 1
        session.add(login)
        session.commit()
        left = MAX_ATTEMPTS - login.attempts
        raise HTTPException(400, f"Wrong code. {left} attempt(s) left." if left else
                            "Wrong code. Too many wrong attempts. Request a new code.")

    login.used_at = now
    session.add(login)
    user = session.exec(select(User).where(User.email == email)).first()
    if user is None:
        user = User(email=email, created_at=now)
        session.add(user)
        session.flush()
    if payload.device_id:
        link = session.get(DeviceLink, (user.id, payload.device_id))
        if link is None:
            session.add(DeviceLink(user_id=user.id, device_id=payload.device_id))
    token = TOKEN_PREFIX + secrets.token_urlsafe(32)
    session.add(AuthSession(user_id=user.id, token_hash=hash_token(token), created_at=now,
                            expires_at=now + timedelta(days=config.USER_SESSION_DAYS)))
    session.commit()
    session.refresh(user)
    return AuthTokenRead(token=token, user=UserRead(id=user.id, email=user.email, created_at=user.created_at))


def current_session(
    authorization: str = Header(default=""),
    session: Session = Depends(get_session),
) -> AuthSession:
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Not signed in")
    token = authorization[7:].strip()
    auth = session.exec(select(AuthSession).where(AuthSession.token_hash == hash_token(token))).first()
    if auth is None or auth.revoked_at is not None or auth.expires_at <= utcnow():
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session expired or invalid, please sign in again")
    return auth


@router.post("/logout", status_code=204)
def logout(auth: AuthSession = Depends(current_session), session: Session = Depends(get_session)):
    auth.revoked_at = utcnow()
    session.add(auth)
    session.commit()


@me_router.get("/me", response_model=UserRead)
def me(auth: AuthSession = Depends(current_session), session: Session = Depends(get_session)):
    user = session.get(User, auth.user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Account no longer exists")
    return UserRead(id=user.id, email=user.email, created_at=user.created_at)


@me_router.delete("/me", status_code=204)
def delete_me(auth: AuthSession = Depends(current_session), session: Session = Depends(get_session)):
    """Deletes the account, its sessions and device links, and the
    telemetry pings of linked devices (they'd identify the person).
    Word reports from linked devices are kept (the word fix stays useful)
    but anonymized: their device_id becomes "deleted"."""
    user = session.get(User, auth.user_id)
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Account no longer exists")
    device_ids = list(session.exec(select(DeviceLink.device_id).where(DeviceLink.user_id == user.id)).all())
    if device_ids:
        session.exec(delete(DevicePing).where(DevicePing.device_id.in_(device_ids)))
        session.exec(update(WordIssue).where(WordIssue.device_id.in_(device_ids)).values(device_id=DELETED_DEVICE_ID))
    session.exec(delete(DeviceLink).where(DeviceLink.user_id == user.id))
    session.exec(delete(AuthSession).where(AuthSession.user_id == user.id))
    session.exec(delete(LoginCode).where(LoginCode.email == user.email))
    session.exec(delete(User).where(User.id == user.id))
    session.commit()
