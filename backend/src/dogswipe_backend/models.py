from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, Float, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class HotdogProfileRecord(Base):
    __tablename__ = "hotdog_profiles"
    __table_args__ = (Index("ix_hotdog_profiles_vendor_owner", "vendor_owner_user_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    style: Mapped[str] = mapped_column(String(120), nullable=False)
    price_dollars: Mapped[float] = mapped_column(Float, nullable=False)
    signature_notes: Mapped[str] = mapped_column(String(120), nullable=False)
    distance_miles: Mapped[float] = mapped_column(Float, nullable=False)
    vendor_name: Mapped[str] = mapped_column(String(160), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text)
    menu_url: Mapped[str | None] = mapped_column(Text)
    media_alt_text: Mapped[str | None] = mapped_column(String(160))
    vendor_owner_user_id: Mapped[str | None] = mapped_column(String(128))
    crave_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    availability_status: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default="available",
    )
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
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
