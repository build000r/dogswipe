from __future__ import annotations

import pytest

from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import VendorSubmissionRequest


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
        assert approved.last_verified_at is not None
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
