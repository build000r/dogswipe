"""order disputes

Revision ID: 0020
Revises: 0019
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0020"
down_revision: str | None = "0019"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("order_items", sa.Column("disputed_at", sa.DateTime(timezone=True)))
    op.add_column("order_items", sa.Column("disputed_by_user_id", sa.String(128)))
    op.add_column("order_items", sa.Column("dispute_reason", sa.Text()))
    op.add_column("order_items", sa.Column("dispute_resolved_at", sa.DateTime(timezone=True)))
    op.add_column("order_items", sa.Column("dispute_resolution_note", sa.Text()))


def downgrade() -> None:
    op.drop_column("order_items", "dispute_resolution_note")
    op.drop_column("order_items", "dispute_resolved_at")
    op.drop_column("order_items", "dispute_reason")
    op.drop_column("order_items", "disputed_by_user_id")
    op.drop_column("order_items", "disputed_at")
