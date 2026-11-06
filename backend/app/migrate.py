"""Run Alembic migrations programmatically (called on app startup).

Databases created before Alembic existed (production v1) have the v1 tables
but no `alembic_version` table: those are stamped at revision 0001 (= the
v1 schema) first, then upgraded in place.

Manual use:  python -m app.migrate        (upgrade DATABASE_URL to head)
"""

import logging

from alembic import command
from alembic.config import Config
from sqlalchemy import inspect
from sqlalchemy.engine import Engine

from .config import BACKEND_DIR

log = logging.getLogger("osg.migrate")

V1_REVISION = "0001"
V1_TABLES = {"word", "packmeta", "deviceping"}


def alembic_config() -> Config:
    cfg = Config(str(BACKEND_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(BACKEND_DIR / "migrations"))
    return cfg


def upgrade_db(engine: Engine, revision: str = "head") -> None:
    cfg = alembic_config()
    with engine.connect() as conn:
        tables = set(inspect(conn).get_table_names())
        cfg.attributes["connection"] = conn
        if "alembic_version" not in tables and V1_TABLES <= tables:
            log.warning("Pre-Alembic database found: stamping it at %s", V1_REVISION)
            command.stamp(cfg, V1_REVISION)
        command.upgrade(cfg, revision)
        conn.commit()


def downgrade_db(engine: Engine, revision: str) -> None:
    cfg = alembic_config()
    with engine.connect() as conn:
        cfg.attributes["connection"] = conn
        command.downgrade(cfg, revision)
        conn.commit()


if __name__ == "__main__":
    from .database import engine

    logging.basicConfig(level=logging.INFO)
    upgrade_db(engine)
