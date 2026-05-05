"""menu ingestion

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-05 15:45:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("menu_status", sa.String(32), nullable=True))
    op.add_column("hotdog_profiles", sa.Column("menu_excerpt", sa.Text(), nullable=True))
    op.add_column(
        "hotdog_profiles",
        sa.Column("menu_checked_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "menu_checked_at")
    op.drop_column("hotdog_profiles", "menu_excerpt")
    op.drop_column("hotdog_profiles", "menu_status")
