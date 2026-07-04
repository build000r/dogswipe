from __future__ import annotations

import pytest
from sqlalchemy import select

from dogswipe_backend.models import (
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
)
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType


async def _configure_profile(
    database,
    *,
    maker_user_id: str = "handoff-maker",
    delivery: bool = False,
) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = maker_user_id
        if delivery:
            profile.fulfillment_mode = "delivery"
            profile.delivery_radius_miles = 3
            profile.delivery_address = "100 Queen St W"
        await session.commit()


async def _fund_user(database, *, user_id: str, amount: int = 6) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id=user_id,
            entry_type=CreditLedgerEntryType.purchase,
            amount=amount,
            idempotency_key=f"handoff-fund:{user_id}:{amount}",
        )
        await session.commit()


async def _create_claimed_order(
    async_client,
    *,
    claimer_user_id: str,
    delivery: bool = False,
) -> str:
    payload: dict[str, object] = {"profile_id": "hotdog-coney", "add_on_ids": []}
    if delivery:
        payload.update(
            {
                "fulfillment_mode": "delivery",
                "delivery_latitude": 43.6539,
                "delivery_longitude": -79.3843,
                "delivery_address": "100 Queen St W",
            }
        )

    created = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": claimer_user_id},
        json=payload,
    )
    assert created.status_code == 201
    order_id = created.json()["order"]["id"]

    claimed = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": claimer_user_id},
    )
    assert claimed.status_code == 200
    assert claimed.json()["order"]["status"] == "claimed"
    return order_id


@pytest.mark.asyncio
async def test_full_pickup_lifecycle_settles_credits_to_maker(
    async_client,
    database,
) -> None:
    await _configure_profile(database, maker_user_id="handoff-maker")
    await _fund_user(database, user_id="handoff-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="handoff-claimer",
    )

    ready = await async_client.post(
        f"/v1/orders/{order_id}/confirm-ready",
        headers={"X-DogSwipe-User-ID": "handoff-maker"},
    )
    assert ready.status_code == 200
    assert ready.json()["order"]["status"] == "ready"
    assert ready.json()["order"]["maker_ready_confirmed_at"] is not None

    first_handoff = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "handoff-claimer"},
    )
    assert first_handoff.status_code == 200
    assert first_handoff.json()["order"]["status"] == "handed_off"
    assert first_handoff.json()["order"]["completed_at"] is None

    completed = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "handoff-maker"},
    )
    assert completed.status_code == 200
    order = completed.json()["order"]
    assert order["status"] == "completed"
    assert order["maker_handoff_confirmed_at"] is not None
    assert order["claimer_handoff_confirmed_at"] is not None
    assert order["completed_at"] is not None

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="handoff-claimer") == 0
        assert await repository.get_ledger_balance(user_id="handoff-maker") == 6
        maker_account = await repository.get_credit_account(user_id="handoff-maker")
        assert maker_account is not None
        assert maker_account.lifetime_earned == 6

        earn = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"settle:{order_id}"
            )
        )
        assert earn is not None
        assert earn.entry_type == "earn"
        assert earn.amount == 6
        assert earn.order_ref == order_id


@pytest.mark.asyncio
async def test_partial_handoff_confirmation_blocks_completion(
    async_client,
    database,
) -> None:
    await _configure_profile(database, maker_user_id="partial-maker")
    await _fund_user(database, user_id="partial-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="partial-claimer",
    )

    ready = await async_client.post(
        f"/v1/orders/{order_id}/confirm-ready",
        headers={"X-DogSwipe-User-ID": "partial-maker"},
    )
    assert ready.status_code == 200

    handoff = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "partial-maker"},
    )

    assert handoff.status_code == 200
    order = handoff.json()["order"]
    assert order["status"] == "handed_off"
    assert order["completed_at"] is None

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="partial-maker") == 0
        earn = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"settle:{order_id}"
            )
        )
        assert earn is None


@pytest.mark.asyncio
async def test_delivery_handoff_confirmation_transitions_to_delivered(
    async_client,
    database,
) -> None:
    await _configure_profile(database, maker_user_id="delivery-maker", delivery=True)
    await _fund_user(database, user_id="delivery-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="delivery-claimer",
        delivery=True,
    )
    ready = await async_client.post(
        f"/v1/orders/{order_id}/confirm-ready",
        headers={"X-DogSwipe-User-ID": "delivery-maker"},
    )
    assert ready.status_code == 200

    delivered = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "delivery-claimer"},
    )

    assert delivered.status_code == 200
    order = delivered.json()["order"]
    assert order["status"] == "delivered"
    assert order["claimer_handoff_confirmed_at"] is not None
    assert order["maker_handoff_confirmed_at"] is None
    assert order["completed_at"] is None
