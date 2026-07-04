from __future__ import annotations

import pytest

from dogswipe_backend.app import create_app
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType
from dogswipe_backend.settings import get_settings


def test_no_cash_out_routes_exist() -> None:
    app = create_app()
    route_paths = {
        route.path
        for route in app.routes
        if hasattr(route, "path")
    }

    forbidden_terms = ("payout", "withdraw", "cashout", "cash-out")
    assert not [
        path
        for path in route_paths
        if any(term in path.lower() for term in forbidden_terms)
    ]


@pytest.mark.asyncio
async def test_negative_purchase_entries_are_rejected(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        with pytest.raises(ValueError, match="purchase ledger entries cannot be negative"):
            await repository.create_ledger_entry(
                user_id="refund-attempt",
                entry_type=CreditLedgerEntryType.purchase,
                amount=-10,
            )


@pytest.mark.asyncio
async def test_credit_reconciliation_endpoint_is_admin_only(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()

    response = await async_client.get(
        "/v1/credits/reconciliation",
        headers={"X-DogSwipe-User-ID": "not-admin"},
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_credit_reconciliation_reports_platform_float_and_outstanding_credits(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id="buyer-one",
            entry_type=CreditLedgerEntryType.purchase,
            amount=25,
            idempotency_key="purchase-one",
        )
        await repository.create_ledger_entry(
            user_id="buyer-one",
            entry_type=CreditLedgerEntryType.spend,
            amount=-8,
            idempotency_key="spend-one",
        )
        await repository.create_ledger_entry(
            user_id="buyer-two",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
            idempotency_key="purchase-two",
        )
        await session.commit()

    monkeypatch.setenv("DOGSWIPE_ADMIN_USER_IDS", "admin-user")
    get_settings.cache_clear()

    response = await async_client.get(
        "/v1/credits/reconciliation",
        headers={"X-DogSwipe-User-ID": "admin-user"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "platform_float": 35,
        "outstanding_credits": 27,
        "float_covers_outstanding": True,
    }
