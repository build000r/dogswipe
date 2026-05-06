#!/usr/bin/env python3
"""Verify the public SPAPS app descriptor stays non-secret and release-aligned."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "spaps.app.json"

EXPECTED_ENV_KEYS = {
    "application_id_env": "SPAPS_APPLICATION_ID",
    "server_secret_key_env": "SPAPS_API_KEY",
    "publishable_key_env": "DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY",
}
SECRET_VALUE_PATTERNS = [
    re.compile(r"spaps_(?:pub|sec)_[A-Za-z0-9._-]+"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"ghp_[A-Za-z0-9_]+"),
    re.compile(r"sk-[A-Za-z0-9_-]+"),
]


def strings_in(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        result: list[str] = []
        for item in value.values():
            result.extend(strings_in(item))
        return result
    if isinstance(value, list):
        result = []
        for item in value:
            result.extend(strings_in(item))
        return result
    return []


def verify_contract(payload: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if payload.get("slug") != "dogswipe":
        failures.append("top-level slug must be dogswipe")
    if payload.get("template") != "ios-fastapi":
        failures.append("template must be ios-fastapi")

    spaps = payload.get("spaps")
    if not isinstance(spaps, dict):
        return ["spaps object is required"]

    local = spaps.get("local")
    if not isinstance(local, dict):
        failures.append("spaps.local object is required")
    else:
        if local.get("api_url") != "http://localhost:3301":
            failures.append("spaps.local.api_url must point at the default local SPAPS runtime")
        if local.get("local_mode_active") is not True:
            failures.append("spaps.local.local_mode_active must document local-mode development")

    production = spaps.get("production")
    if not isinstance(production, dict):
        failures.append("spaps.production object is required")
    else:
        if production.get("api_url") != "https://api.sweetpotato.dev":
            failures.append("spaps.production.api_url must point at production Sweet Potato")
        if production.get("application_slug") != "dogswipe":
            failures.append("spaps.production.application_slug must be dogswipe")

    application = spaps.get("application")
    if not isinstance(application, dict):
        failures.append("spaps.application object is required")
    else:
        if application.get("id") is not None:
            failures.append("spaps.application.id must stay null in the public repo")
        if application.get("slug") != "dogswipe":
            failures.append("spaps.application.slug must be dogswipe")
        if application.get("blueprint_key") != "browser_auth":
            failures.append("spaps.application.blueprint_key must be browser_auth")
        if application.get("blueprint_display_name") != "DogSwipe Native Mobile Auth":
            failures.append("spaps.application.blueprint_display_name must be DogSwipe Native Mobile Auth")
        for field, expected in EXPECTED_ENV_KEYS.items():
            if application.get(field) != expected:
                failures.append(f"spaps.application.{field} must be {expected}")

    auth = spaps.get("auth")
    if not isinstance(auth, dict):
        failures.append("spaps.auth object is required")
    else:
        if auth.get("native_redirect_url") != "dogswipe://auth":
            failures.append("spaps.auth.native_redirect_url must be dogswipe://auth")
        if auth.get("universal_link_redirect_url_env") != "DOGSWIPE_RELEASE_AUTH_REDIRECT_URL":
            failures.append("spaps.auth.universal_link_redirect_url_env is not release-aligned")
        if auth.get("universal_link_hosts_env") != "DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS":
            failures.append("spaps.auth.universal_link_hosts_env is not release-aligned")
        paths = auth.get("aasa_paths")
        if not isinstance(paths, list):
            failures.append("spaps.auth.aasa_paths must be a list")
        else:
            for path in ["/auth", "/auth/callback"]:
                if path not in paths:
                    failures.append(f"spaps.auth.aasa_paths missing {path}")

    for value in strings_in(payload):
        for pattern in SECRET_VALUE_PATTERNS:
            if pattern.search(value):
                failures.append("spaps.app.json must not contain raw SPAPS/API secrets")
                return failures
    return failures


def main() -> int:
    if not CONTRACT_PATH.exists():
        print("spaps.app.json is missing", file=sys.stderr)
        return 1

    try:
        payload = json.loads(CONTRACT_PATH.read_text())
    except json.JSONDecodeError as error:
        print(f"spaps.app.json is invalid JSON: {error}", file=sys.stderr)
        return 1

    failures = verify_contract(payload)
    if failures:
        print("SPAPS app contract verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("SPAPS app contract verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
