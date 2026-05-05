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
    assert [profile["id"] for profile in profiles] == ["hotdog-coney", "hotdog-kimchi"]
    assert profiles[0]["crave_score"] > profiles[1]["crave_score"]


@pytest.mark.asyncio
async def test_swipe_like_can_create_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-1"},
        json={"profile_id": "hotdog-coney", "decision": "like"},
    )
    assert response.status_code == 200
    assert response.json() == {
        "profile_id": "hotdog-coney",
        "decision": "like",
        "matched": True,
    }


@pytest.mark.asyncio
async def test_swipe_pass_does_not_create_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-2"},
        json={"profile_id": "hotdog-coney", "decision": "pass"},
    )
    assert response.status_code == 200
    assert response.json()["matched"] is False


@pytest.mark.asyncio
async def test_matches_only_returns_high_crave_likes(async_client) -> None:
    await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-3"},
        json={"profile_id": "hotdog-coney", "decision": "super_like"},
    )
    await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-3"},
        json={"profile_id": "hotdog-nightcap", "decision": "like"},
    )

    response = await async_client.get("/v1/matches", headers={"X-DogSwipe-User-ID": "user-3"})
    assert response.status_code == 200
    matches = response.json()["matches"]
    assert [match["id"] for match in matches] == ["hotdog-coney"]


@pytest.mark.asyncio
async def test_unknown_profile_swipe_is_not_match(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-4"},
        json={"profile_id": "missing", "decision": "like"},
    )
    assert response.status_code == 200
    assert response.json()["matched"] is False


@pytest.mark.asyncio
async def test_swipe_rejects_client_supplied_user_id(async_client) -> None:
    response = await async_client.post(
        "/v1/swipes",
        headers={"X-DogSwipe-User-ID": "user-5"},
        json={"user_id": "forged", "profile_id": "hotdog-coney", "decision": "like"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_local_matches_use_default_user_when_auth_disabled(async_client) -> None:
    await async_client.post(
        "/v1/swipes",
        json={"profile_id": "hotdog-coney", "decision": "like"},
    )
    response = await async_client.get("/v1/matches")
    assert response.status_code == 200
    assert [match["id"] for match in response.json()["matches"]] == ["hotdog-coney"]


@pytest.mark.asyncio
async def test_preferences_return_default_for_new_user(async_client) -> None:
    response = await async_client.get(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "new-user"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "max_distance_miles": 10,
        "spicy_friendly": True,
        "classic_only": False,
    }


@pytest.mark.asyncio
async def test_preferences_can_be_saved_for_authenticated_user(async_client) -> None:
    response = await async_client.put(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "preference-user"},
        json={
            "max_distance_miles": 6,
            "spicy_friendly": False,
            "classic_only": True,
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "max_distance_miles": 6,
        "spicy_friendly": False,
        "classic_only": True,
    }

    saved = await async_client.get(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "preference-user"},
    )
    assert saved.json() == response.json()


@pytest.mark.asyncio
async def test_preferences_are_user_scoped(async_client) -> None:
    await async_client.put(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "spicy-user"},
        json={
            "max_distance_miles": 4,
            "spicy_friendly": False,
            "classic_only": True,
        },
    )

    response = await async_client.get(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "classic-user"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "max_distance_miles": 10,
        "spicy_friendly": True,
        "classic_only": False,
    }


@pytest.mark.asyncio
async def test_preferences_reject_client_supplied_user_id(async_client) -> None:
    response = await async_client.put(
        "/v1/preferences",
        headers={"X-DogSwipe-User-ID": "honest-user"},
        json={
            "user_id": "forged",
            "max_distance_miles": 6,
            "spicy_friendly": False,
            "classic_only": True,
        },
    )

    assert response.status_code == 422
