"""hotdog profiles

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-05 12:30:00.000000+00:00
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.rename_table("dog_profiles", "hotdog_profiles")
    op.alter_column(
        "hotdog_profiles",
        "breed",
        new_column_name="style",
        existing_type=sa.String(length=120),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "age_years",
        new_column_name="price_dollars",
        existing_type=sa.Float(),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "temperament",
        new_column_name="signature_notes",
        existing_type=sa.String(length=120),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "shelter_name",
        new_column_name="vendor_name",
        existing_type=sa.String(length=160),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "compatibility_score",
        new_column_name="crave_score",
        existing_type=sa.Float(),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "adoption_status",
        new_column_name="availability_status",
        existing_type=sa.String(length=32),
        existing_nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "hotdog_profiles",
        "availability_status",
        new_column_name="adoption_status",
        existing_type=sa.String(length=32),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "crave_score",
        new_column_name="compatibility_score",
        existing_type=sa.Float(),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "vendor_name",
        new_column_name="shelter_name",
        existing_type=sa.String(length=160),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "signature_notes",
        new_column_name="temperament",
        existing_type=sa.String(length=120),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "price_dollars",
        new_column_name="age_years",
        existing_type=sa.Float(),
        existing_nullable=False,
    )
    op.alter_column(
        "hotdog_profiles",
        "style",
        new_column_name="breed",
        existing_type=sa.String(length=120),
        existing_nullable=False,
    )
    op.rename_table("hotdog_profiles", "dog_profiles")
