"""order items

Revision ID: 0009
Revises: 0008
Create Date: 2026-05-06 04:05:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "order_items",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("user_id", sa.String(128), nullable=False),
        sa.Column("profile_id", sa.String(36), nullable=False),
        sa.Column("hotdog_name", sa.String(80), nullable=False),
        sa.Column("vendor_name", sa.String(160), nullable=False),
        sa.Column("base_price_dollars", sa.Float(), nullable=False),
        sa.Column("add_ons_json", sa.Text(), nullable=False),
        sa.Column("total_dollars", sa.Float(), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_order_items_profile",
        "order_items",
        ["profile_id"],
        unique=False,
    )
    op.create_index(
        "ix_order_items_user_created",
        "order_items",
        ["user_id", "created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_order_items_user_created", table_name="order_items")
    op.drop_index("ix_order_items_profile", table_name="order_items")
    op.drop_table("order_items")
