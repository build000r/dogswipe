from __future__ import annotations

import pytest

from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import VendorSubmissionRequest


@pytest.mark.asyncio
async def test_repository_filters_available_profiles_by_coordinate_window(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        profiles = await repository.list_available_profiles(
            limit=20,
            max_distance_miles=1,
            latitude=43.6532,
            longitude=-79.3832,
        )

        assert [profile.id for profile in profiles] == [
            "hotdog-coney",
            "hotdog-kimchi",
            "hotdog-nightcap",
        ]
        assert all(profile.latitude is not None for profile in profiles)


@pytest.mark.asyncio
async def test_repository_approves_pending_vendor_submission_once(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-repository",
            submission=VendorSubmissionRequest(
                name="Repository Snap",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Repository Cart",
            ),
        )

        queued = await repository.list_pending_vendor_submissions()
        assert [submission.id for submission in queued] == [pending.id]

        approved = await repository.approve_vendor_submission(
            profile_id=pending.id,
            crave_score=0.91,
        )

        assert approved is not None
        assert approved.availability_status == "available"
        assert approved.crave_score == 0.91
        assert approved.review_note is None
        assert approved.last_verified_at is not None
        assert approved.last_reviewed_at is not None
        assert await repository.approve_vendor_submission(
            profile_id=pending.id,
            crave_score=0.2,
        ) is None


@pytest.mark.asyncio
async def test_repository_only_approves_vendor_pending_records(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        assert await repository.approve_vendor_submission(
            profile_id="hotdog-coney",
            crave_score=0.9,
        ) is None
        assert await repository.approve_vendor_submission(
            profile_id="missing-hotdog",
            crave_score=0.9,
        ) is None


@pytest.mark.asyncio
async def test_repository_requests_changes_and_accepts_owner_resubmission(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-revisions",
            submission=VendorSubmissionRequest(
                name="Needs Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Revision Cart",
            ),
        )

        changes = await repository.request_vendor_submission_changes(
            profile_id=pending.id,
            review_note="Add a menu URL.",
        )
        updated = await repository.update_vendor_submission(
            user_id="vendor-revisions",
            profile_id=pending.id,
            submission=VendorSubmissionRequest(
                name="Needs Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Revision Cart",
                menu_url="https://revision.example.com/menu",
            ),
        )

        assert changes is not None
        assert changes.availability_status == "changes_requested"
        assert changes.review_note == "Add a menu URL."
        assert changes.last_reviewed_at is not None
        assert updated is not None
        assert updated.availability_status == "pending_review"
        assert updated.review_note is None
        assert updated.last_reviewed_at is None
        assert updated.menu_url == "https://revision.example.com/menu"


@pytest.mark.asyncio
async def test_repository_rejects_pending_submission_as_terminal(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-rejection",
            submission=VendorSubmissionRequest(
                name="Bad Listing",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Reject Cart",
            ),
        )

        rejected = await repository.reject_vendor_submission(
            profile_id=pending.id,
            review_note="Not a hotdog listing.",
        )

        assert rejected is not None
        assert rejected.availability_status == "rejected"
        assert rejected.review_note == "Not a hotdog listing."
        assert rejected.last_reviewed_at is not None
        assert await repository.update_vendor_submission(
            user_id="vendor-rejection",
            profile_id=pending.id,
            submission=VendorSubmissionRequest(
                name="Bad Listing",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Reject Cart",
            ),
        ) is None
