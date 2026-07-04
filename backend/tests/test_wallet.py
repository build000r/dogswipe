from __future__ import annotations

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditAccount
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
