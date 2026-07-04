from __future__ import annotations

import json
from collections.abc import Iterable
from datetime import UTC, datetime
from math import cos, radians

from sqlalchemy import Select, and_, func as sa_func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.elements import ColumnElement

from .models import (
    CreditAccountRecord,
    CreditLedgerEntry as CreditLedgerEntryRecord,
    HotdogProfileRecord,
    OrderRecord,
    ReviewRecord,
    SwipeEventRecord,
    UserPreferenceRecord,
)
from .schemas import (
    CravingPreferences,
    CreditAccount,
    CreditLedgerEntry,
    CreditLedgerEntryType,
    HotdogProfile,
    OrderAddOn,
    OrderItem,
    OrderStatus,
    Review,
    ReviewCreate,
    SwipeDecision,
    VendorSubmissionRequest,
)


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

    async def get_orderable_profile(self, *, profile_id: str) -> HotdogProfile | None:
        raise NotImplementedError

    async def create_order(
        self,
        *,
        user_id: str,
        profile: HotdogProfile,
        add_ons: list[OrderAddOn],
    ) -> OrderItem:
        raise NotImplementedError

    async def list_orders(self, *, user_id: str) -> list[OrderItem]:
        raise NotImplementedError

    async def get_order(self, *, user_id: str, order_id: str) -> OrderItem | None:
        raise NotImplementedError

    async def update_order_status(
        self,
        *,
        user_id: str,
        order_id: str,
        status: OrderStatus,
    ) -> OrderItem | None:
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

    async def list_menu_refresh_candidates(
        self,
        *,
        limit: int,
        stale_before: datetime,
    ) -> list[HotdogProfile]:
        raise NotImplementedError

    async def record_admin_menu_ingestion(
        self,
        *,
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

    async def get_credit_account(self, *, user_id: str) -> CreditAccount | None:
        raise NotImplementedError

    async def get_or_create_credit_account(self, *, user_id: str) -> CreditAccount:
        raise NotImplementedError

    async def create_ledger_entry(
        self,
        *,
        user_id: str,
        entry_type: CreditLedgerEntryType,
        amount: int,
        order_ref: str | None = None,
        purchase_ref: str | None = None,
        idempotency_key: str | None = None,
        reason: str | None = None,
    ) -> CreditLedgerEntry:
        raise NotImplementedError

    async def get_ledger_balance(self, *, user_id: str) -> int:
        raise NotImplementedError

    async def create_review(
        self,
        *,
        rater_user_id: str,
        review: ReviewCreate,
    ) -> Review:
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
        if profile is None or not self._is_swipeable_profile(profile):
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
            .where(HotdogProfileRecord.availability_status.in_(["available", "limited"]))
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

    async def get_orderable_profile(self, *, profile_id: str) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if record is None or record.availability_status not in {"available", "limited"}:
            return None
        return HotdogProfile.model_validate(record)

    async def create_order(
        self,
        *,
        user_id: str,
        profile: HotdogProfile,
        add_ons: list[OrderAddOn],
    ) -> OrderItem:
        total_credits = profile.credit_cost + sum(add_on.credit_cost for add_on in add_ons)
        record = OrderRecord(
            user_id=user_id,
            profile_id=profile.id,
            hotdog_name=profile.name,
            vendor_name=profile.vendor_name,
            base_credit_cost=profile.credit_cost,
            add_ons_json=self._encode_order_add_ons(add_ons),
            total_credits=total_credits,
            status=OrderStatus.draft.value,
        )
        self.session.add(record)
        await self.session.flush()
        return self._order(record)

    async def list_orders(self, *, user_id: str) -> list[OrderItem]:
        statement = (
            select(OrderRecord)
            .where(OrderRecord.user_id == user_id)
            .order_by(OrderRecord.created_at.desc(), OrderRecord.id.desc())
        )
        return [self._order(record) for record in await self.session.scalars(statement)]

    async def get_order(self, *, user_id: str, order_id: str) -> OrderItem | None:
        record = await self.session.get(OrderRecord, order_id)
        if record is None or record.user_id != user_id:
            return None
        return self._order(record)

    async def update_order_status(
        self,
        *,
        user_id: str,
        order_id: str,
        status: OrderStatus,
    ) -> OrderItem | None:
        record = await self.session.get(OrderRecord, order_id)
        if record is None or record.user_id != user_id:
            return None
        record.status = status.value
        await self.session.flush()
        return self._order(record)

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

    async def list_menu_refresh_candidates(
        self,
        *,
        limit: int,
        stale_before: datetime,
    ) -> list[HotdogProfile]:
        statement = (
            select(HotdogProfileRecord)
            .where(HotdogProfileRecord.vendor_owner_user_id.is_not(None))
            .where(HotdogProfileRecord.menu_url.is_not(None))
            .where(HotdogProfileRecord.availability_status != "rejected")
            .where(
                or_(
                    HotdogProfileRecord.menu_checked_at.is_(None),
                    HotdogProfileRecord.menu_checked_at <= stale_before,
                )
            )
            .order_by(
                HotdogProfileRecord.menu_checked_at.is_not(None).asc(),
                HotdogProfileRecord.menu_checked_at.asc(),
                HotdogProfileRecord.name.asc(),
            )
            .limit(limit)
        )
        return self._profiles(await self.session.scalars(statement))

    async def record_admin_menu_ingestion(
        self,
        *,
        profile_id: str,
        status: str,
        excerpt: str | None,
        checked_at: datetime,
    ) -> HotdogProfile | None:
        record = await self.session.get(HotdogProfileRecord, profile_id)
        if record is None or record.menu_url is None or record.availability_status == "rejected":
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
        record.category = submission.category
        record.credit_cost = submission.credit_cost
        record.signature_notes = submission.signature_notes
        record.distance_miles = submission.distance_miles
        record.latitude = submission.latitude
        record.longitude = submission.longitude
        record.vendor_name = submission.vendor_name
        record.address_text = self._blank_to_none(submission.address_text)
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
    def _is_swipeable_profile(record: HotdogProfileRecord) -> bool:
        return record.availability_status in {"available", "limited"}

    @staticmethod
    def _encode_order_add_ons(add_ons: list[OrderAddOn]) -> str:
        return json.dumps(
            [add_on.model_dump() for add_on in add_ons],
            separators=(",", ":"),
        )

    @staticmethod
    def _decode_order_add_ons(value: str) -> list[OrderAddOn]:
        raw_add_ons = json.loads(value)
        if not isinstance(raw_add_ons, list):
            return []
        return [OrderAddOn.model_validate(add_on) for add_on in raw_add_ons]

    @classmethod
    def _order(cls, record: OrderRecord) -> OrderItem:
        return OrderItem(
            id=record.id,
            profile_id=record.profile_id,
            hotdog_name=record.hotdog_name,
            vendor_name=record.vendor_name,
            base_credit_cost=record.base_credit_cost,
            add_ons=cls._decode_order_add_ons(record.add_ons_json),
            total_credits=record.total_credits,
            status=record.status,
            created_at=record.created_at,
        )

    async def get_credit_account(self, *, user_id: str) -> CreditAccount | None:
        record = await self.session.get(CreditAccountRecord, user_id)
        if record is None:
            return None
        return CreditAccount.model_validate(record)

    async def get_or_create_credit_account(self, *, user_id: str) -> CreditAccount:
        record = await self.session.get(CreditAccountRecord, user_id)
        if record is None:
            record = CreditAccountRecord(user_id=user_id)
            self.session.add(record)
            await self.session.flush()
        return CreditAccount.model_validate(record)

    async def create_ledger_entry(
        self,
        *,
        user_id: str,
        entry_type: CreditLedgerEntryType,
        amount: int,
        order_ref: str | None = None,
        purchase_ref: str | None = None,
        idempotency_key: str | None = None,
        reason: str | None = None,
    ) -> CreditLedgerEntry:
        if idempotency_key is not None:
            existing = await self.session.scalar(
                select(CreditLedgerEntryRecord).where(
                    CreditLedgerEntryRecord.idempotency_key == idempotency_key
                )
            )
            if existing is not None:
                raise ValueError("credit ledger idempotency_key already exists")

        account = await self.session.get(CreditAccountRecord, user_id)
        if account is None:
            account = CreditAccountRecord(user_id=user_id)
            self.session.add(account)
            await self.session.flush()

        balance_after = await self.get_ledger_balance(user_id=user_id) + amount
        record = CreditLedgerEntryRecord(
            user_id=user_id,
            entry_type=entry_type.value,
            amount=amount,
            balance_after=balance_after,
            order_ref=order_ref,
            purchase_ref=purchase_ref,
            idempotency_key=idempotency_key,
            reason=reason,
        )
        self.session.add(record)
        self._apply_lifetime_counter(account, entry_type=entry_type, amount=amount)
        await self.session.flush()
        return CreditLedgerEntry.model_validate(record)

    async def get_ledger_balance(self, *, user_id: str) -> int:
        result = await self.session.scalar(
            select(sa_func.coalesce(sa_func.sum(CreditLedgerEntryRecord.amount), 0)).where(
                CreditLedgerEntryRecord.user_id == user_id
            )
        )
        return int(result or 0)

    async def create_review(
        self,
        *,
        rater_user_id: str,
        review: ReviewCreate,
    ) -> Review:
        record = ReviewRecord(
            order_id=review.order_id,
            rater_user_id=rater_user_id,
            ratee_user_id=review.ratee_user_id,
            direction=review.direction.value,
            rating=review.rating,
            text=review.text,
        )
        self.session.add(record)
        await self.session.flush()
        return Review.model_validate(record)

    @staticmethod
    def _apply_lifetime_counter(
        account: CreditAccountRecord,
        *,
        entry_type: CreditLedgerEntryType,
        amount: int,
    ) -> None:
        if entry_type == CreditLedgerEntryType.purchase and amount > 0:
            account.lifetime_purchased += amount
        elif entry_type in {
            CreditLedgerEntryType.earn,
            CreditLedgerEntryType.refund_credit,
            CreditLedgerEntryType.admin_adjustment,
        } and amount > 0:
            account.lifetime_earned += amount
        elif entry_type in {
            CreditLedgerEntryType.spend,
            CreditLedgerEntryType.admin_adjustment,
        } and amount < 0:
            account.lifetime_spent += abs(amount)

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
