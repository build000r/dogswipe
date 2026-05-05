from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import Annotated, Self

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    computed_field,
    model_validator,
)

from .menu import extract_menu_highlights

ReviewNote = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=240),
]
WALKING_SPEED_MILES_PER_HOUR = 3.0


class SwipeDecision(StrEnum):
    like = "like"
    reject = "pass"
    super_like = "super_like"


class HotdogProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    style: str
    price_dollars: float = Field(ge=0)
    signature_notes: str
    distance_miles: float = Field(ge=0)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    vendor_name: str
    address_text: str | None = None
    image_url: str | None = None
    menu_url: str | None = None
    menu_status: str | None = None
    menu_excerpt: str | None = None
    menu_checked_at: datetime | None = None
    media_alt_text: str | None = None
    crave_score: float = Field(ge=0, le=1)
    availability_status: str
    review_note: str | None = None
    last_verified_at: datetime | None = None
    last_reviewed_at: datetime | None = None

    @computed_field  # type: ignore[prop-decorator]
    @property
    def walking_time_minutes(self) -> int:
        minutes = round((self.distance_miles / WALKING_SPEED_MILES_PER_HOUR) * 60)
        return max(1, minutes)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def menu_highlights(self) -> list[str]:
        return extract_menu_highlights(self.menu_excerpt)


class DiscoveryResponse(BaseModel):
    profiles: list[HotdogProfile]


class SwipeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    profile_id: str = Field(min_length=1, max_length=64)
    decision: SwipeDecision


class SwipeResponse(BaseModel):
    profile_id: str
    decision: SwipeDecision
    matched: bool


class MatchResponse(BaseModel):
    matches: list[HotdogProfile]


class CravingPreferences(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    max_distance_miles: float = Field(default=10, ge=1, le=25)
    spicy_friendly: bool = True
    classic_only: bool = False


class VendorSubmissionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=80)
    style: str = Field(min_length=1, max_length=120)
    price_dollars: float = Field(ge=0, le=50)
    signature_notes: str = Field(min_length=1, max_length=120)
    distance_miles: float = Field(ge=0, le=25)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    vendor_name: str = Field(min_length=1, max_length=160)
    address_text: str | None = Field(default=None, max_length=240)
    image_url: str | None = Field(default=None, max_length=2048)
    menu_url: str | None = Field(default=None, max_length=2048)
    media_alt_text: str | None = Field(default=None, max_length=160)

    @model_validator(mode="after")
    def coordinates_are_complete(self) -> Self:
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("latitude and longitude must be provided together")
        return self


class VendorSubmissionResponse(BaseModel):
    profile: HotdogProfile


class MenuIngestionResponse(BaseModel):
    profile: HotdogProfile


class VendorSubmissionListResponse(BaseModel):
    submissions: list[HotdogProfile]


class AdminApprovalRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    crave_score: float = Field(default=0.72, ge=0, le=1)


class AdminReviewQueueResponse(BaseModel):
    submissions: list[HotdogProfile]


class AdminApprovalResponse(BaseModel):
    profile: HotdogProfile


class AdminModerationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    review_note: ReviewNote


class AdminModerationResponse(BaseModel):
    profile: HotdogProfile


class AdminMenuRefreshRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    limit: int = Field(default=20, ge=1, le=50)
    max_age_hours: float = Field(default=24, ge=0, le=168)


class AdminMenuRefreshResponse(BaseModel):
    checked_count: int
    refreshed_count: int
    failed_count: int
    profiles: list[HotdogProfile]
