from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from dogswipe_backend.models import SwipeEventRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import OrderAddOn, SwipeDecision, VendorSubmissionRequest


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
async def test_repository_records_swipes_only_for_swipeable_profiles(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-swipe",
            submission=VendorSubmissionRequest(
                name="Pending Swipe",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Swipe Cart",
            ),
        )

        assert await repository.record_swipe(
            user_id="swipe-owner",
            profile_id="hotdog-coney",
            decision=SwipeDecision.like,
        ) is True
        assert await repository.record_swipe(
            user_id="swipe-owner",
            profile_id="hotdog-kimchi",
            decision=SwipeDecision.reject,
        ) is False
        assert await repository.record_swipe(
            user_id="swipe-owner",
            profile_id=pending.id,
            decision=SwipeDecision.super_like,
        ) is False
        assert await repository.record_swipe(
            user_id="swipe-owner",
            profile_id="missing-hotdog",
            decision=SwipeDecision.like,
        ) is False

        events = list(
            await session.scalars(
                select(SwipeEventRecord)
                .where(SwipeEventRecord.user_id == "swipe-owner")
                .order_by(SwipeEventRecord.profile_id.asc())
            )
        )
        assert [(event.profile_id, event.decision) for event in events] == [
            ("hotdog-coney", "like"),
            ("hotdog-kimchi", "pass"),
        ]
        assert [profile.id for profile in await repository.list_matches(user_id="swipe-owner")] == [
            "hotdog-coney"
        ]


@pytest.mark.asyncio
async def test_repository_creates_user_scoped_order_snapshot(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        profile = await repository.get_orderable_profile(profile_id="hotdog-coney")
        assert profile is not None

        order = await repository.create_order(
            user_id="order-owner",
            profile=profile,
            add_ons=[
                OrderAddOn(id="bacon", name="Bacon", price_dollars=1),
                OrderAddOn(id="extra-pickle", name="Extra Pickle", price_dollars=0.5),
            ],
        )

        assert order.profile_id == "hotdog-coney"
        assert order.hotdog_name == profile.name
        assert order.vendor_name == profile.vendor_name
        assert order.base_price_dollars == profile.price_dollars
        assert order.total_dollars == profile.price_dollars + 1.5
        assert [add_on.id for add_on in order.add_ons] == ["bacon", "extra-pickle"]
        assert await repository.list_orders(user_id="other-user") == []
        assert [saved.id for saved in await repository.list_orders(user_id="order-owner")] == [
            order.id
        ]


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
async def test_repository_gets_vendor_submission_only_for_owner(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-owner",
            submission=VendorSubmissionRequest(
                name="Owned Submission",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Owner Cart",
            ),
        )

        owned = await repository.get_vendor_submission(
            user_id="vendor-owner",
            profile_id=pending.id,
        )

        assert owned is not None
        assert owned.id == pending.id
        assert owned.availability_status == "pending_review"
        assert await repository.get_vendor_submission(
            user_id="other-vendor",
            profile_id=pending.id,
        ) is None
        assert await repository.get_vendor_submission(
            user_id="vendor-owner",
            profile_id="missing-hotdog",
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
                address_text="100 Queen St W, Toronto, ON",
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
        assert updated.address_text == "100 Queen St W, Toronto, ON"
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


@pytest.mark.asyncio
async def test_repository_records_menu_ingestion_for_owner(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-menu-owner",
            submission=VendorSubmissionRequest(
                name="Menu Snap",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Menu Cart",
                menu_url="https://menu.example.com/current",
            ),
        )
        checked_at = datetime.now(UTC)

        updated = await repository.record_menu_ingestion(
            user_id="vendor-menu-owner",
            profile_id=pending.id,
            status="ok",
            excerpt="Menu Snap - mustard, relish, and onion.",
            checked_at=checked_at,
        )

        assert updated is not None
        assert updated.menu_status == "ok"
        assert updated.menu_excerpt == "Menu Snap - mustard, relish, and onion."
        assert updated.menu_checked_at == checked_at
        assert await repository.record_menu_ingestion(
            user_id="other-vendor",
            profile_id=pending.id,
            status="ok",
            excerpt=None,
            checked_at=checked_at,
        ) is None


@pytest.mark.asyncio
async def test_repository_lists_stale_menu_refresh_candidates(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        stale = await repository.submit_vendor_profile(
            user_id="vendor-stale-menu",
            submission=VendorSubmissionRequest(
                name="Stale Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Stale Cart",
                menu_url="https://stale.example.com/menu",
            ),
        )
        fresh = await repository.submit_vendor_profile(
            user_id="vendor-fresh-menu",
            submission=VendorSubmissionRequest(
                name="Fresh Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Fresh Cart",
                menu_url="https://fresh.example.com/menu",
            ),
        )
        rejected = await repository.submit_vendor_profile(
            user_id="vendor-rejected-menu",
            submission=VendorSubmissionRequest(
                name="Rejected Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Rejected Cart",
                menu_url="https://rejected.example.com/menu",
            ),
        )
        now = datetime.now(UTC)
        await repository.record_menu_ingestion(
            user_id="vendor-fresh-menu",
            profile_id=fresh.id,
            status="ok",
            excerpt="Fresh.",
            checked_at=now,
        )
        await repository.record_menu_ingestion(
            user_id="vendor-stale-menu",
            profile_id=stale.id,
            status="ok",
            excerpt="Old.",
            checked_at=now - timedelta(hours=48),
        )
        await repository.reject_vendor_submission(
            profile_id=rejected.id,
            review_note="Not a current hotdog listing.",
        )

        candidates = await repository.list_menu_refresh_candidates(
            limit=20,
            stale_before=now - timedelta(hours=24),
        )

        assert [candidate.id for candidate in candidates] == [stale.id]


@pytest.mark.asyncio
async def test_repository_records_admin_menu_ingestion(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        pending = await repository.submit_vendor_profile(
            user_id="vendor-admin-menu",
            submission=VendorSubmissionRequest(
                name="Admin Menu",
                style="Classic cart dog",
                price_dollars=6.25,
                signature_notes="Mustard, relish, and onion.",
                distance_miles=1.8,
                vendor_name="Admin Cart",
                menu_url="https://admin.example.com/menu",
            ),
        )
        checked_at = datetime.now(UTC)

        updated = await repository.record_admin_menu_ingestion(
            profile_id=pending.id,
            status="ok",
            excerpt="Admin refreshed menu.",
            checked_at=checked_at,
        )

        assert updated is not None
        assert updated.menu_status == "ok"
        assert updated.menu_excerpt == "Admin refreshed menu."
        assert updated.menu_checked_at == checked_at
        assert await repository.record_admin_menu_ingestion(
            profile_id="missing",
            status="ok",
            excerpt=None,
            checked_at=checked_at,
        ) is None
