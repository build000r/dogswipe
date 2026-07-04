from __future__ import annotations

import pytest
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from dogswipe_backend.models import HotdogProfileRecord, ReviewRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import ReviewCreate, ReviewDirection
from dogswipe_backend.service import DogSwipeService


@pytest.mark.asyncio
async def test_review_record_persists_both_directions_for_order(database) -> None:
    async with database.session_factory() as session:
        giver_review = ReviewRecord(
            order_id="order-1",
            rater_user_id="giver",
            ratee_user_id="receiver",
            direction=ReviewDirection.giver_reviews_receiver.value,
            rating=5,
            text="Great handoff.",
        )
        receiver_review = ReviewRecord(
            order_id="order-1",
            rater_user_id="receiver",
            ratee_user_id="giver",
            direction=ReviewDirection.receiver_reviews_giver.value,
            rating=4,
            text=None,
        )
        session.add_all([giver_review, receiver_review])

        await session.flush()

        assert giver_review.id != receiver_review.id
        assert giver_review.created_at is not None
        assert receiver_review.created_at is not None


@pytest.mark.asyncio
async def test_review_record_rejects_duplicate_order_direction(database) -> None:
    async with database.session_factory() as session:
        session.add_all(
            [
                ReviewRecord(
                    order_id="order-dup",
                    rater_user_id="giver",
                    ratee_user_id="receiver",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=5,
                ),
                ReviewRecord(
                    order_id="order-dup",
                    rater_user_id="giver-2",
                    ratee_user_id="receiver",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=4,
                ),
            ]
        )

        with pytest.raises(IntegrityError):
            await session.flush()


@pytest.mark.asyncio
async def test_review_service_stub_creates_review(database) -> None:
    async with database.session_factory() as session:
        service = DogSwipeService(SqlAlchemyHotdogRepository(session))

        response = await service.create_review(
            user_id="reviewer",
            request=ReviewCreate(
                order_id="order-service",
                ratee_user_id="reviewee",
                direction=ReviewDirection.giver_reviews_receiver,
                rating=5,
                text="Exactly as promised.",
            ),
        )

        assert response.review.order_id == "order-service"
        assert response.review.rater_user_id == "reviewer"
        assert response.review.ratee_user_id == "reviewee"
        assert response.review.direction == ReviewDirection.giver_reviews_receiver
        assert response.review.rating == 5


@pytest.mark.parametrize("rating", [0, 6])
def test_review_create_rejects_out_of_range_rating(rating: int) -> None:
    with pytest.raises(ValidationError):
        ReviewCreate(
            order_id="order-rating",
            ratee_user_id="reviewee",
            direction=ReviewDirection.giver_reviews_receiver,
            rating=rating,
        )


@pytest.mark.asyncio
async def test_repository_aggregates_user_reputation(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        session.add_all(
            [
                ReviewRecord(
                    order_id="order-rep-1",
                    rater_user_id="reviewer-1",
                    ratee_user_id="maker-rep",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=5,
                ),
                ReviewRecord(
                    order_id="order-rep-2",
                    rater_user_id="reviewer-2",
                    ratee_user_id="maker-rep",
                    direction=ReviewDirection.receiver_reviews_giver.value,
                    rating=3,
                ),
            ]
        )
        await session.flush()

        reputation = await repository.get_user_reputation(user_id="maker-rep")

        assert reputation.average_rating == 4
        assert reputation.review_count == 2


@pytest.mark.asyncio
async def test_discovery_profiles_include_maker_reputation(database) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = "maker-discovery"
        session.add_all(
            [
                ReviewRecord(
                    order_id="order-card-1",
                    rater_user_id="reviewer-1",
                    ratee_user_id="maker-discovery",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=5,
                ),
                ReviewRecord(
                    order_id="order-card-2",
                    rater_user_id="reviewer-2",
                    ratee_user_id="maker-discovery",
                    direction=ReviewDirection.receiver_reviews_giver.value,
                    rating=4,
                ),
            ]
        )
        await session.flush()

        profiles = await SqlAlchemyHotdogRepository(session).list_available_profiles(limit=10)
        coney = next(profile for profile in profiles if profile.id == "hotdog-coney")

        assert coney.reputation_rating == 4.5
        assert coney.reputation_review_count == 2
