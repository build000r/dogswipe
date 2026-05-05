"""submission review notes

Revision ID: 0005
Revises: 0004
Create Date: 2026-05-05 14:25:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("review_note", sa.Text(), nullable=True))
    op.add_column(
        "hotdog_profiles",
        sa.Column("last_reviewed_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "last_reviewed_at")
    op.drop_column("hotdog_profiles", "review_note")
