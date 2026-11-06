"""v2: language pairs, word reports, minimal accounts (docs/SPEC-v2.md s.4).

- word: german -> term, + lang (default 'de'), + updated_at (= created_at
  for existing rows); translation moves to wordtranslation (lang='en').
- packmeta: + target/source; the existing row becomes (de, en), keeping
  its version; unique (target, source).
- deviceping: + pair.
- new: wordissue, user, logincode, authsession, devicelink.

Works on SQLite (batch_alter_table = copy-and-move) and Postgres.

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-04
"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None

TS = sa.DateTime(timezone=True)


def upgrade() -> None:
    # --- word -----------------------------------------------------------------
    with op.batch_alter_table("word") as b:
        b.alter_column("german", new_column_name="term", existing_type=sa.String(), existing_nullable=False)
        b.add_column(sa.Column("lang", sa.String(), nullable=False, server_default="de"))
        b.add_column(sa.Column("updated_at", TS, nullable=True))
    op.execute("UPDATE word SET updated_at = created_at")
    with op.batch_alter_table("word") as b:
        b.alter_column("updated_at", existing_type=TS, nullable=False)
        b.create_index("ix_word_lang", ["lang"], unique=False)

    # --- wordtranslation (takes over word.translation as 'en') -------------------
    op.create_table(
        "wordtranslation",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("word_id", sa.Integer(), nullable=False),
        sa.Column("lang", sa.String(), nullable=False),
        sa.Column("translation", sa.String(), nullable=False),
        sa.Column("example_translation", sa.String(), nullable=True),
        sa.ForeignKeyConstraint(["word_id"], ["word.id"], name="fk_wordtranslation_word_id", ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("word_id", "lang", name="uq_wordtranslation_word_lang"),
    )
    op.create_index("ix_wordtranslation_word_id", "wordtranslation", ["word_id"], unique=False)
    op.execute(
        "INSERT INTO wordtranslation (word_id, lang, translation, example_translation) "
        "SELECT id, 'en', translation, NULL FROM word ORDER BY id"
    )
    with op.batch_alter_table("word") as b:
        b.drop_column("translation")

    # --- packmeta: one row per pair -------------------------------------------------
    with op.batch_alter_table("packmeta") as b:
        b.add_column(sa.Column("target", sa.String(), nullable=True))
        b.add_column(sa.Column("source", sa.String(), nullable=True))
    # v1 was single-row; if there were ever more, keep the highest version.
    op.execute(
        "DELETE FROM packmeta WHERE id NOT IN "
        "(SELECT id FROM (SELECT id FROM packmeta ORDER BY version DESC, id DESC LIMIT 1) AS keep)"
    )
    op.execute("UPDATE packmeta SET target = 'de', source = 'en'")
    with op.batch_alter_table("packmeta") as b:
        b.alter_column("target", existing_type=sa.String(), nullable=False)
        b.alter_column("source", existing_type=sa.String(), nullable=False)
        b.create_unique_constraint("uq_packmeta_target_source", ["target", "source"])

    # --- deviceping -------------------------------------------------------------------
    with op.batch_alter_table("deviceping") as b:
        b.add_column(sa.Column("pair", sa.String(), nullable=True))

    # --- word reports ---------------------------------------------------------------------
    op.create_table(
        "wordissue",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=False),
        sa.Column("external_id", sa.String(), nullable=False),
        sa.Column("source", sa.String(), nullable=False),
        sa.Column("target", sa.String(), nullable=False),
        sa.Column("kind", sa.String(), nullable=False),
        sa.Column("note", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=False),
        sa.Column("created_at", TS, nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_wordissue_device_id", "wordissue", ["device_id"], unique=False)
    op.create_index("ix_wordissue_external_id", "wordissue", ["external_id"], unique=False)
    op.create_index("ix_wordissue_status", "wordissue", ["status"], unique=False)

    # --- accounts -------------------------------------------------------------------------------
    op.create_table(
        "user",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column("age_range", sa.String(), nullable=True),
        sa.Column("created_at", TS, nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_email", "user", ["email"], unique=True)

    op.create_table(
        "logincode",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("code_hash", sa.String(), nullable=False),
        sa.Column("expires_at", TS, nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("used_at", TS, nullable=True),
        sa.Column("created_at", TS, nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_logincode_email", "logincode", ["email"], unique=False)

    op.create_table(
        "authsession",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(), nullable=False),
        sa.Column("created_at", TS, nullable=False),
        sa.Column("expires_at", TS, nullable=False),
        sa.Column("revoked_at", TS, nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name="fk_authsession_user_id", ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_authsession_user_id", "authsession", ["user_id"], unique=False)
    op.create_index("ix_authsession_token_hash", "authsession", ["token_hash"], unique=True)

    op.create_table(
        "devicelink",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("device_id", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name="fk_devicelink_user_id", ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id", "device_id"),
    )


def downgrade() -> None:
    """Back to the v1 shape. Loses: non-German words, non-English
    translations, per-pair pack versions, pairs, reports and accounts."""
    op.drop_table("devicelink")
    op.drop_index("ix_authsession_token_hash", table_name="authsession")
    op.drop_index("ix_authsession_user_id", table_name="authsession")
    op.drop_table("authsession")
    op.drop_index("ix_logincode_email", table_name="logincode")
    op.drop_table("logincode")
    op.drop_index("ix_user_email", table_name="user")
    op.drop_table("user")
    op.drop_index("ix_wordissue_status", table_name="wordissue")
    op.drop_index("ix_wordissue_external_id", table_name="wordissue")
    op.drop_index("ix_wordissue_device_id", table_name="wordissue")
    op.drop_table("wordissue")

    with op.batch_alter_table("deviceping") as b:
        b.drop_column("pair")

    op.execute("DELETE FROM packmeta WHERE NOT (target = 'de' AND source = 'en')")
    with op.batch_alter_table("packmeta") as b:
        b.drop_constraint("uq_packmeta_target_source", type_="unique")
        b.drop_column("source")
        b.drop_column("target")

    op.execute("DELETE FROM wordtranslation WHERE word_id IN (SELECT id FROM word WHERE lang <> 'de')")
    op.execute("DELETE FROM word WHERE lang <> 'de'")
    with op.batch_alter_table("word") as b:
        b.add_column(sa.Column("translation", sa.String(), nullable=True))
    op.execute(
        "UPDATE word SET translation = COALESCE((SELECT t.translation FROM wordtranslation t "
        "WHERE t.word_id = word.id AND t.lang = 'en'), '')"
    )
    op.drop_index("ix_wordtranslation_word_id", table_name="wordtranslation")
    op.drop_table("wordtranslation")
    with op.batch_alter_table("word") as b:
        b.alter_column("translation", existing_type=sa.String(), nullable=False)
        b.drop_index("ix_word_lang")
        b.drop_column("updated_at")
        b.drop_column("lang")
        b.alter_column("term", new_column_name="german", existing_type=sa.String(), existing_nullable=False)
