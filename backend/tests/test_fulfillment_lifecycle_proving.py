from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from dogswipe_backend.models import (
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
)
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType
from dogswipe_backend.settings import get_settings


async def _configure_profile(
    database,
    *,
    maker_user_id: str,
    available_from: datetime | None = None,
    available_until: datetime | None = None,
    delivery: bool = False,
) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = maker_user_id
        profile.available_from = available_from
        profile.available_until = available_until
        if delivery:
            profile.fulfillment_mode = "delivery"
            profile.latitude = 43.6532
            profile.longitude = -79.3832
            profile.delivery_radius_miles = 1
            profile.delivery_address = "100 Queen St W"
        else:
            profile.fulfillment_mode = "pickup"
            profile.delivery_radius_miles = None
            profile.delivery_address = None
        await session.commit()


async def _fund_user(database, *, user_id: str, amount: int) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id=user_id,
            entry_type=CreditLedgerEntryType.purchase,
            amount=amount,
            idempotency_key=f"fulfillment-proof-fund:{user_id}:{amount}",
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
async def test_fulfillment_validates_pickup_window_and_delivery_radius(
    async_client,
    database,
) -> None:
    now = datetime.now(UTC)
    await _configure_profile(
        database,
        maker_user_id="validation-maker",
        available_from=now + timedelta(days=1),
        available_until=now + timedelta(days=2),
    )

    too_early = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": "validation-claimer"},
        json={"profile_id": "hotdog-coney", "add_on_ids": []},
    )

    assert too_early.status_code == 409
    assert too_early.json()["detail"] == "Offering is not available yet"

    await _configure_profile(
        database,
        maker_user_id="validation-maker",
        delivery=True,
    )
    outside_radius = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": "validation-claimer"},
        json={
            "profile_id": "hotdog-coney",
            "add_on_ids": [],
            "fulfillment_mode": "delivery",
            "delivery_latitude": 43.9,
            "delivery_longitude": -79.6,
            "delivery_address": "Outside radius",
        },
    )

    assert outside_radius.status_code == 422
    assert outside_radius.json()["detail"] == "Delivery address is outside the offering radius"


@pytest.mark.asyncio
async def test_pickup_lifecycle_debits_claim_settles_earn_and_completes_end_to_end(
    async_client,
    database,
) -> None:
    await _configure_profile(database, maker_user_id="lifecycle-maker")
    await _fund_user(database, user_id="lifecycle-claimer", amount=6)

    created = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": "lifecycle-claimer"},
        json={"profile_id": "hotdog-coney", "add_on_ids": []},
    )
    assert created.status_code == 201
    order_id = created.json()["order"]["id"]
    assert created.json()["order"]["status"] == "draft"
    assert created.json()["order"]["total_credits"] == 6

    claimed = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "lifecycle-claimer"},
    )
    assert claimed.status_code == 200
    assert claimed.json()["order"]["status"] == "claimed"

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="lifecycle-claimer") == 0
        spend = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"claim:{order_id}"
            )
        )
        assert spend is not None
        assert spend.entry_type == "spend"
        assert spend.amount == -6
        assert spend.balance_after == 0

    ready = await async_client.post(
        f"/v1/orders/{order_id}/confirm-ready",
        headers={"X-DogSwipe-User-ID": "lifecycle-maker"},
    )
    assert ready.status_code == 200
    assert ready.json()["order"]["status"] == "ready"
    assert ready.json()["order"]["maker_ready_confirmed_at"] is not None

    handed_off = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "lifecycle-claimer"},
    )
    assert handed_off.status_code == 200
    assert handed_off.json()["order"]["status"] == "handed_off"
    assert handed_off.json()["order"]["completed_at"] is None

    completed = await async_client.post(
        f"/v1/orders/{order_id}/confirm-hand-off",
        headers={"X-DogSwipe-User-ID": "lifecycle-maker"},
    )
    assert completed.status_code == 200
    order = completed.json()["order"]
    assert order["status"] == "completed"
    assert order["maker_handoff_confirmed_at"] is not None
    assert order["claimer_handoff_confirmed_at"] is not None
    assert order["completed_at"] is not None

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="lifecycle-claimer") == 0
        assert await repository.get_ledger_balance(user_id="lifecycle-maker") == 6
        earn = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"settle:{order_id}"
            )
        )
        assert earn is not None
        assert earn.entry_type == "earn"
        assert earn.amount == 6
        assert earn.balance_after == 6
        assert earn.order_ref == order_id
        platform_float, outstanding_credits = await repository.get_credit_reconciliation_totals()
        assert platform_float == 6
        assert outstanding_credits == 6


@pytest.mark.asyncio
async def test_dispute_lifecycle_refunds_credits_and_preserves_float(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    await _configure_profile(database, maker_user_id="refund-proof-maker")
    await _fund_user(database, user_id="refund-proof-claimer", amount=6)
    order_id = await _create_claimed_order(
        async_client,
        claimer_user_id="refund-proof-claimer",
    )

    disputed = await async_client.post(
        f"/v1/orders/{order_id}/dispute",
        headers={"X-DogSwipe-User-ID": "refund-proof-maker"},
        json={"reason": "Claimant and maker could not complete pickup."},
    )
    assert disputed.status_code == 200
    assert disputed.json()["order"]["status"] == "disputed"

    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()
    resolved = await async_client.post(
        f"/v1/admin/orders/{order_id}/resolve-dispute",
        headers={"X-DogSwipe-User-ID": "admin-user"},
        json={
            "resolution": "refund_credit",
            "reason": "Refund credits after fulfillment review.",
        },
    )

    assert resolved.status_code == 200
    order = resolved.json()["order"]
    assert order["status"] == "refunded_credit"
    assert order["dispute_resolved_at"] is not None
    assert order["dispute_resolution_note"] == "Refund credits after fulfillment review."

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="refund-proof-claimer") == 6
        assert await repository.get_ledger_balance(user_id="refund-proof-maker") == 0
        refund = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"refund:{order_id}"
            )
        )
        assert refund is not None
        assert refund.entry_type == "refund_credit"
        assert refund.amount == 6
        assert refund.balance_after == 6
        assert refund.order_ref == order_id
        platform_float, outstanding_credits = await repository.get_credit_reconciliation_totals()
        assert platform_float == 6
        assert outstanding_credits == 6
