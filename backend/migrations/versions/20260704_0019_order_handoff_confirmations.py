"""order handoff confirmations

Revision ID: 0019
Revises: 0018
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0019"
down_revision: str | None = "0018"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("order_items", sa.Column("maker_ready_confirmed_at", sa.DateTime(timezone=True)))
    op.add_column(
        "order_items",
        sa.Column("maker_handoff_confirmed_at", sa.DateTime(timezone=True)),
    )
    op.add_column(
        "order_items",
        sa.Column("claimer_handoff_confirmed_at", sa.DateTime(timezone=True)),
    )
    op.add_column("order_items", sa.Column("completed_at", sa.DateTime(timezone=True)))


def downgrade() -> None:
    op.drop_column("order_items", "completed_at")
    op.drop_column("order_items", "claimer_handoff_confirmed_at")
    op.drop_column("order_items", "maker_handoff_confirmed_at")
    op.drop_column("order_items", "maker_ready_confirmed_at")
