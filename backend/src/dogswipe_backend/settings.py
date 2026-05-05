from __future__ import annotations

from typing import Annotated

from pydantic_settings import NoDecode
from spaps_server_quickstart.settings import BaseServiceSettings, create_settings_loader


class DogSwipeSettings(BaseServiceSettings):  # type: ignore[misc]
    app_name: str = "DogSwipe API"
    service_slug: str = "dogswipe-api"
    version: str = "0.1.0"
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/dogswipe"
    redis_url: str = "redis://localhost:6379/0"
    spaps_auth_enabled: bool = False
    dogswipe_admin_user_ids: str = ""
    dogswipe_auto_create_schema: bool = False
    dogswipe_seed_sample_profiles: bool = False
    spaps_auth_exempt_paths: Annotated[tuple[str, ...], NoDecode] = (
        "/health",
        "/docs",
        "/redoc",
    )
    cors_allow_origins: Annotated[tuple[str, ...], NoDecode] = (
        "http://localhost:3000",
        "http://localhost:5173",
    )


get_settings = create_settings_loader(DogSwipeSettings)
