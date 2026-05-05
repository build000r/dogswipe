"""profile coordinates

Revision ID: 0006
Revises: 0005
Create Date: 2026-05-05 15:10:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("hotdog_profiles", sa.Column("longitude", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "longitude")
    op.drop_column("hotdog_profiles", "latitude")
