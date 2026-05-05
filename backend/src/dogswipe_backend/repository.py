from __future__ import annotations

from collections.abc import Iterable

from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import HotdogProfileRecord, SwipeEventRecord
from .schemas import HotdogProfile, SwipeDecision


class HotdogRepository:
    async def list_available_profiles(self, *, limit: int = 20) -> list[HotdogProfile]:
        raise NotImplementedError

    async def record_swipe(
        self,
        *,
        user_id: str,
        profile_id: str,
        decision: SwipeDecision,
    ) -> bool:
        raise NotImplementedError

    async def list_matches(self, *, user_id: str) -> list[HotdogProfile]:
        raise NotImplementedError


class SqlAlchemyHotdogRepository(HotdogRepository):
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_available_profiles(self, *, limit: int = 20) -> list[HotdogProfile]:
        statement = (
            select(HotdogProfileRecord)
            .where(HotdogProfileRecord.availability_status == "available")
            .order_by(HotdogProfileRecord.crave_score.desc(), HotdogProfileRecord.name.asc())
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
        profile = await self.session.get(HotdogProfileRecord, profile_id)
        if profile is None:
            return False
        self.session.add(
            SwipeEventRecord(user_id=user_id, profile_id=profile_id, decision=decision.value)
        )
        await self.session.flush()
        return decision in {SwipeDecision.like, SwipeDecision.super_like} and (
            profile.crave_score >= 0.72
        )

    async def list_matches(self, *, user_id: str) -> list[HotdogProfile]:
        liked_profile_ids = (
            select(SwipeEventRecord.profile_id)
            .where(SwipeEventRecord.user_id == user_id)
            .where(
                SwipeEventRecord.decision.in_(
                    [SwipeDecision.like.value, SwipeDecision.super_like.value]
                )
            )
        )
        statement: Select[tuple[HotdogProfileRecord]] = (
            select(HotdogProfileRecord)
            .where(HotdogProfileRecord.id.in_(liked_profile_ids))
            .where(HotdogProfileRecord.crave_score >= 0.72)
            .order_by(HotdogProfileRecord.crave_score.desc(), HotdogProfileRecord.name.asc())
        )
        return self._profiles(await self.session.scalars(statement))

    @staticmethod
    def _profiles(records: Iterable[HotdogProfileRecord]) -> list[HotdogProfile]:
        return [HotdogProfile.model_validate(record) for record in records]
