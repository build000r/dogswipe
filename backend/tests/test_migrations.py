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
        assert {"alembic_version", "hotdog_profiles", "swipe_events"}.issubset(
            set(inspector.get_table_names())
        )
        assert {column["name"] for column in inspector.get_columns("hotdog_profiles")} == {
            "id",
            "name",
            "style",
            "price_dollars",
            "signature_notes",
            "distance_miles",
            "vendor_name",
            "image_url",
            "crave_score",
            "availability_status",
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
