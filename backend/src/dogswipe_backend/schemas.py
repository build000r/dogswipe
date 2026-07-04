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
    category: str = Field(default="hotdog", min_length=1, max_length=32)
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


class OrderAddOn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=80)
    price_dollars: float = Field(ge=0, le=20)


class OrderCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    profile_id: str = Field(min_length=1, max_length=64)
    add_on_ids: list[str] = Field(default_factory=list, max_length=8)


class OrderStatus(StrEnum):
    draft = "draft"
    claimed = "claimed"
    ready = "ready"
    handed_off = "handed_off"
    delivered = "delivered"
    completed = "completed"
    reviewed = "reviewed"
    canceled = "canceled"
    disputed = "disputed"
    refunded_credit = "refunded_credit"


ALLOWED_TRANSITIONS: dict[OrderStatus, frozenset[OrderStatus]] = {
    OrderStatus.draft: frozenset({OrderStatus.claimed, OrderStatus.canceled}),
    OrderStatus.claimed: frozenset(
        {OrderStatus.ready, OrderStatus.canceled, OrderStatus.disputed}
    ),
    OrderStatus.ready: frozenset(
        {
            OrderStatus.handed_off,
            OrderStatus.delivered,
            OrderStatus.canceled,
            OrderStatus.disputed,
        }
    ),
    OrderStatus.handed_off: frozenset({OrderStatus.completed, OrderStatus.disputed}),
    OrderStatus.delivered: frozenset({OrderStatus.completed, OrderStatus.disputed}),
    OrderStatus.completed: frozenset({OrderStatus.reviewed}),
    OrderStatus.reviewed: frozenset(),
    OrderStatus.canceled: frozenset(),
    OrderStatus.disputed: frozenset({OrderStatus.refunded_credit, OrderStatus.completed}),
    OrderStatus.refunded_credit: frozenset(),
}


def validate_order_status_transition(
    current: str | OrderStatus,
    target: str | OrderStatus,
) -> OrderStatus:
    current_status = OrderStatus(current)
    target_status = OrderStatus(target)
    if target_status not in ALLOWED_TRANSITIONS[current_status]:
        raise ValueError(f"Cannot transition order from {current_status} to {target_status}")
    return target_status


class OrderItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    profile_id: str
    hotdog_name: str
    vendor_name: str
    base_price_dollars: float = Field(ge=0)
    add_ons: list[OrderAddOn]
    total_dollars: float = Field(ge=0)
    status: OrderStatus
    created_at: datetime


class OrderResponse(BaseModel):
    order: OrderItem


class OrderListResponse(BaseModel):
    orders: list[OrderItem]


class VendorSubmissionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=80)
    style: str = Field(min_length=1, max_length=120)
    category: str = Field(default="hotdog", min_length=1, max_length=32)
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


class CreditAccount(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: str
    lifetime_purchased: int = Field(ge=0)
    lifetime_earned: int = Field(ge=0)
    lifetime_spent: int = Field(ge=0)
    created_at: datetime
    updated_at: datetime

    @computed_field  # type: ignore[prop-decorator]
    @property
    def balance(self) -> int:
        return self.lifetime_purchased + self.lifetime_earned - self.lifetime_spent


class WalletResponse(BaseModel):
    account: CreditAccount


class ReviewDirection(StrEnum):
    giver_reviews_receiver = "giver_reviews_receiver"
    receiver_reviews_giver = "receiver_reviews_giver"


class Review(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    order_id: str
    rater_user_id: str
    ratee_user_id: str
    direction: ReviewDirection
    rating: int = Field(ge=1, le=5)
    text: str | None = None
    created_at: datetime


class ReviewCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    order_id: str = Field(min_length=1, max_length=64)
    ratee_user_id: str = Field(min_length=1, max_length=128)
    direction: ReviewDirection
    rating: int = Field(ge=1, le=5)
    text: str | None = Field(default=None, max_length=2000)


class ReviewResponse(BaseModel):
    review: Review
