from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field


class SwipeDecision(StrEnum):
    like = "like"
    reject = "pass"
    super_like = "super_like"


class DogProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    breed: str
    age_years: float = Field(ge=0)
    temperament: str
    distance_miles: float = Field(ge=0)
    shelter_name: str
    image_url: str | None = None
    compatibility_score: float = Field(ge=0, le=1)
    adoption_status: str


class DiscoveryResponse(BaseModel):
    profiles: list[DogProfile]


class SwipeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    profile_id: str = Field(min_length=1, max_length=64)
    decision: SwipeDecision


class SwipeResponse(BaseModel):
    profile_id: str
    decision: SwipeDecision
    matched: bool


class MatchResponse(BaseModel):
    matches: list[DogProfile]
