from __future__ import annotations

import pytest

from dogswipe_backend.repository import SqlAlchemyDogRepository
from dogswipe_backend.runtime import prepare_local_database
from dogswipe_backend.settings import get_settings


@pytest.mark.asyncio
async def test_prepare_local_database_creates_schema_and_seeds(
    database,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    await database.drop_schema()
    monkeypatch.setenv("DOGSWIPE_AUTO_CREATE_SCHEMA", "true")
    monkeypatch.setenv("DOGSWIPE_SEED_SAMPLE_PROFILES", "true")
    get_settings.cache_clear()

    await prepare_local_database()

    async with database.session_factory() as session:
        profiles = await SqlAlchemyDogRepository(session).list_available_profiles(limit=10)

    assert [profile.id for profile in profiles] == ["dog-luna", "dog-sage", "dog-miso"]
