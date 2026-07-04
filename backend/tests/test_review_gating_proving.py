from __future__ import annotations

import pytest
from sqlalchemy.exc import IntegrityError

from dogswipe_backend.models import HotdogProfileRecord, OrderRecord, ReviewRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import ReviewDirection


def _order_record(
    order_id: str,
    *,
    status: str = "completed",
    user_id: str = "review-claimer",
) -> OrderRecord:
    return OrderRecord(
        id=order_id,
        user_id=user_id,
        profile_id="hotdog-coney",
        hotdog_name="Coney Classic",
        vendor_name="Franklin Cart",
        base_credit_cost=6,
        add_ons_json="[]",
        total_credits=6,
        fulfillment_mode="pickup",
        status=status,
    )


@pytest.mark.asyncio
async def test_review_api_allows_completed_order_and_rejects_invalid_state(
    async_client,
    database,
) -> None:
    async with database.session_factory() as session:
        session.add(_order_record("review-completed", status="completed"))
        session.add(_order_record("review-claimed", status="claimed"))
        await session.commit()

    completed = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "completed-reviewer"},
        json={
            "order_id": "review-completed",
            "ratee_user_id": "completed-reviewee",
            "direction": "giver_reviews_receiver",
            "rating": 5,
            "text": "Confirmed hand-off, ready to review.",
        },
    )
    invalid_state = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "claimed-reviewer"},
        json={
            "order_id": "review-claimed",
            "ratee_user_id": "claimed-reviewee",
            "direction": "giver_reviews_receiver",
            "rating": 4,
        },
    )

    assert completed.status_code == 201
    assert completed.json()["review"]["order_id"] == "review-completed"
    assert invalid_state.status_code == 409
    assert (
        invalid_state.json()["detail"]
        == "Reviews are only allowed after order completion or delivery"
    )


@pytest.mark.asyncio
async def test_review_api_blocks_self_review(async_client, database) -> None:
    async with database.session_factory() as session:
        session.add(_order_record("review-self", status="completed"))
        await session.commit()

    response = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "same-review-user"},
        json={
            "order_id": "review-self",
            "ratee_user_id": "same-review-user",
            "direction": "receiver_reviews_giver",
            "rating": 5,
        },
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Users cannot review themselves"


@pytest.mark.asyncio
async def test_one_review_per_direction_per_order_is_enforced(
    async_client,
    database,
) -> None:
    async with database.session_factory() as session:
        session.add(_order_record("review-unique", status="completed"))
        await session.commit()

    first = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "unique-reviewer-1"},
        json={
            "order_id": "review-unique",
            "ratee_user_id": "unique-reviewee",
            "direction": "giver_reviews_receiver",
            "rating": 5,
        },
    )
    duplicate = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "unique-reviewer-2"},
        json={
            "order_id": "review-unique",
            "ratee_user_id": "unique-reviewee",
            "direction": "giver_reviews_receiver",
            "rating": 4,
        },
    )
    opposite_direction = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "unique-reviewer-3"},
        json={
            "order_id": "review-unique",
            "ratee_user_id": "unique-reviewee",
            "direction": "receiver_reviews_giver",
            "rating": 4,
        },
    )

    assert first.status_code == 201
    assert duplicate.status_code == 409
    assert duplicate.json()["detail"] == "Review already exists for this order direction"
    assert opposite_direction.status_code == 201

    async with database.session_factory() as session:
        session.add_all(
            [
                ReviewRecord(
                    order_id="db-unique-order",
                    rater_user_id="db-reviewer-1",
                    ratee_user_id="db-reviewee",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=5,
                ),
                ReviewRecord(
                    order_id="db-unique-order",
                    rater_user_id="db-reviewer-2",
                    ratee_user_id="db-reviewee",
                    direction=ReviewDirection.giver_reviews_receiver.value,
                    rating=4,
                ),
            ]
        )
        with pytest.raises(IntegrityError):
            await session.flush()


@pytest.mark.asyncio
async def test_reputation_aggregation_reflects_new_reviews_in_discovery(
    async_client,
    database,
) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = "rated-maker"
        session.add(_order_record("review-rep-1", status="completed"))
        session.add(_order_record("review-rep-2", status="completed"))
        await session.commit()

    first = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "rep-reviewer-1"},
        json={
            "order_id": "review-rep-1",
            "ratee_user_id": "rated-maker",
            "direction": "giver_reviews_receiver",
            "rating": 5,
        },
    )
    second = await async_client.post(
        "/v1/reviews",
        headers={"X-DogSwipe-User-ID": "rep-reviewer-2"},
        json={
            "order_id": "review-rep-2",
            "ratee_user_id": "rated-maker",
            "direction": "receiver_reviews_giver",
            "rating": 3,
        },
    )

    assert first.status_code == 201
    assert second.status_code == 201

    async with database.session_factory() as session:
        reputation = await SqlAlchemyHotdogRepository(session).get_user_reputation(
            user_id="rated-maker"
        )
        assert reputation.average_rating == 4
        assert reputation.review_count == 2

    discovery = await async_client.get("/v1/discovery", params={"limit": 10})
    assert discovery.status_code == 200
    coney = next(
        profile
        for profile in discovery.json()["profiles"]
        if profile["id"] == "hotdog-coney"
    )
    assert coney["reputation_rating"] == 4
    assert coney["reputation_review_count"] == 2
