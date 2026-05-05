from __future__ import annotations

import pytest

from dogswipe_backend import service as service_module
from dogswipe_backend.menu import MenuIngestionResult
from dogswipe_backend.settings import get_settings


class FakeHTTPMenuIngestor:
    def __init__(self) -> None:
        self.urls: list[str] = []

    async def ingest(self, url: str) -> MenuIngestionResult:
        self.urls.append(url)
        return MenuIngestionResult(status="ok", excerpt="Admin refreshed menu.")


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
async def test_discovery_uses_saved_distance_preference(async_client) -> None:
    headers = {"X-DogSwipe-User-ID": "distance-discovery-user"}
    await async_client.put(
        "/v1/preferences",
        headers=headers,
        json={
            "max_distance_miles": 2,
            "spicy_friendly": True,
            "classic_only": False,
        },
    )

    response = await async_client.get("/v1/discovery", headers=headers, params={"limit": 10})

    assert response.status_code == 200
    assert [profile["id"] for profile in response.json()["profiles"]] == ["hotdog-coney"]


@pytest.mark.asyncio
async def test_discovery_uses_saved_classic_preference(async_client) -> None:
    headers = {"X-DogSwipe-User-ID": "classic-discovery-user"}
    await async_client.put(
        "/v1/preferences",
        headers=headers,
        json={
            "max_distance_miles": 10,
            "spicy_friendly": True,
            "classic_only": True,
        },
    )

    response = await async_client.get("/v1/discovery", headers=headers, params={"limit": 10})

    assert response.status_code == 200
    assert [profile["id"] for profile in response.json()["profiles"]] == [
        "hotdog-coney",
        "hotdog-chicago",
    ]


@pytest.mark.asyncio
async def test_discovery_can_compute_distance_from_query_location(async_client) -> None:
    response = await async_client.get(
        "/v1/discovery",
        params={
            "limit": 1,
            "latitude": 43.6532,
            "longitude": -79.3832,
        },
    )

    assert response.status_code == 200
    profile = response.json()["profiles"][0]
    assert profile["id"] == "hotdog-coney"
    assert profile["latitude"] == 43.6539
    assert profile["longitude"] == -79.3843
    assert profile["distance_miles"] < 0.1


@pytest.mark.asyncio
async def test_discovery_rejects_partial_query_location(async_client) -> None:
    response = await async_client.get("/v1/discovery", params={"latitude": 43.6532})

    assert response.status_code == 422
    assert response.json()["detail"] == "latitude and longitude must be provided together"


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


@pytest.mark.asyncio
async def test_vendor_submission_is_pending_and_user_scoped(async_client) -> None:
    response = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-1"},
        json={
            "name": "Boardwalk Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Griddled bun, beef frank, mustard, relish, and onion.",
            "distance_miles": 1.8,
            "latitude": 43.6532,
            "longitude": -79.3832,
            "vendor_name": "Boardwalk Dogs",
            "address_text": "100 Queen St W, Toronto, ON",
            "image_url": "https://cdn.example.com/boardwalk.jpg",
            "menu_url": "https://boardwalk.example.com/menu",
            "media_alt_text": "Classic hotdog on a paper tray",
        },
    )

    assert response.status_code == 201
    profile = response.json()["profile"]
    assert profile["id"]
    assert profile["name"] == "Boardwalk Snap"
    assert profile["availability_status"] == "pending_review"
    assert profile["crave_score"] == 0.5
    assert profile["latitude"] == 43.6532
    assert profile["longitude"] == -79.3832
    assert profile["address_text"] == "100 Queen St W, Toronto, ON"
    assert profile["menu_url"] == "https://boardwalk.example.com/menu"
    assert profile["media_alt_text"] == "Classic hotdog on a paper tray"

    own_submissions = await async_client.get(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-1"},
    )
    assert [item["id"] for item in own_submissions.json()["submissions"]] == [profile["id"]]

    other_submissions = await async_client.get(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-2"},
    )
    assert other_submissions.json()["submissions"] == []


@pytest.mark.asyncio
async def test_vendor_submission_does_not_enter_discovery_until_available(async_client) -> None:
    await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-3"},
        json={
            "name": "Hidden Review Dog",
            "style": "Test dog",
            "price_dollars": 5,
            "signature_notes": "Pending item",
            "distance_miles": 1,
            "vendor_name": "Review Cart",
        },
    )

    response = await async_client.get("/v1/discovery", params={"limit": 50})

    assert response.status_code == 200
    assert "Hidden Review Dog" not in [profile["name"] for profile in response.json()["profiles"]]


@pytest.mark.asyncio
async def test_vendor_submission_rejects_client_supplied_user_id(async_client) -> None:
    response = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "honest-vendor"},
        json={
            "user_id": "forged",
            "name": "Forged Dog",
            "style": "Classic",
            "price_dollars": 5,
            "signature_notes": "Should fail",
            "distance_miles": 1,
            "vendor_name": "Forgery Cart",
        },
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_vendor_can_record_missing_menu_ingestion(async_client) -> None:
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-menu"},
        json={
            "name": "Menu Pending Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Menu Cart",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    response = await async_client.post(
        f"/v1/vendor/submissions/{profile_id}/ingest-menu",
        headers={"X-DogSwipe-User-ID": "vendor-menu"},
    )

    assert response.status_code == 200
    profile = response.json()["profile"]
    assert profile["menu_status"] == "missing_url"
    assert profile["menu_excerpt"] is None
    assert profile["menu_checked_at"] is not None

    other_vendor = await async_client.post(
        f"/v1/vendor/submissions/{profile_id}/ingest-menu",
        headers={"X-DogSwipe-User-ID": "other-vendor"},
    )
    assert other_vendor.status_code == 404


@pytest.mark.asyncio
async def test_admin_can_approve_vendor_submission(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-approval"},
        json={
            "name": "Approved Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Approval Cart",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    queue = await async_client.get(
        "/v1/admin/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "admin-user"},
    )

    assert queue.status_code == 200
    assert [item["id"] for item in queue.json()["submissions"]] == [profile_id]

    approved = await async_client.post(
        f"/v1/admin/vendor/submissions/{profile_id}/approve",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"crave_score": 0.86},
    )

    assert approved.status_code == 200
    profile = approved.json()["profile"]
    assert profile["availability_status"] == "available"
    assert profile["crave_score"] == 0.86
    assert profile["last_verified_at"] is not None

    discovery = await async_client.get("/v1/discovery", params={"limit": 50})
    assert "Approved Snap" in [item["name"] for item in discovery.json()["profiles"]]

    repeat_approval = await async_client.post(
        f"/v1/admin/vendor/submissions/{profile_id}/approve",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"crave_score": 0.9},
    )
    assert repeat_approval.status_code == 404


@pytest.mark.asyncio
async def test_admin_can_refresh_stale_vendor_menus(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    ingestor = FakeHTTPMenuIngestor()
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    monkeypatch.setattr(service_module, "HTTPMenuIngestor", lambda: ingestor)
    get_settings.cache_clear()
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-menu-refresh"},
        json={
            "name": "Refresh Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Refresh Cart",
            "menu_url": "https://refresh.example.com/menu",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    response = await async_client.post(
        "/v1/admin/vendor/menus/refresh",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"limit": 5, "max_age_hours": 0},
    )

    assert response.status_code == 200
    payload = response.json()
    assert ingestor.urls == ["https://refresh.example.com/menu"]
    assert payload["checked_count"] == 1
    assert payload["refreshed_count"] == 1
    assert payload["failed_count"] == 0
    assert [profile["id"] for profile in payload["profiles"]] == [profile_id]
    assert payload["profiles"][0]["menu_status"] == "ok"
    assert payload["profiles"][0]["menu_excerpt"] == "Admin refreshed menu."


@pytest.mark.asyncio
async def test_admin_can_request_changes_and_vendor_can_resubmit(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-edits"},
        json={
            "name": "Edit Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Edit Cart",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    changes = await async_client.post(
        f"/v1/admin/vendor/submissions/{profile_id}/request-changes",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"review_note": "Add a current menu URL before review."},
    )

    assert changes.status_code == 200
    profile = changes.json()["profile"]
    assert profile["availability_status"] == "changes_requested"
    assert profile["review_note"] == "Add a current menu URL before review."
    assert profile["last_reviewed_at"] is not None

    queue = await async_client.get(
        "/v1/admin/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "admin-user"},
    )
    assert [item["id"] for item in queue.json()["submissions"]] == []

    owned = await async_client.get(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-edits"},
    )
    assert owned.json()["submissions"][0]["review_note"] == (
        "Add a current menu URL before review."
    )

    updated = await async_client.put(
        f"/v1/vendor/submissions/{profile_id}",
        headers={"X-DogSwipe-User-ID": "vendor-edits"},
        json={
            "name": "Edited Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.5,
            "signature_notes": "Mustard, relish, onion, and celery salt.",
            "distance_miles": 1.9,
            "vendor_name": "Edit Cart",
            "menu_url": "https://edit.example.com/menu",
        },
    )

    assert updated.status_code == 200
    profile = updated.json()["profile"]
    assert profile["name"] == "Edited Snap"
    assert profile["availability_status"] == "pending_review"
    assert profile["review_note"] is None
    assert profile["last_reviewed_at"] is None
    assert profile["menu_url"] == "https://edit.example.com/menu"

    queue = await async_client.get(
        "/v1/admin/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "admin-user"},
    )
    assert [item["id"] for item in queue.json()["submissions"]] == [profile_id]


@pytest.mark.asyncio
async def test_admin_can_reject_vendor_submission(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-rejected"},
        json={
            "name": "Rejected Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Reject Cart",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    rejected = await async_client.post(
        f"/v1/admin/vendor/submissions/{profile_id}/reject",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"review_note": "Listing does not show a hotdog item."},
    )

    assert rejected.status_code == 200
    profile = rejected.json()["profile"]
    assert profile["availability_status"] == "rejected"
    assert profile["review_note"] == "Listing does not show a hotdog item."
    assert profile["last_reviewed_at"] is not None

    discovery = await async_client.get("/v1/discovery", params={"limit": 50})
    assert "Rejected Snap" not in [item["name"] for item in discovery.json()["profiles"]]

    update = await async_client.put(
        f"/v1/vendor/submissions/{profile_id}",
        headers={"X-DogSwipe-User-ID": "vendor-rejected"},
        json={
            "name": "Rejected Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Reject Cart",
        },
    )
    assert update.status_code == 404


@pytest.mark.asyncio
async def test_vendor_submission_update_is_owner_scoped(async_client) -> None:
    submitted = await async_client.post(
        "/v1/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-owner"},
        json={
            "name": "Owner Snap",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Owner Cart",
        },
    )
    profile_id = submitted.json()["profile"]["id"]

    response = await async_client.put(
        f"/v1/vendor/submissions/{profile_id}",
        headers={"X-DogSwipe-User-ID": "other-vendor"},
        json={
            "name": "Forged Edit",
            "style": "Classic cart dog",
            "price_dollars": 6.25,
            "signature_notes": "Mustard, relish, and onion.",
            "distance_miles": 1.8,
            "vendor_name": "Owner Cart",
        },
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_admin_moderation_requires_note(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()

    response = await async_client.post(
        "/v1/admin/vendor/submissions/missing/reject",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"review_note": "   "},
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_admin_routes_reject_non_admin(async_client, clear_settings) -> None:
    del clear_settings
    response = await async_client.get(
        "/v1/admin/vendor/submissions",
        headers={"X-DogSwipe-User-ID": "vendor-user"},
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_approve_missing_submission_returns_404(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()

    response = await async_client.post(
        "/v1/admin/vendor/submissions/missing/approve",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"crave_score": 0.75},
    )

    assert response.status_code == 404
