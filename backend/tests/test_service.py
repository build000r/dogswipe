from __future__ import annotations

import pytest

from dogswipe_backend.repository import HotdogRepository
from dogswipe_backend.schemas import (
    CravingPreferences,
    HotdogProfile,
    SwipeDecision,
    SwipeRequest,
)
from dogswipe_backend.service import DogSwipeService


class FakeRepository(HotdogRepository):
    def __init__(self) -> None:
        self.limit_seen = 0
        self.swipes: list[tuple[str, str, SwipeDecision]] = []
        self.preferences_by_user: dict[str, CravingPreferences] = {}

    async def list_available_profiles(self, *, limit: int = 20) -> list[HotdogProfile]:
        self.limit_seen = limit
        return [
            HotdogProfile(
                id="hotdog-test",
                name="Test",
                style="Classic",
                price_dollars=1,
                signature_notes="Gentle",
                distance_miles=1,
                vendor_name="Test Cart",
                crave_score=0.8,
                availability_status="available",
            )
        ]

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


@pytest.mark.asyncio
async def test_discovery_clamps_limit() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.discovery(limit=1000)
    assert repository.limit_seen == 50
    assert response.profiles[0].id == "hotdog-test"


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
