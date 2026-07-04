from __future__ import annotations

import pytest
from sqlalchemy import func, select

from dogswipe_backend.models import (
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
    OrderRecord,
)
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType


async def _set_vendor_owner(database, owner_user_id: str = "vendor-user") -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = owner_user_id
        await session.commit()


async def _fund_user(database, user_id: str, amount: int = 20) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id=user_id,
            entry_type=CreditLedgerEntryType.purchase,
            amount=amount,
            idempotency_key=f"fund:{user_id}:{amount}",
        )
        await session.commit()


async def _create_claimable_order(async_client, user_id: str = "claimer") -> str:
    response = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": user_id},
        json={
            "profile_id": "hotdog-coney",
            "add_on_ids": ["bacon", "extra-pickle"],
        },
    )
    assert response.status_code == 201
    return response.json()["order"]["id"]


@pytest.mark.asyncio
async def test_claim_order_debits_credits_and_marks_claimed(async_client, database) -> None:
    await _set_vendor_owner(database)
    await _fund_user(database, "claimer", amount=20)
    order_id = await _create_claimable_order(async_client, user_id="claimer")

    response = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "claimer"},
    )

    assert response.status_code == 200
    order = response.json()["order"]
    assert order["id"] == order_id
    assert order["status"] == "claimed"
    assert order["base_credit_cost"] == 6
    assert order["total_credits"] == 8
    assert [add_on["id"] for add_on in order["add_ons"]] == ["bacon", "extra-pickle"]

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="claimer") == 12
        account = await repository.get_credit_account(user_id="claimer")
        assert account is not None
        assert account.lifetime_spent == 8

        spend = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == f"claim:{order_id}"
            )
        )
        assert spend is not None
        assert spend.entry_type == "spend"
        assert spend.amount == -8
        assert spend.balance_after == 12
        assert spend.order_ref == order_id


@pytest.mark.asyncio
async def test_claim_order_rejects_insufficient_balance(async_client, database) -> None:
    await _set_vendor_owner(database)
    order_id = await _create_claimable_order(async_client, user_id="short-balance")

    response = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "short-balance"},
    )

    assert response.status_code == 409
    assert response.json()["detail"] == "Insufficient credits"

    async with database.session_factory() as session:
        record = await session.get(OrderRecord, order_id)
        assert record is not None
        assert record.status == "draft"


@pytest.mark.asyncio
async def test_claim_order_rejects_self_claim(async_client, database) -> None:
    await _set_vendor_owner(database, owner_user_id="vendor-user")
    await _fund_user(database, "vendor-user", amount=20)
    order_id = await _create_claimable_order(async_client, user_id="vendor-user")

    response = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "vendor-user"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Vendors cannot claim their own orders"


@pytest.mark.asyncio
async def test_claim_order_rejects_double_claim(async_client, database) -> None:
    await _set_vendor_owner(database)
    await _fund_user(database, "double-claimer", amount=20)
    order_id = await _create_claimable_order(async_client, user_id="double-claimer")

    first = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "double-claimer"},
    )
    second = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "double-claimer"},
    )

    assert first.status_code == 200
    assert second.status_code == 409
    assert second.json()["detail"] == "Order is not claimable"

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="double-claimer") == 12
        spend_count = await session.scalar(
            select(func.count(CreditLedgerEntryRecord.id)).where(
                CreditLedgerEntryRecord.order_ref == order_id,
                CreditLedgerEntryRecord.entry_type == CreditLedgerEntryType.spend.value,
            )
        )
        assert spend_count == 1
