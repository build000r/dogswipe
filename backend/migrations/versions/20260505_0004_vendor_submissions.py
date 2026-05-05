"""vendor submissions

Revision ID: 0004
Revises: 0003
Create Date: 2026-05-05 13:35:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("menu_url", sa.Text(), nullable=True))
    op.add_column(
        "hotdog_profiles",
        sa.Column("media_alt_text", sa.String(length=160), nullable=True),
    )
    op.add_column(
        "hotdog_profiles",
        sa.Column("vendor_owner_user_id", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "hotdog_profiles",
        sa.Column("last_verified_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_hotdog_profiles_vendor_owner",
        "hotdog_profiles",
        ["vendor_owner_user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_hotdog_profiles_vendor_owner", table_name="hotdog_profiles")
    op.drop_column("hotdog_profiles", "last_verified_at")
    op.drop_column("hotdog_profiles", "vendor_owner_user_id")
    op.drop_column("hotdog_profiles", "media_alt_text")
    op.drop_column("hotdog_profiles", "menu_url")
