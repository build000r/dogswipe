from __future__ import annotations

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditAccount, CreditLedgerEntryType
from dogswipe_backend.service import DogSwipeService


@pytest.mark.asyncio
async def test_wallet_call_auto_provisions_account(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        service = DogSwipeService(repository)

        assert await repository.get_credit_account(user_id="wallet-user") is None

        response = await service.wallet(user_id="wallet-user")

        assert response.account.user_id == "wallet-user"
        assert await repository.get_credit_account(user_id="wallet-user") == response.account


@pytest.mark.asyncio
async def test_wallet_balance_starts_at_zero(database) -> None:
    async with database.session_factory() as session:
        service = DogSwipeService(SqlAlchemyHotdogRepository(session))

        response = await service.wallet(user_id="zero-balance-user")

        assert response.account.lifetime_purchased == 0
        assert response.account.lifetime_earned == 0
        assert response.account.lifetime_spent == 0
        assert response.account.balance == 0


@pytest.mark.parametrize("counter", ["lifetime_purchased", "lifetime_earned", "lifetime_spent"])
def test_credit_account_schema_rejects_negative_lifetime_counters(counter: str) -> None:
    now = datetime.now(UTC)
    payload = {
        "user_id": "invalid-wallet-user",
        "lifetime_purchased": 0,
        "lifetime_earned": 0,
        "lifetime_spent": 0,
        "created_at": now,
        "updated_at": now,
    }
    payload[counter] = -1

    with pytest.raises(ValidationError):
        CreditAccount(**payload)


@pytest.mark.asyncio
async def test_get_wallet_api_returns_account(async_client) -> None:
    response = await async_client.get(
        "/v1/wallet",
        headers={"X-DogSwipe-User-ID": "wallet-api-user"},
    )

    assert response.status_code == 200
    payload = response.json()["account"]
    assert payload["user_id"] == "wallet-api-user"
    assert payload["lifetime_purchased"] == 0
    assert payload["lifetime_earned"] == 0
    assert payload["lifetime_spent"] == 0
    assert payload["balance"] == 0


@pytest.mark.asyncio
async def test_credit_account_idempotent_provisioning(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        first = await repository.get_or_create_credit_account(user_id="idempotent-user")
        second = await repository.get_or_create_credit_account(user_id="idempotent-user")

        assert first.user_id == second.user_id
        assert first.created_at == second.created_at


@pytest.mark.asyncio
async def test_credit_account_separate_per_user(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        account_a = await repository.get_or_create_credit_account(user_id="user-a")
        account_b = await repository.get_or_create_credit_account(user_id="user-b")

        assert account_a.user_id == "user-a"
        assert account_b.user_id == "user-b"
        assert account_a.user_id != account_b.user_id


@pytest.mark.asyncio
async def test_wallet_api_returns_same_account_on_repeat(async_client) -> None:
    headers = {"X-DogSwipe-User-ID": "wallet-repeat-user"}

    first = await async_client.get("/v1/wallet", headers=headers)
    second = await async_client.get("/v1/wallet", headers=headers)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["account"]["created_at"] == second.json()["account"]["created_at"]


@pytest.mark.asyncio
async def test_wallet_api_exposes_only_authenticated_users_ledger_history(
    async_client, database,
) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        purchase = await repository.create_ledger_entry(
            user_id="history-api-owner",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
            purchase_ref="history-purchase",
            reason="credits purchased",
        )
        spend = await repository.create_ledger_entry(
            user_id="history-api-owner",
            entry_type=CreditLedgerEntryType.spend,
            amount=-3,
            order_ref="history-order",
            reason="order claimed",
        )
        private = await repository.create_ledger_entry(
            user_id="history-api-other",
            entry_type=CreditLedgerEntryType.purchase,
            amount=80,
        )
        await session.commit()

    for user_id, expected, balance in [
        ("history-api-owner", [purchase, spend], 7),
        ("history-api-other", [private], 80),
        ("history-api-empty", [], 0),
    ]:
        response = await async_client.get(
            "/v1/wallet", headers={"X-DogSwipe-User-ID": user_id},
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["account"]["user_id"] == user_id
        assert payload["account"]["balance"] == balance
        assert len(payload["entries"]) == len(expected)
        for actual, entry in zip(payload["entries"], expected, strict=True):
            # SQLite drops tzinfo on reload; compare the UTC instant separately.
            timestamp = datetime.fromisoformat(actual.pop("created_at")).replace(tzinfo=UTC)
            assert timestamp == entry.created_at
            assert actual == entry.model_dump(mode="json", exclude={"created_at"})
