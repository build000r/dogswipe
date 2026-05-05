from __future__ import annotations

import pytest

from dogswipe_backend.repository import DogRepository
from dogswipe_backend.schemas import DogProfile, SwipeDecision, SwipeRequest
from dogswipe_backend.service import DogSwipeService


class FakeRepository(DogRepository):
    def __init__(self) -> None:
        self.limit_seen = 0
        self.swipes: list[tuple[str, str, SwipeDecision]] = []

    async def list_available_profiles(self, *, limit: int = 20) -> list[DogProfile]:
        self.limit_seen = limit
        return [
            DogProfile(
                id="dog-test",
                name="Test",
                breed="Mixed",
                age_years=1,
                temperament="Gentle",
                distance_miles=1,
                shelter_name="Test Shelter",
                compatibility_score=0.8,
                adoption_status="available",
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

    async def list_matches(self, *, user_id: str) -> list[DogProfile]:
        assert user_id
        return await self.list_available_profiles()


@pytest.mark.asyncio
async def test_discovery_clamps_limit() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.discovery(limit=1000)
    assert repository.limit_seen == 50
    assert response.profiles[0].id == "dog-test"


@pytest.mark.asyncio
async def test_swipe_returns_repository_match_signal() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.swipe(
        SwipeRequest(user_id="u1", profile_id="dog-test", decision=SwipeDecision.super_like)
    )
    assert response.matched is True
    assert repository.swipes == [("u1", "dog-test", SwipeDecision.super_like)]
