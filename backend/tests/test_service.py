from __future__ import annotations

import pytest

from dogswipe_backend.repository import HotdogRepository
from dogswipe_backend.schemas import (
    AdminApprovalRequest,
    AdminModerationRequest,
    CravingPreferences,
    HotdogProfile,
    SwipeDecision,
    SwipeRequest,
    VendorSubmissionRequest,
)
from dogswipe_backend.service import DogSwipeService


class FakeRepository(HotdogRepository):
    def __init__(self) -> None:
        self.limit_seen = 0
        self.swipes: list[tuple[str, str, SwipeDecision]] = []
        self.preferences_by_user: dict[str, CravingPreferences] = {}
        self.submissions_by_user: dict[str, list[HotdogProfile]] = {}

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
            price_dollars=submission.price_dollars,
            signature_notes=submission.signature_notes,
            distance_miles=submission.distance_miles,
            vendor_name=submission.vendor_name,
            image_url=submission.image_url,
            menu_url=submission.menu_url,
            media_alt_text=submission.media_alt_text,
            crave_score=0.5,
            availability_status="pending_review",
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
                price_dollars=submission.price_dollars,
                signature_notes=submission.signature_notes,
                distance_miles=submission.distance_miles,
                vendor_name=submission.vendor_name,
                image_url=submission.image_url,
                menu_url=submission.menu_url,
                media_alt_text=submission.media_alt_text,
                crave_score=0.5,
                availability_status="pending_review",
            )
            self.submissions_by_user[user_id][index] = updated
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
                    price_dollars=profile.price_dollars,
                    signature_notes=profile.signature_notes,
                    distance_miles=profile.distance_miles,
                    vendor_name=profile.vendor_name,
                    image_url=profile.image_url,
                    menu_url=profile.menu_url,
                    media_alt_text=profile.media_alt_text,
                    crave_score=crave_score,
                    availability_status="available",
                    review_note=None,
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
                    price_dollars=profile.price_dollars,
                    signature_notes=profile.signature_notes,
                    distance_miles=profile.distance_miles,
                    vendor_name=profile.vendor_name,
                    image_url=profile.image_url,
                    menu_url=profile.menu_url,
                    media_alt_text=profile.media_alt_text,
                    crave_score=profile.crave_score,
                    availability_status=availability_status,
                    review_note=review_note,
                )
                self.submissions_by_user[user_id][index] = moderated
                return moderated
        return None


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


@pytest.mark.asyncio
async def test_vendor_submission_round_trips_through_repository() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    request = VendorSubmissionRequest(
        name="Submitted Snap",
        style="Classic cart dog",
        price_dollars=6,
        signature_notes="Mustard and onion",
        distance_miles=2,
        vendor_name="Submit Cart",
        menu_url="https://submit.example.com/menu",
    )

    response = await service.submit_vendor_profile(user_id="vendor-1", submission=request)
    submissions = await service.vendor_submissions(user_id="vendor-1")

    assert response.profile.name == "Submitted Snap"
    assert response.profile.availability_status == "pending_review"
    assert submissions.submissions == [response.profile]


@pytest.mark.asyncio
async def test_admin_approval_promotes_pending_submission() -> None:
    repository = FakeRepository()
    service = DogSwipeService(repository)
    response = await service.submit_vendor_profile(
        user_id="vendor-1",
        submission=VendorSubmissionRequest(
            name="Submitted Snap",
            style="Classic cart dog",
            price_dollars=6,
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
            price_dollars=6,
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
            price_dollars=6,
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
            price_dollars=6,
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
