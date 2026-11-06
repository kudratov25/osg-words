import time

from app import config, security

from .conftest import ADMIN, ADMIN_PASSWORD, ADMIN_USER


def login(client, password=ADMIN_PASSWORD, username=ADMIN_USER):
    return client.post("/admin/login", json={"username": username, "password": password})


def bearer(client):
    return {"Authorization": f"Bearer {login(client).json()['token']}"}


def ping(client, device, event="app_open", os="android 13", ver="1.0.0"):
    r = client.post("/telemetry/ping", json={"device_id": device, "event_type": event, "os_version": os, "app_version": ver})
    assert r.status_code == 204


# --- password hashing & tokens ---------------------------------------------

def test_password_hash_roundtrip():
    h = security.hash_password("hunter2-long")
    assert security.verify_password("hunter2-long", h)
    assert not security.verify_password("wrong", h)
    assert not security.verify_password("x", "garbage")


def test_token_roundtrip_and_tamper():
    token, _ = security.create_token("admin")
    assert security.verify_token(token) == "admin"
    payload, sig = token.split(".")
    assert security.verify_token(payload + "." + sig[:-2] + "AA") is None
    assert security.verify_token("nonsense") is None


def test_token_expires():
    token, _ = security.create_token("admin", ttl_seconds=-1)
    assert security.verify_token(token) is None


# --- login ------------------------------------------------------------------

def test_login_success_and_me(client):
    r = login(client)
    assert r.status_code == 200
    body = r.json()
    assert body["username"] == ADMIN_USER and body["token"]
    me = client.get("/admin/me", headers={"Authorization": f"Bearer {body['token']}"})
    assert me.json() == {"username": ADMIN_USER}


def test_login_wrong_password(client):
    assert login(client, password="nope").status_code == 401
    assert login(client, username="root").status_code == 401


def test_login_lockout_after_5_failures(client):
    for _ in range(5):
        assert login(client, password="nope").status_code == 401
    assert login(client).status_code == 429  # even the right password is blocked


def test_login_disabled_without_hash(client, monkeypatch):
    monkeypatch.setattr(config, "ADMIN_PASSWORD_HASH", "")
    assert login(client).status_code == 503


def test_bad_or_missing_token_rejected(client):
    assert client.get("/admin/stats").status_code == 401
    assert client.get("/admin/stats", headers={"Authorization": "Bearer junk"}).status_code == 401


def test_api_key_still_works(client):
    assert client.get("/admin/stats", headers=ADMIN).status_code == 200


def test_token_can_manage_words(client):
    h = bearer(client)
    r = client.post("/admin/words", headers=h, json={
        "external_id": "das_fenster", "german": "Fenster", "article": "das",
        "translation": "window", "example": "Das Fenster ist offen.", "category": "Daily Life"})
    assert r.status_code == 201


# --- stats --------------------------------------------------------------------

def test_stats_empty(client):
    s = client.get("/admin/stats", headers=bearer(client)).json()
    assert s["devices_total"] == 0 and s["active_today"] == 0
    assert s["words_total"] == 60 and s["pack_version"] == 1
    assert len(s["daily"]) == 30
    assert s["events"] == {"app_open": 0, "notif_tapped": 0, "notif_delivered": 0}


def test_stats_counts(client):
    ping(client, "dev-a")
    ping(client, "dev-a")
    ping(client, "dev-a", "notif_tapped")
    ping(client, "dev-b", os="ios 18.1", ver="1.1.0")
    s = client.get("/admin/stats", headers=bearer(client)).json()
    assert s["devices_total"] == 2
    assert s["active_today"] == 2 and s["active_7d"] == 2 and s["active_30d"] == 2
    assert s["new_7d"] == 2
    assert s["pings_total"] == 4
    assert s["events"]["app_open"] == 3 and s["events"]["notif_tapped"] == 1
    today = s["daily"][-1]
    assert today["active_devices"] == 2 and today["app_opens"] == 3 and today["notif_taps"] == 1
    assert {p["os"]: p["devices"] for p in s["platforms"]} == {"android": 1, "ios": 1}
    assert {v["version"]: v["devices"] for v in s["app_versions"]} == {"1.0.0": 1, "1.1.0": 1}


# --- devices ------------------------------------------------------------------

def test_devices_list_sorted_and_aggregated(client):
    ping(client, "dev-old", os="android 12", ver="0.9.0")
    time.sleep(0.01)
    ping(client, "dev-new")
    ping(client, "dev-new", "notif_tapped")
    ping(client, "dev-old", os="android 13", ver="1.0.0")  # dev-old most recent now
    body = client.get("/admin/devices", headers=bearer(client)).json()
    assert body["total"] == 2
    first = body["items"][0]
    assert first["device_id"] == "dev-old"
    assert first["os_version"] == "android 13" and first["app_version"] == "1.0.0"  # latest ping wins
    assert first["pings"] == 2 and first["app_opens"] == 2
    new = body["items"][1]
    assert new["notif_taps"] == 1 and new["app_opens"] == 1


def test_devices_search_and_paging(client):
    for i in range(5):
        ping(client, f"abc-{i}")
    ping(client, "zzz-1")
    h = bearer(client)
    assert client.get("/admin/devices?q=abc", headers=h).json()["total"] == 5
    page = client.get("/admin/devices?limit=2&offset=0", headers=h).json()
    assert page["total"] == 6 and len(page["items"]) == 2
