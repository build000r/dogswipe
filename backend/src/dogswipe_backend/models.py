from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import DateTime, Float, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


class DogProfileRecord(Base):
    __tablename__ = "dog_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    breed: Mapped[str] = mapped_column(String(120), nullable=False)
    age_years: Mapped[float] = mapped_column(Float, nullable=False)
    temperament: Mapped[str] = mapped_column(String(120), nullable=False)
    distance_miles: Mapped[float] = mapped_column(Float, nullable=False)
    shelter_name: Mapped[str] = mapped_column(String(160), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text)
    compatibility_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    adoption_status: Mapped[str] = mapped_column(String(32), nullable=False, default="available")
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
