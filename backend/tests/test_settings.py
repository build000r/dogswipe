from __future__ import annotations

import pytest

from dogswipe_backend.app import create_app
from dogswipe_backend.settings import get_settings


def test_settings_accept_production_development_environment(
    clear_settings,
    monkeypatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("ENV", "production")
    monkeypatch.setenv("DEVELOPMENT_ENVIRONMENT", "production")
    get_settings.cache_clear()

    settings = get_settings()

    assert settings.development_environment == "production"
    assert settings.is_local_development is False


def test_app_rejects_auth_disabled_production(
    clear_settings,
    monkeypatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("ENV", "production")
    monkeypatch.setenv("DEVELOPMENT_ENVIRONMENT", "production")
    monkeypatch.setenv("SPAPS_AUTH_ENABLED", "false")
    get_settings.cache_clear()

    with pytest.raises(RuntimeError, match="SPAPS auth must be enabled"):
        create_app()
