from __future__ import annotations

from fastapi import HTTPException, status

from .repository import HotdogRepository
from .schemas import (
    AdminApprovalRequest,
    AdminApprovalResponse,
    AdminReviewQueueResponse,
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

    async def admin_review_queue(self) -> AdminReviewQueueResponse:
        return AdminReviewQueueResponse(
            submissions=await self.repository.list_pending_vendor_submissions()
        )

    async def approve_vendor_submission(
        self,
        *,
        profile_id: str,
        request: AdminApprovalRequest,
    ) -> AdminApprovalResponse:
        profile = await self.repository.approve_vendor_submission(
            profile_id=profile_id,
            crave_score=request.crave_score,
        )
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )
        return AdminApprovalResponse(profile=profile)
