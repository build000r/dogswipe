from __future__ import annotations

import re
from datetime import UTC, datetime, timedelta
from math import asin, cos, radians, sin, sqrt
from typing import Any, Mapping

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
    CreditLedgerEntryType,
    CreditPurchaseRequest,
    CreditPurchaseResponse,
    CreditReconciliationResponse,
    CreditWebhookResponse,
    DiscoveryResponse,
    FulfillmentMode,
    HotdogProfile,
    MatchResponse,
    MenuIngestionResponse,
    OrderAddOn,
    OrderCreateRequest,
    OrderListResponse,
    OrderResponse,
    OrderStatus,
    ReviewCreate,
    ReviewResponse,
    SwipeRequest,
    SwipeResponse,
    VendorSubmissionListResponse,
    VendorSubmissionRequest,
    VendorSubmissionResponse,
    WalletResponse,
    validate_order_status_transition,
)
from .settings import get_settings

EARTH_RADIUS_MILES = 3958.8
MENU_QUERY_MAX_LENGTH = 64
STRIPE_CENTS_PER_CREDIT = 100

stripe: Any | None = None


def _stripe_module() -> Any:
    global stripe
    if stripe is None:
        import stripe as stripe_package

        stripe = stripe_package
    return stripe


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

    async def create_credit_purchase(
        self,
        *,
        user_id: str,
        request: CreditPurchaseRequest,
    ) -> CreditPurchaseResponse:
        if request.amount_cents % STRIPE_CENTS_PER_CREDIT != 0:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="amount_cents must convert to whole credits",
            )

        credits = request.amount_cents // STRIPE_CENTS_PER_CREDIT
        settings = get_settings()
        if not settings.stripe_secret_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Stripe checkout is not configured",
            )

        stripe_client = _stripe_module()
        stripe_client.api_key = settings.stripe_secret_key
        session = stripe_client.checkout.Session.create(
            mode="payment",
            success_url=settings.stripe_success_url,
            cancel_url=settings.stripe_cancel_url,
            client_reference_id=user_id,
            metadata={
                "user_id": user_id,
                "credits": str(credits),
                "amount_cents": str(request.amount_cents),
            },
            line_items=[
                {
                    "quantity": 1,
                    "price_data": {
                        "currency": "usd",
                        "unit_amount": request.amount_cents,
                        "product_data": {"name": f"{credits} DogSwipe credits"},
                    },
                }
            ],
        )
        return CreditPurchaseResponse(
            checkout_session_id=str(self._stripe_value(session, "id")),
            checkout_url=str(self._stripe_value(session, "url")),
            amount_cents=request.amount_cents,
            credits=credits,
        )

    async def handle_credit_webhook(
        self,
        *,
        payload: bytes,
        stripe_signature: str | None,
    ) -> CreditWebhookResponse:
        settings = get_settings()
        if not settings.stripe_webhook_secret:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Stripe webhook is not configured",
            )
        if not stripe_signature:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing Stripe-Signature header",
            )

        stripe_client = _stripe_module()
        try:
            event = stripe_client.Webhook.construct_event(
                payload,
                stripe_signature,
                settings.stripe_webhook_secret,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Stripe webhook signature",
            ) from exc

        if self._stripe_value(event, "type") != "checkout.session.completed":
            return CreditWebhookResponse(received=True)

        event_id = str(self._stripe_value(event, "id"))
        session = self._stripe_value(self._stripe_value(event, "data"), "object")
        metadata = self._stripe_value(session, "metadata") or {}
        user_id = str(self._stripe_metadata_value(metadata, "user_id"))
        credits = int(self._stripe_metadata_value(metadata, "credits"))
        purchase_ref = str(self._stripe_value(session, "id"))

        try:
            await self.repository.create_ledger_entry(
                user_id=user_id,
                entry_type=CreditLedgerEntryType.purchase,
                amount=credits,
                purchase_ref=purchase_ref,
                idempotency_key=event_id,
                reason="Stripe checkout.session.completed",
            )
        except ValueError as exc:
            if "idempotency_key" in str(exc):
                return CreditWebhookResponse(received=True, duplicate=True)
            raise

        return CreditWebhookResponse(received=True, credited=True)

    async def credit_reconciliation(self) -> CreditReconciliationResponse:
        platform_float, outstanding_credits = await self.repository.get_credit_reconciliation_totals()
        return CreditReconciliationResponse(
            platform_float=platform_float,
            outstanding_credits=outstanding_credits,
            float_covers_outstanding=platform_float >= outstanding_credits,
        )

    @staticmethod
    def _location_from_coordinates(
        latitude: float | None,
        longitude: float | None,
    ) -> tuple[float, float] | None:
        if latitude is None or longitude is None:
            return None
        return (latitude, longitude)

    @staticmethod
    def _stripe_value(source: Any, key: str) -> Any:
        if isinstance(source, Mapping):
            return source.get(key)
        return getattr(source, key, None)

    @staticmethod
    def _stripe_metadata_value(metadata: Any, key: str) -> Any:
        value = DogSwipeService._stripe_value(metadata, key)
        if value is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Stripe session metadata missing {key}",
            )
        return value

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
        profile = await self.repository.get_orderable_profile(profile_id=request.profile_id)
        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hotdog profile not found",
            )
        self._ensure_available_now(profile, now=datetime.now(UTC))
        self._validate_fulfillment_request(profile=profile, request=request)
        add_ons = self._order_add_ons(
            add_on_ids=request.add_on_ids,
            available_add_ons=profile.add_ons,
        )
        return OrderResponse(
            order=await self.repository.create_order(
                user_id=user_id,
                profile=profile,
                add_ons=add_ons,
                fulfillment_mode=request.fulfillment_mode,
                delivery_address=request.delivery_address,
            )
        )

    async def claim_order(
        self,
        *,
        user_id: str,
        order_id: str,
    ) -> OrderResponse:
        try:
            order = await self.repository.claim_order(
                order_id=order_id,
                claimer_user_id=user_id,
            )
        except PermissionError as exc:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=str(exc),
            ) from exc
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=str(exc),
            ) from exc
        if order is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found",
            )
        return OrderResponse(order=order)

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

    async def create_review(
        self,
        *,
        user_id: str,
        request: ReviewCreate,
    ) -> ReviewResponse:
        review = await self.repository.create_review(rater_user_id=user_id, review=request)
        return ReviewResponse(review=review)

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
        reputation_score = DogSwipeService._reputation_score(profile)
        weighted_score = (
            (profile.crave_score * 0.50)
            + (distance_score * 0.25)
            + (spicy_score * 0.10)
            + (classic_score * 0.10)
            + (reputation_score * 0.05)
        )
        if menu_query is not None:
            weighted_score = (weighted_score * 0.82) + (
                DogSwipeService._menu_query_score(profile, menu_query) * 0.18
            )
        return min(max(weighted_score, 0.0), 1.0)

    @staticmethod
    def _is_spicy(profile: HotdogProfile) -> bool:
        return "spicy" in profile.tags

    @staticmethod
    def _is_classic(profile: HotdogProfile) -> bool:
        return "classic" in profile.tags

    @staticmethod
    def _reputation_score(profile: HotdogProfile) -> float:
        if profile.reputation_rating is None or profile.reputation_review_count == 0:
            return 0.7
        return max(0.0, min(profile.reputation_rating / 5.0, 1.0))

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
                " ".join(profile.tags),
                " ".join(add_on.name for add_on in profile.add_ons),
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
    def _ensure_available_now(profile: HotdogProfile, *, now: datetime) -> None:
        available_from = DogSwipeService._comparable_datetime(profile.available_from)
        available_until = DogSwipeService._comparable_datetime(profile.available_until)
        comparable_now = DogSwipeService._comparable_datetime(now)
        if available_from is not None and comparable_now < available_from:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Offering is not available yet",
            )
        if available_until is not None and comparable_now > available_until:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Offering is no longer available",
            )

    @staticmethod
    def _validate_fulfillment_request(
        *,
        profile: HotdogProfile,
        request: OrderCreateRequest,
    ) -> None:
        if request.fulfillment_mode == FulfillmentMode.pickup:
            return
        if profile.fulfillment_mode != FulfillmentMode.delivery:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Offering does not support delivery",
            )
        if request.delivery_latitude is None or request.delivery_longitude is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Delivery coordinates are required",
            )
        if (
            profile.latitude is not None
            and profile.longitude is not None
            and profile.delivery_radius_miles is not None
        ):
            distance_miles = DogSwipeService._haversine_miles(
                latitude=request.delivery_latitude,
                longitude=request.delivery_longitude,
                target_latitude=profile.latitude,
                target_longitude=profile.longitude,
            )
            if distance_miles > profile.delivery_radius_miles:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    detail="Delivery address is outside the offering radius",
                )

    @staticmethod
    def _comparable_datetime(value: datetime | None) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _order_add_ons(
        *,
        add_on_ids: list[str],
        available_add_ons: list[OrderAddOn],
    ) -> list[OrderAddOn]:
        seen: set[str] = set()
        add_ons: list[OrderAddOn] = []
        add_ons_by_id = {add_on.id: add_on for add_on in available_add_ons}
        for add_on_id in add_on_ids:
            normalized = add_on_id.strip()
            if not normalized or normalized not in add_ons_by_id:
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
            add_ons.append(add_ons_by_id[normalized])
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
