from sqlmodel import Session, create_engine

from .config import DATABASE_URL

_connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=_connect_args, pool_pre_ping=True)


def init_db() -> None:
    """Bring the schema to the latest Alembic revision (see migrate.py)."""
    from .migrate import upgrade_db

    upgrade_db(engine)


def get_session():
    with Session(engine) as session:
        yield session
