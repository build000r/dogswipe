from __future__ import annotations

from collections.abc import Iterable

from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import HotdogProfileRecord, SwipeEventRecord, UserPreferenceRecord
from .schemas import CravingPreferences, HotdogProfile, SwipeDecision, VendorSubmissionRequest


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

    async def get_preferences(self, *, user_id: str) -> CravingPreferences:
        raise NotImplementedError

    async def upsert_preferences(
        self,
        *,
        user_id: str,
        preferences: CravingPreferences,
    ) -> CravingPreferences:
        raise NotImplementedError

    async def submit_vendor_profile(
        self,
        *,
        user_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile:
        raise NotImplementedError

    async def list_vendor_submissions(self, *, user_id: str) -> list[HotdogProfile]:
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

    async def get_preferences(self, *, user_id: str) -> CravingPreferences:
        record = await self.session.get(UserPreferenceRecord, user_id)
        if record is None:
            return CravingPreferences()
        return CravingPreferences.model_validate(record)

    async def upsert_preferences(
        self,
        *,
        user_id: str,
        preferences: CravingPreferences,
    ) -> CravingPreferences:
        record = await self.session.get(UserPreferenceRecord, user_id)
        if record is None:
            record = UserPreferenceRecord(user_id=user_id)
            self.session.add(record)
        record.max_distance_miles = preferences.max_distance_miles
        record.spicy_friendly = preferences.spicy_friendly
        record.classic_only = preferences.classic_only
        await self.session.flush()
        return CravingPreferences.model_validate(record)

    async def submit_vendor_profile(
        self,
        *,
        user_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile:
        record = HotdogProfileRecord(
            name=submission.name,
            style=submission.style,
            price_dollars=submission.price_dollars,
            signature_notes=submission.signature_notes,
            distance_miles=submission.distance_miles,
            vendor_name=submission.vendor_name,
            image_url=self._blank_to_none(submission.image_url),
            menu_url=self._blank_to_none(submission.menu_url),
            media_alt_text=self._blank_to_none(submission.media_alt_text),
            vendor_owner_user_id=user_id,
            crave_score=0.5,
            availability_status="pending_review",
        )
        self.session.add(record)
        await self.session.flush()
        return HotdogProfile.model_validate(record)

    async def list_vendor_submissions(self, *, user_id: str) -> list[HotdogProfile]:
        statement = (
            select(HotdogProfileRecord)
            .where(HotdogProfileRecord.vendor_owner_user_id == user_id)
            .order_by(HotdogProfileRecord.created_at.desc(), HotdogProfileRecord.name.asc())
        )
        return self._profiles(await self.session.scalars(statement))

    @staticmethod
    def _profiles(records: Iterable[HotdogProfileRecord]) -> list[HotdogProfile]:
        return [HotdogProfile.model_validate(record) for record in records]

    @staticmethod
    def _blank_to_none(value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None
