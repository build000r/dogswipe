"""document order status state machine

Revision ID: 0012
Revises: 0011
Create Date: 2026-07-04 00:00:00.000000+00:00

Order status values:
draft, claimed, ready, handed_off, delivered, completed, reviewed, canceled,
disputed, refunded_credit.
"""

from __future__ import annotations

from collections.abc import Sequence

revision: str = "0012"
down_revision: str | None = "0011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
