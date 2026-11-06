"""v2.1: CEFR level + job-area topics on words."""

from .conftest import ADMIN
from .test_content_v2 import do_import, make_word


def topic_word(i, topics=("retail",), level="B1"):
    w = make_word(f"t{i}")
    w.update(level=level, topics=list(topics))
    return w


def test_topic_words_hidden_from_old_apps(client):
    before = client.get("/content/words").json()["words"]
    res = do_import(client, [topic_word(1), topic_word(2, ("it", "office"))])
    assert res["created"] == 2 and not res["errors"]

    # App <= 2.0 (no `topics` param) keeps getting general words only.
    old = client.get("/content/words").json()["words"]
    assert len(old) == len(before)
    assert all(w["topics"] == [] for w in old)

    pairs = {f"{p['source']}-{p['target']}": p["words"] for p in client.get("/content/pairs").json()["pairs"]}
    assert pairs["en-de"] == len(before)
    pairs = {f"{p['source']}-{p['target']}": p["words"]
             for p in client.get("/content/pairs?topics=true").json()["pairs"]}
    assert pairs["en-de"] == len(before) + 2

    new = client.get("/content/words?topics=true").json()["words"]
    assert len(new) == len(before) + 2
    by_id = {w["external_id"]: w for w in new}
    assert by_id["de_test_t1"]["topics"] == ["retail"]
    assert by_id["de_test_t2"]["topics"] == ["it", "office"]
    assert by_id["de_test_t1"]["level"] == "B1"


def test_level_decides_difficulty(client):
    words = [topic_word(1, level="A1"), topic_word(2, level="B1"), topic_word(3, level="C1")]
    do_import(client, words)
    got = {w["external_id"]: w for w in client.get("/admin/words?target=de", headers=ADMIN).json()}
    assert got["de_test_t1"]["difficulty"] == "beginner"
    assert got["de_test_t2"]["difficulty"] == "intermediate"
    assert got["de_test_t3"]["difficulty"] == "advanced"

    r = client.patch("/admin/words/de_test_t1", json={"level": "B2", "topics": ["care", "medicine"]}, headers=ADMIN)
    assert r.status_code == 200, r.text
    assert r.json()["difficulty"] == "advanced"
    assert r.json()["topics"] == ["care", "medicine"]


def test_unknown_topic_or_level_rejected(client):
    res = do_import(client, [topic_word(1, topics=("astronaut",)), topic_word(2, level="Z9")])
    assert res["created"] == 0 and len(res["errors"]) == 2


def test_level_and_topic_changes_bump_the_pack(client):
    do_import(client, [topic_word(1)])
    v = client.get("/content/meta").json()["version"]
    assert client.patch("/admin/words/de_test_t1", json={"level": "A2"}, headers=ADMIN).status_code == 200
    assert client.get("/content/meta").json()["version"] == v + 1
    # Same values again: nothing changes, no bump.
    assert client.patch("/admin/words/de_test_t1", json={"level": "A2"}, headers=ADMIN).status_code == 200
    assert client.get("/content/meta").json()["version"] == v + 1
