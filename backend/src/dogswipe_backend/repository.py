from __future__ import annotations

from collections.abc import Iterable

from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import DogProfileRecord, SwipeEventRecord
from .schemas import DogProfile, SwipeDecision


class DogRepository:
    async def list_available_profiles(self, *, limit: int = 20) -> list[DogProfile]:
        raise NotImplementedError

    async def record_swipe(
        self,
        *,
        user_id: str,
        profile_id: str,
        decision: SwipeDecision,
    ) -> bool:
        raise NotImplementedError

    async def list_matches(self, *, user_id: str) -> list[DogProfile]:
        raise NotImplementedError


class SqlAlchemyDogRepository(DogRepository):
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_available_profiles(self, *, limit: int = 20) -> list[DogProfile]:
        statement = (
            select(DogProfileRecord)
            .where(DogProfileRecord.adoption_status == "available")
            .order_by(DogProfileRecord.compatibility_score.desc(), DogProfileRecord.name.asc())
            .limit(limit)
        )
        return self._profiles(await self.session.scalars(statement))

    async def record_swipe(
        self,
        *,
        user_id: str,
        profile_id: str,
        decision: SwipeDecision,
    ) -> bool:
        profile = await self.session.get(DogProfileRecord, profile_id)
        if profile is None:
            return False
        self.session.add(
            SwipeEventRecord(user_id=user_id, profile_id=profile_id, decision=decision.value)
        )
        await self.session.flush()
        return decision in {SwipeDecision.like, SwipeDecision.super_like} and (
            profile.compatibility_score >= 0.72
        )

    async def list_matches(self, *, user_id: str) -> list[DogProfile]:
        liked_profile_ids = (
            select(SwipeEventRecord.profile_id)
            .where(SwipeEventRecord.user_id == user_id)
            .where(
                SwipeEventRecord.decision.in_(
                    [SwipeDecision.like.value, SwipeDecision.super_like.value]
                )
            )
        )
        statement: Select[tuple[DogProfileRecord]] = (
            select(DogProfileRecord)
            .where(DogProfileRecord.id.in_(liked_profile_ids))
            .where(DogProfileRecord.compatibility_score >= 0.72)
            .order_by(DogProfileRecord.compatibility_score.desc(), DogProfileRecord.name.asc())
        )
        return self._profiles(await self.session.scalars(statement))

    @staticmethod
    def _profiles(records: Iterable[DogProfileRecord]) -> list[DogProfile]:
        return [DogProfile.model_validate(record) for record in records]
