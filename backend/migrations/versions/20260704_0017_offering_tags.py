"""offering tags

Revision ID: 0017
Revises: 0016
Create Date: 2026-07-04 00:00:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0017"
down_revision: str | None = "0016"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

CLASSIC_MATCH = (
    "lower(coalesce(name, '') || ' ' || coalesce(style, '') || ' ' || "
    "coalesce(signature_notes, '') || ' ' || coalesce(menu_excerpt, '')) "
    "LIKE '%classic%' OR lower(coalesce(style, '')) LIKE '%chicago%' OR "
    "lower(coalesce(signature_notes, '')) LIKE '%mustard%'"
)
SPICY_MATCH = (
    "lower(coalesce(name, '') || ' ' || coalesce(style, '') || ' ' || "
    "coalesce(signature_notes, '') || ' ' || coalesce(menu_excerpt, '')) "
    "LIKE '%jalapeno%' OR lower(coalesce(signature_notes, '')) LIKE '%gochujang%' OR "
    "lower(coalesce(signature_notes, '')) LIKE '%pepper%'"
)


def upgrade() -> None:
    op.add_column(
        "hotdog_profiles",
        sa.Column("tags_json", sa.Text(), nullable=False, server_default="[]"),
    )
    op.execute(
        f"UPDATE hotdog_profiles SET tags_json = '[\"classic\",\"spicy\"]' "
        f"WHERE ({CLASSIC_MATCH}) AND ({SPICY_MATCH})"
    )
    op.execute(
        f"UPDATE hotdog_profiles SET tags_json = '[\"classic\"]' "
        f"WHERE tags_json = '[]' AND ({CLASSIC_MATCH})"
    )
    op.execute(
        f"UPDATE hotdog_profiles SET tags_json = '[\"spicy\"]' "
        f"WHERE tags_json = '[]' AND ({SPICY_MATCH})"
    )


def downgrade() -> None:
    op.drop_column("hotdog_profiles", "tags_json")
