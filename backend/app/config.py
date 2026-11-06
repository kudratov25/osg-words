"""Runtime settings, read from environment variables.

Locally nothing needs to be set: the defaults give a SQLite file, an admin
API that is switched off and user accounts that are switched off.

Core:
  DATABASE_URL   e.g. postgresql://user:pass@host:5432/dbname
                 (hosts like Railway/Render provide this automatically)
  ADMIN_API_KEY  long random string; required to use /admin/* with X-Admin-Key
  ADMIN_USERNAME / ADMIN_PASSWORD_HASH / SECRET_KEY / TOKEN_TTL_HOURS
                 admin panel login (python -m app.set_password)

Content:
  MIN_PAIR_WORDS  a language pair is offered to the app once its target has
                  at least this many words translated into its source
                  (default 100). en-de is always served (built into the app).
  CONTENT_DIR     where de.json / en.json are read from on first start
                  (default: backend/content)

User accounts (email code login). Off unless EMAIL_BACKEND is set:
  EMAIL_BACKEND   "smtp" (real email) or "console" (code is written to the
                  log; for development and tests only). Empty = /auth/* -> 503.
  SMTP_HOST, SMTP_PORT (default 587), SMTP_USER, SMTP_PASSWORD, SMTP_FROM
                  for EMAIL_BACKEND=smtp. STARTTLS is used unless
                  SMTP_STARTTLS=0 (only for a local relay).
  AUTH_CODE_SECRET  server secret mixed into the stored hash of login codes
                  (falls back to SECRET_KEY). Changing it invalidates pending
                  codes only, not sessions.
  USER_SESSION_DAYS lifetime of a user session token (default 180).
"""

import os
import secrets
from pathlib import Path


def _normalize_db_url(url: str) -> str:
    # Hosts usually hand out "postgres://..." or "postgresql://...". SQLAlchemy
    # needs the driver named explicitly to use psycopg (v3).
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://"):]
    if url.startswith("postgresql://"):
        url = "postgresql+psycopg://" + url[len("postgresql://"):]
    return url


BACKEND_DIR = Path(__file__).resolve().parent.parent

DATABASE_URL: str = _normalize_db_url(os.environ.get("DATABASE_URL", "sqlite:///./osg.db"))

# Empty/unset = admin endpoints disabled (they return 503).
ADMIN_API_KEY: str = os.environ.get("ADMIN_API_KEY", "")

# Admin panel login. Generate with: python -m app.set_password
# Empty ADMIN_PASSWORD_HASH = panel login disabled (returns 503).
ADMIN_USERNAME: str = os.environ.get("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD_HASH: str = os.environ.get("ADMIN_PASSWORD_HASH", "")

# Signs login tokens. Changing it logs everyone out. If unset, a random one
# is used per process start (tokens then don't survive a restart).
SECRET_KEY: str = os.environ.get("SECRET_KEY") or secrets.token_urlsafe(32)
TOKEN_TTL_HOURS: int = int(os.environ.get("TOKEN_TTL_HOURS", "12"))

# --- content ------------------------------------------------------------------
MIN_PAIR_WORDS: int = int(os.environ.get("MIN_PAIR_WORDS", "100"))
CONTENT_DIR: Path = Path(os.environ.get("CONTENT_DIR") or BACKEND_DIR / "content")

# --- user accounts ----------------------------------------------------------------
EMAIL_BACKEND: str = os.environ.get("EMAIL_BACKEND", "").strip().lower()  # "" | console | smtp
SMTP_HOST: str = os.environ.get("SMTP_HOST", "")
SMTP_PORT: int = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USER: str = os.environ.get("SMTP_USER", "")
SMTP_PASSWORD: str = os.environ.get("SMTP_PASSWORD", "")
SMTP_FROM: str = os.environ.get("SMTP_FROM", "")
SMTP_STARTTLS: bool = os.environ.get("SMTP_STARTTLS", "1") not in ("0", "false", "no")
AUTH_CODE_SECRET: str = os.environ.get("AUTH_CODE_SECRET") or SECRET_KEY
USER_SESSION_DAYS: int = int(os.environ.get("USER_SESSION_DAYS", "180"))


def auth_enabled() -> bool:
    """Accounts are on only when an email sender is configured."""
    if EMAIL_BACKEND == "console":
        return True
    if EMAIL_BACKEND == "smtp":
        return bool(SMTP_HOST and SMTP_FROM)
    return False
