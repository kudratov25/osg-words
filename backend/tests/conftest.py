import os
import tempfile

# Must be set before the app (and its engine) is imported.
_tmp = tempfile.mkdtemp()
os.environ.setdefault("DATABASE_URL", f"sqlite:///{os.path.join(_tmp, 'test.db')}")
os.environ["ADMIN_API_KEY"] = "test-admin-key"
# Tests don't depend on backend/content/*.json: first start seeds the
# built-in 60 German words (test_content_files.py checks the real files).
os.environ["CONTENT_DIR"] = os.path.join(_tmp, "no-content")
os.environ.pop("EMAIL_BACKEND", None)

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import MetaData  # noqa: E402

from app import config  # noqa: E402
from app.database import engine  # noqa: E402
from app.main import app  # noqa: E402
from app.security import hash_password  # noqa: E402

ADMIN = {"X-Admin-Key": "test-admin-key"}
ADMIN_USER = "admin"
ADMIN_PASSWORD = "test-password-123"
config.ADMIN_USERNAME = ADMIN_USER
config.ADMIN_PASSWORD_HASH = hash_password(ADMIN_PASSWORD)


def drop_everything(eng=engine) -> None:
    """Drop every table incl. alembic_version, so startup migrates from zero."""
    md = MetaData()
    md.reflect(eng)
    md.drop_all(eng)


@pytest.fixture
def client():
    # Fresh, migrated + re-seeded database and throttles for every test.
    from app import emailer, security
    from app.routers import auth

    security._failures.clear()
    auth._ip_starts.clear()
    emailer.outbox.clear()
    drop_everything()
    with TestClient(app) as c:  # runs startup: alembic upgrade + seed
        yield c
