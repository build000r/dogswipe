from __future__ import annotations

import pytest
from sqlalchemy import select

from dogswipe_backend.models import (
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
)
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType
from dogswipe_backend.settings import get_settings


async def _configure_profile(database, *, maker_user_id: str = "dispute-maker") -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = maker_user_id
        await session.commit()


async def _fund_user(database, *, user_id: str, amount: int = 6) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id=user_id,
            entry_type=CreditLedgerEntryType.purchase,
            amount=amount,
            idempotency_key=f"dispute-fund:{user_id}:{amount}",
        )
        await session.commit()


async def _create_claimed_order(async_client, *, claimer_user_id: str) -> str:
    created = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": claimer_user_id},
        json={"profile_id": "hotdog-coney", "add_on_ids": []},
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
@pytest.mark.parametrize("ready_first", [False, True])
async def test_participants_can_dispute_from_claimed_or_ready(
    async_client,
    database,
    ready_first: bool,
) -> None:
    await _configure_profile(database, maker_user_id="dispute-maker")
    await _fund_user(database, user_id="dispute-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="dispute-claimer",
    )
    if ready_first:
        ready = await async_client.post(
            f"/v1/orders/{order_id}/confirm-ready",
            headers={"X-DogSwipe-User-ID": "dispute-maker"},
        )
        assert ready.status_code == 200
        assert ready.json()["order"]["status"] == "ready"

    actor = "dispute-maker" if ready_first else "dispute-claimer"
    disputed = await async_client.post(
        f"/v1/orders/{order_id}/dispute",
        headers={"X-DogSwipe-User-ID": actor},
        json={"reason": "No-show at the hand-off point."},
    )

    assert disputed.status_code == 200
    order = disputed.json()["order"]
    assert order["status"] == "disputed"
    assert order["disputed_by_user_id"] == actor
    assert order["disputed_at"] is not None
    assert order["dispute_reason"] == "No-show at the hand-off point."


@pytest.mark.asyncio
async def test_disputed_orders_are_listed_for_admin_review(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    await _configure_profile(database, maker_user_id="queue-maker")
    await _fund_user(database, user_id="queue-claimer", amount=6)
    order_id = await _create_claimed_order(async_client, claimer_user_id="queue-claimer")
    disputed = await async_client.post(
        f"/v1/orders/{order_id}/dispute",
        headers={"X-DogSwipe-User-ID": "queue-maker"},
        json={"reason": "Pickup window missed."},
    )
    assert disputed.status_code == 200

    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    queue = await async_client.get(
        "/v1/admin/orders/disputes",
        headers={"X-DogSwipe-User-ID": "admin-user"},
    )

    assert queue.status_code == 200
    assert [order["id"] for order in queue.json()["orders"]] == [order_id]


@pytest.mark.asyncio
async def test_admin_resolves_dispute_with_credit_refund_only(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    await _configure_profile(database, maker_user_id="refund-maker")
    await _fund_user(database, user_id="refund-claimer", amount=6)
    order_id = await _create_claimed_order(async_client, claimer_user_id="refund-claimer")

    disputed = await async_client.post(
        f"/v1/orders/{order_id}/dispute",
        headers={"X-DogSwipe-User-ID": "refund-claimer"},
        json={"reason": "Order could not be fulfilled."},
    )
    assert disputed.status_code == 200

    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    resolved = await async_client.post(
        f"/v1/admin/orders/{order_id}/resolve-dispute",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={"resolution": "refund_credit", "reason": "Refund credits after review."},
    )

    assert resolved.status_code == 200
    order = resolved.json()["order"]
    assert order["status"] == "refunded_credit"
    assert order["dispute_resolved_at"] is not None
    assert order["dispute_resolution_note"] == "Refund credits after review."

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="refund-claimer") == 6
        platform_float, outstanding_credits = await repository.get_credit_reconciliation_totals()
        assert platform_float == 6
        assert outstanding_credits == 6

        refund = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"refund:{order_id}"
            )
        )
        assert refund is not None
        assert refund.entry_type == "refund_credit"
        assert refund.amount == 6
        assert refund.order_ref == order_id


@pytest.mark.asyncio
async def test_non_participant_cannot_dispute_order(async_client, database) -> None:
    await _configure_profile(database, maker_user_id="participant-maker")
    await _fund_user(database, user_id="participant-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="participant-claimer",
    )

    response = await async_client.post(
        f"/v1/orders/{order_id}/dispute",
        headers={"X-DogSwipe-User-ID": "stranger"},
        json={},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Only order participants can dispute an order"
