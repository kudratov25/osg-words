"""Language pairs: content API per pair, availability, bump rules, bulk
import (dry run vs apply) and coverage."""

import pytest
from sqlmodel import Session

from app import config, packs
from app.database import engine
from app.languages import PAIRS
from app.seed_words import SEED_WORDS

from .conftest import ADMIN

N_SEED = len(SEED_WORDS)


def make_word(i, lang="de", sources=("en", "uz", "ru")):
    prefix = "en." if lang == "en" else "de_test_"
    w = {
        "external_id": f"{prefix}{i}",
        "term": f"Wort{i}" if lang == "de" else f"word{i}",
        "article": "das" if lang == "de" else None,
        "example": f"Beispiel {i}." if lang == "de" else f"Example {i}.",
        "category": "Home",
        "difficulty": "beginner",
        "translations": {s: {"translation": f"{s}-{i}", "example_translation": f"{s} ex {i}"}
                         for s in sources if s != lang},
    }
    return w


def do_import(client, words, dry_run=False, target=None):
    body = {"words": words}
    if target:
        body["target"] = target
    r = client.post(f"/admin/import?dry_run={'true' if dry_run else 'false'}", json=body, headers=ADMIN)
    assert r.status_code == 200, r.text
    return r.json()


def versions(client):
    """Pack version per pair, read from the DB (unavailable pairs 404 publicly)."""
    with Session(engine) as session:
        return {f"{s}-{t}": packs.get_meta(session, s, t).version for s, t in PAIRS}


@pytest.fixture
def low_threshold(monkeypatch):
    monkeypatch.setattr(config, "MIN_PAIR_WORDS", 3)


# --- backwards compatibility ---------------------------------------------------------

def test_no_params_is_v1_shape(client):
    pack = client.get("/content/words").json()
    assert pack["source"] == "en" and pack["target"] == "de"
    first = pack["words"][0]
    v1_fields = {"external_id", "german", "article", "translation", "example", "pronunciation",
                 "category", "difficulty", "created_at"}
    assert v1_fields <= set(first)
    assert first["german"] == first["term"] == "Schlüssel"
    assert first["translation"] == "key" and first["lang"] == "de"
    assert first["example_translation"] is None
    assert client.get("/content/words?source=en&target=de").json() == pack
    meta = client.get("/content/meta").json()
    assert set(meta) == {"version", "updated_at", "source", "target"}


def test_default_pair_served_below_threshold(client):
    assert config.MIN_PAIR_WORDS == 100 and N_SEED < 100
    assert client.get("/content/meta").status_code == 200
    pairs = client.get("/content/pairs").json()["pairs"]
    assert pairs == [{"source": "en", "target": "de", "words": N_SEED, "version": 1}]


def test_unknown_and_unavailable_pairs_404(client):
    for qs in ("source=fr&target=de", "source=de&target=de", "source=en&target=en",
               "source=uz&target=de", "source=ru&target=en"):
        assert client.get(f"/content/meta?{qs}").status_code == 404, qs
        assert client.get(f"/content/words?{qs}").status_code == 404, qs


# --- pairs + availability threshold ---------------------------------------------------

def test_pair_availability_threshold(client, low_threshold):
    do_import(client, [make_word(i, sources=("en", "uz")) for i in range(2)])
    assert client.get("/content/meta?source=uz&target=de").status_code == 404  # 2 < 3
    do_import(client, [make_word(2, sources=("uz",))])
    assert client.get("/content/meta?source=uz&target=de").status_code == 200  # 3 >= 3
    pairs = {f"{p['source']}-{p['target']}": p for p in client.get("/content/pairs").json()["pairs"]}
    assert set(pairs) == {"en-de", "uz-de"}
    assert pairs["uz-de"]["words"] == 3 and pairs["en-de"]["words"] == N_SEED + 2


def test_words_per_pair(client, low_threshold):
    do_import(client, [make_word(i) for i in range(3)])
    do_import(client, [make_word(i, lang="en") for i in range(4)], target="en")
    uz = client.get("/content/words?source=uz&target=de").json()
    assert uz["source"] == "uz" and uz["target"] == "de"
    assert [w["external_id"] for w in uz["words"]] == [f"de_test_{i}" for i in range(3)]  # only uz-translated
    assert uz["words"][0]["translation"] == "uz-0" and uz["words"][0]["example_translation"] == "uz ex 0"
    assert uz["words"][0]["german"] == "Wort0"
    ru_en = client.get("/content/words?source=ru&target=en").json()
    assert len(ru_en["words"]) == 4
    w = ru_en["words"][0]
    assert w["lang"] == "en" and w["term"] == w["german"] == "word0" and w["article"] is None
    assert w["translation"] == "ru-0"
    en_de = client.get("/content/words").json()["words"]
    assert len(en_de) == N_SEED + 3 and all(x["lang"] == "de" for x in en_de)


# --- bump rules -----------------------------------------------------------------------------

def test_bump_rules(client):
    v0 = versions(client)
    assert set(v0.values()) == {1}
    client.post("/admin/words", json=make_word(1, sources=("en",)), headers=ADMIN)
    v1 = versions(client)  # new word = target change -> every de pack
    assert v1 == {"en-de": 2, "uz-de": 2, "ru-de": 2, "uz-en": 1, "ru-en": 1}

    # translation change bumps only that pair
    client.patch("/admin/words/de_test_1", json={"translations": {"uz": {"translation": "so'z"}}}, headers=ADMIN)
    assert versions(client) == {**v1, "uz-de": 3}
    client.patch("/admin/words/de_test_1", json={"translations": {"uz": None}}, headers=ADMIN)
    assert versions(client) == {**v1, "uz-de": 4}

    # target-side change bumps all packs of the target
    client.patch("/admin/words/de_test_1", json={"example": "Neu."}, headers=ADMIN)
    assert versions(client) == {"en-de": 3, "uz-de": 5, "ru-de": 3, "uz-en": 1, "ru-en": 1}

    # no actual change -> no bump
    before = versions(client)
    r = client.patch("/admin/words/de_test_1", json={"example": "Neu.", "translations": {"en": {"translation": "en-1"}}},
                     headers=ADMIN)
    assert r.status_code == 200
    assert versions(client) == before

    # delete bumps all packs of the target
    client.delete("/admin/words/de_test_1", headers=ADMIN)
    assert versions(client) == {"en-de": 4, "uz-de": 6, "ru-de": 4, "uz-en": 1, "ru-en": 1}


def test_patch_translations_merge_and_remove(client):
    client.post("/admin/words", json=make_word(1), headers=ADMIN)
    r = client.patch("/admin/words/de_test_1", json={"translations": {
        "uz": {"example_translation": "yangi"}, "ru": None}}, headers=ADMIN)
    tr = r.json()["translations"]
    assert set(tr) == {"en", "uz"}
    assert tr["uz"] == {"translation": "uz-1", "example_translation": "yangi"}  # translation kept
    r = client.patch("/admin/words/de_test_1", json={"translations": {"ru": {"example_translation": "x"}}},
                     headers=ADMIN)
    assert r.status_code == 422  # new language needs a translation
    r = client.patch("/admin/words/de_test_1", json={"translations": {"fr": {"translation": "x"}}}, headers=ADMIN)
    assert r.status_code == 422


def test_admin_words_filter_and_shape(client):
    do_import(client, [make_word(i, lang="en") for i in range(2)], target="en")
    all_words = client.get("/admin/words", headers=ADMIN).json()
    assert len(all_words) == N_SEED + 2
    en = client.get("/admin/words?target=en", headers=ADMIN).json()
    assert [w["external_id"] for w in en] == ["en.0", "en.1"]
    assert set(en[0]["translations"]) == {"uz", "ru"}
    de = client.get("/admin/words?target=de", headers=ADMIN).json()
    assert len(de) == N_SEED
    assert de[0]["translations"] == {"en": {"translation": "key", "example_translation": None}}
    assert set(de[0]) == {"external_id", "lang", "term", "article", "example", "pronunciation", "category",
                          "difficulty", "level", "topics", "created_at", "updated_at", "translations"}


# --- import ---------------------------------------------------------------------------------

def test_import_dry_run_writes_nothing(client):
    words = [make_word(i) for i in range(5)]
    res = do_import(client, words, dry_run=True)
    assert res["dry_run"] is True
    assert (res["created"], res["updated"], res["unchanged"], res["errors"]) == (5, 0, 0, [])
    assert res["bumped"] == ["en-de", "ru-de", "uz-de"]
    assert len(client.get("/admin/words", headers=ADMIN).json()) == N_SEED
    assert versions(client)["en-de"] == 1

    res = do_import(client, words)
    assert (res["created"], res["updated"], res["unchanged"]) == (5, 0, 0)
    assert res["bumped"] == ["en-de", "ru-de", "uz-de"]
    assert len(client.get("/admin/words", headers=ADMIN).json()) == N_SEED + 5
    assert versions(client)["en-de"] == 2  # one bump per import, not per word


def test_import_upsert_counts_and_bumps(client):
    do_import(client, [make_word(i) for i in range(3)])
    w0 = make_word(0)
    w1 = make_word(1)
    w1["translations"]["uz"] = {"translation": "changed"}  # translation-only change
    w2 = make_word(2)
    w2["term"] = "Geändert"  # target change
    for dry in (True, False):
        res = do_import(client, [w0, w1, w2, make_word(3)], dry_run=dry)
        assert (res["created"], res["updated"], res["unchanged"]) == (1, 2, 1), dry
        assert res["bumped"] == ["en-de", "ru-de", "uz-de"]
    res = do_import(client, [w0, w1, w2])
    assert (res["created"], res["updated"], res["unchanged"], res["bumped"]) == (0, 0, 3, [])
    words = {w["external_id"]: w for w in client.get("/admin/words?target=de", headers=ADMIN).json()}
    assert words["de_test_1"]["translations"]["uz"] == {"translation": "changed", "example_translation": None}
    assert words["de_test_2"]["term"] == "Geändert"

    # only a uz translation changes -> only uz-de bumps
    w1["translations"] = {"uz": {"translation": "again"}}
    res = do_import(client, [w1])
    assert res["updated"] == 1 and res["bumped"] == ["uz-de"]
    assert words["de_test_1"]["translations"]["ru"]  # unlisted languages kept
    assert "ru" in client.get("/admin/words/de_test_1", headers=ADMIN).json()["translations"]


def test_import_existing_v1_words_unchanged(client):
    res = do_import(client, SEED_WORDS)  # legacy shape (german/translation)
    assert (res["created"], res["updated"], res["unchanged"], res["errors"]) == (0, 0, N_SEED, [])


def test_import_errors(client):
    good = make_word(1)
    bad_items = [
        {"external_id": "x1"},  # missing fields
        {**make_word(2), "category": "Nope"},
        {**make_word(3), "article": "le"},
        {**make_word(4), "difficulty": "expert"},
        {**make_word(5), "translations": {"de": {"translation": "x"}}},
        {**make_word(6), "translations": {"uz": {"translation": ""}}},
        good,  # duplicate below
        "not an object",
        {**make_word(7, lang="en"), "lang": "en"},  # lang doesn't match import target
        {**make_word(8), "external_id": "der_schluessel", "lang": "de"},  # fine (updates seed word)
    ]
    items = [bad_items[0], bad_items[1], bad_items[2], bad_items[3], bad_items[4], bad_items[5],
             good, dict(good), bad_items[7], bad_items[8], bad_items[9]]
    for dry in (True, False):
        res = do_import(client, items, dry_run=dry, target="de")
        err_idx = [e["index"] for e in res["errors"]]
        assert err_idx == [0, 1, 2, 3, 4, 5, 7, 8, 9], res["errors"]
        assert res["errors"][0]["external_id"] == "x1"
        assert "duplicate" in res["errors"][6]["error"]
        assert res["errors"][7]["external_id"] is None
        assert res["created"] == 1 and res["updated"] == 1
    # an existing id can't move to another target
    res = do_import(client, [{**make_word(9, lang="en"), "external_id": "der_schluessel"}], target="en")
    assert "already exists" in res["errors"][0]["error"]


def test_import_limits(client):
    r = client.post("/admin/import?dry_run=true", json={"words": [make_word(i) for i in range(2001)]},
                    headers=ADMIN)
    assert r.status_code == 413
    r = client.post("/admin/import", json={"target": "fr", "words": []}, headers=ADMIN)
    assert r.status_code == 422
    r = client.post("/admin/import", json={"words": [make_word(1)]}, headers=ADMIN)
    assert r.json()["dry_run"] is True  # default is a dry run
    assert client.post("/admin/import", json={"words": []}).status_code == 401


def test_import_content_file_shape(client):
    """A whole content file (target + words without lang) imports as-is."""
    body = {"target": "en", "words": [{k: v for k, v in make_word(i, lang="en").items()} for i in range(2)]}
    r = client.post("/admin/import?dry_run=false", json=body, headers=ADMIN)
    assert r.json()["created"] == 2 and r.json()["bumped"] == ["ru-en", "uz-en"]


# --- coverage --------------------------------------------------------------------------------

def test_coverage(client, low_threshold):
    do_import(client, [make_word(i, sources=("en", "uz")) for i in range(3)])
    do_import(client, [make_word(i, lang="en", sources=("ru",)) for i in range(2)], target="en")
    cov = client.get("/admin/coverage", headers=ADMIN).json()
    assert cov["min_pair_words"] == 3
    assert cov["targets"] == [
        {"target": "de", "words": N_SEED + 3, "translations": {"en": N_SEED + 3, "uz": 3, "ru": 0}},
        {"target": "en", "words": 2, "translations": {"uz": 0, "ru": 2}},
    ]
    pairs = {f"{p['source']}-{p['target']}": (p["words"], p["available"]) for p in cov["pairs"]}
    assert pairs == {"en-de": (N_SEED + 3, True), "uz-de": (3, True), "ru-de": (0, False),
                     "uz-en": (0, False), "ru-en": (2, False)}
