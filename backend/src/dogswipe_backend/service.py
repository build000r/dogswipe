from __future__ import annotations

from datetime import UTC, datetime, timedelta
from math import asin, cos, radians, sin, sqrt

from fastapi import HTTPException, status

from .menu import HTTPMenuIngestor, MenuIngestionResult, MenuIngestor
from .repository import HotdogRepository
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
    HotdogProfile,
    MatchResponse,
    MenuIngestionResponse,
    SwipeRequest,
    SwipeResponse,
    VendorSubmissionListResponse,
    VendorSubmissionRequest,
    VendorSubmissionResponse,
)

EARTH_RADIUS_MILES = 3958.8


class DogSwipeService:
    def __init__(
        self,
        repository: HotdogRepository,
        menu_ingestor: MenuIngestor | None = None,
    ) -> None:
        self.repository = repository
        self.menu_ingestor = menu_ingestor or HTTPMenuIngestor()

    async def discovery(
        self,
        *,
        user_id: str,
        limit: int = 20,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> DiscoveryResponse:
        preferences = await self.repository.get_preferences(user_id=user_id)
        max_distance_miles = max(preferences.max_distance_miles, 1)
        location = (latitude, longitude) if latitude is not None and longitude is not None else None
        profiles = await self.repository.list_available_profiles(
            limit=200 if location is not None else 50,
            max_distance_miles=max_distance_miles,
            latitude=latitude,
            longitude=longitude,
        )
        profiles = [self._profile_with_location_distance(profile, location) for profile in profiles]
        ranked = sorted(
            (profile for profile in profiles if self._is_eligible(profile, preferences)),
            key=lambda profile: self._score(profile, preferences),
            reverse=True,
        )
        return DiscoveryResponse(profiles=ranked[: max(1, min(limit, 50))])

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

    async def matches(
        self,
        *,
        user_id: str,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> MatchResponse:
        location = (latitude, longitude) if latitude is not None and longitude is not None else None
        matches = await self.repository.list_matches(user_id=user_id)
        return MatchResponse(
            matches=[self._profile_with_location_distance(profile, location) for profile in matches]
        )

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

    async def update_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
        submission: VendorSubmissionRequest,
    ) -> VendorSubmissionResponse:
        profile = await self.repository.update_vendor_submission(
            user_id=user_id,
            profile_id=profile_id,
            submission=submission,
        )
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )
        return VendorSubmissionResponse(profile=profile)

    async def ingest_vendor_submission_menu(
        self,
        *,
        user_id: str,
        profile_id: str,
    ) -> MenuIngestionResponse:
        profile = await self.repository.get_vendor_submission(
            user_id=user_id,
            profile_id=profile_id,
        )
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )

        status_value = "missing_url"
        excerpt = None
        if profile.menu_url:
            result = await self.menu_ingestor.ingest(profile.menu_url)
            status_value = result.status
            excerpt = result.excerpt

        updated = await self.repository.record_menu_ingestion(
            user_id=user_id,
            profile_id=profile_id,
            status=status_value,
            excerpt=excerpt,
            checked_at=datetime.now(UTC),
        )
        if updated is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )
        return MenuIngestionResponse(profile=updated)

    async def refresh_stale_menus(
        self,
        *,
        request: AdminMenuRefreshRequest,
    ) -> AdminMenuRefreshResponse:
        checked_at = datetime.now(UTC)
        stale_before = checked_at - timedelta(hours=request.max_age_hours)
        candidates = await self.repository.list_menu_refresh_candidates(
            limit=request.limit,
            stale_before=stale_before,
        )
        updated_profiles: list[HotdogProfile] = []
        for profile in candidates:
            if profile.menu_url is None:
                result = MenuIngestionResult(status="missing_url")
            else:
                result = await self.menu_ingestor.ingest(profile.menu_url)
            updated = await self.repository.record_admin_menu_ingestion(
                profile_id=profile.id,
                status=result.status,
                excerpt=result.excerpt,
                checked_at=checked_at,
            )
            if updated is not None:
                updated_profiles.append(updated)
        refreshed_count = sum(
            1 for profile in updated_profiles if profile.menu_status == "ok"
        )
        return AdminMenuRefreshResponse(
            checked_count=len(updated_profiles),
            refreshed_count=refreshed_count,
            failed_count=len(updated_profiles) - refreshed_count,
            profiles=updated_profiles,
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

    async def request_vendor_submission_changes(
        self,
        *,
        profile_id: str,
        request: AdminModerationRequest,
    ) -> AdminModerationResponse:
        profile = await self.repository.request_vendor_submission_changes(
            profile_id=profile_id,
            review_note=request.review_note,
        )
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )
        return AdminModerationResponse(profile=profile)

    async def reject_vendor_submission(
        self,
        *,
        profile_id: str,
        request: AdminModerationRequest,
    ) -> AdminModerationResponse:
        profile = await self.repository.reject_vendor_submission(
            profile_id=profile_id,
            review_note=request.review_note,
        )
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vendor submission not found",
            )
        return AdminModerationResponse(profile=profile)

    @staticmethod
    def _is_eligible(profile: HotdogProfile, preferences: CravingPreferences) -> bool:
        max_distance_miles = max(preferences.max_distance_miles, 1)
        if profile.distance_miles > max_distance_miles:
            return False
        if preferences.classic_only and not DogSwipeService._is_classic(profile):
            return False
        return True

    @staticmethod
    def _score(profile: HotdogProfile, preferences: CravingPreferences) -> float:
        max_distance_miles = max(preferences.max_distance_miles, 1)
        distance_score = max(0.0, 1 - (profile.distance_miles / max_distance_miles))
        spicy_score = (
            1.0 if preferences.spicy_friendly or not DogSwipeService._is_spicy(profile) else 0.58
        )
        classic_score = (
            1.0 if not preferences.classic_only or DogSwipeService._is_classic(profile) else 0.62
        )
        weighted_score = (
            (profile.crave_score * 0.55)
            + (distance_score * 0.25)
            + (spicy_score * 0.10)
            + (classic_score * 0.10)
        )
        return min(max(weighted_score, 0.0), 1.0)

    @staticmethod
    def _is_spicy(profile: HotdogProfile) -> bool:
        flavor_text = DogSwipeService._flavor_text(profile)
        return "jalapeno" in flavor_text or "gochujang" in flavor_text or "pepper" in flavor_text

    @staticmethod
    def _is_classic(profile: HotdogProfile) -> bool:
        flavor_text = DogSwipeService._flavor_text(profile)
        return "classic" in flavor_text or "chicago" in flavor_text or "mustard" in flavor_text

    @staticmethod
    def _flavor_text(profile: HotdogProfile) -> str:
        return f"{profile.name} {profile.style} {profile.signature_notes}".lower()

    @staticmethod
    def _profile_with_location_distance(
        profile: HotdogProfile,
        location: tuple[float, float] | None,
    ) -> HotdogProfile:
        if location is None or profile.latitude is None or profile.longitude is None:
            return profile
        distance_miles = DogSwipeService._haversine_miles(
            latitude=location[0],
            longitude=location[1],
            target_latitude=profile.latitude,
            target_longitude=profile.longitude,
        )
        return profile.model_copy(update={"distance_miles": distance_miles})

    @staticmethod
    def _haversine_miles(
        *,
        latitude: float,
        longitude: float,
        target_latitude: float,
        target_longitude: float,
    ) -> float:
        latitude_1 = radians(latitude)
        latitude_2 = radians(target_latitude)
        latitude_delta = radians(target_latitude - latitude)
        longitude_delta = radians(target_longitude - longitude)
        haversine = (
            sin(latitude_delta / 2) ** 2
            + cos(latitude_1) * cos(latitude_2) * sin(longitude_delta / 2) ** 2
        )
        return 2 * EARTH_RADIUS_MILES * asin(min(1.0, sqrt(haversine)))
