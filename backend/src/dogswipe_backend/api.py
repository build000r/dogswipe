from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from spaps_server_quickstart.api.health import HealthRouterFactory
from sqlalchemy.ext.asyncio import AsyncSession

from .auth import get_current_admin_user_id, get_current_user_id
from .db import get_db_session
from .repository import HotdogRepository, SqlAlchemyHotdogRepository
from .schemas import (
    AdminApprovalRequest,
    AdminApprovalResponse,
    AdminMenuRefreshRequest,
    AdminMenuRefreshResponse,
    AdminModerationRequest,
    AdminModerationResponse,
    AdminReviewQueueResponse,
    CravingPreferences,
    DiscoveryResponse,
    MatchResponse,
    MenuIngestionResponse,
    OrderCreateRequest,
    OrderListResponse,
    OrderResponse,
    SwipeRequest,
    SwipeResponse,
    VendorSubmissionListResponse,
    VendorSubmissionRequest,
    VendorSubmissionResponse,
    WalletResponse,
)
from .service import DogSwipeService
from .settings import get_settings


async def get_repository(session: AsyncSession = Depends(get_db_session)) -> HotdogRepository:
    return SqlAlchemyHotdogRepository(session)


async def get_service(
    repository: HotdogRepository = Depends(get_repository),
) -> DogSwipeService:
    return DogSwipeService(repository)


def build_api_router() -> APIRouter:
    router = APIRouter()
    health_factory = HealthRouterFactory(
        settings_loader=get_settings,
        session_dependency=None,
        include_redis=False,
        include_migrations=False,
    )
    router.include_router(health_factory.create_router())

    v1 = APIRouter(prefix="/v1")

    @v1.get("/discovery", response_model=DiscoveryResponse)
    async def discovery(
        limit: int = Query(default=20, ge=1, le=50),
        latitude: float | None = Query(default=None, ge=-90, le=90),
        longitude: float | None = Query(default=None, ge=-180, le=180),
        menu_query: str | None = Query(default=None, max_length=64),
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> DiscoveryResponse:
        if (latitude is None) != (longitude is None):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="latitude and longitude must be provided together",
            )
        return await service.discovery(
            user_id=user_id,
            limit=limit,
            latitude=latitude,
            longitude=longitude,
            menu_query=menu_query,
        )

    @v1.post("/swipes", response_model=SwipeResponse)
    async def swipe(
        request: SwipeRequest,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> SwipeResponse:
        return await service.swipe(user_id=user_id, request=request)

    @v1.get("/matches", response_model=MatchResponse)
    async def matches(
        latitude: float | None = Query(default=None, ge=-90, le=90),
        longitude: float | None = Query(default=None, ge=-180, le=180),
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> MatchResponse:
        if (latitude is None) != (longitude is None):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="latitude and longitude must be provided together",
            )
        return await service.matches(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
        )

    @v1.get("/preferences", response_model=CravingPreferences)
    async def preferences(
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> CravingPreferences:
        return await service.preferences(user_id=user_id)

    @v1.put("/preferences", response_model=CravingPreferences)
    async def update_preferences(
        request: CravingPreferences,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> CravingPreferences:
        return await service.update_preferences(user_id=user_id, preferences=request)

    @v1.get("/wallet", response_model=WalletResponse)
    async def wallet(
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> WalletResponse:
        return await service.wallet(user_id=user_id)

    @v1.get("/orders", response_model=OrderListResponse)
    async def orders(
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> OrderListResponse:
        return await service.orders(user_id=user_id)

    @v1.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
    async def create_order(
        request: OrderCreateRequest,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> OrderResponse:
        return await service.create_order(user_id=user_id, request=request)

    @v1.get("/vendor/submissions", response_model=VendorSubmissionListResponse)
    async def vendor_submissions(
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> VendorSubmissionListResponse:
        return await service.vendor_submissions(user_id=user_id)

    @v1.post(
        "/vendor/submissions",
        response_model=VendorSubmissionResponse,
        status_code=status.HTTP_201_CREATED,
    )
    async def submit_vendor_profile(
        request: VendorSubmissionRequest,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> VendorSubmissionResponse:
        return await service.submit_vendor_profile(user_id=user_id, submission=request)

    @v1.put("/vendor/submissions/{profile_id}", response_model=VendorSubmissionResponse)
    async def update_vendor_submission(
        profile_id: str,
        request: VendorSubmissionRequest,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> VendorSubmissionResponse:
        return await service.update_vendor_submission(
            user_id=user_id,
            profile_id=profile_id,
            submission=request,
        )

    @v1.post(
        "/vendor/submissions/{profile_id}/ingest-menu",
        response_model=MenuIngestionResponse,
    )
    async def ingest_vendor_submission_menu(
        profile_id: str,
        service: DogSwipeService = Depends(get_service),
        user_id: str = Depends(get_current_user_id),
    ) -> MenuIngestionResponse:
        return await service.ingest_vendor_submission_menu(
            user_id=user_id,
            profile_id=profile_id,
        )

    @v1.get("/admin/vendor/submissions", response_model=AdminReviewQueueResponse)
    async def admin_vendor_submissions(
        service: DogSwipeService = Depends(get_service),
        admin_user_id: str = Depends(get_current_admin_user_id),
    ) -> AdminReviewQueueResponse:
        del admin_user_id
        return await service.admin_review_queue()

    @v1.post("/admin/vendor/menus/refresh", response_model=AdminMenuRefreshResponse)
    async def refresh_vendor_menus(
        request: AdminMenuRefreshRequest,
        service: DogSwipeService = Depends(get_service),
        admin_user_id: str = Depends(get_current_admin_user_id),
    ) -> AdminMenuRefreshResponse:
        del admin_user_id
        return await service.refresh_stale_menus(request=request)

    @v1.post(
        "/admin/vendor/submissions/{profile_id}/approve",
        response_model=AdminApprovalResponse,
    )
    async def approve_vendor_submission(
        profile_id: str,
        request: AdminApprovalRequest,
        service: DogSwipeService = Depends(get_service),
        admin_user_id: str = Depends(get_current_admin_user_id),
    ) -> AdminApprovalResponse:
        del admin_user_id
        return await service.approve_vendor_submission(profile_id=profile_id, request=request)

    @v1.post(
        "/admin/vendor/submissions/{profile_id}/request-changes",
        response_model=AdminModerationResponse,
    )
    async def request_vendor_submission_changes(
        profile_id: str,
        request: AdminModerationRequest,
        service: DogSwipeService = Depends(get_service),
        admin_user_id: str = Depends(get_current_admin_user_id),
    ) -> AdminModerationResponse:
        del admin_user_id
        return await service.request_vendor_submission_changes(
            profile_id=profile_id,
            request=request,
        )

    @v1.post(
        "/admin/vendor/submissions/{profile_id}/reject",
        response_model=AdminModerationResponse,
    )
    async def reject_vendor_submission(
        profile_id: str,
        request: AdminModerationRequest,
        service: DogSwipeService = Depends(get_service),
        admin_user_id: str = Depends(get_current_admin_user_id),
    ) -> AdminModerationResponse:
        del admin_user_id
        return await service.reject_vendor_submission(profile_id=profile_id, request=request)

    router.include_router(v1)
    return router
