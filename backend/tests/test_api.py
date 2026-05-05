from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_health_endpoint(async_client) -> None:
    response = await async_client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["service"] == "dogswipe-api"


@pytest.mark.asyncio
async def test_discovery_returns_ranked_profiles(async_client) -> None:
    response = await async_client.get("/v1/discovery", params={"limit": 2})
    assert response.status_code == 200
    profiles = response.json()["profiles"]
    assert [profile["id"] for profile in profiles] == ["dog-luna", "dog-miso"]
    assert profiles[0]["compatibility_score"] > profiles[1]["compatibility_score"]


@pytest.mark.asyncio
async def test_swipe_like_can_create_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        json={"user_id": "user-1", "profile_id": "dog-luna", "decision": "like"},
    )
    assert response.status_code == 200
    assert response.json() == {
        "profile_id": "dog-luna",
        "decision": "like",
        "matched": True,
    }


@pytest.mark.asyncio
async def test_swipe_pass_does_not_create_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        json={"user_id": "user-2", "profile_id": "dog-luna", "decision": "pass"},
    )
    assert response.status_code == 200
    assert response.json()["matched"] is False


@pytest.mark.asyncio
async def test_matches_only_returns_high_compatibility_likes(async_client) -> None:
    await async_client.post(
        "/v1/swipes",
        json={"user_id": "user-3", "profile_id": "dog-luna", "decision": "super_like"},
    )
    await async_client.post(
        "/v1/swipes",
        json={"user_id": "user-3", "profile_id": "dog-miso", "decision": "like"},
    )

    response = await async_client.get("/v1/matches", params={"user_id": "user-3"})
    assert response.status_code == 200
    matches = response.json()["matches"]
    assert [match["id"] for match in matches] == ["dog-luna"]


@pytest.mark.asyncio
async def test_unknown_profile_swipe_is_not_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        json={"user_id": "user-4", "profile_id": "missing", "decision": "like"},
    )
    assert response.status_code == 200
    assert response.json()["matched"] is False
