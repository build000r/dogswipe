from __future__ import annotations

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
