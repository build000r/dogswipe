"""Verify backend seed data and Swift samples match the contract manifest."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST = REPO_ROOT / "fixtures" / "contract-profiles.json"
SEED_PY = REPO_ROOT / "backend" / "src" / "dogswipe_backend" / "seed.py"
SWIFT_PROFILE = REPO_ROOT / "packages" / "DogSwipeCore" / "Sources" / "DogSwipeCore" / "HotdogProfile.swift"

SHARED_FIELDS = [
    "id", "name", "style", "price_dollars", "signature_notes",
    "distance_miles", "latitude", "longitude", "vendor_name",
    "address_text", "menu_excerpt", "crave_score",
]


def load_manifest() -> list[dict[str, object]]:
    return json.loads(MANIFEST.read_text())


def extract_seed_profiles() -> list[dict[str, object]]:
    import ast
    source = SEED_PY.read_text()
    match = re.search(
        r"SAMPLE_PROFILE_ROWS.*?=\s*(\(.*?\))\s*$",
        source,
        re.DOTALL | re.MULTILINE,
    )
    if not match:
        sys.exit("Could not parse SAMPLE_PROFILE_ROWS from seed.py")
    return list(ast.literal_eval(match.group(1)))


def extract_swift_samples() -> list[dict[str, object]]:
    source = SWIFT_PROFILE.read_text()
    match = re.search(
        r"static let samples.*?\[(.*?)\n    \]",
        source,
        re.DOTALL,
    )
    if not match:
        sys.exit("Could not parse HotdogProfile.samples from HotdogProfile.swift")
    block = match.group(1)

    profiles: list[dict[str, object]] = []
    for m in re.finditer(r"HotdogProfile\((.*?)\n        \)", block, re.DOTALL):
        body = m.group(1)
        profile: dict[str, object] = {}
        for line in body.strip().split("\n"):
            line = line.strip().rstrip(",")
            if ":" not in line:
                continue
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip()
            snake = re.sub(r"([A-Z])", r"_\1", key).lower().lstrip("_")
            if snake in ("menu_highlights", "image_u_r_l", "menu_u_r_l"):
                continue
            snake = snake.replace("_u_r_l", "_url")
            if val.startswith('"') and val.endswith('"'):
                profile[snake] = val.strip('"')
            elif val == "nil":
                profile[snake] = None
            else:
                try:
                    profile[snake] = float(val) if "." in val else int(val)
                except ValueError:
                    continue
        profiles.append(profile)
    return profiles


def compare(label: str, manifest: list[dict[str, object]], actual: list[dict[str, object]]) -> int:
    errors = 0
    manifest_by_id = {str(p["id"]): p for p in manifest}
    actual_by_id = {str(p["id"]): p for p in actual}

    for pid, expected in manifest_by_id.items():
        if pid not in actual_by_id:
            print(f"  FAIL: {label} missing profile {pid}")
            errors += 1
            continue
        got = actual_by_id[pid]
        for field in SHARED_FIELDS:
            e = expected.get(field)
            g = got.get(field)
            if isinstance(e, float) and isinstance(g, (int, float)):
                if abs(e - float(g)) > 0.001:
                    print(f"  FAIL: {label} {pid}.{field}: expected {e}, got {g}")
                    errors += 1
            elif e != g:
                print(f"  FAIL: {label} {pid}.{field}: expected {e!r}, got {g!r}")
                errors += 1

    extra = set(actual_by_id) - set(manifest_by_id)
    if extra:
        print(f"  WARN: {label} has extra profiles not in manifest: {extra}")
    return errors


def main() -> None:
    manifest = load_manifest()
    print(f"Manifest: {len(manifest)} profiles")

    seed_profiles = extract_seed_profiles()
    print(f"Backend seed.py: {len(seed_profiles)} profiles")
    seed_errors = compare("seed.py", manifest, seed_profiles)

    swift_samples = extract_swift_samples()
    print(f"Swift HotdogProfile.samples: {len(swift_samples)} profiles")
    swift_errors = compare("Swift samples", manifest, swift_samples)

    total = seed_errors + swift_errors
    if total:
        print(f"\n{total} contract fixture mismatches")
        sys.exit(1)
    print("\nAll contract fixtures match manifest")


if __name__ == "__main__":
    main()
