from __future__ import annotations

import asyncio
import contextlib
import logging

from fastapi import FastAPI

from .db import get_database
from .menu import MenuIngestor
from .repository import SqlAlchemyHotdogRepository
from .schemas import AdminMenuRefreshRequest, AdminMenuRefreshResponse
from .seed import seed_sample_profiles
from .service import DogSwipeService
from .settings import get_settings

logger = logging.getLogger(__name__)
MENU_REFRESH_TASK_ATTR = "dogswipe_menu_refresh_task"


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


async def refresh_stale_menus_once(
    *,
    menu_ingestor: MenuIngestor | None = None,
    limit: int | None = None,
    max_age_hours: float | None = None,
) -> AdminMenuRefreshResponse:
    settings = get_settings()
    request = AdminMenuRefreshRequest(
        limit=settings.dogswipe_menu_refresh_batch_size if limit is None else limit,
        max_age_hours=(
            settings.dogswipe_menu_refresh_max_age_hours
            if max_age_hours is None
            else max_age_hours
        ),
    )
    database = get_database()
    async with database.session_factory() as session:
        service = DogSwipeService(
            SqlAlchemyHotdogRepository(session),
            menu_ingestor=menu_ingestor,
        )
        response = await service.refresh_stale_menus(request=request)
        await session.commit()
        return response


async def start_menu_refresh_worker(app: FastAPI) -> None:
    settings = get_settings()
    if not settings.dogswipe_menu_refresh_enabled:
        return
    existing_task = getattr(app.state, MENU_REFRESH_TASK_ATTR, None)
    if isinstance(existing_task, asyncio.Task) and not existing_task.done():
        return
    setattr(
        app.state,
        MENU_REFRESH_TASK_ATTR,
        asyncio.create_task(_menu_refresh_loop(), name="dogswipe-menu-refresh"),
    )


async def stop_menu_refresh_worker(app: FastAPI) -> None:
    task = getattr(app.state, MENU_REFRESH_TASK_ATTR, None)
    if not isinstance(task, asyncio.Task):
        return
    task.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await task
    setattr(app.state, MENU_REFRESH_TASK_ATTR, None)


async def _menu_refresh_loop() -> None:
    while True:
        try:
            response = await refresh_stale_menus_once()
            logger.info(
                "stale menu refresh checked=%s refreshed=%s failed=%s",
                response.checked_count,
                response.refreshed_count,
                response.failed_count,
            )
        except asyncio.CancelledError:
            raise
        except Exception:
            logger.exception("stale menu refresh failed")
        await asyncio.sleep(get_settings().dogswipe_menu_refresh_interval_seconds)
