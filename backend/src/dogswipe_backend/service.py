from __future__ import annotations

import re
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
    OrderAddOn,
    OrderCreateRequest,
    OrderListResponse,
    OrderResponse,
    OrderStatus,
    SwipeRequest,
    SwipeResponse,
    VendorSubmissionListResponse,
    VendorSubmissionRequest,
    VendorSubmissionResponse,
    WalletResponse,
    validate_order_status_transition,
)

EARTH_RADIUS_MILES = 3958.8
MENU_QUERY_MAX_LENGTH = 64
ORDER_ADD_ONS: dict[str, OrderAddOn] = {
    add_on.id: add_on
    for add_on in [
        OrderAddOn(id="bacon", name="Bacon", price_dollars=1.00),
        OrderAddOn(id="jalapenos", name="Jalapenos", price_dollars=0.75),
        OrderAddOn(id="cheese-sauce", name="Cheese Sauce", price_dollars=1.25),
        OrderAddOn(id="extra-pickle", name="Extra Pickle", price_dollars=0.50),
    ]
}


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
        menu_query: str | None = None,
    ) -> DiscoveryResponse:
        preferences = await self.repository.get_preferences(user_id=user_id)
        max_distance_miles = max(preferences.max_distance_miles, 1)
        location = self._location_from_coordinates(latitude, longitude)
        normalized_menu_query = self._normalize_menu_query(menu_query)
        profiles = await self.repository.list_available_profiles(
            limit=self._profile_fetch_limit(location, normalized_menu_query),
            max_distance_miles=max_distance_miles,
            latitude=latitude,
            longitude=longitude,
        )
        ranked = self._rank_discovery_profiles(
            self._profiles_with_location_distance(profiles, location),
            preferences,
            normalized_menu_query,
        )
        return DiscoveryResponse(profiles=ranked[: self._clamped_discovery_limit(limit)])

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

    async def wallet(self, *, user_id: str) -> WalletResponse:
        account = await self.repository.get_or_create_credit_account(user_id=user_id)
        return WalletResponse(account=account)

    @staticmethod
    def _location_from_coordinates(
        latitude: float | None,
        longitude: float | None,
    ) -> tuple[float, float] | None:
        if latitude is None or longitude is None:
            return None
        return (latitude, longitude)

    @staticmethod
    def _profile_fetch_limit(
        location: tuple[float, float] | None,
        normalized_menu_query: str | None,
    ) -> int:
        if location is not None or normalized_menu_query is not None:
            return 200
        return 50

    @staticmethod
    def _clamped_discovery_limit(limit: int) -> int:
        return max(1, min(limit, 50))

    def _profiles_with_location_distance(
        self,
        profiles: list[HotdogProfile],
        location: tuple[float, float] | None,
    ) -> list[HotdogProfile]:
        return [self._profile_with_location_distance(profile, location) for profile in profiles]

    def _rank_discovery_profiles(
        self,
        profiles: list[HotdogProfile],
        preferences: CravingPreferences,
        normalized_menu_query: str | None,
    ) -> list[HotdogProfile]:
        return sorted(
            (
                profile
                for profile in profiles
                if self._is_eligible(profile, preferences)
                and self._matches_menu_query(profile, normalized_menu_query)
            ),
            key=lambda profile: self._score(profile, preferences, normalized_menu_query),
            reverse=True,
        )

    async def orders(self, *, user_id: str) -> OrderListResponse:
        return OrderListResponse(orders=await self.repository.list_orders(user_id=user_id))

    async def create_order(
        self,
        *,
        user_id: str,
        request: OrderCreateRequest,
    ) -> OrderResponse:
        add_ons = self._order_add_ons(request.add_on_ids)
        profile = await self.repository.get_orderable_profile(profile_id=request.profile_id)
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hotdog profile not found",
            )
        return OrderResponse(
            order=await self.repository.create_order(
                user_id=user_id,
                profile=profile,
                add_ons=add_ons,
            )
        )

    async def transition_order_status(
        self,
        *,
        user_id: str,
        order_id: str,
        target_status: OrderStatus,
    ) -> OrderResponse:
        order = await self.repository.get_order(user_id=user_id, order_id=order_id)
        if order is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found",
            )
        try:
            next_status = validate_order_status_transition(order.status, target_status)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=str(exc),
            ) from exc

        updated = await self.repository.update_order_status(
            user_id=user_id,
            order_id=order_id,
            status=next_status,
        )
        if updated is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found",
            )
        return OrderResponse(order=updated)

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
    def _score(
        profile: HotdogProfile,
        preferences: CravingPreferences,
        menu_query: str | None = None,
    ) -> float:
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
        if menu_query is not None:
            weighted_score = (weighted_score * 0.82) + (
                DogSwipeService._menu_query_score(profile, menu_query) * 0.18
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
        return DogSwipeService._menu_search_text(profile)

    @staticmethod
    def _matches_menu_query(profile: HotdogProfile, menu_query: str | None) -> bool:
        if menu_query is None:
            return True
        terms = DogSwipeService._query_terms(menu_query)
        if not terms:
            return True
        search_text = DogSwipeService._menu_search_text(profile)
        return all(term in search_text for term in terms)

    @staticmethod
    def _menu_query_score(profile: HotdogProfile, menu_query: str) -> float:
        terms = DogSwipeService._query_terms(menu_query)
        if not terms:
            return 0.0
        search_text = DogSwipeService._menu_search_text(profile)
        menu_text = " ".join(
            [profile.menu_excerpt or "", *profile.menu_highlights]
        ).lower()
        search_matches = sum(1 for term in terms if term in search_text) / len(terms)
        menu_matches = sum(1 for term in terms if term in menu_text) / len(terms)
        return min(1.0, (search_matches * 0.7) + (menu_matches * 0.3))

    @staticmethod
    def _menu_search_text(profile: HotdogProfile) -> str:
        return " ".join(
            [
                profile.name,
                profile.style,
                profile.signature_notes,
                profile.vendor_name,
                profile.menu_excerpt or "",
                " ".join(profile.menu_highlights),
            ]
        ).lower()

    @staticmethod
    def _normalize_menu_query(menu_query: str | None) -> str | None:
        if menu_query is None:
            return None
        normalized = " ".join(menu_query.strip().split())
        if not normalized:
            return None
        return normalized[:MENU_QUERY_MAX_LENGTH]

    @staticmethod
    def _query_terms(menu_query: str) -> list[str]:
        return re.findall(r"[a-z0-9]+", menu_query.lower())

    @staticmethod
    def _order_add_ons(add_on_ids: list[str]) -> list[OrderAddOn]:
        seen: set[str] = set()
        add_ons: list[OrderAddOn] = []
        for add_on_id in add_on_ids:
            normalized = add_on_id.strip()
            if not normalized or normalized not in ORDER_ADD_ONS:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="Unknown order add-on",
                )
            if normalized in seen:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="Duplicate order add-on",
                )
            seen.add(normalized)
            add_ons.append(ORDER_ADD_ONS[normalized])
        return add_ons

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
