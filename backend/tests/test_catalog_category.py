from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_discovery_profiles_include_default_hotdog_category(async_client) -> None:
    response = await async_client.get("/v1/discovery")

    assert response.status_code == 200
    profiles = response.json()["profiles"]
    assert profiles
    assert all(profile["category"] == "hotdog" for profile in profiles)
