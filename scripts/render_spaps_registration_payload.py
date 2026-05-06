#!/usr/bin/env python3
"""Render the non-secret SPAPS application registration payload."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse, urlunparse


ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "spaps.app.json"

SECRET_VALUE_PATTERNS = [
    re.compile(r"spaps_(?:pub|sec)_[A-Za-z0-9._-]+"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"ghp_[A-Za-z0-9_]+"),
    re.compile(r"sk-[A-Za-z0-9_-]+"),
]
PLACEHOLDER_PATTERN = re.compile(r"(<[^>]+>|replace-me|example\.com|spaps_pub_example)")
HOST_PATTERN = re.compile(r"^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")


def env_value(name: str) -> str:
    return os.environ.get(name, "").strip()


def is_true(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


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


def load_contract() -> dict[str, Any]:
    with CONTRACT_PATH.open() as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError("spaps.app.json must be a JSON object")
    return payload


def https_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def origin_for(url: str) -> str:
    parsed = urlparse(url)
    return urlunparse((parsed.scheme, parsed.netloc, "", "", "", ""))


def dedupe(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        result.append(value)
    return result


def host_list(value: str) -> list[str]:
    return [item.strip().lower() for item in value.split(",") if item.strip()]


def default_domain(allow_placeholders: bool) -> str:
    return "dogswipe.example.com" if allow_placeholders else ""


def build_payload(contract: dict[str, Any], allow_placeholders: bool) -> dict[str, Any]:
    spaps = contract.get("spaps")
    if not isinstance(spaps, dict):
        raise ValueError("spaps.app.json must define spaps")
    application = spaps.get("application")
    auth = spaps.get("auth")
    if not isinstance(application, dict) or not isinstance(auth, dict):
        raise ValueError("spaps.app.json must define spaps.application and spaps.auth")

    associated_domain = (
        env_value("DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN")
        or default_domain(allow_placeholders)
    )
    release_origin = (
        env_value("DOGSWIPE_RELEASE_SPAPS_ORIGIN")
        or (f"https://{associated_domain}" if associated_domain else "")
    )
    redirect_url = (
        env_value("DOGSWIPE_RELEASE_AUTH_REDIRECT_URL")
        or (f"https://{associated_domain}/auth" if associated_domain else "")
    )
    universal_hosts = (
        env_value("DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS")
        or associated_domain
    )
    bundle_id = env_value("IOS_RELEASE_BUNDLE_ID") or "com.build000r.dogswipe"
    hosts = host_list(universal_hosts)

    allowed_origins = [release_origin]
    if redirect_url:
        allowed_origins.append(origin_for(redirect_url))

    slug = str(application.get("slug") or contract.get("slug") or "dogswipe")
    name = str(contract.get("name") or "DogSwipe")
    blueprint_key = str(application.get("blueprint_key") or "browser_auth")
    native_redirect = str(auth.get("native_redirect_url") or "dogswipe://auth")
    aasa_paths = auth.get("aasa_paths")
    if not isinstance(aasa_paths, list):
        aasa_paths = ["/auth", "/auth/callback"]

    return {
        "name": name,
        "slug": slug,
        "description": "Swipe-first local hotdog discovery app for native iOS.",
        "allowed_origins": dedupe([value for value in allowed_origins if value]),
        "settings": {
            "email_redirect_url": redirect_url,
            "magic_link_redirect_url": redirect_url,
            "password_reset_redirect_url": redirect_url,
            "dogswipe": {
                "ios_bundle_id": bundle_id,
                "native_redirect_url": native_redirect,
                "universal_link_redirect_url": redirect_url,
                "universal_link_hosts": hosts,
                "aasa_paths": aasa_paths,
                "release_origin": release_origin,
            },
        },
        "blueprint_key": blueprint_key,
        "blueprint": {
            "name": application.get("blueprint_display_name")
            or "DogSwipe Native Mobile Auth",
            "description": "Browser-auth SPAPS blueprint constrained for DogSwipe native iOS magic-link auth.",
            "settings": {
                "dogswipe_native_ios_auth": True,
            },
        },
    }


def validate_payload(payload: dict[str, Any], allow_placeholders: bool) -> list[str]:
    failures: list[str] = []
    if payload.get("slug") != "dogswipe":
        failures.append("registration slug must be dogswipe")
    if payload.get("blueprint_key") != "browser_auth":
        failures.append("registration blueprint_key must be browser_auth")

    allowed_origins = payload.get("allowed_origins")
    if not isinstance(allowed_origins, list) or not allowed_origins:
        failures.append("allowed_origins must contain the release origin")
    else:
        for origin in allowed_origins:
            if not isinstance(origin, str) or not https_url(origin):
                failures.append("allowed_origins must be HTTPS origins")

    settings = payload.get("settings")
    if not isinstance(settings, dict):
        failures.append("settings object is required")
        settings = {}

    redirect_url = settings.get("magic_link_redirect_url")
    if not isinstance(redirect_url, str) or not https_url(redirect_url):
        failures.append("magic_link_redirect_url must be an absolute HTTPS URL")
        redirect_host = None
    else:
        redirect_host = urlparse(redirect_url).hostname

    dogswipe = settings.get("dogswipe")
    if not isinstance(dogswipe, dict):
        failures.append("settings.dogswipe object is required")
        dogswipe = {}

    hosts = dogswipe.get("universal_link_hosts")
    if not isinstance(hosts, list) or not hosts:
        failures.append("settings.dogswipe.universal_link_hosts must be non-empty")
    else:
        for host in hosts:
            if not isinstance(host, str) or not HOST_PATTERN.match(host):
                failures.append("universal-link hosts must be DNS hostnames")
        if redirect_host and redirect_host.lower() not in set(hosts):
            failures.append("magic-link redirect host must be listed as a universal-link host")

    if dogswipe.get("native_redirect_url") != "dogswipe://auth":
        failures.append("native redirect URL must be dogswipe://auth")

    paths = dogswipe.get("aasa_paths")
    if not isinstance(paths, list) or "/auth" not in paths or "/auth/callback" not in paths:
        failures.append("AASA paths must include /auth and /auth/callback")

    for value in strings_in(payload):
        for pattern in SECRET_VALUE_PATTERNS:
            if pattern.search(value):
                failures.append("registration payload must not contain raw SPAPS/API secrets")
                return failures
        if not allow_placeholders and PLACEHOLDER_PATTERN.search(value):
            failures.append("registration payload must not contain placeholder values")
            return failures

    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render the SPAPS self-service application payload for DogSwipe."
    )
    parser.add_argument(
        "--allow-placeholders",
        action="store_true",
        default=is_true(env_value("ALLOW_PLACEHOLDERS")),
        help="allow example domains for public template/CI validation",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate the rendered payload without printing it",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        payload = build_payload(load_contract(), args.allow_placeholders)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"SPAPS registration payload render failed: {error}", file=sys.stderr)
        return 1

    failures = validate_payload(payload, args.allow_placeholders)
    if failures:
        print("SPAPS registration payload verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    if not args.check:
        print(json.dumps(payload, indent=2, sort_keys=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
