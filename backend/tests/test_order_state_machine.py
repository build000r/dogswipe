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

# Independent business contract recovered from the unfinished state-machine
# work. Deriving these expectations from ALLOWED_TRANSITIONS hid graph drift.
EXPECTED_TRANSITIONS = {
    "draft": {"claimed", "canceled"},
    "claimed": {"ready", "canceled", "disputed"},
    "ready": {"handed_off", "delivered", "canceled", "disputed"},
    "handed_off": {"completed", "disputed"},
    "delivered": {"completed", "disputed"},
    "completed": {"reviewed"},
    "reviewed": set(),
    "canceled": set(),
    "disputed": {"refunded_credit", "completed"},
    "refunded_credit": set(),
}


def test_order_status_contract_covers_every_state() -> None:
    assert set(EXPECTED_TRANSITIONS) == {status.value for status in OrderStatus}
    assert set(ALLOWED_TRANSITIONS) == set(OrderStatus)


@pytest.mark.parametrize("current", EXPECTED_TRANSITIONS)
@pytest.mark.parametrize("target", EXPECTED_TRANSITIONS)
def test_order_status_transition_matches_independent_contract(
    current: str, target: str,
) -> None:
    if target in EXPECTED_TRANSITIONS[current]:
        assert validate_order_status_transition(current, target) == OrderStatus(target)
    else:
        # Includes every outgoing move from all three terminal states.
        with pytest.raises(ValueError):
            validate_order_status_transition(current, target)


@pytest.mark.parametrize(
    ("current", "target"),
    [("draft", "bogus"), ("bogus", "claimed"), ("bogus", "bogus")],
)
def test_order_status_transition_rejects_unknown_states(current: str, target: str) -> None:
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


@pytest.mark.asyncio
@pytest.mark.parametrize("case", ["wrong_user", "missing_order"])
async def test_service_refuses_unavailable_order_without_changing_owner_state(
    database, case: str,
) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        service = DogSwipeService(repository)
        profile = (await repository.list_available_profiles(limit=1))[0]
        order = await repository.create_order(
            user_id="state-owner",
            profile=profile,
            add_ons=[],
        )
        order_id = order.id

        with pytest.raises(HTTPException) as exc_info:
            await service.transition_order_status(
                user_id="state-stranger" if case == "wrong_user" else "state-owner",
                order_id=order_id if case == "wrong_user" else "nonexistent-order",
                target_status=OrderStatus.claimed,
            )

        assert exc_info.value.status_code == 404
        await session.flush()
        session.expire_all()
        persisted = await repository.get_order(user_id="state-owner", order_id=order_id)
        assert persisted is not None
        assert persisted.status == OrderStatus.draft
