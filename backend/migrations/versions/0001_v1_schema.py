"""v1 schema: word, packmeta, deviceping exactly as production had them
(created by SQLModel.metadata.create_all before Alembic existed).

A database that already has these tables but no alembic_version table is
stamped at this revision by app/migrate.py instead of running it.

Revision ID: 0001
Revises:
Create Date: 2026-11-04
"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "word",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("external_id", sa.String(), nullable=False),
        sa.Column("german", sa.String(), nullable=False),
        sa.Column("article", sa.String(), nullable=True),
        sa.Column("translation", sa.String(), nullable=False),
        sa.Column("example", sa.String(), nullable=False),
        sa.Column("pronunciation", sa.String(), nullable=True),
        sa.Column("category", sa.String(), nullable=False),
        sa.Column("difficulty", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_word_external_id", "word", ["external_id"], unique=True)

    op.create_table(
        "packmeta",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "deviceping",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=False),
        sa.Column("device_model", sa.String(), nullable=True),
        sa.Column("os_version", sa.String(), nullable=True),
        sa.Column("app_version", sa.String(), nullable=True),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_deviceping_device_id", "deviceping", ["device_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_deviceping_device_id", table_name="deviceping")
    op.drop_table("deviceping")
    op.drop_table("packmeta")
    op.drop_index("ix_word_external_id", table_name="word")
    op.drop_table("word")
