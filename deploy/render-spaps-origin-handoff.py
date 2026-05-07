#!/usr/bin/env python3
"""Render a no-secret SPAPS allowed-origin operator handoff."""

from __future__ import annotations

import argparse
import os
import re
import sys
from urllib.parse import urlparse, urlunparse


PLACEHOLDER_PATTERN = re.compile(r"(<[^>]+>|replace-me|example\.com)")
SECRET_PATTERNS = [
    re.compile(r"spaps_(?:pub|sec)_[A-Za-z0-9._-]+"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"ghp_[A-Za-z0-9_]+"),
    re.compile(r"sk-[A-Za-z0-9_-]+"),
]
SLUG_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
HOST_PATTERN = re.compile(
    r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r"(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$"
)


def env_value(name: str) -> str:
    return os.environ.get(name, "").strip()


def is_true(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


def default_domain(allow_placeholders: bool) -> str:
    return "dogswipe.example.com" if allow_placeholders else ""


def origin_for_url(value: str) -> str:
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError("SPAPS origin must be an absolute HTTPS URL")
    if parsed.path not in {"", "/"} or parsed.params or parsed.query or parsed.fragment:
        raise ValueError("SPAPS allowed origin must not include path, query, or fragment")
    return urlunparse((parsed.scheme, parsed.netloc.lower(), "", "", "", ""))


def origin_from_env(allow_placeholders: bool) -> str:
    explicit = env_value("DOGSWIPE_RELEASE_SPAPS_ORIGIN")
    if explicit:
        return origin_for_url(explicit)

    domain = env_value("DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN") or default_domain(
        allow_placeholders
    )
    if not domain:
        raise ValueError(
            "DOGSWIPE_RELEASE_SPAPS_ORIGIN or DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN is required"
        )
    if not HOST_PATTERN.match(domain):
        raise ValueError(f"DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN is invalid: {domain}")
    return f"https://{domain.lower()}"


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def render_handoff(slug: str, origin: str) -> str:
    slug_sql = sql_quote(slug)
    origin_sql = sql_quote(origin)
    return f"""DogSwipe SPAPS allowed-origin handoff

Review and apply this on the SPAPS production database. It only adds the
origin if it is missing and keeps existing origins intact.

Target:

  Application slug: {slug}
  Required origin:  {origin}

Read-only check:

  docker exec spaps-python-db \\
    psql -U spaps -d spaps \\
    -c "SELECT id, slug, allowed_origins FROM applications WHERE slug = {slug_sql};"

Apply:

  docker exec -i spaps-python-db psql -U spaps -d spaps <<'SQL'
BEGIN;

SELECT id, slug, allowed_origins
FROM applications
WHERE slug = {slug_sql}
FOR UPDATE;

UPDATE applications
SET allowed_origins = (
    SELECT ARRAY(
        SELECT DISTINCT origin
        FROM unnest(
            COALESCE(allowed_origins, ARRAY[]::text[])
            || ARRAY[{origin_sql}]::text[]
        ) AS origin
        ORDER BY origin
    )
),
updated_at = now()
WHERE slug = {slug_sql}
  AND NOT ({origin_sql} = ANY(COALESCE(allowed_origins, ARRAY[]::text[])))
RETURNING id, slug, allowed_origins;

SELECT id, slug, allowed_origins
FROM applications
WHERE slug = {slug_sql};

COMMIT;
SQL

After apply, rerun release readiness with the same release origin:

  DOGSWIPE_RELEASE_SPAPS_ORIGIN={origin} \\
  make deploy-release-readiness
"""


def validate_output(output: str, allow_placeholders: bool) -> list[str]:
    failures: list[str] = []
    for pattern in SECRET_PATTERNS:
        if pattern.search(output):
            failures.append("handoff output must not contain raw secrets")
            return failures
    if not allow_placeholders and PLACEHOLDER_PATTERN.search(output):
        failures.append("handoff output must not contain placeholder values")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate the rendered handoff without printing it",
    )
    args = parser.parse_args()

    allow_placeholders = is_true(env_value("ALLOW_PLACEHOLDERS"))
    slug = env_value("SPAPS_APPLICATION_SLUG") or "dogswipe"
    if not SLUG_PATTERN.match(slug):
        print(f"SPAPS_APPLICATION_SLUG is invalid: {slug}", file=sys.stderr)
        return 1

    try:
        origin = origin_from_env(allow_placeholders)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1

    output = render_handoff(slug, origin)
    failures = validate_output(output, allow_placeholders)
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1

    if args.check:
        print("SPAPS origin handoff verified.")
    else:
        print(output, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
