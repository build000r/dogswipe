from __future__ import annotations

from typing import Annotated, cast

from fastapi import Depends, HTTPException, Request, status
from spaps_server_quickstart.auth import AuthenticatedUser

try:
    from spaps_server_quickstart.auth.dependencies import optional_authenticated_user
except ImportError as exc:
    if "optional_authenticated_user" not in str(exc):
        raise

    def optional_authenticated_user(request: Request) -> AuthenticatedUser | None:
        user = getattr(request.state, "authenticated_user", None)
        if isinstance(user, AuthenticatedUser):
            return user
        return None

from .settings import get_settings

LOCAL_USER_HEADER = "X-DogSwipe-User-ID"
DEFAULT_LOCAL_USER_ID = "local-user"
MAX_USER_ID_LENGTH = 128
LOCAL_AUTH_ENVS = {"local", "test", "testing", "development", "dev"}


def get_current_user_id(request: Request) -> str:
    user = optional_authenticated_user(request)
    if user is not None:
        return cast(str, user.user_id)

    settings = get_settings()
    if settings.spaps_auth_enabled:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not _local_identity_fallback_allowed(settings.env):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    local_user_id = request.headers.get(LOCAL_USER_HEADER, DEFAULT_LOCAL_USER_ID).strip()
    if not local_user_id or len(local_user_id) > MAX_USER_ID_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{LOCAL_USER_HEADER} must be between 1 and {MAX_USER_ID_LENGTH} characters",
        )

    return local_user_id


def _local_identity_fallback_allowed(env: object) -> bool:
    return str(env or "").lower() in LOCAL_AUTH_ENVS


def get_current_admin_user_id(
    user_id: Annotated[str, Depends(get_current_user_id)],
) -> str:
    admin_user_ids = {
        admin_user_id.strip()
        for admin_user_id in get_settings().dogswipe_admin_user_ids.split(",")
        if admin_user_id.strip()
    }
    if user_id not in admin_user_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return user_id
