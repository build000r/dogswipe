from __future__ import annotations

from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect, text

from dogswipe_backend.models import HotdogProfileRecord, OfferingAddOnRecord
from dogswipe_backend.repository import SqlAlchemyHotdogRepository
from dogswipe_backend.schemas import CreditLedgerEntryType
from dogswipe_backend.settings import get_settings


def _alembic_config() -> Config:
    backend_root = Path(__file__).resolve().parents[1]
    config = Config(str(backend_root / "alembic.ini"))
    config.set_main_option("script_location", str(backend_root / "migrations"))
    return config


async def _add_profile(
    database,
    *,
    profile_id: str,
    name: str,
    category: str,
    tags_json: str = "[]",
    crave_score: float = 0.93,
) -> None:
    async with database.session_factory() as session:
        session.add(
            HotdogProfileRecord(
                id=profile_id,
                name=name,
                style="Generalized offering",
                category=category,
                tags_json=tags_json,
                credit_cost=5,
                signature_notes="A category-neutral listing.",
                distance_miles=1.5,
                vendor_name="Generalized Vendor",
                crave_score=crave_score,
                availability_status="available",
            )
        )
        await session.commit()


@pytest.mark.asyncio
async def test_discovery_filters_by_category(async_client, database) -> None:
    await _add_profile(
        database,
        profile_id="coffee-cortado",
        name="Morning Cortado",
        category="coffee",
    )

    response = await async_client.get(
        "/v1/discovery",
        params={"limit": 10, "category": "Coffee"},
    )

    assert response.status_code == 200
    profiles = response.json()["profiles"]
    assert [profile["id"] for profile in profiles] == ["coffee-cortado"]
    assert all(profile["category"] == "coffee" for profile in profiles)


@pytest.mark.asyncio
async def test_discovery_returns_mixed_categories_without_filter(async_client, database) -> None:
    await _add_profile(
        database,
        profile_id="coffee-flat-white",
        name="Flat White",
        category="coffee",
    )

    response = await async_client.get("/v1/discovery", params={"limit": 10})

    assert response.status_code == 200
    categories = {profile["category"] for profile in response.json()["profiles"]}
    assert {"hotdog", "coffee"}.issubset(categories)


@pytest.mark.asyncio
async def test_discovery_uses_credit_cost_without_dollar_price(async_client) -> None:
    response = await async_client.get("/v1/discovery", params={"limit": 1})

    assert response.status_code == 200
    profile = response.json()["profiles"][0]
    assert profile["credit_cost"] == 6
    assert "price_dollars" not in profile


@pytest.mark.asyncio
async def test_claim_uses_snapshot_of_maker_add_ons(async_client, database) -> None:
    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        assert profile is not None
        profile.vendor_owner_user_id = "catalog-maker"
        await session.commit()

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        await repository.create_ledger_entry(
            user_id="catalog-claimer",
            entry_type=CreditLedgerEntryType.purchase,
            amount=20,
            idempotency_key="catalog-claimer-funding",
        )
        await session.commit()

    created = await async_client.post(
        "/v1/orders",
        headers={"X-DogSwipe-User-ID": "catalog-claimer"},
        json={"profile_id": "hotdog-coney", "add_on_ids": ["bacon"]},
    )
    assert created.status_code == 201
    order_id = created.json()["order"]["id"]

    async with database.session_factory() as session:
        profile = await session.get(HotdogProfileRecord, "hotdog-coney")
        bacon = await session.get(OfferingAddOnRecord, "bacon")
        assert profile is not None
        assert bacon is not None
        profile.credit_cost = 20
        bacon.credit_cost = 5
        await session.commit()

    claimed = await async_client.post(
        f"/v1/orders/{order_id}/claim",
        headers={"X-DogSwipe-User-ID": "catalog-claimer"},
    )

    assert claimed.status_code == 200
    order = claimed.json()["order"]
    assert order["base_credit_cost"] == 6
    assert order["total_credits"] == 7
    assert order["add_ons"] == [{"id": "bacon", "name": "Bacon", "credit_cost": 1}]

    async with database.session_factory() as session:
        repository = SqlAlchemyHotdogRepository(session)
        assert await repository.get_ledger_balance(user_id="catalog-claimer") == 13


@pytest.mark.asyncio
async def test_discovery_search_matches_category_aware_tags(async_client, database) -> None:
    await _add_profile(
        database,
        profile_id="tea-umami",
        name="Quiet Cup",
        category="tea",
        tags_json='["umami"]',
    )

    response = await async_client.get(
        "/v1/discovery",
        params={"limit": 10, "menu_query": "umami"},
    )

    assert response.status_code == 200
    assert [profile["id"] for profile in response.json()["profiles"]] == ["tea-umami"]


def test_catalog_migrations_backfill_category_and_credit_cost(
    clear_settings,
    tmp_path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    del clear_settings
    database_path = tmp_path / "dogswipe.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite+aiosqlite:///{database_path}")
    get_settings.cache_clear()

    config = _alembic_config()
    command.upgrade(config, "0010")

    engine = create_engine(f"sqlite:///{database_path}")
    try:
        with engine.begin() as connection:
            connection.execute(
                text(
                    """
                    INSERT INTO hotdog_profiles (
                        id,
                        name,
                        style,
                        price_dollars,
                        signature_notes,
                        distance_miles,
                        vendor_name,
                        crave_score,
                        availability_status
                    ) VALUES (
                        'legacy-hotdog',
                        'Legacy Hotdog',
                        'Classic',
                        6.0,
                        'Legacy listing',
                        1.0,
                        'Legacy Cart',
                        0.8,
                        'available'
                    )
                    """
                )
            )

        command.upgrade(config, "0011")
        with engine.connect() as connection:
            category = connection.execute(
                text("SELECT category FROM hotdog_profiles WHERE id = 'legacy-hotdog'")
            ).scalar_one()
            assert category == "hotdog"

        command.upgrade(config, "0014")
        with engine.begin() as connection:
            connection.execute(
                text(
                    """
                    INSERT INTO order_items (
                        id,
                        user_id,
                        profile_id,
                        hotdog_name,
                        vendor_name,
                        base_price_dollars,
                        add_ons_json,
                        total_dollars,
                        status,
                        created_at
                    ) VALUES (
                        'legacy-order',
                        'legacy-user',
                        'legacy-hotdog',
                        'Legacy Hotdog',
                        'Legacy Cart',
                        6.0,
                        '[]',
                        8.0,
                        'draft',
                        CURRENT_TIMESTAMP
                    )
                    """
                )
            )

        command.upgrade(config, "0015")
        with engine.connect() as connection:
            profile_credit_cost = connection.execute(
                text("SELECT credit_cost FROM hotdog_profiles WHERE id = 'legacy-hotdog'")
            ).scalar_one()
            order_costs = connection.execute(
                text(
                    """
                    SELECT base_credit_cost, total_credits
                    FROM order_items
                    WHERE id = 'legacy-order'
                    """
                )
            ).one()
            assert profile_credit_cost == 6
            assert tuple(order_costs) == (6, 8)

        inspector = inspect(engine)
        profile_columns = {column["name"] for column in inspector.get_columns("hotdog_profiles")}
        order_columns = {column["name"] for column in inspector.get_columns("order_items")}
        assert "price_dollars" not in profile_columns
        assert "credit_cost" in profile_columns
        assert "base_price_dollars" not in order_columns
        assert "total_dollars" not in order_columns
        assert {"base_credit_cost", "total_credits"}.issubset(order_columns)
    finally:
        engine.dispose()
