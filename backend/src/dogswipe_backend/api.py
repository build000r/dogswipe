from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from spaps_server_quickstart.api.health import HealthRouterFactory
from sqlalchemy.ext.asyncio import AsyncSession

from .db import get_db_session
from .repository import DogRepository, SqlAlchemyDogRepository
from .schemas import DiscoveryResponse, MatchResponse, SwipeRequest, SwipeResponse
from .service import DogSwipeService
from .settings import get_settings


async def get_repository(session: AsyncSession = Depends(get_db_session)) -> DogRepository:
    return SqlAlchemyDogRepository(session)


async def get_service(
    repository: DogRepository = Depends(get_repository),
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
        service: DogSwipeService = Depends(get_service),
    ) -> DiscoveryResponse:
        return await service.discovery(limit=limit)

    @v1.post("/swipes", response_model=SwipeResponse)
    async def swipe(
        request: SwipeRequest,
        service: DogSwipeService = Depends(get_service),
    ) -> SwipeResponse:
        return await service.swipe(request)

    @v1.get("/matches", response_model=MatchResponse)
    async def matches(
        user_id: str = Query(min_length=1, max_length=128),
        service: DogSwipeService = Depends(get_service),
    ) -> MatchResponse:
        return await service.matches(user_id=user_id)

    router.include_router(v1)
    return router
