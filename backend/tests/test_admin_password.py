"""Admin panel: change password (stored in DB, overrides .env, logs out old sessions)."""

from app import security
from app.database import engine
from app.models import AdminCredential
from sqlmodel import Session

from .conftest import ADMIN, ADMIN_PASSWORD, ADMIN_USER

NEW = "brand-new-password-42"


def login(client, password=ADMIN_PASSWORD):
    return client.post("/admin/login", json={"username": ADMIN_USER, "password": password})


def auth(token):
    return {"Authorization": f"Bearer {token}"}


def change(client, token, current=ADMIN_PASSWORD, new=NEW):
    return client.post("/admin/password", headers=auth(token), json={"current_password": current, "new_password": new})


def test_change_password_flow(client):
    old_tab = login(client).json()["token"]
    this_tab = login(client).json()["token"]

    r = change(client, this_tab)
    assert r.status_code == 200
    fresh = r.json()["token"]
    assert r.json()["username"] == ADMIN_USER

    # The caller stays logged in with the returned token; every older session is out.
    assert client.get("/admin/me", headers=auth(fresh)).status_code == 200
    assert client.get("/admin/me", headers=auth(old_tab)).status_code == 401
    assert client.get("/admin/me", headers=auth(this_tab)).status_code == 401

    # Old password no longer works, new one does.
    assert login(client).status_code == 401
    assert login(client, NEW).status_code == 200

    with Session(engine) as s:
        row = s.get(AdminCredential, 1)
        assert row and security.verify_password(NEW, row.password_hash)


def test_wrong_current_password(client):
    token = login(client).json()["token"]
    r = change(client, token, current="not-the-password")
    assert r.status_code == 400 and "Current password" in r.json()["detail"]
    assert login(client).status_code == 200  # unchanged


def test_new_password_rules(client):
    token = login(client).json()["token"]
    assert change(client, token, new="short").status_code == 422
    r = change(client, token, new=ADMIN_PASSWORD)
    assert r.status_code == 400 and "different" in r.json()["detail"]


def test_wrong_current_password_is_throttled(client):
    token = login(client).json()["token"]
    for _ in range(5):
        assert change(client, token, current="wrong-wrong").status_code == 400
    assert change(client, token).status_code == 429


def test_requires_login(client):
    r = client.post("/admin/password", json={"current_password": ADMIN_PASSWORD, "new_password": NEW})
    assert r.status_code == 401


def test_api_key_still_works_after_change(client):
    token = login(client).json()["token"]
    assert change(client, token).status_code == 200
    assert client.get("/admin/me", headers=ADMIN).status_code == 200


def test_reset_command_restores_env_password(client, capsys):
    from app import set_password

    token = login(client).json()["token"]
    assert change(client, token).status_code == 200
    set_password.reset()
    assert "removed" in capsys.readouterr().out
    assert login(client, NEW).status_code == 401
    assert login(client).status_code == 200
