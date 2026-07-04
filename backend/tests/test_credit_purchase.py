from __future__ import annotations

from types import SimpleNamespace

import pytest
from sqlalchemy import select

from dogswipe_backend import service as service_module
from dogswipe_backend.models import CreditLedgerEntry as CreditLedgerEntryRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.settings import get_settings


class FakeCheckoutSession:
    created: list[dict[str, object]] = []

    @classmethod
    def create(cls, **kwargs: object) -> dict[str, str]:
        cls.created.append(kwargs)
        return {
            "id": "cs_test_123",
            "url": "https://stripe.test/checkout/cs_test_123",
        }


class FakeWebhook:
    event: dict[str, object] = {}
    calls: list[tuple[bytes, str, str]] = []

    @classmethod
    def construct_event(
        cls,
        payload: bytes,
        sig_header: str,
        secret: str,
    ) -> dict[str, object]:
        cls.calls.append((payload, sig_header, secret))
        return cls.event


class FakeStripe:
    api_key: str | None = None
    checkout = SimpleNamespace(Session=FakeCheckoutSession)
    Webhook = FakeWebhook


def _configure_fake_stripe(monkeypatch: pytest.MonkeyPatch) -> None:
    FakeStripe.api_key = None
    FakeCheckoutSession.created = []
    FakeWebhook.calls = []
    FakeWebhook.event = {}
    monkeypatch.setattr(service_module, "stripe", FakeStripe)
    monkeypatch.setenv("STRIPE_SECRET_KEY", "sk_test_dogswipe")
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_dogswipe")
    get_settings.cache_clear()


def _checkout_completed_event(*, event_id: str = "evt_checkout_1") -> dict[str, object]:
    return {
        "id": event_id,
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": "cs_test_123",
                "metadata": {
                    "user_id": "stripe-buyer",
                    "credits": "10",
                    "amount_cents": "1000",
                },
            }
        },
    }


@pytest.mark.asyncio
async def test_credit_purchase_creates_stripe_checkout_session(
    async_client,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    _configure_fake_stripe(monkeypatch)

    response = await async_client.post(
        "/v1/credits/purchase",
        headers={"X-DogSwipe-User-ID": "stripe-buyer"},
        json={"amount_cents": 1000},
    )

    assert response.status_code == 200
    assert response.json() == {
        "checkout_session_id": "cs_test_123",
        "checkout_url": "https://stripe.test/checkout/cs_test_123",
        "amount_cents": 1000,
        "credits": 10,
    }
    assert FakeStripe.api_key == "sk_test_dogswipe"
    assert len(FakeCheckoutSession.created) == 1
    checkout_args = FakeCheckoutSession.created[0]
    assert checkout_args["mode"] == "payment"
    assert checkout_args["client_reference_id"] == "stripe-buyer"
    assert checkout_args["metadata"] == {
        "user_id": "stripe-buyer",
        "credits": "10",
        "amount_cents": "1000",
    }
    line_item = checkout_args["line_items"][0]  # type: ignore[index]
    assert line_item["price_data"]["unit_amount"] == 1000


@pytest.mark.asyncio
async def test_credit_webhook_writes_purchase_ledger_entry(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    _configure_fake_stripe(monkeypatch)
    FakeWebhook.event = _checkout_completed_event()

    response = await async_client.post(
        "/v1/credits/webhook",
        content=b'{"id":"evt_checkout_1"}',
        headers={"Stripe-Signature": "test-signature"},
    )

    assert response.status_code == 200
    assert response.json() == {"received": True, "credited": True, "duplicate": False}
    assert FakeWebhook.calls == [
        (b'{"id":"evt_checkout_1"}', "test-signature", "whsec_dogswipe")
    ]

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="stripe-buyer") == 10
        account = await repository.get_credit_account(user_id="stripe-buyer")
        assert account is not None
        assert account.lifetime_purchased == 10

        entry = await session.scalar(
            select(CreditLedgerEntryRecord).where(
                CreditLedgerEntryRecord.idempotency_key == "evt_checkout_1"
            )
        )
        assert entry is not None
        assert entry.entry_type == "purchase"
        assert entry.amount == 10
        assert entry.balance_after == 10
        assert entry.purchase_ref == "cs_test_123"


@pytest.mark.asyncio
async def test_credit_webhook_duplicate_event_is_idempotent_noop(
    async_client,
    database,
    clear_settings,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    _configure_fake_stripe(monkeypatch)
    FakeWebhook.event = _checkout_completed_event(event_id="evt_duplicate")

    first = await async_client.post(
        "/v1/credits/webhook",
        content=b"{}",
        headers={"Stripe-Signature": "test-signature"},
    )
    second = await async_client.post(
        "/v1/credits/webhook",
        content=b"{}",
        headers={"Stripe-Signature": "test-signature"},
    )

    assert first.status_code == 200
    assert first.json() == {"received": True, "credited": True, "duplicate": False}
    assert second.status_code == 200
    assert second.json() == {"received": True, "credited": False, "duplicate": True}

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="stripe-buyer") == 10
        account = await repository.get_credit_account(user_id="stripe-buyer")
        assert account is not None
        assert account.lifetime_purchased == 10
