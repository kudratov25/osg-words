"""Database tables. The schema itself is owned by Alembic (migrations/):
any change here needs a new migration, see migrations/versions/.

Datetimes are timezone-aware UTC everywhere (sqlmodel 0.0.48 refuses naive
datetimes in queries)."""

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Column, ForeignKey, Integer, UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Word(SQLModel, table=True):
    """A vocabulary item of one target language (`lang`).

    external_id is globally unique and stable across re-seeds/updates so the
    app can dedupe when merging a freshly-downloaded pack into its local cache.
    Translations live in WordTranslation, one row per source language.
    """

    id: Optional[int] = Field(default=None, primary_key=True)
    external_id: str = Field(index=True, unique=True)
    lang: str = Field(default="de", index=True, sa_column_kwargs={"server_default": "de"})
    term: str
    article: Optional[str] = None
    example: str
    pronunciation: Optional[str] = None
    category: str
    difficulty: str = "beginner"  # beginner | intermediate | advanced (derived from level)
    level: Optional[str] = None  # A1..C1 (v2.1)
    # Comma-separated job-area keys (languages.TOPICS); "" = general word.
    topics: str = Field(default="", sa_column_kwargs={"server_default": ""})
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)


class WordTranslation(SQLModel, table=True):
    __table_args__ = (UniqueConstraint("word_id", "lang", name="uq_wordtranslation_word_lang"),)

    id: Optional[int] = Field(default=None, primary_key=True)
    word_id: int = Field(
        sa_column=Column(Integer, ForeignKey("word.id", ondelete="CASCADE"), nullable=False, index=True)
    )
    lang: str  # source language
    translation: str
    example_translation: Optional[str] = None


class PackMeta(SQLModel, table=True):
    """Content pack version per pair (target, source).

    Clients check /content/meta cheaply before downloading the word list.
    Bump rules (see packs.py): a change to a word's target-side fields bumps
    every pack of that target; a translation change bumps only that pair.
    """

    __table_args__ = (UniqueConstraint("target", "source", name="uq_packmeta_target_source"),)

    id: Optional[int] = Field(default=None, primary_key=True)
    target: str
    source: str
    version: int = 1
    updated_at: datetime = Field(default_factory=utcnow)


class DevicePing(SQLModel, table=True):
    """Anonymous device/usage telemetry. device_id is a client-generated
    UUID with no identity attached, unless the user signs in on that
    device (DeviceLink); deleting the account deletes those pings."""

    id: Optional[int] = Field(default=None, primary_key=True)
    device_id: str = Field(index=True)
    device_model: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None
    event_type: str  # app_open | notif_delivered | notif_tapped
    pair: Optional[str] = None  # e.g. "uz-de"
    created_at: datetime = Field(default_factory=utcnow)


class WordIssue(SQLModel, table=True):
    """A "Report a mistake" sent from the word card."""

    id: Optional[int] = Field(default=None, primary_key=True)
    device_id: str = Field(index=True)
    external_id: str = Field(index=True)
    source: str
    target: str
    kind: str  # wrong_translation | wrong_article | wrong_example | other
    note: Optional[str] = None
    status: str = Field(default="open", index=True)  # open | resolved
    created_at: datetime = Field(default_factory=utcnow)


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True, unique=True)  # always lowercased
    name: Optional[str] = None  # not asked for in v2
    age_range: Optional[str] = None  # not asked for in v2
    created_at: datetime = Field(default_factory=utcnow)


class LoginCode(SQLModel, table=True):
    """A 6-digit email code. Only its keyed hash is stored."""

    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True)
    code_hash: str
    expires_at: datetime
    attempts: int = 0
    used_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=utcnow)


class AuthSession(SQLModel, table=True):
    """A signed-in app. The bearer token is random; only sha256(token) is stored."""

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(
        sa_column=Column(Integer, ForeignKey("user.id", ondelete="CASCADE"), nullable=False, index=True)
    )
    token_hash: str = Field(index=True, unique=True)
    created_at: datetime = Field(default_factory=utcnow)
    expires_at: datetime
    revoked_at: Optional[datetime] = None


class DeviceLink(SQLModel, table=True):
    """Device (telemetry device_id) used by a signed-in user."""

    user_id: int = Field(
        sa_column=Column(Integer, ForeignKey("user.id", ondelete="CASCADE"), primary_key=True)
    )
    device_id: str = Field(primary_key=True)


class AdminCredential(SQLModel, table=True):
    """Admin panel password set from the panel (Settings → Change password).

    At most one row (id=1). When present it replaces ADMIN_USERNAME /
    ADMIN_PASSWORD_HASH from .env; `python -m app.set_password --reset`
    deletes it so .env applies again."""

    id: Optional[int] = Field(default=None, primary_key=True)
    username: str
    password_hash: str
    updated_at: datetime = Field(default_factory=utcnow)
