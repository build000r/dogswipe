#!/usr/bin/env python3
"""Verify iOS release-facing assets without depending on Xcode."""

from __future__ import annotations

import json
import plistlib
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT / "apps" / "ios" / "DogSwipe" / "DogSwipe"
PROJECT_YML = ROOT / "apps" / "ios" / "DogSwipe" / "project.yml"
APP_ICON_SET = APP_ROOT / "Assets.xcassets" / "AppIcon.appiconset"
PRIVACY_MANIFEST = APP_ROOT / "PrivacyInfo.xcprivacy"
ENTITLEMENTS = APP_ROOT / "DogSwipe.entitlements"
AASA_TEMPLATE = ROOT / "deploy" / "apple-app-site-association.template.json"


def png_info(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        header = handle.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"{path} is not a PNG with an IHDR header")
    width, height = struct.unpack(">II", header[16:24])
    color_type = header[25]
    return width, height, color_type


def expected_pixels(size: str, scale: str) -> int:
    points = float(size.split("x", maxsplit=1)[0])
    multiplier = int(scale.removesuffix("x"))
    return round(points * multiplier)


def verify_app_icons() -> list[str]:
    failures: list[str] = []
    contents = json.loads((APP_ICON_SET / "Contents.json").read_text())
    images = contents.get("images", [])
    if not images:
        return ["AppIcon.appiconset has no image entries"]

    seen: set[tuple[str, str, str]] = set()
    for image in images:
        filename = image.get("filename")
        idiom = image.get("idiom")
        scale = image.get("scale")
        size = image.get("size")
        if not filename or not idiom or not scale or not size:
            failures.append(f"Incomplete app icon entry: {image}")
            continue
        key = (idiom, size, scale)
        if key in seen:
            failures.append(f"Duplicate app icon entry: {key}")
        seen.add(key)

        icon_path = APP_ICON_SET / filename
        if not icon_path.exists():
            failures.append(f"Missing app icon file: {filename}")
            continue
        expected = expected_pixels(size, scale)
        width, height, color_type = png_info(icon_path)
        if (width, height) != (expected, expected):
            failures.append(f"{filename} is {width}x{height}, expected {expected}x{expected}")
        if color_type in {4, 6}:
            failures.append(f"{filename} must not include an alpha channel")

    required = {
        ("iphone", "60x60", "3x"),
        ("iphone", "60x60", "2x"),
        ("ipad", "83.5x83.5", "2x"),
        ("ios-marketing", "1024x1024", "1x"),
    }
    missing = sorted(required - seen)
    failures.extend(f"Missing required app icon slot: {item}" for item in missing)
    return failures


def verify_privacy_manifest() -> list[str]:
    failures: list[str] = []
    if not PRIVACY_MANIFEST.exists():
        return ["PrivacyInfo.xcprivacy is missing"]

    with PRIVACY_MANIFEST.open("rb") as handle:
        manifest = plistlib.load(handle)

    if manifest.get("NSPrivacyTracking") is not False:
        failures.append("NSPrivacyTracking must be false")
    if manifest.get("NSPrivacyTrackingDomains") != []:
        failures.append("NSPrivacyTrackingDomains must be empty")
    if manifest.get("NSPrivacyAccessedAPITypes") != []:
        failures.append("NSPrivacyAccessedAPITypes must be empty until required-reason APIs are used")

    collected = {
        entry.get("NSPrivacyCollectedDataType"): entry
        for entry in manifest.get("NSPrivacyCollectedDataTypes", [])
    }
    expected_types = {
        "NSPrivacyCollectedDataTypeEmailAddress",
        "NSPrivacyCollectedDataTypePreciseLocation",
    }
    missing = sorted(expected_types - set(collected))
    failures.extend(f"Missing collected data type: {data_type}" for data_type in missing)

    for data_type in expected_types & set(collected):
        entry = collected[data_type]
        if entry.get("NSPrivacyCollectedDataTypeLinked") is not True:
            failures.append(f"{data_type} should be declared as linked to the user")
        if entry.get("NSPrivacyCollectedDataTypeTracking") is not False:
            failures.append(f"{data_type} must not be used for tracking")
        if entry.get("NSPrivacyCollectedDataTypePurposes") != [
            "NSPrivacyCollectedDataTypePurposeAppFunctionality"
        ]:
            failures.append(f"{data_type} must be scoped to app functionality")
    return failures


def verify_universal_link_surface() -> list[str]:
    failures: list[str] = []
    if not ENTITLEMENTS.exists():
        failures.append("DogSwipe.entitlements is missing")
    else:
        with ENTITLEMENTS.open("rb") as handle:
            entitlements = plistlib.load(handle)
        domains = entitlements.get("com.apple.developer.associated-domains")
        if not isinstance(domains, list) or not domains:
            failures.append("Associated domains entitlement is missing")
        elif "applinks:$(DOGSWIPE_ASSOCIATED_DOMAIN)" not in domains:
            failures.append(
                "Associated domains must use applinks:$(DOGSWIPE_ASSOCIATED_DOMAIN)"
            )

    if not PROJECT_YML.exists():
        failures.append("project.yml is missing")
    else:
        project_text = PROJECT_YML.read_text()
        required_project_values = [
            "CODE_SIGN_ENTITLEMENTS: DogSwipe/DogSwipe.entitlements",
            "DOGSWIPE_ASSOCIATED_DOMAIN:",
            "DOGSWIPE_AUTH_REDIRECT_URL:",
            "DOGSWIPE_AUTH_UNIVERSAL_LINK_HOSTS:",
        ]
        for value in required_project_values:
            if value not in project_text:
                failures.append(f"project.yml missing {value}")

    if not AASA_TEMPLATE.exists():
        failures.append("Apple app-site association template is missing")
    else:
        try:
            aasa = json.loads(AASA_TEMPLATE.read_text())
        except json.JSONDecodeError as error:
            failures.append(f"Apple app-site association template is invalid JSON: {error}")
        else:
            details = aasa.get("applinks", {}).get("details", [])
            if not details:
                failures.append("Apple app-site association template has no applinks details")
            else:
                app_ids = details[0].get("appIDs", [])
                if "${APPLE_TEAM_ID}.com.build000r.dogswipe" not in app_ids:
                    failures.append("Apple app-site association template has the wrong app ID")
                components = details[0].get("components", [])
                paths = {
                    component.get("/")
                    for component in components
                    if isinstance(component, dict)
                }
                for path in ["/auth", "/auth/callback"]:
                    if path not in paths:
                        failures.append(
                            f"Apple app-site association template missing path: {path}"
                        )
    return failures


def main() -> int:
    failures = verify_app_icons() + verify_privacy_manifest() + verify_universal_link_surface()
    if failures:
        print("iOS release asset verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print("iOS release assets verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
