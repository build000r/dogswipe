from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import cast

from fastapi import FastAPI
from spaps_server_quickstart import create_app as quickstart_create_app

from .api import build_api_router
from .runtime import prepare_local_database, start_menu_refresh_worker, stop_menu_refresh_worker
from .settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = cast(
        FastAPI,
        quickstart_create_app(
            settings_loader=get_settings,
            api_router=build_api_router(),
            enable_cors=True,
            enable_spaps_auth=settings.spaps_auth_enabled,
            run_startup_checks=settings.env != "test",
        ),
    )

    app.add_event_handler("startup", prepare_local_database)
    app.add_event_handler("startup", _menu_refresh_startup_handler(app))
    app.add_event_handler("shutdown", _menu_refresh_shutdown_handler(app))
    return app


def _menu_refresh_startup_handler(app: FastAPI) -> Callable[[], Awaitable[None]]:
    async def startup() -> None:
        await start_menu_refresh_worker(app)

    return startup


def _menu_refresh_shutdown_handler(app: FastAPI) -> Callable[[], Awaitable[None]]:
    async def shutdown() -> None:
        await stop_menu_refresh_worker(app)

    return shutdown
