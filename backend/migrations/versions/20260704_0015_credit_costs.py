"""rename dollar prices to credit costs

Revision ID: 0015
Revises: 0014
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0015"
down_revision: str | None = "0014"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("hotdog_profiles") as batch_op:
        batch_op.add_column(sa.Column("credit_cost", sa.Integer(), nullable=True))
    op.execute(
        "UPDATE hotdog_profiles "
        "SET credit_cost = CAST(ROUND(price_dollars) AS INTEGER)"
    )
    with op.batch_alter_table("hotdog_profiles") as batch_op:
        batch_op.alter_column("credit_cost", nullable=False)
        batch_op.drop_column("price_dollars")

    with op.batch_alter_table("order_items") as batch_op:
        batch_op.add_column(sa.Column("base_credit_cost", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("total_credits", sa.Integer(), nullable=True))
    op.execute(
        "UPDATE order_items SET "
        "base_credit_cost = CAST(ROUND(base_price_dollars) AS INTEGER), "
        "total_credits = CAST(ROUND(total_dollars) AS INTEGER)"
    )
    with op.batch_alter_table("order_items") as batch_op:
        batch_op.alter_column("base_credit_cost", nullable=False)
        batch_op.alter_column("total_credits", nullable=False)
        batch_op.drop_column("base_price_dollars")
        batch_op.drop_column("total_dollars")


def downgrade() -> None:
    with op.batch_alter_table("order_items") as batch_op:
        batch_op.add_column(sa.Column("base_price_dollars", sa.Float(), nullable=True))
        batch_op.add_column(sa.Column("total_dollars", sa.Float(), nullable=True))
    op.execute(
        "UPDATE order_items SET "
        "base_price_dollars = base_credit_cost * 1.0, "
        "total_dollars = total_credits * 1.0"
    )
    with op.batch_alter_table("order_items") as batch_op:
        batch_op.alter_column("base_price_dollars", nullable=False)
        batch_op.alter_column("total_dollars", nullable=False)
        batch_op.drop_column("base_credit_cost")
        batch_op.drop_column("total_credits")

    with op.batch_alter_table("hotdog_profiles") as batch_op:
        batch_op.add_column(sa.Column("price_dollars", sa.Float(), nullable=True))
    op.execute("UPDATE hotdog_profiles SET price_dollars = credit_cost * 1.0")
    with op.batch_alter_table("hotdog_profiles") as batch_op:
        batch_op.alter_column("price_dollars", nullable=False)
        batch_op.drop_column("credit_cost")
