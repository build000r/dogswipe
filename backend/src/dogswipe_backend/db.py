from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from .settings import get_settings


class Base(DeclarativeBase):
    pass


class Database:
    def __init__(self, database_url: str) -> None:
        self.database_url = database_url
        self.engine = create_async_engine(database_url, **self._engine_kwargs(database_url))
        self.session_factory = async_sessionmaker(self.engine, expire_on_commit=False)

    @staticmethod
    def _engine_kwargs(database_url: str) -> dict[str, object]:
        if database_url.startswith("sqlite"):
            return {}
        settings = get_settings()
        return {
            "echo": settings.database_echo,
            "pool_size": settings.database_pool_size,
            "max_overflow": settings.database_max_overflow,
            "pool_timeout": settings.database_pool_timeout,
            "pool_pre_ping": settings.database_pool_pre_ping,
        }

    async def create_schema(self) -> None:
        async with self.engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)

    async def drop_schema(self) -> None:
        async with self.engine.begin() as connection:
            await connection.run_sync(Base.metadata.drop_all)

    async def dispose(self) -> None:
        await self.engine.dispose()


_database: Database | None = None


def get_database() -> Database:
    global _database
    settings = get_settings()
    if _database is None or _database.database_url != settings.database_url:
        _database = Database(settings.database_url)
    return _database


def set_database_for_tests(database: Database | None) -> None:
    global _database
    _database = database


def get_engine() -> AsyncEngine:
    return get_database().engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    return get_database().session_factory


async def get_db_session() -> AsyncIterator[AsyncSession]:
    async with get_session_factory()() as session:
        yield session
        await session.commit()
