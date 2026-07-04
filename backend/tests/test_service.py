from __future__ import annotations

from datetime import datetime

import pytest
from fastapi import HTTPException

from dogswipe_backend.menu import MenuIngestionResult
from dogswipe_backend.repository import HotdogRepository
from dogswipe_backend.schemas import (
    AdminApprovalRequest,
    AdminMenuRefreshRequest,
    AdminModerationRequest,
    CravingPreferences,
    HotdogProfile,
    OrderAddOn,
    OrderCreateRequest,
    OrderItem,
    FulfillmentMode,
    SwipeDecision,
    SwipeRequest,
    VendorSubmissionRequest,
)
from dogswipe_backend.service import DogSwipeService


def _profile(
    profile_id: str,
    *,
    name: str = "Test",
    style: str = "Classic",
    category: str = "hotdog",
    signature_notes: str = "Gentle",
    distance_miles: float = 1,
    latitude: float | None = None,
    longitude: float | None = None,
    address_text: str | None = None,
    available_from: datetime | None = None,
    available_until: datetime | None = None,
    fulfillment_mode: FulfillmentMode = FulfillmentMode.pickup,
    delivery_radius_miles: float | None = None,
    delivery_address: str | None = None,
    menu_url: str | None = None,
    menu_excerpt: str | None = None,
    crave_score: float = 0.8,
    add_ons: list[OrderAddOn] | None = None,
    tags: list[str] | None = None,
    reputation_rating: float | None = None,
    reputation_review_count: int = 0,
) -> HotdogProfile:
    return HotdogProfile(
        id=profile_id,
        name=name,
        style=style,
        category=category,
        credit_cost=1,
        signature_notes=signature_notes,
        distance_miles=distance_miles,
        latitude=latitude,
        longitude=longitude,
        vendor_name="Test Cart",
        address_text=address_text,
        available_from=available_from,
        available_until=available_until,
        fulfillment_mode=fulfillment_mode,
        delivery_radius_miles=delivery_radius_miles,
        delivery_address=delivery_address,
        menu_url=menu_url,
        menu_excerpt=menu_excerpt,
        crave_score=crave_score,
        availability_status="available",
        tags=tags or ["classic"],
        reputation_rating=reputation_rating,
        reputation_review_count=reputation_review_count,
        add_ons=add_ons
        if add_ons is not None
        else [
            OrderAddOn(id="bacon", name="Bacon", credit_cost=1),
            OrderAddOn(id="extra-pickle", name="Extra Pickle", credit_cost=1),
        ],
    )


class FakeMenuIngestor:
    def __init__(self, result: MenuIngestionResult | list[MenuIngestionResult]) -> None:
        self.results = result if isinstance(result, list) else [result]
        self.urls: list[str] = []

    async def ingest(self, url: str) -> MenuIngestionResult:
        self.urls.append(url)
        if len(self.results) == 1:
            return self.results[0]
        return self.results.pop(0)


class FakeRepository(HotdogRepository):
    def __init__(self) -> None:
        self.limit_seen = 0
        self.max_distance_seen: float | None = None
        self.latitude_seen: float | None = None
        self.longitude_seen: float | None = None
        self.available_profiles = [_profile("hotdog-test")]
        self.swipes: list[tuple[str, str, SwipeDecision]] = []
        self.preferences_by_user: dict[str, CravingPreferences] = {}
        self.submissions_by_user: dict[str, list[HotdogProfile]] = {}
        self.menu_refresh_candidates: list[HotdogProfile] = []
        self.menu_refreshes: list[tuple[str, str, str | None]] = []
        self.orders_by_user: dict[str, list[OrderItem]] = {}

    async def list_available_profiles(
        self,
        *,
        limit: int = 20,
        max_distance_miles: float | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> list[HotdogProfile]:
        self.limit_seen = limit
        self.max_distance_seen = max_distance_miles
        self.latitude_seen = latitude
        self.longitude_seen = longitude
        profiles = self.available_profiles
        if max_distance_miles is not None:
            profiles = [
                profile
                for profile in profiles
                if profile.distance_miles <= max_distance_miles
            ]
        return profiles[:limit]

    async def record_swipe(
        self,
        *,
        user_id: str,
        profile_id: str,
        decision: SwipeDecision,
    ) -> bool:
        self.swipes.append((user_id, profile_id, decision))
        return decision == SwipeDecision.super_like

    async def list_matches(self, *, user_id: str) -> list[HotdogProfile]:
        assert user_id
        return await self.list_available_profiles()

    async def get_preferences(self, *, user_id: str) -> CravingPreferences:
        return self.preferences_by_user.get(user_id, CravingPreferences())

    async def upsert_preferences(
        self,
        *,
        user_id: str,
        preferences: CravingPreferences,
    ) -> CravingPreferences:
        self.preferences_by_user[user_id] = preferences
        return preferences

    async def get_orderable_profile(self, *, profile_id: str) -> HotdogProfile | None:
        for profile in self.available_profiles:
            if profile.id == profile_id and profile.availability_status in {"available", "limited"}:
                return profile
        return None

    async def create_order(
        self,
        *,
        user_id: str,
        profile: HotdogProfile,
        add_ons: list[OrderAddOn],
        fulfillment_mode: FulfillmentMode = FulfillmentMode.pickup,
        delivery_address: str | None = None,
    ) -> OrderItem:
        order = OrderItem(
            id=f"order-{len(self.orders_by_user.get(user_id, [])) + 1}",
            profile_id=profile.id,
            hotdog_name=profile.name,
            vendor_name=profile.vendor_name,
            base_credit_cost=profile.credit_cost,
            add_ons=add_ons,
            total_credits=profile.credit_cost + sum(add_on.credit_cost for add_on in add_ons),
            fulfillment_mode=fulfillment_mode,
            available_from=profile.available_from,
            available_until=profile.available_until,
            delivery_address=delivery_address,
            status="draft",
            created_at=datetime(2026, 5, 6),
        )
        self.orders_by_user.setdefault(user_id, []).append(order)
        return order

    async def list_orders(self, *, user_id: str) -> list[OrderItem]:
        return self.orders_by_user.get(user_id, [])

    async def submit_vendor_profile(
        self,
        *,
        user_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile:
        profile = HotdogProfile(
            id="submitted-hotdog",
            name=submission.name,
            style=submission.style,
            credit_cost=submission.credit_cost,
            signature_notes=submission.signature_notes,
            distance_miles=submission.distance_miles,
            latitude=submission.latitude,
            longitude=submission.longitude,
            vendor_name=submission.vendor_name,
            address_text=submission.address_text,
            available_from=submission.available_from,
            available_until=submission.available_until,
            fulfillment_mode=submission.fulfillment_mode,
            delivery_radius_miles=submission.delivery_radius_miles,
            delivery_address=submission.delivery_address,
            image_url=submission.image_url,
            menu_url=submission.menu_url,
            media_alt_text=submission.media_alt_text,
            crave_score=0.5,
            availability_status="pending_review",
            tags=submission.tags,
            add_ons=[
                OrderAddOn(
                    id=add_on.id or f"submitted-add-on-{index}",
                    name=add_on.name,
                    credit_cost=add_on.credit_cost,
                )
                for index, add_on in enumerate(submission.add_ons, start=1)
            ],
        )
        self.submissions_by_user.setdefault(user_id, []).append(profile)
        return profile

    async def list_vendor_submissions(self, *, user_id: str) -> list[HotdogProfile]:
        return self.submissions_by_user.get(user_id, [])

    async def update_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile | None:
        submissions = self.submissions_by_user.get(user_id, [])
        for index, profile in enumerate(submissions):
            if profile.id != profile_id or profile.availability_status not in {
                "pending_review",
                "changes_requested",
            }:
                continue
            updated = HotdogProfile(
                id=profile.id,
                name=submission.name,
                style=submission.style,
                credit_cost=submission.credit_cost,
                signature_notes=submission.signature_notes,
                distance_miles=submission.distance_miles,
                latitude=submission.latitude,
                longitude=submission.longitude,
                vendor_name=submission.vendor_name,
                address_text=submission.address_text,
                available_from=submission.available_from,
                available_until=submission.available_until,
                fulfillment_mode=submission.fulfillment_mode,
                delivery_radius_miles=submission.delivery_radius_miles,
                delivery_address=submission.delivery_address,
                image_url=submission.image_url,
                menu_url=submission.menu_url,
                media_alt_text=submission.media_alt_text,
                crave_score=0.5,
                availability_status="pending_review",
                tags=submission.tags,
                add_ons=[
                    OrderAddOn(
                        id=add_on.id or f"updated-add-on-{add_on_index}",
                        name=add_on.name,
                        credit_cost=add_on.credit_cost,
                    )
                    for add_on_index, add_on in enumerate(submission.add_ons, start=1)
                ],
            )
            self.submissions_by_user[user_id][index] = updated
            return updated
        return None

    async def get_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
    ) -> HotdogProfile | None:
        for profile in self.submissions_by_user.get(user_id, []):
            if profile.id == profile_id:
                return profile
        return None

    async def record_menu_ingestion(
        self,
        *,
        user_id: str,
        profile_id: str,
        status: str,
        excerpt: str | None,
        checked_at: datetime,
    ) -> HotdogProfile | None:
        submissions = self.submissions_by_user.get(user_id, [])
        for index, profile in enumerate(submissions):
            if profile.id != profile_id:
                continue
            updated = profile.model_copy(
                update={
                    "menu_status": status,
                    "menu_excerpt": excerpt,
                    "menu_checked_at": checked_at,
                }
            )
            self.submissions_by_user[user_id][index] = updated
            return updated
        return None

    async def list_menu_refresh_candidates(
        self,
        *,
        limit: int,
        stale_before: datetime,
    ) -> list[HotdogProfile]:
        del stale_before
        return self.menu_refresh_candidates[:limit]

    async def record_admin_menu_ingestion(
        self,
        *,
        profile_id: str,
        status: str,
        excerpt: str | None,
        checked_at: datetime,
    ) -> HotdogProfile | None:
        self.menu_refreshes.append((profile_id, status, excerpt))
        for index, profile in enumerate(self.menu_refresh_candidates):
            if profile.id != profile_id:
                continue
            updated = profile.model_copy(
                update={
                    "menu_status": status,
                    "menu_excerpt": excerpt,
                    "menu_checked_at": checked_at,
                }
            )
            self.menu_refresh_candidates[index] = updated
            return updated
        return None

    async def list_pending_vendor_submissions(self) -> list[HotdogProfile]:
        return [
            profile
            for submissions in self.submissions_by_user.values()
            for profile in submissions
            if profile.availability_status == "pending_review"
        ]

    async def approve_vendor_submission(
        self,
        *,
        profile_id: str,
        crave_score: float,
    ) -> HotdogProfile | None:
        for user_id, submissions in self.submissions_by_user.items():
            for index, profile in enumerate(submissions):
                if profile.id != profile_id or profile.availability_status != "pending_review":
                    continue
                approved = HotdogProfile(
                    id=profile.id,
                    name=profile.name,
                    style=profile.style,
                    credit_cost=profile.credit_cost,
                    signature_notes=profile.signature_notes,
                    distance_miles=profile.distance_miles,
                    latitude=profile.latitude,
                    longitude=profile.longitude,
                    vendor_name=profile.vendor_name,
                    address_text=profile.address_text,
                    available_from=profile.available_from,
                    available_until=profile.available_until,
                    fulfillment_mode=profile.fulfillment_mode,
                    delivery_radius_miles=profile.delivery_radius_miles,
                    delivery_address=profile.delivery_address,
                    image_url=profile.image_url,
                    menu_url=profile.menu_url,
                    media_alt_text=profile.media_alt_text,
                    crave_score=crave_score,
                    availability_status="available",
                    review_note=None,
                    tags=profile.tags,
                    add_ons=profile.add_ons,
                )
                self.submissions_by_user[user_id][index] = approved
                return approved
        return None

    async def request_vendor_submission_changes(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        return self._moderate_submission(
            profile_id=profile_id,
            availability_status="changes_requested",
            review_note=review_note,
        )

    async def reject_vendor_submission(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        return self._moderate_submission(
            profile_id=profile_id,
            availability_status="rejected",
            review_note=review_note,
        )

    def _moderate_submission(
        self,
        *,
        profile_id: str,
        availability_status: str,
        review_note: str,
    ) -> HotdogProfile | None:
        for user_id, submissions in self.submissions_by_user.items():
            for index, profile in enumerate(submissions):
                if profile.id != profile_id or profile.availability_status != "pending_review":
                    continue
                moderated = HotdogProfile(
                    id=profile.id,
                    name=profile.name,
                    style=profile.style,
                    credit_cost=profile.credit_cost,
                    signature_notes=profile.signature_notes,
                    distance_miles=profile.distance_miles,
                    latitude=profile.latitude,
                    longitude=profile.longitude,
                    vendor_name=profile.vendor_name,
                    address_text=profile.address_text,
                    available_from=profile.available_from,
                    available_until=profile.available_until,
                    fulfillment_mode=profile.fulfillment_mode,
                    delivery_radius_miles=profile.delivery_radius_miles,
                    delivery_address=profile.delivery_address,
                    image_url=profile.image_url,
                    menu_url=profile.menu_url,
                    media_alt_text=profile.media_alt_text,
                    crave_score=profile.crave_score,
                    availability_status=availability_status,
                    review_note=review_note,
                    tags=profile.tags,
                    add_ons=profile.add_ons,
                )
                self.submissions_by_user[user_id][index] = moderated
                return moderated
        return None


@pytest.mark.asyncio
async def test_discovery_clamps_limit() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.discovery(user_id="u1", limit=1000)
    assert repository.limit_seen == 50
    assert repository.max_distance_seen == 10
    assert repository.latitude_seen is None
    assert repository.longitude_seen is None
    assert response.profiles[0].id == "hotdog-test"
    assert response.profiles[0].walking_time_minutes == 20


@pytest.mark.asyncio
async def test_discovery_filters_by_saved_distance_preference() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile("near-classic", name="Near Classic", distance_miles=1.2, crave_score=0.8),
        _profile("far-classic", name="Far Classic", distance_miles=4.2, crave_score=0.99),
    ]
    repository.preferences_by_user["u1"] = CravingPreferences(max_distance_miles=2)
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10)

    assert [profile.id for profile in response.profiles] == ["near-classic"]


@pytest.mark.asyncio
async def test_discovery_filters_by_classic_preference() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile("classic", name="Coney Classic", distance_miles=1.2, crave_score=0.8),
        _profile(
            "modern",
            name="Kimchi Crunch",
            style="Korean street dog",
            signature_notes="Gochujang mayo and sesame crunch.",
            distance_miles=1.1,
            crave_score=0.99,
            tags=["spicy"],
        ),
    ]
    repository.preferences_by_user["u1"] = CravingPreferences(classic_only=True)
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10)

    assert [profile.id for profile in response.profiles] == ["classic"]


@pytest.mark.asyncio
async def test_discovery_preferences_use_category_aware_tags() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "classic-hotdog",
            name="Coney Classic",
            category="hotdog",
            tags=["classic"],
            distance_miles=1.2,
            crave_score=0.8,
        ),
        _profile(
            "classic-coffee",
            name="House Espresso",
            style="Coffee",
            category="coffee",
            tags=["classic"],
            signature_notes="Balanced roast with mustard-colored crema.",
            distance_miles=1.1,
            crave_score=0.9,
        ),
        _profile(
            "spicy-coffee",
            name="Chile Mocha",
            style="Coffee",
            category="coffee",
            tags=["spicy"],
            distance_miles=1.0,
            crave_score=0.99,
        ),
    ]
    repository.preferences_by_user["u1"] = CravingPreferences(
        classic_only=True,
        spicy_friendly=False,
    )
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10)

    assert [profile.id for profile in response.profiles] == [
        "classic-coffee",
        "classic-hotdog",
    ]


@pytest.mark.asyncio
async def test_discovery_uses_reputation_as_ranking_signal() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "low-reputation",
            distance_miles=1.2,
            crave_score=0.8,
            reputation_rating=2,
            reputation_review_count=4,
        ),
        _profile(
            "high-reputation",
            distance_miles=1.2,
            crave_score=0.8,
            reputation_rating=5,
            reputation_review_count=4,
        ),
    ]
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10)

    assert [profile.id for profile in response.profiles] == [
        "high-reputation",
        "low-reputation",
    ]


@pytest.mark.asyncio
async def test_reputation_ranking_does_not_override_proximity() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "near-low-reputation",
            distance_miles=1,
            crave_score=0.8,
            reputation_rating=1,
            reputation_review_count=10,
        ),
        _profile(
            "far-high-reputation",
            distance_miles=9,
            crave_score=0.8,
            reputation_rating=5,
            reputation_review_count=10,
        ),
    ]
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10)

    assert response.profiles[0].id == "near-low-reputation"


@pytest.mark.asyncio
async def test_create_order_uses_canonical_add_on_prices() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)

    response = await service.create_order(
        user_id="order-service-user",
        request=OrderCreateRequest(
            profile_id="hotdog-test",
            add_on_ids=["bacon", "extra-pickle"],
        ),
    )

    assert response.order.profile_id == "hotdog-test"
    assert response.order.add_ons == [
        OrderAddOn(id="bacon", name="Bacon", credit_cost=1),
        OrderAddOn(id="extra-pickle", name="Extra Pickle", credit_cost=1),
    ]
    assert response.order.total_credits == 3


@pytest.mark.asyncio
async def test_create_order_rejects_unknown_add_on() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)

    with pytest.raises(HTTPException) as exc_info:
        await service.create_order(
            user_id="order-service-user",
            request=OrderCreateRequest(profile_id="hotdog-test", add_on_ids=["gold-leaf"]),
        )

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_create_order_rejects_unavailable_window() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "future-hotdog",
            available_from=datetime(2099, 5, 7),
            available_until=datetime(2099, 5, 8),
        )
    ]
    service = DogSwipeService(repository)

    with pytest.raises(HTTPException) as exc_info:
        await service.create_order(
            user_id="order-service-user",
            request=OrderCreateRequest(profile_id="future-hotdog", add_on_ids=[]),
        )

    assert exc_info.value.status_code == 409


@pytest.mark.asyncio
async def test_create_order_rejects_delivery_outside_radius() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "delivery-hotdog",
            latitude=43.6532,
            longitude=-79.3832,
            fulfillment_mode=FulfillmentMode.delivery,
            delivery_radius_miles=1,
        )
    ]
    service = DogSwipeService(repository)

    with pytest.raises(HTTPException) as exc_info:
        await service.create_order(
            user_id="order-service-user",
            request=OrderCreateRequest(
                profile_id="delivery-hotdog",
                add_on_ids=[],
                fulfillment_mode=FulfillmentMode.delivery,
                delivery_latitude=43.9,
                delivery_longitude=-79.6,
                delivery_address="Far away",
            ),
        )

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_create_order_accepts_delivery_inside_radius() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "delivery-hotdog",
            latitude=43.6532,
            longitude=-79.3832,
            fulfillment_mode=FulfillmentMode.delivery,
            delivery_radius_miles=2,
        )
    ]
    service = DogSwipeService(repository)

    response = await service.create_order(
        user_id="order-service-user",
        request=OrderCreateRequest(
            profile_id="delivery-hotdog",
            add_on_ids=[],
            fulfillment_mode=FulfillmentMode.delivery,
            delivery_latitude=43.6539,
            delivery_longitude=-79.3843,
            delivery_address="100 Queen St W",
        ),
    )

    assert response.order.fulfillment_mode == FulfillmentMode.delivery
    assert response.order.delivery_address == "100 Queen St W"


@pytest.mark.asyncio
async def test_orders_lists_current_user_drafts() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    await service.create_order(
        user_id="order-service-user",
        request=OrderCreateRequest(profile_id="hotdog-test", add_on_ids=[]),
    )

    response = await service.orders(user_id="order-service-user")

    assert [order.profile_id for order in response.orders] == ["hotdog-test"]


@pytest.mark.asyncio
async def test_discovery_reranks_with_query_location_distance() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "near-classic",
            name="Near Classic",
            distance_miles=9,
            latitude=43.6539,
            longitude=-79.3843,
            crave_score=0.8,
        ),
        _profile(
            "far-classic",
            name="Far Classic",
            distance_miles=1,
            latitude=44,
            longitude=-80,
            crave_score=0.99,
        ),
    ]
    service = DogSwipeService(repository)

    response = await service.discovery(
        user_id="u1",
        limit=10,
        latitude=43.6532,
        longitude=-79.3832,
    )

    assert repository.limit_seen == 200
    assert repository.latitude_seen == 43.6532
    assert repository.longitude_seen == -79.3832
    assert [profile.id for profile in response.profiles] == ["near-classic"]
    assert response.profiles[0].distance_miles < 0.1


@pytest.mark.asyncio
async def test_discovery_filters_by_menu_query() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "classic",
            name="Boardwalk Snap",
            signature_notes="Mustard and onion.",
            menu_excerpt="Classic dog with relish and celery salt.",
            crave_score=0.95,
        ),
        _profile(
            "kimchi",
            name="Fermented Crunch",
            style="Korean street dog",
            signature_notes="Scallion and sesame.",
            menu_excerpt="Kimchi crunch with gochujang mayo.",
            crave_score=0.72,
        ),
    ]
    service = DogSwipeService(repository)

    response = await service.discovery(user_id="u1", limit=10, menu_query="kimchi gochujang")

    assert repository.limit_seen == 200
    assert [profile.id for profile in response.profiles] == ["kimchi"]


@pytest.mark.asyncio
async def test_matches_can_resolve_location_distance() -> None:
    repository = FakeRepository()
    repository.available_profiles = [
        _profile(
            "near-classic",
            name="Near Classic",
            distance_miles=9,
            latitude=43.6539,
            longitude=-79.3843,
            crave_score=0.8,
        )
    ]
    service = DogSwipeService(repository)

    response = await service.matches(
        user_id="u1",
        latitude=43.6532,
        longitude=-79.3832,
    )

    assert response.matches[0].id == "near-classic"
    assert response.matches[0].distance_miles < 0.1
    assert response.matches[0].walking_time_minutes == 1


@pytest.mark.asyncio
async def test_swipe_returns_repository_match_signal() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.swipe(
        user_id="u1",
        request=SwipeRequest(profile_id="hotdog-test", decision=SwipeDecision.super_like),
    )
    assert response.matched is True
    assert repository.swipes == [("u1", "hotdog-test", SwipeDecision.super_like)]


@pytest.mark.asyncio
async def test_preferences_round_trip_through_repository() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    preferences = CravingPreferences(
        max_distance_miles=5,
        spicy_friendly=False,
        classic_only=True,
    )

    updated = await service.update_preferences(user_id="u1", preferences=preferences)

    assert updated == preferences
    assert await service.preferences(user_id="u1") == preferences


@pytest.mark.asyncio
async def test_vendor_submission_round_trips_through_repository() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    request = VendorSubmissionRequest(
        name="Submitted Snap",
        style="Classic cart dog",
        credit_cost=6,
        signature_notes="Mustard and onion",
        distance_miles=2,
        vendor_name="Submit Cart",
        address_text="100 Queen St W, Toronto, ON",
        menu_url="https://submit.example.com/menu",
    )

    response = await service.submit_vendor_profile(user_id="vendor-1", submission=request)
    submissions = await service.vendor_submissions(user_id="vendor-1")

    assert response.profile.name == "Submitted Snap"
    assert response.profile.availability_status == "pending_review"
    assert response.profile.address_text == "100 Queen St W, Toronto, ON"
    assert submissions.submissions == [response.profile]


@pytest.mark.asyncio
async def test_vendor_can_ingest_menu_snapshot() -> None:
    repository = FakeRepository()
    ingestor = FakeMenuIngestor(
        MenuIngestionResult(
            status="ok",
            excerpt="Boardwalk Snap - classic dog, relish, onion, and celery salt.",
        )
    )
    service = DogSwipeService(repository, menu_ingestor=ingestor)
    submitted = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="Boardwalk Snap",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
            menu_url="https://submit.example.com/menu",
        ),
    )

    response = await service.ingest_vendor_submission_menu(
        user_id="vendor-1",
        profile_id=submitted.profile.id,
    )

    assert ingestor.urls == ["https://submit.example.com/menu"]
    assert response.profile.menu_status == "ok"
    assert response.profile.menu_excerpt == (
        "Boardwalk Snap - classic dog, relish, onion, and celery salt."
    )
    assert response.profile.menu_checked_at is not None


@pytest.mark.asyncio
async def test_menu_ingestion_records_missing_menu_url_without_fetch() -> None:
    repository = FakeRepository()
    ingestor = FakeMenuIngestor(MenuIngestionResult(status="ok", excerpt="unused"))
    service = DogSwipeService(repository, menu_ingestor=ingestor)
    submitted = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="No Menu Snap",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
        ),
    )

    response = await service.ingest_vendor_submission_menu(
        user_id="vendor-1",
        profile_id=submitted.profile.id,
    )

    assert ingestor.urls == []
    assert response.profile.menu_status == "missing_url"
    assert response.profile.menu_excerpt is None
    assert response.profile.menu_checked_at is not None


@pytest.mark.asyncio
async def test_admin_refreshes_stale_menu_snapshots() -> None:
    repository = FakeRepository()
    repository.menu_refresh_candidates = [
        _profile(
            "stale-menu",
            name="Stale Menu",
            menu_url="https://stale.example.com/menu",
        ),
        _profile(
            "broken-menu",
            name="Broken Menu",
            menu_url="https://broken.example.com/menu",
        ),
    ]
    ingestor = FakeMenuIngestor(
        [
            MenuIngestionResult(status="ok", excerpt="Fresh menu text."),
            MenuIngestionResult(status="fetch_failed"),
        ]
    )
    service = DogSwipeService(repository, menu_ingestor=ingestor)

    response = await service.refresh_stale_menus(
        request=AdminMenuRefreshRequest(limit=2, max_age_hours=12)
    )

    assert ingestor.urls == [
        "https://stale.example.com/menu",
        "https://broken.example.com/menu",
    ]
    assert repository.menu_refreshes == [
        ("stale-menu", "ok", "Fresh menu text."),
        ("broken-menu", "fetch_failed", None),
    ]
    assert response.checked_count == 2
    assert response.refreshed_count == 1
    assert response.failed_count == 1
    assert [profile.menu_status for profile in response.profiles] == ["ok", "fetch_failed"]


@pytest.mark.asyncio
async def test_admin_approval_promotes_pending_submission() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="Submitted Snap",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
        ),
    )

    queue = await service.admin_review_queue()
    approved = await service.approve_vendor_submission(
        profile_id=response.profile.id,
        request=AdminApprovalRequest(crave_score=0.88),
    )

    assert queue.submissions == [response.profile]
    assert approved.profile.availability_status == "available"
    assert approved.profile.crave_score == 0.88


@pytest.mark.asyncio
async def test_admin_can_request_changes_and_vendor_can_resubmit() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="Needs Work",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
        ),
    )

    changes = await service.request_vendor_submission_changes(
        profile_id=response.profile.id,
        request=AdminModerationRequest(review_note="Add a current menu URL."),
    )
    updated = await service.update_vendor_submission(
        user_id="vendor-1",
        profile_id=response.profile.id,
        submission=VendorSubmissionRequest(
            name="Needs Work",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
            menu_url="https://submit.example.com/menu",
        ),
    )

    assert changes.profile.availability_status == "changes_requested"
    assert changes.profile.review_note == "Add a current menu URL."
    assert updated.profile.availability_status == "pending_review"
    assert updated.profile.review_note is None
    assert updated.profile.menu_url == "https://submit.example.com/menu"


@pytest.mark.asyncio
async def test_admin_can_reject_pending_submission() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="Bad Snap",
            style="Classic cart dog",
            credit_cost=6,
            signature_notes="Mustard and onion",
            distance_miles=2,
            vendor_name="Submit Cart",
        ),
    )

    rejected = await service.reject_vendor_submission(
        profile_id=response.profile.id,
        request=AdminModerationRequest(review_note="Photo is not a hotdog."),
    )

    assert rejected.profile.availability_status == "rejected"
    assert rejected.profile.review_note == "Photo is not a hotdog."
