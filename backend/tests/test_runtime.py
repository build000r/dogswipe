from __future__ import annotations

import asyncio

import pytest
from fastapi import FastAPI

from dogswipe_backend.menu import MenuIngestionResult
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.runtime import (
    MENU_REFRESH_TASK_ATTR,
    prepare_local_database,
    refresh_stale_menus_once,
    start_menu_refresh_worker,
    stop_menu_refresh_worker,
)
from dogswipe_backend.schemas import AdminMenuRefreshResponse, VendorSubmissionRequest
from dogswipe_backend.settings import get_settings


class FakeMenuIngestor:
    def __init__(self) -> None:
        self.urls: list[str] = []

    async def ingest(self, url: str) -> MenuIngestionResult:
        self.urls.append(url)
        return MenuIngestionResult(status="ok", excerpt="Runtime refreshed menu.")


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
        profiles = await SqlAlchemyHotdogRepository(session).list_available_profiles(limit=10)

    assert [profile.id for profile in profiles] == [
        "hotdog-coney",
        "hotdog-kimchi",
        "hotdog-chicago",
        "hotdog-nightcap",
    ]


@pytest.mark.asyncio
async def test_refresh_stale_menus_once_uses_configured_batch(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="runtime-menu-vendor",
            submission=VendorSubmissionRequest(
                name="Runtime Snap",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Runtime Cart",
                menu_url="https://runtime.example.com/menu",
            ),
        )
        await session.commit()

    ingestor = FakeMenuIngestor()

    response = await refresh_stale_menus_once(
        menu_ingestor=ingestor,
        limit=5,
        max_age_hours=0,
    )

    assert ingestor.urls == ["https://runtime.example.com/menu"]
    assert response.checked_count == 1
    assert response.refreshed_count == 1
    assert response.failed_count == 0
    assert [profile.id for profile in response.profiles] == [pending.id]
    assert response.profiles[0].menu_excerpt == "Runtime refreshed menu."


@pytest.mark.asyncio
async def test_menu_refresh_worker_is_disabled_by_default(clear_settings) -> None:
    del clear_settings
    app = FastAPI()

    await start_menu_refresh_worker(app)

    assert getattr(app.state, MENU_REFRESH_TASK_ATTR, None) is None
    await stop_menu_refresh_worker(app)


@pytest.mark.asyncio
async def test_menu_refresh_worker_runs_until_stopped(
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_MENU_REFRESH_ENABLED", "true")
    get_settings.cache_clear()
    app = FastAPI()
    refreshed = asyncio.Event()
    calls = 0

    async def fake_refresh_stale_menus_once() -> AdminMenuRefreshResponse:
        nonlocal calls
        calls += 1
        refreshed.set()
        return AdminMenuRefreshResponse(
            checked_count=0,
            refreshed_count=0,
            failed_count=0,
            profiles=[],
        )

    monkeypatch.setattr(
        "dogswipe_backend.runtime.refresh_stale_menus_once",
        fake_refresh_stale_menus_once,
    )

    await start_menu_refresh_worker(app)
    first_task = getattr(app.state, MENU_REFRESH_TASK_ATTR)
    await start_menu_refresh_worker(app)

    assert getattr(app.state, MENU_REFRESH_TASK_ATTR) is first_task
    await asyncio.wait_for(refreshed.wait(), timeout=1)
    await stop_menu_refresh_worker(app)

    assert calls == 1
    assert getattr(app.state, MENU_REFRESH_TASK_ATTR) is None
