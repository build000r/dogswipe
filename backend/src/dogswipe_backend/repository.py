from __future__ import annotations

from collections.abc import Iterable
from datetime import UTC, datetime
from math import cos, radians

from sqlalchemy import Select, and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.elements import ColumnElement

from .models import HotdogProfileRecord, SwipeEventRecord, UserPreferenceRecord
from .schemas import CravingPreferences, HotdogProfile, SwipeDecision, VendorSubmissionRequest


class HotdogRepository:
    async def list_available_profiles(
        self,
        *,
        limit: int = 20,
        max_distance_miles: float | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> list[HotdogProfile]:
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

    async def update_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile | None:
        raise NotImplementedError

    async def get_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
    ) -> HotdogProfile | None:
        raise NotImplementedError

    async def record_menu_ingestion(
        self,
        *,
        user_id: str,
        profile_id: str,
        status: str,
        excerpt: str | None,
        checked_at: datetime,
    ) -> HotdogProfile | None:
        raise NotImplementedError

    async def list_pending_vendor_submissions(self) -> list[HotdogProfile]:
        raise NotImplementedError

    async def approve_vendor_submission(
        self,
        *,
        profile_id: str,
        crave_score: float,
    ) -> HotdogProfile | None:
        raise NotImplementedError

    async def request_vendor_submission_changes(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        raise NotImplementedError

    async def reject_vendor_submission(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        raise NotImplementedError


class SqlAlchemyHotdogRepository(HotdogRepository):
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_available_profiles(
        self,
        *,
        limit: int = 20,
        max_distance_miles: float | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
    ) -> list[HotdogProfile]:
        statement = select(HotdogProfileRecord).where(
            HotdogProfileRecord.availability_status == "available"
        )
        if max_distance_miles is not None:
            statement = statement.where(
                self._distance_candidate_filter(
                    max_distance_miles=max_distance_miles,
                    latitude=latitude,
                    longitude=longitude,
                )
            )
        statement = statement.order_by(
            HotdogProfileRecord.crave_score.desc(),
            HotdogProfileRecord.name.asc(),
        ).limit(limit)
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
        record = self._record_from_submission(
            submission,
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

    async def update_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
        submission: VendorSubmissionRequest,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if (
            record is None
            or record.vendor_owner_user_id != user_id
            or record.availability_status not in {"pending_review", "changes_requested"}
        ):
            return None
        self._apply_submission(record, submission)
        record.availability_status = "pending_review"
        record.crave_score = 0.5
        record.review_note = None
        record.last_reviewed_at = None
        record.last_verified_at = None
        record.menu_status = None
        record.menu_excerpt = None
        record.menu_checked_at = None
        await self.session.flush()
        return HotdogProfile.model_validate(record)

    async def get_vendor_submission(
        self,
        *,
        user_id: str,
        profile_id: str,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if record is None or record.vendor_owner_user_id != user_id:
            return None
        return HotdogProfile.model_validate(record)

    async def record_menu_ingestion(
        self,
        *,
        user_id: str,
        profile_id: str,
        status: str,
        excerpt: str | None,
        checked_at: datetime,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if record is None or record.vendor_owner_user_id != user_id:
            return None
        record.menu_status = status
        record.menu_excerpt = excerpt
        record.menu_checked_at = checked_at
        await self.session.flush()
        return HotdogProfile.model_validate(record)

    async def list_pending_vendor_submissions(self) -> list[HotdogProfile]:
        statement = (
            select(HotdogProfileRecord)
            .where(HotdogProfileRecord.availability_status == "pending_review")
            .where(HotdogProfileRecord.vendor_owner_user_id.is_not(None))
            .order_by(HotdogProfileRecord.created_at.asc(), HotdogProfileRecord.name.asc())
        )
        return self._profiles(await self.session.scalars(statement))

    async def approve_vendor_submission(
        self,
        *,
        profile_id: str,
        crave_score: float,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if (
            record is None
            or record.vendor_owner_user_id is None
            or record.availability_status != "pending_review"
        ):
            return None
        record.availability_status = "available"
        record.crave_score = crave_score
        record.review_note = None
        record.last_verified_at = datetime.now(UTC)
        record.last_reviewed_at = record.last_verified_at
        await self.session.flush()
        return HotdogProfile.model_validate(record)

    async def request_vendor_submission_changes(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        return await self._moderate_pending_vendor_submission(
            profile_id=profile_id,
            availability_status="changes_requested",
            review_note=review_note,
        )

    async def reject_vendor_submission(
        self,
        *,
        profile_id: str,
        review_note: str,
    ) -> HotdogProfile | None:
        return await self._moderate_pending_vendor_submission(
            profile_id=profile_id,
            availability_status="rejected",
            review_note=review_note,
        )

    async def _moderate_pending_vendor_submission(
        self,
        *,
        profile_id: str,
        availability_status: str,
        review_note: str,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if (
            record is None
            or record.vendor_owner_user_id is None
            or record.availability_status != "pending_review"
        ):
            return None
        record.availability_status = availability_status
        record.review_note = review_note.strip()
        record.last_reviewed_at = datetime.now(UTC)
        await self.session.flush()
        return HotdogProfile.model_validate(record)

    @staticmethod
    def _profiles(records: Iterable[HotdogProfileRecord]) -> list[HotdogProfile]:
        return [HotdogProfile.model_validate(record) for record in records]

    def _record_from_submission(
        self,
        submission: VendorSubmissionRequest,
        *,
        vendor_owner_user_id: str,
        crave_score: float,
        availability_status: str,
    ) -> HotdogProfileRecord:
        record = HotdogProfileRecord(
            vendor_owner_user_id=vendor_owner_user_id,
            crave_score=crave_score,
            availability_status=availability_status,
        )
        self._apply_submission(record, submission)
        return record

    def _apply_submission(
        self,
        record: HotdogProfileRecord,
        submission: VendorSubmissionRequest,
    ) -> None:
        record.name = submission.name
        record.style = submission.style
        record.price_dollars = submission.price_dollars
        record.signature_notes = submission.signature_notes
        record.distance_miles = submission.distance_miles
        record.latitude = submission.latitude
        record.longitude = submission.longitude
        record.vendor_name = submission.vendor_name
        record.image_url = self._blank_to_none(submission.image_url)
        record.menu_url = self._blank_to_none(submission.menu_url)
        record.media_alt_text = self._blank_to_none(submission.media_alt_text)

    @staticmethod
    def _blank_to_none(value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None

    @staticmethod
    def _distance_candidate_filter(
        *,
        max_distance_miles: float,
        latitude: float | None,
        longitude: float | None,
    ) -> ColumnElement[bool]:
        if latitude is None or longitude is None:
            return HotdogProfileRecord.distance_miles <= max_distance_miles

        latitude_delta = max_distance_miles / 69.0
        longitude_delta = max_distance_miles / (69.0 * max(cos(radians(latitude)), 0.01))
        coordinate_window = and_(
            HotdogProfileRecord.latitude.is_not(None),
            HotdogProfileRecord.longitude.is_not(None),
            HotdogProfileRecord.latitude.between(
                latitude - latitude_delta,
                latitude + latitude_delta,
            ),
            HotdogProfileRecord.longitude.between(
                longitude - longitude_delta,
                longitude + longitude_delta,
            ),
        )
        stored_distance_fallback = and_(
            or_(
                HotdogProfileRecord.latitude.is_(None),
                HotdogProfileRecord.longitude.is_(None),
            ),
            HotdogProfileRecord.distance_miles <= max_distance_miles,
        )
        return or_(coordinate_window, stored_distance_fallback)
