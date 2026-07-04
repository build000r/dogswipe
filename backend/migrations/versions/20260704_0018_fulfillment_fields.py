"""fulfillment fields

Revision ID: 0018
Revises: 0017
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0018"
down_revision: str | None = "0017"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("hotdog_profiles", sa.Column("available_from", sa.DateTime(timezone=True)))
    op.add_column("hotdog_profiles", sa.Column("available_until", sa.DateTime(timezone=True)))
    op.add_column(
        "hotdog_profiles",
        sa.Column("fulfillment_mode", sa.String(16), nullable=False, server_default="pickup"),
    )
    op.add_column("hotdog_profiles", sa.Column("delivery_radius_miles", sa.Float()))
    op.add_column("hotdog_profiles", sa.Column("delivery_address", sa.String(240)))

    op.add_column(
        "order_items",
        sa.Column("fulfillment_mode", sa.String(16), nullable=False, server_default="pickup"),
    )
    op.add_column("order_items", sa.Column("available_from", sa.DateTime(timezone=True)))
    op.add_column("order_items", sa.Column("available_until", sa.DateTime(timezone=True)))
    op.add_column("order_items", sa.Column("delivery_address", sa.String(240)))


def downgrade() -> None:
    op.drop_column("order_items", "delivery_address")
    op.drop_column("order_items", "available_until")
    op.drop_column("order_items", "available_from")
    op.drop_column("order_items", "fulfillment_mode")

    op.drop_column("hotdog_profiles", "delivery_address")
    op.drop_column("hotdog_profiles", "delivery_radius_miles")
    op.drop_column("hotdog_profiles", "fulfillment_mode")
    op.drop_column("hotdog_profiles", "available_until")
    op.drop_column("hotdog_profiles", "available_from")
