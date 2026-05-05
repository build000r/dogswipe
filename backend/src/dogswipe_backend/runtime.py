from __future__ import annotations

from .db import get_database
from .seed import seed_sample_profiles
from .settings import get_settings


async def prepare_local_database() -> None:
    settings = get_settings()
    if not settings.dogswipe_auto_create_schema:
        return

    database = get_database()
    await database.create_schema()
    if settings.dogswipe_seed_sample_profiles:
        async with database.session_factory() as session:
            await seed_sample_profiles(session)
            await session.commit()
