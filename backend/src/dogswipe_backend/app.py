from __future__ import annotations

from typing import cast

from fastapi import FastAPI
from spaps_server_quickstart import create_app as quickstart_create_app

from .api import build_api_router
from .settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    return cast(
        FastAPI,
        quickstart_create_app(
            settings_loader=get_settings,
            api_router=build_api_router(),
            enable_cors=True,
            enable_spaps_auth=settings.spaps_auth_enabled,
            run_startup_checks=settings.env != "test",
        ),
    )
