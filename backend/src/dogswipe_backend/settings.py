from __future__ import annotations

from typing import Annotated, Literal

from pydantic import Field
from pydantic_settings import NoDecode
from spaps_server_quickstart.settings import BaseServiceSettings, create_settings_loader


class DogSwipeSettings(BaseServiceSettings):  # type: ignore[misc]
    app_name: str = "DogSwipe API"
    service_slug: str = "dogswipe-api"
    version: str = "0.1.0"
    development_environment: Literal["local", "production", "prod"] | None = None
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/dogswipe"
    redis_url: str = "redis://localhost:6379/0"
    spaps_auth_enabled: bool = False
    dogswipe_admin_user_ids: str = ""
    dogswipe_auto_create_schema: bool = False
    dogswipe_seed_sample_profiles: bool = False
    dogswipe_menu_refresh_enabled: bool = False
    dogswipe_menu_refresh_interval_seconds: int = Field(default=3600, ge=60, le=86400)
    dogswipe_menu_refresh_batch_size: int = Field(default=20, ge=1, le=50)
    dogswipe_menu_refresh_max_age_hours: float = Field(default=24, ge=0, le=168)
    stripe_secret_key: str | None = None
    stripe_webhook_secret: str | None = None
    stripe_success_url: str = "https://dogswipe.local/credits/success"
    stripe_cancel_url: str = "https://dogswipe.local/credits/cancel"
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
