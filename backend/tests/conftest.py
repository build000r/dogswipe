from __future__ import annotations

from collections.abc import AsyncIterator, Iterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from dogswipe_backend.app import create_app
from dogswipe_backend.db import Database, set_database_for_tests
from dogswipe_backend.seed import seed_sample_profiles
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
        await seed_sample_profiles(session)
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
