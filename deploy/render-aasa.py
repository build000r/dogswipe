#!/usr/bin/env python3
"""Render DogSwipe's Apple app-site association file for a signed build."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEMPLATE = ROOT / "deploy" / "apple-app-site-association.template.json"
TEAM_ID_PATTERN = re.compile(r"^[A-Z0-9]{10}$")
BUNDLE_ID_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]+[A-Za-z0-9]$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--template",
        type=Path,
        default=DEFAULT_TEMPLATE,
        help="AASA JSON template with APPLE_TEAM_ID and IOS_BUNDLE_ID placeholders.",
    )
    parser.add_argument(
        "--apple-team-id",
        required=True,
        help="Apple Developer Team ID, for example ABCDE12345.",
    )
    parser.add_argument(
        "--bundle-id",
        default="com.build000r.dogswipe",
        help="iOS bundle identifier used for the signed build.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Rendered output path. Defaults to stdout.",
    )
    return parser.parse_args()


def validate_inputs(apple_team_id: str, bundle_id: str) -> list[str]:
    failures: list[str] = []
    if not TEAM_ID_PATTERN.fullmatch(apple_team_id):
        failures.append("--apple-team-id must be a 10-character Apple Team ID")
    if apple_team_id == "replace-me":
        failures.append("--apple-team-id must not be a placeholder")
    if not BUNDLE_ID_PATTERN.fullmatch(bundle_id) or ".." in bundle_id:
        failures.append("--bundle-id must be a valid reverse-DNS bundle identifier")
    return failures


def render(template_path: Path, apple_team_id: str, bundle_id: str) -> str:
    template = template_path.read_text()
    rendered = template.replace("${APPLE_TEAM_ID}", apple_team_id).replace(
        "${IOS_BUNDLE_ID}",
        bundle_id,
    )
    payload = json.loads(rendered)
    app_ids = payload.get("applinks", {}).get("details", [{}])[0].get("appIDs", [])
    expected_app_id = f"{apple_team_id}.{bundle_id}"
    if expected_app_id not in app_ids:
        raise ValueError(f"rendered AASA does not include {expected_app_id}")
    return json.dumps(payload, indent=2, sort_keys=False) + "\n"


def main() -> int:
    args = parse_args()
    failures = validate_inputs(args.apple_team_id, args.bundle_id)
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    try:
        rendered = render(args.template, args.apple_team_id, args.bundle_id)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered)
        print(f"Rendered AASA: {args.output}")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
