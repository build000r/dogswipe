from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    event,
    Float,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class HotdogProfileRecord(Base):
    __tablename__ = "hotdog_profiles"
    __table_args__ = (Index("ix_hotdog_profiles_vendor_owner", "vendor_owner_user_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    style: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default="hotdog",
        server_default="hotdog",
    )
    price_dollars: Mapped[float] = mapped_column(Float, nullable=False)
    signature_notes: Mapped[str] = mapped_column(String(120), nullable=False)
    distance_miles: Mapped[float] = mapped_column(Float, nullable=False)
    latitude: Mapped[float | None] = mapped_column(Float)
    longitude: Mapped[float | None] = mapped_column(Float)
    vendor_name: Mapped[str] = mapped_column(String(160), nullable=False)
    address_text: Mapped[str | None] = mapped_column(String(240))
    image_url: Mapped[str | None] = mapped_column(Text)
    menu_url: Mapped[str | None] = mapped_column(Text)
    menu_status: Mapped[str | None] = mapped_column(String(32))
    menu_excerpt: Mapped[str | None] = mapped_column(Text)
    menu_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    media_alt_text: Mapped[str | None] = mapped_column(String(160))
    vendor_owner_user_id: Mapped[str | None] = mapped_column(String(128))
    crave_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    availability_status: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default="available",
    )
    review_note: Mapped[str | None] = mapped_column(Text)
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class SwipeEventRecord(Base):
    __tablename__ = "swipe_events"
    __table_args__ = (Index("ix_swipe_events_user_profile", "user_id", "profile_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    profile_id: Mapped[str] = mapped_column(String(36), nullable=False)
    decision: Mapped[str] = mapped_column(String(32), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class UserPreferenceRecord(Base):
    __tablename__ = "user_preferences"

    user_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    max_distance_miles: Mapped[float] = mapped_column(Float, nullable=False, default=10)
    spicy_friendly: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    classic_only: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class CreditAccountRecord(Base):
    __tablename__ = "credit_accounts"

    user_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    lifetime_purchased: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lifetime_earned: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    lifetime_spent: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class CreditLedgerEntry(Base):
    __tablename__ = "credit_ledger"
    __table_args__ = (
        Index("ix_credit_ledger_user", "user_id"),
        UniqueConstraint("idempotency_key", name="uq_credit_ledger_idempotency_key"),
        CheckConstraint(
            "entry_type IN ('purchase', 'spend', 'earn', 'refund_credit', 'admin_adjustment')",
            name="ck_credit_ledger_entry_type",
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    entry_type: Mapped[str] = mapped_column(String(32), nullable=False)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    balance_after: Mapped[int] = mapped_column(Integer, nullable=False)
    order_ref: Mapped[str | None] = mapped_column(String(36))
    purchase_ref: Mapped[str | None] = mapped_column(String(128))
    idempotency_key: Mapped[str | None] = mapped_column(String(128))
    reason: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


@event.listens_for(CreditLedgerEntry, "before_update")
def _prevent_credit_ledger_update(*_args: object) -> None:
    raise ValueError("credit ledger entries are append-only")


@event.listens_for(CreditLedgerEntry, "before_delete")
def _prevent_credit_ledger_delete(*_args: object) -> None:
    raise ValueError("credit ledger entries are append-only")


class OrderRecord(Base):
    __tablename__ = "order_items"
    __table_args__ = (
        Index("ix_order_items_user_created", "user_id", "created_at"),
        Index("ix_order_items_profile", "profile_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    profile_id: Mapped[str] = mapped_column(String(36), nullable=False)
    hotdog_name: Mapped[str] = mapped_column(String(80), nullable=False)
    vendor_name: Mapped[str] = mapped_column(String(160), nullable=False)
    base_price_dollars: Mapped[float] = mapped_column(Float, nullable=False)
    add_ons_json: Mapped[str] = mapped_column(Text, nullable=False, default="[]")
    total_dollars: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class ReviewRecord(Base):
    __tablename__ = "reviews"
    __table_args__ = (
        UniqueConstraint("order_id", "direction", name="uq_reviews_order_direction"),
        CheckConstraint(
            "direction IN ('giver_reviews_receiver', 'receiver_reviews_giver')",
            name="ck_reviews_direction",
        ),
        CheckConstraint("rating >= 1 AND rating <= 5", name="ck_reviews_rating_range"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    order_id: Mapped[str] = mapped_column(String(36), nullable=False)
    rater_user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    ratee_user_id: Mapped[str] = mapped_column(String(128), nullable=False)
    direction: Mapped[str] = mapped_column(String(32), nullable=False)
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    text: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
