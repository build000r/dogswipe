#!/usr/bin/env python3
"""Render a private DogSwipe production env file without printing secrets."""

from __future__ import annotations

import argparse
import os
import re
import stat
import sys
from collections.abc import Mapping
from pathlib import Path
from urllib.parse import quote, urlparse


PLACEHOLDER_PATTERN = re.compile(r"(<[^>]+>|replace-me|example\.com|spaps_pub_example)")
UUID_PATTERN = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
SECRET_KEYS = {"POSTGRES_PASSWORD", "SPAPS_API_KEY"}


def env_value(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def is_true(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


def domain_from_env() -> str:
    return env_value("DOGSWIPE_API_DOMAIN") or env_value("DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN")


def default_database_url(user: str, password: str, db_name: str) -> str:
    encoded_user = quote(user, safe="")
    encoded_password = quote(password, safe="")
    return f"postgresql+asyncpg://{encoded_user}:{encoded_password}@postgres:5432/{db_name}"


def build_env(allow_placeholders: bool) -> dict[str, str]:
    domain = domain_from_env()
    postgres_user = env_value("POSTGRES_USER", "postgres")
    postgres_password = require_env("POSTGRES_PASSWORD")
    postgres_db = env_value("POSTGRES_DB", "dogswipe")
    cors = env_value("CORS_ALLOW_ORIGINS") or (f"https://{domain}" if domain else "")

    return {
        "ENV": "production",
        "DEVELOPMENT_ENVIRONMENT": "production",
        "DOGSWIPE_IMAGE": require_env("DOGSWIPE_IMAGE"),
        "DOGSWIPE_ENV_FILE": env_value("DOGSWIPE_ENV_FILE", "prod.env"),
        "POSTGRES_USER": postgres_user,
        "POSTGRES_PASSWORD": postgres_password,
        "POSTGRES_DB": postgres_db,
        "DATABASE_URL": env_value("DATABASE_URL")
        or default_database_url(postgres_user, postgres_password, postgres_db),
        "REDIS_URL": env_value("REDIS_URL", "redis://redis:6379/0"),
        "CORS_ALLOW_ORIGINS": cors,
        "SPAPS_AUTH_ENABLED": env_value("SPAPS_AUTH_ENABLED", "true"),
        "SPAPS_API_URL": env_value("SPAPS_API_URL", "https://api.sweetpotato.dev"),
        "SPAPS_API_KEY": require_env("SPAPS_API_KEY"),
        "SPAPS_APPLICATION_ID": require_env("SPAPS_APPLICATION_ID"),
        "DOGSWIPE_ADMIN_USER_IDS": require_env("DOGSWIPE_ADMIN_USER_IDS"),
        "DOGSWIPE_AUTO_CREATE_SCHEMA": "false",
        "DOGSWIPE_SEED_SAMPLE_PROFILES": "false",
        "DOGSWIPE_MENU_REFRESH_ENABLED": env_value("DOGSWIPE_MENU_REFRESH_ENABLED", "false"),
        "DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS": env_value(
            "DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS", "3600"
        ),
        "DOGSWIPE_MENU_REFRESH_BATCH_SIZE": env_value("DOGSWIPE_MENU_REFRESH_BATCH_SIZE", "20"),
        "DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS": env_value(
            "DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS", "24"
        ),
    }


def require_env(name: str) -> str:
    value = env_value(name)
    if not value:
        raise ValueError(f"{name} is required")
    return value


def validate_url(label: str, value: str, scheme: str | None = None) -> list[str]:
    parsed = urlparse(value)
    if not parsed.scheme or not parsed.netloc:
        return [f"{label} must be an absolute URL"]
    if scheme and parsed.scheme != scheme:
        return [f"{label} must use {scheme}"]
    return []


def validate_env(values: Mapping[str, str], allow_placeholders: bool) -> list[str]:
    failures: list[str] = []
    for key, value in values.items():
        if not value:
            failures.append(f"{key} is required")
        if "\n" in value or "\r" in value:
            failures.append(f"{key} must not contain newlines")
        if key in SECRET_KEYS and re.search(r"\s", value):
            failures.append(f"{key} must not contain whitespace for dotenv/compose safety")
        if not allow_placeholders and PLACEHOLDER_PATTERN.search(value):
            failures.append(f"{key} must not use placeholder values")

    failures.extend(validate_url("DATABASE_URL", values["DATABASE_URL"]))
    failures.extend(validate_url("REDIS_URL", values["REDIS_URL"]))
    failures.extend(validate_url("SPAPS_API_URL", values["SPAPS_API_URL"], scheme="https"))

    for origin in values["CORS_ALLOW_ORIGINS"].split(","):
        origin = origin.strip()
        if not origin:
            continue
        failures.extend(validate_url("CORS_ALLOW_ORIGINS", origin, scheme="https"))

    auth_enabled = values["SPAPS_AUTH_ENABLED"].lower()
    if auth_enabled not in {"true", "1"}:
        failures.append("SPAPS_AUTH_ENABLED must stay true for production")
    if not allow_placeholders and not UUID_PATTERN.match(values["SPAPS_APPLICATION_ID"]):
        failures.append("SPAPS_APPLICATION_ID must be a UUID")

    for flag in ["DOGSWIPE_AUTO_CREATE_SCHEMA", "DOGSWIPE_SEED_SAMPLE_PROFILES"]:
        if values[flag].lower() not in {"false", "0"}:
            failures.append(f"{flag} must stay false in production")

    for key in [
        "DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS",
        "DOGSWIPE_MENU_REFRESH_BATCH_SIZE",
        "DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS",
    ]:
        if not values[key].isdigit() or int(values[key]) <= 0:
            failures.append(f"{key} must be a positive integer")

    return failures


def render_env(values: Mapping[str, str]) -> str:
    return "".join(f"{key}={value}\n" for key, value in values.items())


def write_secret_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    path.chmod(stat.S_IRUSR | stat.S_IWUSR)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render the private DogSwipe production env file from environment values."
    )
    parser.add_argument("--output", type=Path, help="private env output path")
    parser.add_argument(
        "--allow-placeholders",
        action="store_true",
        default=is_true(env_value("ALLOW_PLACEHOLDERS")),
        help="allow placeholder values for template validation only",
    )
    parser.add_argument("--check", action="store_true", help="validate without writing")
    parser.add_argument(
        "--print-redacted",
        action="store_true",
        help="print key names with redacted values after validation",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        values = build_env(args.allow_placeholders)
    except ValueError as error:
        print(f"DogSwipe production env render failed: {error}", file=sys.stderr)
        return 1

    failures = validate_env(values, args.allow_placeholders)
    if failures:
        print("DogSwipe production env verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    if args.print_redacted:
        for key in values:
            print(f"{key}=<redacted>")

    if args.check:
        return 0
    if args.output is None:
        print("--output is required unless --check is used", file=sys.stderr)
        return 1
    if str(args.output) == "-":
        print("refusing to print production env secrets to stdout", file=sys.stderr)
        return 1

    write_secret_file(args.output, render_env(values))
    print(f"Wrote DogSwipe production env: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
