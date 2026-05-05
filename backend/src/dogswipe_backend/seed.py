from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import HotdogProfileRecord

SAMPLE_PROFILE_ROWS: tuple[dict[str, object], ...] = (
    {
        "id": "hotdog-coney",
        "name": "Coney Classic",
        "style": "Chili dog",
        "price_dollars": 6.5,
        "signature_notes": "Beef frank, snap casing, chili, onion, and yellow mustard.",
        "distance_miles": 1.2,
        "latitude": 43.6539,
        "longitude": -79.3843,
        "vendor_name": "Franklin Cart",
        "address_text": "100 Queen St W, Toronto, ON",
        "image_url": None,
        "crave_score": 0.91,
    },
    {
        "id": "hotdog-kimchi",
        "name": "Kimchi Crunch",
        "style": "Korean street dog",
        "price_dollars": 8.75,
        "signature_notes": "Gochujang mayo, kimchi, scallion, and sesame crunch.",
        "distance_miles": 2.4,
        "latitude": 43.6555,
        "longitude": -79.38,
        "vendor_name": "Bun Signal",
        "address_text": "200 King St W, Toronto, ON",
        "image_url": None,
        "crave_score": 0.88,
    },
    {
        "id": "hotdog-chicago",
        "name": "Garden Snap",
        "style": "Chicago dog",
        "price_dollars": 7.25,
        "signature_notes": "Sport peppers, relish, tomato, pickle spear, and celery salt.",
        "distance_miles": 3.1,
        "latitude": 43.665,
        "longitude": -79.407,
        "vendor_name": "Northside Stand",
        "address_text": "860 Bloor St W, Toronto, ON",
        "image_url": None,
        "crave_score": 0.82,
    },
    {
        "id": "hotdog-nightcap",
        "name": "Nightcap Melt",
        "style": "Chili cheese dog",
        "price_dollars": 9.0,
        "signature_notes": "Sharp cheddar, late-night chili, grilled onions, and jalapeno dust.",
        "distance_miles": 4.8,
        "latitude": 43.647,
        "longitude": -79.395,
        "vendor_name": "Depot Dogs",
        "address_text": "65 Front St W, Toronto, ON",
        "image_url": None,
        "crave_score": 0.69,
    },
)


async def seed_sample_profiles(session: AsyncSession) -> int:
    sample_ids = [str(row["id"]) for row in SAMPLE_PROFILE_ROWS]
    existing_ids = set(
        await session.scalars(
            select(HotdogProfileRecord.id).where(HotdogProfileRecord.id.in_(sample_ids))
        )
    )
    records = [
        HotdogProfileRecord(**row)
        for row in SAMPLE_PROFILE_ROWS
        if str(row["id"]) not in existing_ids
    ]
    session.add_all(records)
    await session.flush()
    return len(records)
