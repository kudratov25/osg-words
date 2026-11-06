"""Alembic migrations on a database built the v1 way (create_all, no
alembic_version) — the production case — plus fresh DBs and downgrade."""

from datetime import datetime, timezone

import pytest
import sqlalchemy as sa
from fastapi.testclient import TestClient

from app.database import engine
from app.main import app
from app.migrate import downgrade_db, upgrade_db
from app.seed_words import SEED_WORDS

from .conftest import drop_everything

T0 = datetime(2026, 11, 4, 15, 33, 46, 236512, tzinfo=timezone.utc)


def build_v1_db(eng) -> None:
    """Exactly what v1's SQLModel.metadata.create_all produced."""
    md = sa.MetaData()
    word = sa.Table(
        "word", md,
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("external_id", sa.String, nullable=False, index=True, unique=True),
        sa.Column("german", sa.String, nullable=False),
        sa.Column("article", sa.String),
        sa.Column("translation", sa.String, nullable=False),
        sa.Column("example", sa.String, nullable=False),
        sa.Column("pronunciation", sa.String),
        sa.Column("category", sa.String, nullable=False),
        sa.Column("difficulty", sa.String, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    packmeta = sa.Table(
        "packmeta", md,
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("version", sa.Integer, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    ping = sa.Table(
        "deviceping", md,
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("device_id", sa.String, nullable=False, index=True),
        sa.Column("device_model", sa.String),
        sa.Column("os_version", sa.String),
        sa.Column("app_version", sa.String),
        sa.Column("event_type", sa.String, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    md.create_all(eng)
    with eng.begin() as conn:
        conn.execute(word.insert(), [
            {"pronunciation": None, "difficulty": "beginner", **w, "created_at": T0} for w in SEED_WORDS
        ])
        conn.execute(packmeta.insert(), [{"version": 7, "updated_at": T0}])
        conn.execute(ping.insert(), [
            {"device_id": f"dev-{i % 3}", "event_type": "app_open", "os_version": "android 14",
             "app_version": "1.0.0", "created_at": T0} for i in range(32)
        ])


@pytest.fixture
def v1_db():
    drop_everything()
    build_v1_db(engine)
    yield engine
    drop_everything()


def scalar(sql, **params):
    with engine.connect() as conn:
        return conn.execute(sa.text(sql), params).scalar()


def test_upgrade_v1_database_in_place(v1_db):
    upgrade_db(v1_db)
    assert scalar("SELECT version_num FROM alembic_version") == "0004"
    assert scalar("SELECT count(*) FROM word") == len(SEED_WORDS)
    assert scalar("SELECT count(*) FROM wordtranslation WHERE lang = 'en'") == len(SEED_WORDS)
    assert scalar("SELECT count(*) FROM word WHERE lang = 'de'") == len(SEED_WORDS)
    assert scalar("SELECT count(*) FROM deviceping") == 32
    assert scalar("SELECT count(*) FROM deviceping WHERE pair IS NULL") == 32
    assert scalar("SELECT version FROM packmeta WHERE target = 'de' AND source = 'en'") == 7
    assert scalar("SELECT count(*) FROM packmeta") == 1
    cols = {c["name"] for c in sa.inspect(engine).get_columns("word")}
    assert "german" not in cols and "translation" not in cols and {"term", "lang", "updated_at"} <= cols
    with engine.connect() as conn:
        rows = conn.execute(sa.text(
            "SELECT w.external_id, w.term, w.article, w.example, t.translation "
            "FROM word w JOIN wordtranslation t ON t.word_id = w.id ORDER BY w.id")).all()
    assert [tuple(r) for r in rows] == [
        (w["external_id"], w["german"], w["article"], w["example"], w["translation"]) for w in SEED_WORDS
    ]
    tables = set(sa.inspect(engine).get_table_names())
    assert {"wordissue", "user", "logincode", "authsession", "devicelink"} <= tables


def test_app_start_on_v1_database_serves_same_words(v1_db):
    with TestClient(app) as c:
        meta = c.get("/content/meta").json()
        assert meta["version"] == 7
        assert meta["updated_at"].startswith("2026-11-04T15:33:46.236512")
        words = c.get("/content/words").json()
        assert words["version"] == 7 and len(words["words"]) == len(SEED_WORDS)
        for w, seed in zip(words["words"], SEED_WORDS):
            assert w["external_id"] == seed["external_id"]
            assert w["german"] == w["term"] == seed["german"]
            assert w["translation"] == seed["translation"]
            assert w["article"] == seed["article"] and w["example"] == seed["example"]
            assert w["category"] == seed["category"] and w["difficulty"] == seed["difficulty"]
            assert w["created_at"].startswith("2026-11-04T15:33:46.236512")
        # startup added the missing pair rows but didn't re-seed or bump
        assert scalar("SELECT count(*) FROM packmeta") == 5
        assert scalar("SELECT count(*) FROM word") == len(SEED_WORDS)
    with TestClient(app) as c:  # second start is a no-op
        assert c.get("/content/meta").json()["version"] == 7
    assert scalar("SELECT count(*) FROM packmeta") == 5


def test_downgrade_to_v1_and_back(v1_db):
    upgrade_db(v1_db)
    downgrade_db(v1_db, "0001")
    cols = {c["name"] for c in sa.inspect(engine).get_columns("word")}
    assert {"german", "translation"} <= cols and "term" not in cols
    assert scalar("SELECT translation FROM word WHERE external_id = 'der_schluessel'") == "key"
    assert scalar("SELECT version FROM packmeta") == 7
    assert "wordtranslation" not in sa.inspect(engine).get_table_names()
    upgrade_db(v1_db)
    assert scalar("SELECT count(*) FROM wordtranslation") == len(SEED_WORDS)


def test_fresh_database_gets_full_schema_and_seed():
    drop_everything()
    with TestClient(app) as c:
        assert scalar("SELECT version_num FROM alembic_version") == "0004"
        pack = c.get("/content/words").json()
        assert pack["version"] == 1 and len(pack["words"]) == len(SEED_WORDS)
    assert scalar("SELECT count(*) FROM packmeta") == 5
    drop_everything()
