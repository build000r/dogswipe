from __future__ import annotations

import asyncio
from types import SimpleNamespace

import pytest
from sqlalchemy import func, select

from dogswipe_backend import service as service_module
from dogswipe_backend.app import create_app
from dogswipe_backend.models import (
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
)
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType
from dogswipe_backend.settings import get_settings


class FakeWebhook:
    event: dict[str, object] = {}

    @classmethod
    def construct_event(
        cls,
        payload: bytes,
        sig_header: str,
        secret: str,
    ) -> dict[str, object]:
        assert payload == b"{}"
        assert sig_header == "sig"
        assert secret == "whsec_ledger"
        return cls.event


class FakeStripe:
    api_key: str | None = None
    checkout = SimpleNamespace(Session=SimpleNamespace(create=lambda **_: None))
    Webhook = FakeWebhook


def _checkout_completed_event() -> dict[str, object]:
    return {
        "id": "evt_ledger_duplicate",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_ledger_duplicate",
                "metadata": {
                    "user_id": "ledger-webhook-user",
                    "credits": "10",
                    "amount_cents": "1000",
                },
            }
        },
    }


@pytest.mark.asyncio
async def test_duplicate_purchase_webhook_creates_single_ledger_entry(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    FakeWebhook.event = _checkout_completed_event()
    monkeypatch.setattr(service_module, "stripe", FakeStripe)
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_ledger")
    get_settings.cache_clear()

    first = await async_client.post(
        "/v1/credits/webhook",
        content=b"{}",
        headers={"Stripe-Signature": "sig"},
    )
    second = await async_client.post(
        "/v1/credits/webhook",
        content=b"{}",
        headers={"Stripe-Signature": "sig"},
    )

    assert first.status_code == 200
    assert first.json()["credited"] is True
    assert second.status_code == 200
    assert second.json() == {"received": True, "credited": False, "duplicate": True}

    async with database.session_factory() as session:
        entry_count = await session.scalar(
            select(func.count(CreditLedgerEntryRecord.id)).where(
                CreditLedgerEntryRecord.idempotency_key == "evt_ledger_duplicate"
            )
        )
        repository = SqlAlchemyHotdogRepository(session)
        assert entry_count == 1
        assert await repository.get_ledger_balance(user_id="ledger-webhook-user") == 10


@pytest.mark.asyncio
async def test_ledger_balance_after_chain_matches_cumulative_amounts(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        purchase = await repository.create_ledger_entry(
            user_id="chain-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
            idempotency_key="chain-purchase",
        )
        earn = await repository.create_ledger_entry(
            user_id="chain-user",
            entry_type=CreditLedgerEntryType.earn,
            amount=3,
            idempotency_key="chain-earn",
        )
        spend = await repository.create_ledger_entry(
            user_id="chain-user",
            entry_type=CreditLedgerEntryType.spend,
            amount=-4,
            idempotency_key="chain-spend",
        )
        refund = await repository.create_ledger_entry(
            user_id="chain-user",
            entry_type=CreditLedgerEntryType.refund_credit,
            amount=2,
            idempotency_key="chain-refund",
        )

        assert [purchase.balance_after, earn.balance_after, spend.balance_after, refund.balance_after] == [
            10,
            13,
            9,
            11,
        ]
        assert await repository.get_ledger_balance(user_id="chain-user") == 11


@pytest.mark.asyncio
async def test_concurrent_claims_cannot_double_spend_one_balance(async_client, database) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = "ledger-maker"
        await session.commit()

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id="single-balance-claimer",
            entry_type=CreditLedgerEntryType.purchase,
            amount=6,
            idempotency_key="single-balance-funding",
        )
        await session.commit()

    order_ids: list[str] = []
    for index in range(2):
        response = await async_client.post(
            "/v1/orders",
            headers={"X-DogSwipe-User-ID": "single-balance-claimer"},
            json={"profile_id": "hotdog-coney", "add_on_ids": []},
        )
        assert response.status_code == 201
        order_ids.append(response.json()["order"]["id"])

    responses = await asyncio.gather(
        *[
            async_client.post(
                f"/v1/orders/{order_id}/claim",
                headers={"X-DogSwipe-User-ID": "single-balance-claimer"},
            )
            for order_id in order_ids
        ]
    )

    statuses = sorted(response.status_code for response in responses)
    assert statuses == [200, 409]
    assert [response.json()["detail"] for response in responses if response.status_code == 409] == [
        "Insufficient credits"
    ]

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="single-balance-claimer") == 0
        spend_count = await session.scalar(
            select(func.count(CreditLedgerEntryRecord.id)).where(
                CreditLedgerEntryRecord.user_id == "single-balance-claimer",
                CreditLedgerEntryRecord.entry_type == CreditLedgerEntryType.spend.value,
            )
        )
        assert spend_count == 1


@pytest.mark.asyncio
async def test_credit_ledger_append_only_update_and_delete_raise(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        entry = await repository.create_ledger_entry(
            user_id="append-proof-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=4,
        )
        await session.commit()

        record = await session.get(CreditLedgerEntryRecord, entry.id)
        assert record is not None
        record.reason = "mutated"
        with pytest.raises(ValueError, match="append-only"):
            await session.flush()
        await session.rollback()

        record = await session.get(CreditLedgerEntryRecord, entry.id)
        assert record is not None
        await session.delete(record)
        with pytest.raises(ValueError, match="append-only"):
            await session.flush()


@pytest.mark.asyncio
async def test_no_cash_out_invariant_blocks_negative_purchase_and_withdrawal_types(
    database,
) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        with pytest.raises(ValueError, match="purchase ledger entries cannot be negative"):
            await repository.create_ledger_entry(
                user_id="cashout-user",
                entry_type=CreditLedgerEntryType.purchase,
                amount=-1,
            )

    assert "withdrawal" not in {entry_type.value for entry_type in CreditLedgerEntryType}
    assert "payout" not in {entry_type.value for entry_type in CreditLedgerEntryType}
    route_paths = {route.path for route in create_app().routes if hasattr(route, "path")}
    assert not [
        path
        for path in route_paths
        if any(term in path.lower() for term in ("withdraw", "payout", "cashout", "cash-out"))
    ]
