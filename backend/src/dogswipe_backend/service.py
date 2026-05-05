from __future__ import annotations

from .repository import HotdogRepository
from .schemas import (
    CravingPreferences,
    DiscoveryResponse,
    MatchResponse,
    SwipeRequest,
    SwipeResponse,
    VendorSubmissionListResponse,
    VendorSubmissionRequest,
    VendorSubmissionResponse,
)


class DogSwipeService:
    def __init__(self, repository: HotdogRepository) -> None:
        self.repository = repository

    async def discovery(self, *, limit: int = 20) -> DiscoveryResponse:
        profiles = await self.repository.list_available_profiles(limit=max(1, min(limit, 50)))
        return DiscoveryResponse(profiles=profiles)

    async def swipe(self, *, user_id: str, request: SwipeRequest) -> SwipeResponse:
        matched = await self.repository.record_swipe(
            user_id=user_id,
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

    async def preferences(self, *, user_id: str) -> CravingPreferences:
        return await self.repository.get_preferences(user_id=user_id)

    async def update_preferences(
        self,
        *,
        user_id: str,
        preferences: CravingPreferences,
    ) -> CravingPreferences:
        return await self.repository.upsert_preferences(user_id=user_id, preferences=preferences)

    async def submit_vendor_profile(
        self,
        *,
        user_id: str,
        submission: VendorSubmissionRequest,
    ) -> VendorSubmissionResponse:
        profile = await self.repository.submit_vendor_profile(
            user_id=user_id,
            submission=submission,
        )
        return VendorSubmissionResponse(profile=profile)

    async def vendor_submissions(self, *, user_id: str) -> VendorSubmissionListResponse:
        return VendorSubmissionListResponse(
            submissions=await self.repository.list_vendor_submissions(user_id=user_id)
        )
