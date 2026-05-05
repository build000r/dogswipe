"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-05-05 12:15:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "hotdog_profiles",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("style", sa.String(length=120), nullable=False),
        sa.Column("price_dollars", sa.Float(), nullable=False),
        sa.Column("signature_notes", sa.String(length=120), nullable=False),
        sa.Column("distance_miles", sa.Float(), nullable=False),
        sa.Column("vendor_name", sa.String(length=160), nullable=False),
        sa.Column("image_url", sa.Text(), nullable=True),
        sa.Column("crave_score", sa.Float(), nullable=False),
        sa.Column("availability_status", sa.String(length=32), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "swipe_events",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=128), nullable=False),
        sa.Column("profile_id", sa.String(length=36), nullable=False),
        sa.Column("decision", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_swipe_events_user_profile",
        "swipe_events",
        ["user_id", "profile_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_swipe_events_user_profile", table_name="swipe_events")
    op.drop_table("swipe_events")
    op.drop_table("hotdog_profiles")
