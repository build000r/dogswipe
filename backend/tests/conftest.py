from __future__ import annotations

from collections.abc import AsyncIterator, Iterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from dogswipe_backend.app import create_app
from dogswipe_backend.db import Database, set_database_for_tests
from dogswipe_backend.models import DogProfileRecord
from dogswipe_backend.settings import get_settings


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


@pytest_asyncio.fixture
async def database(tmp_path, monkeypatch: pytest.MonkeyPatch) -> AsyncIterator[Database]:
    database_url = f"sqlite+aiosqlite:///{tmp_path / 'dogswipe.db'}"
    monkeypatch.setenv("ENV", "test")
    monkeypatch.setenv("DATABASE_URL", database_url)
    get_settings.cache_clear()
    db = Database(database_url)
    set_database_for_tests(db)
    await db.create_schema()
    async with db.session_factory() as session:
        session.add_all(
            [
                DogProfileRecord(
                    id="dog-luna",
                    name="Luna",
                    breed="Australian Shepherd",
                    age_years=2.5,
                    temperament="Active, focused, affectionate",
                    distance_miles=4.2,
                    shelter_name="River North Rescue",
                    image_url="https://images.unsplash.com/photo-1552053831-71594a27632d",
                    compatibility_score=0.91,
                ),
                DogProfileRecord(
                    id="dog-miso",
                    name="Miso",
                    breed="Shiba Inu",
                    age_years=4,
                    temperament="Independent, quiet, apartment-ready",
                    distance_miles=8.7,
                    shelter_name="West Loop Humane",
                    image_url="https://images.unsplash.com/photo-1537151625747-768eb6cf92b2",
                    compatibility_score=0.68,
                ),
            ]
        )
        await session.commit()
    try:
        yield db
    finally:
        await db.dispose()
        set_database_for_tests(None)
        get_settings.cache_clear()


@pytest_asyncio.fixture
async def async_client(database: Database) -> AsyncIterator[AsyncClient]:
    del database
    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        yield client


@pytest.fixture
def clear_settings() -> Iterator[None]:
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()
