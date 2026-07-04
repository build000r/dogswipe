"""offering add-ons

Revision ID: 0016
Revises: 0015
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0016"
down_revision: str | None = "0015"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "offering_add_ons",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("profile_id", sa.String(36), nullable=False),
        sa.Column("name", sa.String(80), nullable=False),
        sa.Column("credit_cost", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["profile_id"], ["hotdog_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_offering_add_ons_profile", "offering_add_ons", ["profile_id"])


def downgrade() -> None:
    op.drop_index("ix_offering_add_ons_profile", table_name="offering_add_ons")
    op.drop_table("offering_add_ons")
