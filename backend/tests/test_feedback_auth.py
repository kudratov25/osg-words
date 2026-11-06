"""Word reports, user accounts (email code), stats/devices additions."""

import re
from datetime import timedelta

import pytest
from sqlalchemy import func
from sqlmodel import Session, select

from app import config, emailer
from app.database import engine
from app.models import AuthSession, DeviceLink, DevicePing, LoginCode, User, WordIssue, utcnow
from app.routers import auth as auth_mod

from .conftest import ADMIN

ISSUE = {"device_id": "dev-1", "external_id": "der_schluessel", "source": "en", "target": "de",
         "kind": "wrong_translation", "note": "should be 'the key'"}


def count(model, *where):
    with Session(engine) as s:
        return s.exec(select(func.count()).select_from(model).where(*where)).one()


# --- word issues ---------------------------------------------------------------------------

def test_word_issue_created_and_listed(client):
    assert client.post("/feedback/word-issue", json=ISSUE).status_code == 204
    issues = client.get("/admin/word-issues?status=open", headers=ADMIN).json()
    assert len(issues) == 1
    i = issues[0]
    assert {k: i[k] for k in ISSUE} == ISSUE
    assert i["status"] == "open" and i["term"] == "Schlüssel" and i["created_at"]

    r = client.patch(f"/admin/word-issues/{i['id']}", json={"status": "resolved"}, headers=ADMIN)
    assert r.status_code == 200 and r.json()["status"] == "resolved"
    assert client.get("/admin/word-issues?status=open", headers=ADMIN).json() == []
    assert len(client.get("/admin/word-issues?status=resolved", headers=ADMIN).json()) == 1
    assert len(client.get("/admin/word-issues", headers=ADMIN).json()) == 1
    assert client.patch("/admin/word-issues/999", json={"status": "resolved"}, headers=ADMIN).status_code == 404
    assert client.patch(f"/admin/word-issues/{i['id']}", json={"status": "nope"}, headers=ADMIN).status_code == 422
    assert client.get("/admin/word-issues").status_code == 401


def test_word_issue_validation(client):
    assert client.post("/feedback/word-issue", json={**ISSUE, "external_id": "nope"}).status_code == 404
    assert client.post("/feedback/word-issue", json={**ISSUE, "kind": "spam"}).status_code == 422
    assert client.post("/feedback/word-issue", json={**ISSUE, "note": "x" * 301}).status_code == 422
    assert client.post("/feedback/word-issue", json={**ISSUE, "source": "english"}).status_code == 422
    no_note = {k: v for k, v in ISSUE.items() if k != "note"}
    assert client.post("/feedback/word-issue", json={**no_note, "kind": "other"}).status_code == 204


def test_word_issue_daily_limit_per_device(client):
    for _ in range(20):
        assert client.post("/feedback/word-issue", json=ISSUE).status_code == 204
    assert client.post("/feedback/word-issue", json=ISSUE).status_code == 429
    assert client.post("/feedback/word-issue", json={**ISSUE, "device_id": "dev-2"}).status_code == 204
    # yesterday's reports don't count
    with Session(engine) as s:
        for issue in s.exec(select(WordIssue).where(WordIssue.device_id == "dev-1")).all():
            issue.created_at = utcnow() - timedelta(days=1, hours=1)
            s.add(issue)
        s.commit()
    assert client.post("/feedback/word-issue", json=ISSUE).status_code == 204


# --- auth ----------------------------------------------------------------------------------

EMAIL = "Person@Example.com"


@pytest.fixture
def accounts(monkeypatch):
    monkeypatch.setattr(config, "EMAIL_BACKEND", "console")


def last_code():
    msg = emailer.outbox[-1]
    m = re.search(r"Your OSG code: (\d{6}) — valid 10 minutes", msg.get_content())
    assert m, msg.get_content()
    return m.group(1)


def sign_in(client, email=EMAIL, device_id=None):
    assert client.post("/auth/email/start", json={"email": email}).status_code == 204
    body = {"email": email, "code": last_code()}
    if device_id:
        body["device_id"] = device_id
    r = client.post("/auth/email/verify", json=body)
    assert r.status_code == 200, r.text
    return r.json()


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def test_auth_disabled_returns_503(client):
    assert config.EMAIL_BACKEND == ""
    assert client.get("/auth/config").json() == {"enabled": False, "methods": []}
    assert client.post("/auth/email/start", json={"email": "a@b.co"}).status_code == 503
    assert client.post("/auth/email/verify", json={"email": "a@b.co", "code": "123456"}).status_code == 503
    assert client.post("/auth/logout").status_code == 503


def test_auth_smtp_without_host_is_disabled(client, monkeypatch):
    monkeypatch.setattr(config, "EMAIL_BACKEND", "smtp")
    monkeypatch.setattr(config, "SMTP_HOST", "")
    assert client.get("/auth/config").json()["enabled"] is False
    monkeypatch.setattr(config, "SMTP_HOST", "smtp.example.com")
    monkeypatch.setattr(config, "SMTP_FROM", "OSG <no-reply@example.com>")
    assert client.get("/auth/config").json() == {"enabled": True, "methods": ["email_code"]}


def test_full_flow(client, accounts):
    assert client.get("/auth/config").json() == {"enabled": True, "methods": ["email_code"]}
    body = sign_in(client, device_id="dev-x")
    token, user = body["token"], body["user"]
    assert set(user) == {"id", "email", "created_at"}
    assert user["email"] == "person@example.com"  # lowercased
    assert emailer.outbox[-1]["To"] == "person@example.com"
    assert client.get("/me", headers=bearer(token)).json() == user
    assert count(DeviceLink, DeviceLink.device_id == "dev-x") == 1

    # signing in again: same user, second session, link not duplicated
    again = sign_in(client, email="person@example.com", device_id="dev-x")
    assert again["user"]["id"] == user["id"] and again["token"] != token
    assert count(User) == 1 and count(AuthSession) == 2 and count(DeviceLink) == 1

    # tokens are stored hashed only
    with Session(engine) as s:
        hashes = s.exec(select(AuthSession.token_hash)).all()
        codes = s.exec(select(LoginCode.code_hash)).all()
    assert token not in hashes and auth_mod.hash_token(token) in hashes
    assert all(len(h) == 64 for h in codes)

    # a used code can't be reused
    r = client.post("/auth/email/verify", json={"email": EMAIL, "code": last_code()})
    assert r.status_code == 400

    assert client.post("/auth/logout", headers=bearer(token)).status_code == 204
    assert client.get("/me", headers=bearer(token)).status_code == 401
    assert client.get("/me", headers=bearer(again["token"])).status_code == 200  # other session untouched


def test_me_requires_valid_token(client, accounts):
    assert client.get("/me").status_code == 401
    assert client.get("/me", headers=bearer("osgu_nonsense")).status_code == 401
    token = sign_in(client)["token"]
    with Session(engine) as s:
        sess = s.exec(select(AuthSession)).one()
        sess.expires_at = utcnow() - timedelta(seconds=1)
        s.add(sess)
        s.commit()
    assert client.get("/me", headers=bearer(token)).status_code == 401


def test_wrong_code_then_too_many_attempts(client, accounts):
    client.post("/auth/email/start", json={"email": EMAIL})
    code = last_code()
    wrong = "000000" if code != "000000" else "111111"
    for i in range(5):
        r = client.post("/auth/email/verify", json={"email": EMAIL, "code": wrong})
        assert r.status_code == 400 and "Wrong code" in r.json()["detail"]
    r = client.post("/auth/email/verify", json={"email": EMAIL, "code": code})  # even the right one
    assert r.status_code == 400 and "Too many" in r.json()["detail"]
    # a new code works
    assert sign_in(client)["user"]["email"] == "person@example.com"


def test_expired_code(client, accounts):
    client.post("/auth/email/start", json={"email": EMAIL})
    code = last_code()
    with Session(engine) as s:
        lc = s.exec(select(LoginCode)).one()
        assert timedelta(minutes=9) < lc.expires_at - lc.created_at <= timedelta(minutes=10)
        lc.expires_at = utcnow() - timedelta(seconds=1)
        s.add(lc)
        s.commit()
    r = client.post("/auth/email/verify", json={"email": EMAIL, "code": code})
    assert r.status_code == 400 and "expired" in r.json()["detail"]


def test_verify_without_code_and_only_newest_code_counts(client, accounts):
    r = client.post("/auth/email/verify", json={"email": "nobody@example.com", "code": "123456"})
    assert r.status_code == 400
    client.post("/auth/email/start", json={"email": EMAIL})
    first = last_code()
    client.post("/auth/email/start", json={"email": EMAIL})
    second = last_code()
    if first != second:
        assert client.post("/auth/email/verify", json={"email": EMAIL, "code": first}).status_code == 400
    assert client.post("/auth/email/verify", json={"email": EMAIL, "code": second}).status_code == 200


def test_start_is_204_for_any_valid_email_and_validates(client, accounts):
    assert client.post("/auth/email/start", json={"email": "new@example.com"}).status_code == 204
    sign_in(client)
    assert client.post("/auth/email/start", json={"email": EMAIL.lower()}).status_code == 204  # existing
    assert client.post("/auth/email/start", json={"email": "not-an-email"}).status_code == 422


def test_rate_limit_per_email(client, accounts):
    for _ in range(3):
        assert client.post("/auth/email/start", json={"email": EMAIL}).status_code == 204
    assert client.post("/auth/email/start", json={"email": EMAIL.upper()}).status_code == 429
    assert client.post("/auth/email/start", json={"email": "other@example.com"}).status_code == 204


def test_rate_limit_per_ip(client, accounts):
    for i in range(10):
        assert client.post("/auth/email/start", json={"email": f"u{i}@example.com"}).status_code == 204
    assert client.post("/auth/email/start", json={"email": "u99@example.com"}).status_code == 429


def test_email_send_failure_is_503(client, accounts, monkeypatch):
    def boom(to, code):
        raise emailer.EmailError("down")
    monkeypatch.setattr(emailer, "send_login_code", boom)
    assert client.post("/auth/email/start", json={"email": EMAIL}).status_code == 503


def test_user_token_rejected_by_admin(client, accounts):
    token = sign_in(client)["token"]
    for path in ("/admin/me", "/admin/stats", "/admin/words"):
        assert client.get(path, headers=bearer(token)).status_code == 401


def test_admin_token_is_not_a_user_token(client, accounts):
    from app import security
    admin_token, _ = security.create_token("admin")
    assert client.get("/me", headers=bearer(admin_token)).status_code == 401


def test_delete_me_cascades_including_pings(client, accounts):
    for dev in ("dev-a", "dev-b", "dev-other"):
        client.post("/telemetry/ping", json={"device_id": dev, "event_type": "app_open"})
    sign_in(client, device_id="dev-a")
    token = sign_in(client, device_id="dev-b")["token"]
    other = sign_in(client, email="other@example.com", device_id="dev-other")["token"]
    assert count(DevicePing) == 3 and count(DeviceLink) == 3

    assert client.delete("/me", headers=bearer(token)).status_code == 204
    assert count(User) == 1 and count(AuthSession) == 1 and count(DeviceLink) == 1
    assert count(LoginCode, LoginCode.email == "person@example.com") == 0
    assert count(DevicePing) == 1 and count(DevicePing, DevicePing.device_id == "dev-other") == 1
    assert client.get("/me", headers=bearer(token)).status_code == 401
    assert client.get("/me", headers=bearer(other)).status_code == 200
    assert client.delete("/me", headers=bearer(token)).status_code == 401


def test_me_still_works_when_accounts_get_disabled(client, accounts, monkeypatch):
    token = sign_in(client)["token"]
    monkeypatch.setattr(config, "EMAIL_BACKEND", "")
    assert client.get("/me", headers=bearer(token)).status_code == 200
    assert client.delete("/me", headers=bearer(token)).status_code == 204


def test_login_code_email_text():
    msg = emailer.login_code_message("a@b.co", "123456")
    assert msg.get_content().startswith("Your OSG code: 123456 — valid 10 minutes")
    assert msg["Subject"] == "Your OSG code: 123456"


def test_smtp_backend_uses_starttls(monkeypatch):
    calls = []

    class FakeSMTP:
        def __init__(self, host, port, timeout):
            calls.append(("connect", host, port))
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def ehlo(self): calls.append("ehlo")
        def starttls(self, context): calls.append("starttls")
        def login(self, u, p): calls.append(("login", u, p))
        def send_message(self, msg): calls.append(("send", msg["To"]))

    monkeypatch.setattr(config, "EMAIL_BACKEND", "smtp")
    monkeypatch.setattr(config, "SMTP_HOST", "smtp.example.com")
    monkeypatch.setattr(config, "SMTP_PORT", 587)
    monkeypatch.setattr(config, "SMTP_USER", "user")
    monkeypatch.setattr(config, "SMTP_PASSWORD", "pw")
    monkeypatch.setattr(config, "SMTP_FROM", "OSG <no-reply@example.com>")
    monkeypatch.setattr(emailer.smtplib, "SMTP", FakeSMTP)
    emailer.send_login_code("a@b.co", "123456")
    assert calls == [("connect", "smtp.example.com", 587), "ehlo", "starttls", "ehlo",
                     ("login", "user", "pw"), ("send", "a@b.co")]


# --- stats / devices additions ---------------------------------------------------------------

def ping(client, device, pair=None):
    body = {"device_id": device, "event_type": "app_open"}
    if pair:
        body["pair"] = pair
    assert client.post("/telemetry/ping", json=body).status_code == 204


def test_stats_pairs_and_users(client, accounts):
    ping(client, "a", "en-de")
    ping(client, "a", "uz-de")  # latest pair wins
    ping(client, "a")  # no pair: ignored for the pair
    ping(client, "b", "uz-de")
    ping(client, "c", "ru-en")
    ping(client, "d")  # old app, no pair
    sign_in(client)
    s = client.get("/admin/stats", headers=ADMIN).json()
    assert s["pairs"] == [{"pair": "uz-de", "devices": 2}, {"pair": "ru-en", "devices": 1}]
    assert s["users_total"] == 1
    devices = {d["device_id"]: d for d in client.get("/admin/devices", headers=ADMIN).json()["items"]}
    assert devices["a"]["pair"] == "uz-de" and devices["d"]["pair"] is None


def test_delete_me_anonymizes_word_issues_of_linked_devices(client, accounts):
    linked = {**ISSUE, "device_id": "dev-a", "kind": "wrong_article", "note": "is 'die'"}
    unlinked = {**ISSUE, "device_id": "dev-z"}
    assert client.post("/feedback/word-issue", json=linked).status_code == 204
    assert client.post("/feedback/word-issue", json=unlinked).status_code == 204
    token = sign_in(client, device_id="dev-a")["token"]
    assert client.delete("/me", headers=bearer(token)).status_code == 204

    with Session(engine) as s:
        issues = {i.note: i for i in s.exec(select(WordIssue)).all()}
    assert len(issues) == 2
    kept = issues["is 'die'"]
    assert kept.device_id == "deleted"
    assert (kept.external_id, kept.kind, kept.source, kept.target, kept.status) == (
        "der_schluessel", "wrong_article", "en", "de", "open")
    assert issues[ISSUE["note"]].device_id == "dev-z"
