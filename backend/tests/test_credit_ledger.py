from __future__ import annotations

import pytest

from dogswipe_backend.models import CreditLedgerEntry as CreditLedgerEntryRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType


@pytest.mark.asyncio
async def test_credit_ledger_entry_creation(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        entry = await repository.create_ledger_entry(
            user_id="ledger-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
            purchase_ref="stripe-session-1",
            idempotency_key="purchase-1",
            reason="initial purchase",
        )

        assert entry.user_id == "ledger-user"
        assert entry.entry_type == CreditLedgerEntryType.purchase
        assert entry.amount == 10
        assert entry.balance_after == 10
        assert entry.purchase_ref == "stripe-session-1"
        assert entry.idempotency_key == "purchase-1"
        assert entry.reason == "initial purchase"


@pytest.mark.asyncio
async def test_credit_ledger_balance_after_tracks_user_sum(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)

        purchase = await repository.create_ledger_entry(
            user_id="balance-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=20,
        )
        spend = await repository.create_ledger_entry(
            user_id="balance-user",
            entry_type=CreditLedgerEntryType.spend,
            amount=-7,
        )

        assert purchase.balance_after == 20
        assert spend.balance_after == 13
        assert await repository.get_ledger_balance(user_id="balance-user") == 13
        assert await repository.get_ledger_balance(user_id="other-user") == 0


@pytest.mark.asyncio
async def test_credit_ledger_rejects_duplicate_idempotency_key(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id="idempotency-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
            idempotency_key="duplicate-key",
        )

        with pytest.raises(ValueError):
            await repository.create_ledger_entry(
                user_id="idempotency-user",
                entry_type=CreditLedgerEntryType.purchase,
                amount=10,
                idempotency_key="duplicate-key",
            )

        assert await repository.get_ledger_balance(user_id="idempotency-user") == 10


@pytest.mark.asyncio
async def test_credit_ledger_entries_are_append_only(database) -> None:
    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        entry = await repository.create_ledger_entry(
            user_id="append-only-user",
            entry_type=CreditLedgerEntryType.purchase,
            amount=10,
        )
        await session.commit()

        record = await session.get(CreditLedgerEntryRecord, entry.id)
        assert record is not None
        record.amount = 99
        with pytest.raises(ValueError):
            await session.flush()
        await session.rollback()

        record = await session.get(CreditLedgerEntryRecord, entry.id)
        assert record is not None
        await session.delete(record)
        with pytest.raises(ValueError):
            await session.flush()
