from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import DogProfileRecord

SAMPLE_PROFILE_ROWS: tuple[dict[str, object], ...] = (
    {
        "id": "dog-luna",
        "name": "Luna",
        "breed": "Australian Shepherd",
        "age_years": 2.5,
        "temperament": "Active, focused, affectionate",
        "distance_miles": 4.2,
        "shelter_name": "River North Rescue",
        "image_url": "https://images.unsplash.com/photo-1552053831-71594a27632d",
        "compatibility_score": 0.91,
    },
    {
        "id": "dog-miso",
        "name": "Miso",
        "breed": "Shiba Inu",
        "age_years": 4.0,
        "temperament": "Independent, quiet, apartment-ready",
        "distance_miles": 8.7,
        "shelter_name": "West Loop Humane",
        "image_url": "https://images.unsplash.com/photo-1537151625747-768eb6cf92b2",
        "compatibility_score": 0.68,
    },
    {
        "id": "dog-sage",
        "name": "Sage",
        "breed": "Greyhound",
        "age_years": 5.0,
        "temperament": "Calm, warm, couch loyal",
        "distance_miles": 2.1,
        "shelter_name": "Lakeside Adoption Center",
        "image_url": "https://images.unsplash.com/photo-1518717758536-85ae29035b6d",
        "compatibility_score": 0.84,
    },
)


async def seed_sample_profiles(session: AsyncSession) -> int:
    sample_ids = [str(row["id"]) for row in SAMPLE_PROFILE_ROWS]
    existing_ids = set(
        await session.scalars(
            select(DogProfileRecord.id).where(DogProfileRecord.id.in_(sample_ids))
        )
    )
    records = [
        DogProfileRecord(**row) for row in SAMPLE_PROFILE_ROWS if str(row["id"]) not in existing_ids
    ]
    session.add_all(records)
    await session.flush()
    return len(records)
