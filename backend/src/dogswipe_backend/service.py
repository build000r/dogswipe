from __future__ import annotations

from .repository import DogRepository
from .schemas import DiscoveryResponse, MatchResponse, SwipeRequest, SwipeResponse


class DogSwipeService:
    def __init__(self, repository: DogRepository) -> None:
        self.repository = repository

    async def discovery(self, *, limit: int = 20) -> DiscoveryResponse:
        profiles = await self.repository.list_available_profiles(limit=max(1, min(limit, 50)))
        return DiscoveryResponse(profiles=profiles)

    async def swipe(self, request: SwipeRequest) -> SwipeResponse:
        matched = await self.repository.record_swipe(
            user_id=request.user_id,
            profile_id=request.profile_id,
            decision=request.decision,
        )
        return SwipeResponse(
            profile_id=request.profile_id,
            decision=request.decision,
            matched=matched,
        )

    async def matches(self, *, user_id: str) -> MatchResponse:
        return MatchResponse(matches=await self.repository.list_matches(user_id=user_id))
