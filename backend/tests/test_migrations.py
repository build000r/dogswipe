from __future__ import annotations

from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from dogswipe_backend.settings import get_settings


def _alembic_config() -> Config:
    backend_root = Path(__file__).resolve().parents[1]
    config = Config(str(backend_root / "alembic.ini"))
    config.set_main_option("script_location", str(backend_root / "migrations"))
    return config


def test_migrations_upgrade_and_downgrade(clear_settings, tmp_path, monkeypatch) -> None:
    del clear_settings
    database_path = tmp_path / "dogswipe.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite+aiosqlite:///{database_path}")
    get_settings.cache_clear()

    command.upgrade(_alembic_config(), "head")

    engine = create_engine(f"sqlite:///{database_path}")
    try:
        inspector = inspect(engine)
        assert {
            "alembic_version",
            "hotdog_profiles",
            "swipe_events",
            "user_preferences",
            "order_items",
            "offering_add_ons",
        }.issubset(set(inspector.get_table_names()))
        assert {column["name"] for column in inspector.get_columns("hotdog_profiles")} == {
            "id",
            "name",
            "style",
            "category",
            "tags_json",
            "credit_cost",
            "signature_notes",
            "distance_miles",
            "latitude",
            "longitude",
            "vendor_name",
            "address_text",
            "available_from",
            "available_until",
            "fulfillment_mode",
            "delivery_radius_miles",
            "delivery_address",
            "image_url",
            "menu_url",
            "menu_status",
            "menu_excerpt",
            "menu_checked_at",
            "media_alt_text",
            "vendor_owner_user_id",
            "crave_score",
            "availability_status",
            "review_note",
            "last_verified_at",
            "last_reviewed_at",
            "created_at",
        }
        assert {column["name"] for column in inspector.get_columns("user_preferences")} == {
            "user_id",
            "max_distance_miles",
            "spicy_friendly",
            "classic_only",
            "created_at",
            "updated_at",
        }
        assert {column["name"] for column in inspector.get_columns("order_items")} == {
            "id",
            "user_id",
            "profile_id",
            "hotdog_name",
            "vendor_name",
            "base_credit_cost",
            "add_ons_json",
            "total_credits",
            "fulfillment_mode",
            "available_from",
            "available_until",
            "delivery_address",
            "maker_ready_confirmed_at",
            "maker_handoff_confirmed_at",
            "claimer_handoff_confirmed_at",
            "completed_at",
            "status",
            "created_at",
        }
        assert {column["name"] for column in inspector.get_columns("offering_add_ons")} == {
            "id",
            "profile_id",
            "name",
            "credit_cost",
            "created_at",
        }
    finally:
        engine.dispose()

    command.downgrade(_alembic_config(), "base")

    engine = create_engine(f"sqlite:///{database_path}")
    try:
        assert inspect(engine).get_table_names() == ["alembic_version"]
    finally:
        engine.dispose()
