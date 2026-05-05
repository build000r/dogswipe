from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import DateTime, Float, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class HotdogProfileRecord(Base):
    __tablename__ = "hotdog_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    style: Mapped[str] = mapped_column(String(120), nullable=False)
    price_dollars: Mapped[float] = mapped_column(Float, nullable=False)
    signature_notes: Mapped[str] = mapped_column(String(120), nullable=False)
    distance_miles: Mapped[float] = mapped_column(Float, nullable=False)
    vendor_name: Mapped[str] = mapped_column(String(160), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text)
    crave_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    availability_status: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default="available",
    )
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
