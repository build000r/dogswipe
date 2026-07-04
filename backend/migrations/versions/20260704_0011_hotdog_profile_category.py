"""hotdog profile category

Revision ID: 0011
Revises: 0010
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0011"
down_revision: str | None = "0010"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "hotdog_profiles",
        sa.Column(
            "category",
            sa.String(32),
            nullable=False,
            server_default="hotdog",
        ),
    )
    op.execute("UPDATE hotdog_profiles SET category = 'hotdog' WHERE category IS NULL")


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "category")
