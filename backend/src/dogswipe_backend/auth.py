from __future__ import annotations

from typing import cast

from fastapi import HTTPException, Request, status
from spaps_server_quickstart.auth.dependencies import optional_authenticated_user

from .settings import get_settings

LOCAL_USER_HEADER = "X-DogSwipe-User-ID"
DEFAULT_LOCAL_USER_ID = "local-user"
MAX_USER_ID_LENGTH = 128


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

    local_user_id = request.headers.get(LOCAL_USER_HEADER, DEFAULT_LOCAL_USER_ID).strip()
    if not local_user_id or len(local_user_id) > MAX_USER_ID_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{LOCAL_USER_HEADER} must be between 1 and {MAX_USER_ID_LENGTH} characters",
        )

    return local_user_id
