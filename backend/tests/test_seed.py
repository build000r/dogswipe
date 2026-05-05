from __future__ import annotations

import pytest

from dogswipe_backend.seed import seed_sample_profiles


@pytest.mark.asyncio
async def test_seed_sample_profiles_is_idempotent(database) -> None:
    async with database.session_factory() as session:
        first_count = await seed_sample_profiles(session)
        await session.commit()

    async with database.session_factory() as session:
        second_count = await seed_sample_profiles(session)
        await session.commit()

    assert first_count == 0
    assert second_count == 0
