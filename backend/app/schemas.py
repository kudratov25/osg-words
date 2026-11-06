from datetime import datetime
from typing import Annotated, Any, Literal, Optional

from pydantic import StringConstraints, model_validator
from sqlmodel import Field, SQLModel

Difficulty = Literal["beginner", "intermediate", "advanced"]
Level = Literal["A1", "A2", "B1", "B2", "C1"]
Topic = Literal["retail", "it", "medicine", "hospitality", "construction", "logistics", "office", "care"]
EventType = Literal["app_open", "notif_delivered", "notif_tapped"]
IssueKind = Literal["wrong_translation", "wrong_article", "wrong_example", "other"]
IssueStatus = Literal["open", "resolved"]
PAIR_PATTERN = r"^[a-z]{2}-[a-z]{2}$"
LANG_PATTERN = r"^[a-z]{2}$"
# sqlmodel's Field(regex=...) isn't enforced, so patterns go in the type.
PairCode = Annotated[str, StringConstraints(pattern=PAIR_PATTERN)]
LangCode = Annotated[str, StringConstraints(pattern=LANG_PATTERN)]


# --- public content -------------------------------------------------------------

class WordRead(SQLModel):
    """One word of a pack, flattened for one source language.
    `german` is an alias of `term`, kept for app v1.0.x (always present)."""

    external_id: str
    lang: str
    term: str
    german: str
    article: Optional[str]
    translation: str
    example: str
    example_translation: Optional[str]
    pronunciation: Optional[str]
    category: str
    difficulty: str
    level: Optional[str] = None
    topics: list[str] = []
    created_at: datetime


class ContentMetaRead(SQLModel):
    version: int
    updated_at: datetime
    source: str
    target: str


class ContentPackRead(SQLModel):
    version: int
    source: str
    target: str
    words: list[WordRead]


class PairRead(SQLModel):
    source: str
    target: str
    words: int
    version: int


class PairList(SQLModel):
    pairs: list[PairRead]


class DevicePingCreate(SQLModel):
    device_id: str = Field(min_length=1, max_length=64)
    device_model: Optional[str] = Field(default=None, max_length=100)
    os_version: Optional[str] = Field(default=None, max_length=100)
    app_version: Optional[str] = Field(default=None, max_length=32)
    event_type: EventType
    pair: Optional[PairCode] = None


class WordIssueCreate(SQLModel):
    device_id: str = Field(min_length=1, max_length=64)
    external_id: str = Field(min_length=1, max_length=64)
    source: LangCode
    target: LangCode
    kind: IssueKind
    note: Optional[str] = Field(default=None, max_length=300)


# --- admin: words -------------------------------------------------------------------

class TranslationIn(SQLModel):
    translation: str = Field(min_length=1, max_length=200)
    example_translation: Optional[str] = Field(default=None, max_length=500)


class TranslationPatch(SQLModel):
    """Partial: only fields sent are changed. A language the word doesn't
    have yet needs `translation`."""

    translation: Optional[str] = Field(default=None, min_length=1, max_length=200)
    example_translation: Optional[str] = Field(default=None, max_length=500)


class TranslationRead(SQLModel):
    translation: str
    example_translation: Optional[str]


def _legacy_word_fields(data: Any) -> Any:
    """Accept the v1 admin shape too: `german` -> term, `translation` -> en."""
    if not isinstance(data, dict):
        return data
    data = dict(data)
    if "german" in data:
        german = data.pop("german")
        data.setdefault("term", german)
    if "translation" in data:
        tr = data.pop("translation")
        translations = dict(data.get("translations") or {})
        if tr is not None and "en" not in translations:
            translations["en"] = {"translation": tr}
        data["translations"] = translations
    return data


class AdminWordInput(SQLModel):
    """A word as sent to POST /admin/words and /admin/import (same shape as
    the items of backend/content/*.json). `lang` defaults to the import's
    `target`, else `de`."""

    external_id: str = Field(min_length=1, max_length=64)
    lang: Optional[LangCode] = None
    term: str = Field(min_length=1, max_length=200)
    article: Optional[str] = Field(default=None, max_length=10)
    example: str = Field(min_length=1, max_length=500)
    pronunciation: Optional[str] = Field(default=None, max_length=200)
    category: str = Field(min_length=1, max_length=50)
    difficulty: Difficulty = "beginner"
    level: Optional[Level] = None
    topics: list[Topic] = Field(default_factory=list)
    translations: dict[str, Optional[TranslationIn]] = Field(default_factory=dict)

    @model_validator(mode="before")
    @classmethod
    def _legacy(cls, data: Any) -> Any:
        return _legacy_word_fields(data)


class AdminWordPatch(SQLModel):
    """Partial update. external_id and lang can't be changed.
    `translations` is merged per language; `{"uz": null}` removes uz."""

    term: Optional[str] = Field(default=None, min_length=1, max_length=200)
    article: Optional[str] = Field(default=None, max_length=10)
    example: Optional[str] = Field(default=None, min_length=1, max_length=500)
    pronunciation: Optional[str] = Field(default=None, max_length=200)
    category: Optional[str] = Field(default=None, min_length=1, max_length=50)
    difficulty: Optional[Difficulty] = None
    level: Optional[Level] = None
    topics: Optional[list[Topic]] = None
    translations: Optional[dict[str, Optional[TranslationPatch]]] = None

    @model_validator(mode="before")
    @classmethod
    def _legacy(cls, data: Any) -> Any:
        return _legacy_word_fields(data)


class AdminWord(SQLModel):
    external_id: str
    lang: str
    term: str
    article: Optional[str]
    example: str
    pronunciation: Optional[str]
    category: str
    difficulty: str
    level: Optional[str] = None
    topics: list[str] = []
    created_at: datetime
    updated_at: datetime
    translations: dict[str, TranslationRead]


class ImportRequest(SQLModel):
    """Same shape as backend/content/<target>.json; `target` is optional.
    Items are validated one by one so a bad item doesn't fail the batch."""

    target: Optional[LangCode] = None
    words: list[Any]  # max 2000, checked in the router; items validated one by one


class ImportError_(SQLModel):
    index: int
    external_id: Optional[str]
    error: str


class ImportResult(SQLModel):
    dry_run: bool
    created: int
    updated: int
    unchanged: int
    errors: list[ImportError_]
    bumped: list[str]


class TargetCoverage(SQLModel):
    target: str
    words: int
    translations: dict[str, int]


class PairCoverage(SQLModel):
    source: str
    target: str
    words: int
    available: bool


class CoverageRead(SQLModel):
    targets: list[TargetCoverage]
    pairs: list[PairCoverage]
    min_pair_words: int


class WordIssueRead(SQLModel):
    id: int
    device_id: str
    external_id: str
    term: Optional[str]  # current term of the word, null if it was deleted
    source: str
    target: str
    kind: str
    note: Optional[str]
    status: str
    created_at: datetime


class WordIssuePatch(SQLModel):
    status: IssueStatus


# --- auth (user accounts) ---------------------------------------------------------------

class AuthConfigRead(SQLModel):
    enabled: bool
    methods: list[str]


class EmailStart(SQLModel):
    email: str = Field(min_length=3, max_length=254)


class EmailVerify(SQLModel):
    email: str = Field(min_length=3, max_length=254)
    code: str = Field(min_length=1, max_length=12)
    device_id: Optional[str] = Field(default=None, min_length=1, max_length=64)


class UserRead(SQLModel):
    id: int
    email: str
    created_at: datetime


class AuthTokenRead(SQLModel):
    token: str
    user: UserRead


# --- admin panel --------------------------------------------------------------

class LoginRequest(SQLModel):
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=256)


class LoginResponse(SQLModel):
    token: str
    expires_at: datetime
    username: str


class PasswordChange(SQLModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=10, max_length=256)


class AdminMe(SQLModel):
    username: str


class DailyPoint(SQLModel):
    date: str
    active_devices: int
    app_opens: int
    notif_taps: int


class PlatformCount(SQLModel):
    os: str
    devices: int


class VersionCount(SQLModel):
    version: str
    devices: int


class PairCount(SQLModel):
    pair: str
    devices: int


class StatsRead(SQLModel):
    words_total: int
    pack_version: int  # of the default pair en-de (what v1 apps download)
    pack_updated_at: Optional[datetime]
    devices_total: int
    active_today: int
    active_7d: int
    active_30d: int
    new_7d: int
    pings_total: int
    events: dict[str, int]
    daily: list[DailyPoint]
    platforms: list[PlatformCount]
    app_versions: list[VersionCount]
    pairs: list[PairCount]
    users_total: int


class DeviceRow(SQLModel):
    device_id: str
    first_seen: datetime
    last_seen: datetime
    os_version: Optional[str]
    app_version: Optional[str]
    pair: Optional[str]
    pings: int
    app_opens: int
    notif_taps: int


class DeviceList(SQLModel):
    total: int
    items: list[DeviceRow]
