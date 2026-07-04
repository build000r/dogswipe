"""credit ledger

Revision ID: 0014
Revises: 0013
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0014"
down_revision: str | None = "0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "credit_ledger",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("user_id", sa.String(128), nullable=False),
        sa.Column("entry_type", sa.String(32), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("balance_after", sa.Integer(), nullable=False),
        sa.Column("order_ref", sa.String(36), nullable=True),
        sa.Column("purchase_ref", sa.String(128), nullable=True),
        sa.Column("idempotency_key", sa.String(128), nullable=True),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("idempotency_key", name="uq_credit_ledger_idempotency_key"),
        sa.CheckConstraint(
            "entry_type IN ('purchase', 'spend', 'earn', 'refund_credit', 'admin_adjustment')",
            name="ck_credit_ledger_entry_type",
        ),
    )
    op.create_index("ix_credit_ledger_user", "credit_ledger", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_credit_ledger_user", table_name="credit_ledger")
    op.drop_table("credit_ledger")
