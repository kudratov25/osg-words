from app import config
from app.seed_words import SEED_WORDS

from .conftest import ADMIN

NEW_WORD = {
    "external_id": "test-001",
    "term": "Testwort",
    "article": "das",
    "example": "Das ist ein Testwort.",
    "category": "Daily Life",
    "translations": {"en": {"translation": "test word"}},
}


def version(client, source="en", target="de"):
    return client.get(f"/content/meta?source={source}&target={target}").json()["version"]


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_content_seeded(client):
    meta = client.get("/content/meta").json()
    assert meta["version"] == 1
    pack = client.get("/content/words").json()
    assert pack["version"] == 1
    assert len(pack["words"]) == len(SEED_WORDS)


# --- telemetry -------------------------------------------------------------

def test_ping_ok(client):
    r = client.post("/telemetry/ping", json={"device_id": "abc", "event_type": "app_open"})
    assert r.status_code == 204


def test_ping_with_pair(client):
    r = client.post("/telemetry/ping", json={"device_id": "abc", "event_type": "app_open", "pair": "uz-de"})
    assert r.status_code == 204
    r = client.post("/telemetry/ping", json={"device_id": "abc", "event_type": "app_open", "pair": "UZ_de"})
    assert r.status_code == 422


def test_ping_rejects_unknown_event(client):
    r = client.post("/telemetry/ping", json={"device_id": "abc", "event_type": "hacked"})
    assert r.status_code == 422


def test_ping_rejects_oversized_device_id(client):
    r = client.post("/telemetry/ping", json={"device_id": "x" * 1000, "event_type": "app_open"})
    assert r.status_code == 422


# --- admin auth ------------------------------------------------------------

def test_admin_requires_key(client):
    assert client.get("/admin/words").status_code == 401
    assert client.get("/admin/words", headers={"X-Admin-Key": "wrong"}).status_code == 401


def test_admin_disabled_without_configured_key(client, monkeypatch):
    monkeypatch.setattr(config, "ADMIN_API_KEY", "")
    assert client.get("/admin/words", headers=ADMIN).status_code == 503


# --- admin CRUD ------------------------------------------------------------

def test_create_word_bumps_version(client):
    r = client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    assert r.status_code == 201
    body = r.json()
    assert body["difficulty"] == "beginner" and body["lang"] == "de"
    assert body["translations"] == {"en": {"translation": "test word", "example_translation": None}}
    assert body["created_at"] and body["updated_at"]
    assert version(client) == 2
    ids = [w["external_id"] for w in client.get("/content/words").json()["words"]]
    assert "test-001" in ids


def test_create_word_legacy_v1_shape(client):
    legacy = {"external_id": "das_fenster", "german": "Fenster", "article": "das", "translation": "window",
              "example": "Das Fenster ist offen.", "category": "Daily Life"}
    r = client.post("/admin/words", json=legacy, headers=ADMIN)
    assert r.status_code == 201
    assert r.json()["term"] == "Fenster"
    assert r.json()["translations"]["en"]["translation"] == "window"


def test_create_duplicate_conflicts(client):
    client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    r = client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    assert r.status_code == 409
    assert version(client) == 2  # failed create didn't bump


def test_create_rejects_bad_difficulty(client):
    r = client.post("/admin/words", json={**NEW_WORD, "difficulty": "expert"}, headers=ADMIN)
    assert r.status_code == 422


def test_create_rejects_bad_category_article_lang(client):
    for bad in ({"category": "test"}, {"article": "le"}, {"lang": "fr"},
                {"translations": {"de": {"translation": "x"}}},
                {"lang": "en", "external_id": "en.x", "article": "the", "translations": {"uz": {"translation": "x"}}}):
        r = client.post("/admin/words", json={**NEW_WORD, **bad}, headers=ADMIN)
        assert r.status_code == 422, bad
    assert version(client) == 1


def test_update_word(client):
    client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    r = client.patch("/admin/words/test-001", json={"translations": {"en": {"translation": "fixed"}}}, headers=ADMIN)
    assert r.status_code == 200
    body = r.json()
    assert body["translations"]["en"]["translation"] == "fixed"
    assert body["term"] == "Testwort"  # untouched
    assert version(client) == 3


def test_update_word_legacy_translation_field(client):
    client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    r = client.patch("/admin/words/test-001", json={"translation": "fixed"}, headers=ADMIN)
    assert r.json()["translations"]["en"]["translation"] == "fixed"


def test_update_missing_word_404(client):
    r = client.patch("/admin/words/nope", json={"term": "x"}, headers=ADMIN)
    assert r.status_code == 404


def test_delete_word(client):
    client.post("/admin/words", json=NEW_WORD, headers=ADMIN)
    assert client.delete("/admin/words/test-001", headers=ADMIN).status_code == 204
    ids = [w["external_id"] for w in client.get("/content/words").json()["words"]]
    assert "test-001" not in ids
    assert version(client) == 3
    assert client.delete("/admin/words/test-001", headers=ADMIN).status_code == 404
