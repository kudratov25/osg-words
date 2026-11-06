"""backend/content/*.json: valid for the importer, and de.json keeps the
existing 60 words exactly (SPEC-v2 s.3). Skipped while a file is missing."""

import json

import pytest
from sqlmodel import Session

from app import config, packs
from app.database import engine
from app.seed_words import SEED_WORDS

from .conftest import ADMIN

CONTENT = config.BACKEND_DIR / "content"
REQUIRED_SOURCES = {"de": {"en", "uz", "ru"}, "en": {"uz", "ru"}}


def load(target):
    path = CONTENT / f"{target}.json"
    if not path.is_file():
        pytest.skip(f"{path} not present")
    return json.loads(path.read_text(encoding="utf-8"))


@pytest.mark.parametrize("target", ["de", "en"])
def test_content_file_imports_cleanly(client, target):
    data = load(target)
    assert data["target"] == target
    words = data["words"]
    r = client.post("/admin/import?dry_run=true", json=data, headers=ADMIN)
    assert r.status_code == 200
    res = r.json()
    assert res["errors"] == [], res["errors"][:10]
    for w in words:
        assert set(w["translations"]) >= REQUIRED_SOURCES[target], w["external_id"]
        if target == "en":
            assert w["external_id"].startswith("en.") and w["article"] is None


def test_de_keeps_existing_words():
    data = load("de")
    by_id = {w["external_id"]: w for w in data["words"]}
    for seed in SEED_WORDS:
        w = by_id.get(seed["external_id"])
        assert w is not None, seed["external_id"]
        assert (w["term"], w["article"], w["example"], w["category"], w["difficulty"]) == (
            seed["german"], seed["article"], seed["example"], seed["category"], seed["difficulty"]
        ), seed["external_id"]
        assert w["translations"]["en"]["translation"] == seed["translation"], seed["external_id"]


def test_ids_globally_unique():
    ids = []
    for target in ("de", "en"):
        path = CONTENT / f"{target}.json"
        if path.is_file():
            ids += [w["external_id"] for w in json.loads(path.read_text(encoding="utf-8"))["words"]]
    if not ids:
        pytest.skip("no content files")
    assert len(ids) == len(set(ids))


def test_seed_from_content_files(client, monkeypatch, tmp_path):
    """First start on an empty DB imports the content files (versions stay 1)."""
    load("de")
    monkeypatch.setattr(config, "CONTENT_DIR", CONTENT)
    from .conftest import drop_everything
    from fastapi.testclient import TestClient
    from app.main import app

    topic_path = CONTENT / "topics" / "de.json"
    n_topic = len(json.loads(topic_path.read_text(encoding="utf-8"))["words"]) if topic_path.is_file() else 0
    n_de = len(load("de")["words"]) + n_topic
    drop_everything()
    with TestClient(app) as c:
        pairs = {f"{p['source']}-{p['target']}": p for p in c.get("/content/pairs").json()["pairs"]}
        assert pairs["en-de"]["version"] == 1
        assert pairs["en-de"]["words"] == len(load("de")["words"])
        assert {p["target"]: p["words"] for p in c.get("/content/pairs?topics=true").json()["pairs"]}["de"] == n_de
        # General words only without ?topics=true.
        assert len(c.get("/content/words").json()["words"]) == len(load("de")["words"])
    with Session(engine) as s:
        assert packs.target_word_counts(s).get("de") == n_de


def test_seed_from_synthetic_content_dir(client, monkeypatch, tmp_path):
    """Seeding logic without depending on the real files: de.json + en.json
    in CONTENT_DIR replace the built-in words on an empty database."""
    def word(ext, term, article, sources):
        return {"external_id": ext, "term": term, "article": article, "example": f"{term}!",
                "category": "Home", "difficulty": "beginner", "pronunciation": None,
                "translations": {s: {"translation": f"{term}-{s}", "example_translation": None} for s in sources}}

    (tmp_path / "de.json").write_text(json.dumps({"target": "de", "words": [
        word("das_haus", "Haus", "das", ["en", "uz", "ru"]), word("gehen", "gehen", None, ["en", "uz"])]}))
    (tmp_path / "en.json").write_text(json.dumps({"target": "en", "words": [
        word("en.house", "house", None, ["uz", "ru"])]}))
    monkeypatch.setattr(config, "CONTENT_DIR", tmp_path)
    monkeypatch.setattr(config, "MIN_PAIR_WORDS", 1)
    from fastapi.testclient import TestClient
    from app.main import app
    from .conftest import drop_everything

    drop_everything()
    with TestClient(app) as c:
        pairs = {f"{p['source']}-{p['target']}": (p["words"], p["version"]) for p in c.get("/content/pairs").json()["pairs"]}
        assert pairs == {"en-de": (2, 1), "uz-de": (2, 1), "ru-de": (1, 1), "uz-en": (1, 1), "ru-en": (1, 1)}
        assert c.get("/content/words?source=ru&target=en").json()["words"][0]["translation"] == "house-ru"


@pytest.mark.parametrize("target", ["de", "en"])
def test_topic_file_imports_cleanly(client, target):
    path = CONTENT / "topics" / f"{target}.json"
    if not path.is_file():
        pytest.skip(f"{path} not present")
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["target"] == target
    r = client.post("/admin/import?dry_run=false", json=data, headers=ADMIN)
    assert r.status_code == 200
    res = r.json()
    assert res["errors"] == [], res["errors"][:10]
    assert all(w["topics"] for w in data["words"])
    # Topic words stay out of the pack that apps <= 2.0 download.
    old = client.get(f"/content/words?source={'en' if target == 'de' else 'uz'}&target={target}").json()
    assert not any(w["topics"] for w in old["words"])
