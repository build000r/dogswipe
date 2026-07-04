"""reviews

Revision ID: 0013
Revises: 0012
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0013"
down_revision: str | None = "0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "reviews",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("order_id", sa.String(36), nullable=False),
        sa.Column("rater_user_id", sa.String(128), nullable=False),
        sa.Column("ratee_user_id", sa.String(128), nullable=False),
        sa.Column("direction", sa.String(32), nullable=False),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("text", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("order_id", "direction", name="uq_reviews_order_direction"),
        sa.CheckConstraint(
            "direction IN ('giver_reviews_receiver', 'receiver_reviews_giver')",
            name="ck_reviews_direction",
        ),
        sa.CheckConstraint("rating >= 1 AND rating <= 5", name="ck_reviews_rating_range"),
    )


def downgrade() -> None:
    op.drop_table("reviews")
