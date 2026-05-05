"""address text

Revision ID: 0008
Revises: 0007
Create Date: 2026-05-05 16:30:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("address_text", sa.String(240), nullable=True))


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "address_text")
