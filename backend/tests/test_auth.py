from __future__ import annotations

import pytest
from fastapi import HTTPException
from spaps_server_quickstart.auth import AuthenticatedUser
from starlette.requests import Request

from dogswipe_backend.auth import (
    DEFAULT_LOCAL_USER_ID,
    LOCAL_USER_HEADER,
    MAX_USER_ID_LENGTH,
    get_current_admin_user_id,
    get_current_user_id,
)
from dogswipe_backend.settings import get_settings


def _request(headers: dict[str, str] | None = None) -> Request:
    raw_headers = [
        (key.lower().encode("latin-1"), value.encode("latin-1"))
        for key, value in (headers or {}).items()
    ]
    return Request({"type": "http", "method": "GET", "path": "/", "headers": raw_headers})


def test_get_current_user_id_prefers_authenticated_user() -> None:
    request = _request({LOCAL_USER_HEADER: "local-user"})
    request.state.authenticated_user = AuthenticatedUser(
        user_id="spaps-user",
        session_id="session-1",
        application_id="app-1",
    )
    assert get_current_user_id(request) == "spaps-user"


def test_get_current_user_id_uses_local_header_when_auth_disabled(clear_settings) -> None:
    del clear_settings
    assert get_current_user_id(_request({LOCAL_USER_HEADER: "local-dev"})) == "local-dev"


def test_get_current_user_id_uses_default_local_user_when_auth_disabled(clear_settings) -> None:
    del clear_settings
    assert get_current_user_id(_request()) == DEFAULT_LOCAL_USER_ID


@pytest.mark.parametrize("local_user_id", ["", " ", "u" * (MAX_USER_ID_LENGTH + 1)])
def test_get_current_user_id_rejects_invalid_local_header(
    clear_settings,
    local_user_id: str,
) -> None:
    del clear_settings
    with pytest.raises(HTTPException) as exc_info:
        get_current_user_id(_request({LOCAL_USER_HEADER: local_user_id}))
    assert exc_info.value.status_code == 400


def test_get_current_user_id_requires_auth_when_spaps_enabled(
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("SPAPS_AUTH_ENABLED", "true")
    get_settings.cache_clear()
    with pytest.raises(HTTPException) as exc_info:
        get_current_user_id(_request())
    assert exc_info.value.status_code == 401


def test_get_current_user_id_rejects_local_header_outside_local_env(
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("ENV", "production")
    get_settings.cache_clear()
    with pytest.raises(HTTPException) as exc_info:
        get_current_user_id(_request({LOCAL_USER_HEADER: "spoofed-admin"}))
    assert exc_info.value.status_code == 401


def test_get_current_admin_user_id_accepts_configured_admin(
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-1, admin-2")
    get_settings.cache_clear()
    assert get_current_admin_user_id("admin-2") == "admin-2"


def test_get_current_admin_user_id_rejects_unconfigured_user(clear_settings) -> None:
    del clear_settings
    with pytest.raises(HTTPException) as exc_info:
        get_current_admin_user_id("vendor-1")
    assert exc_info.value.status_code == 403
