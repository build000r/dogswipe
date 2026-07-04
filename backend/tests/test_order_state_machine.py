from __future__ import annotations

import pytest
from fastapi import HTTPException

from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import (
    ALLOWED_TRANSITIONS,
    OrderStatus,
    validate_order_status_transition,
)
from dogswipe_backend.service import DogSwipeService


def _legal_transition_pairs() -> list[tuple[OrderStatus, OrderStatus]]:
    return [
        (current, target)
        for current, allowed_targets in ALLOWED_TRANSITIONS.items()
        for target in allowed_targets
    ]


@pytest.mark.parametrize(("current", "target"), _legal_transition_pairs())
def test_order_status_transition_helper_accepts_legal_transitions(
    current: OrderStatus,
    target: OrderStatus,
) -> None:
    assert validate_order_status_transition(current, target) == target


@pytest.mark.parametrize(
    ("current", "target"),
    [
        (OrderStatus.draft, OrderStatus.completed),
        (OrderStatus.claimed, OrderStatus.reviewed),
        (OrderStatus.completed, OrderStatus.claimed),
        (OrderStatus.reviewed, OrderStatus.refunded_credit),
    ],
)
def test_order_status_transition_helper_rejects_illegal_transitions(
    current: OrderStatus,
    target: OrderStatus,
) -> None:
    with pytest.raises(ValueError):
        validate_order_status_transition(current, target)


@pytest.mark.asyncio
async def test_service_persists_legal_order_status_transition(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        service = DogSwipeService(repository)
        profile = (await repository.list_available_profiles(limit=1))[0]
        order = await repository.create_order(
            user_id="state-user",
            profile=profile,
            add_ons=[],
        )

        response = await service.transition_order_status(
            user_id="state-user",
            order_id=order.id,
            target_status=OrderStatus.claimed,
        )

        assert response.order.status == OrderStatus.claimed
        persisted = await repository.get_order(user_id="state-user", order_id=order.id)
        assert persisted is not None
        assert persisted.status == OrderStatus.claimed


@pytest.mark.asyncio
async def test_service_rejects_illegal_order_status_transition(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        service = DogSwipeService(repository)
        profile = (await repository.list_available_profiles(limit=1))[0]
        order = await repository.create_order(
            user_id="state-reject-user",
            profile=profile,
            add_ons=[],
        )
        await service.transition_order_status(
            user_id="state-reject-user",
            order_id=order.id,
            target_status=OrderStatus.claimed,
        )

        with pytest.raises(HTTPException) as exc_info:
            await service.transition_order_status(
                user_id="state-reject-user",
                order_id=order.id,
                target_status=OrderStatus.completed,
            )

        assert exc_info.value.status_code == 409
        persisted = await repository.get_order(user_id="state-reject-user", order_id=order.id)
        assert persisted is not None
        assert persisted.status == OrderStatus.claimed
