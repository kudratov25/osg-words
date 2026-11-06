"""Alembic environment.

Runs either with a connection handed in by app/migrate.py (normal case: the
app upgrades itself on startup) or standalone from the `alembic` CLI, using
DATABASE_URL. render_as_batch makes ALTERs work on SQLite (table copy).
"""

from alembic import context
from sqlalchemy import create_engine

from app import models  # noqa: F401  (registers tables on SQLModel.metadata)
from app.config import DATABASE_URL
from sqlmodel import SQLModel

target_metadata = SQLModel.metadata


def _run(connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        render_as_batch=True,
    )
    with context.begin_transaction():
        context.run_migrations()


connection = context.config.attributes.get("connection")
if connection is not None:
    _run(connection)
elif context.is_offline_mode():
    context.configure(url=DATABASE_URL, target_metadata=target_metadata, render_as_batch=True,
                      literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()
else:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        _run(conn)
        conn.commit()
