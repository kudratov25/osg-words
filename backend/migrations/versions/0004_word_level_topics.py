"""Word CEFR level + job-area topics (v2.1).

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-06
"""

import sqlalchemy as sa
from alembic import op

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("word") as batch:
        batch.add_column(sa.Column("level", sa.String(), nullable=True))
        batch.add_column(sa.Column("topics", sa.String(), nullable=False, server_default=""))
    # Until the content files are re-imported with real CEFR levels, derive
    # one from the old difficulty so every word has a level.
    op.execute("UPDATE word SET level = CASE difficulty "
               "WHEN 'intermediate' THEN 'B1' WHEN 'advanced' THEN 'B2' ELSE 'A2' END "
               "WHERE level IS NULL")


def downgrade() -> None:
    with op.batch_alter_table("word") as batch:
        batch.drop_column("topics")
        batch.drop_column("level")
