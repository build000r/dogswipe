#!/usr/bin/env python3
from __future__ import annotations

import argparse
import platform
import shutil
import subprocess
from pathlib import Path

from select_ios_simulator import select_simulator


REPO_ROOT = Path(__file__).resolve().parents[1]
PROJECT_PATH = REPO_ROOT / "apps/ios/DogSwipe/DogSwipe.xcodeproj"
DEFAULT_OUTPUT_DIR = REPO_ROOT / ".build/ios-screenshots"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run the deterministic iOS UI smoke test and export kept screenshots."
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory for the xcresult bundle and exported attachments.",
    )
    parser.add_argument(
        "--skip-export",
        action="store_true",
        help="Run the UI smoke test without exporting screenshot attachments.",
    )
    args = parser.parse_args()

    selected = select_simulator()
    print(f"Selected iOS simulator: {selected.name} ({selected.udid}) on {selected.runtime}")
    subprocess.run(["xcrun", "simctl", "boot", selected.udid], check=False)
    subprocess.run(["xcrun", "simctl", "bootstatus", selected.udid, "-b"], check=True)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    result_bundle = args.output_dir / "DogSwipeScreenshots.xcresult"
    attachments_dir = args.output_dir / "attachments"
    if result_bundle.exists():
        shutil.rmtree(result_bundle)
    if attachments_dir.exists():
        shutil.rmtree(attachments_dir)

    destination = f"platform=iOS Simulator,id={selected.udid}"
    if platform.machine() == "arm64":
        destination += ",arch=arm64"

    command = [
        "xcodebuild",
        "-quiet",
        "-destination-timeout",
        "120",
        "-parallel-testing-enabled",
        "NO",
        "-test-timeouts-enabled",
        "YES",
        "-default-test-execution-time-allowance",
        "45",
        "-maximum-test-execution-time-allowance",
        "90",
        "-project",
        str(PROJECT_PATH),
        "-scheme",
        "DogSwipe",
        "-destination",
        destination,
        "-only-testing:DogSwipeUITests/DogSwipeScreenshotUITests",
        "-resultBundlePath",
        str(result_bundle),
        "test",
    ]
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError:
        print("xcodebuild failed; xcresult summary follows.")
        subprocess.run(
            [
                "xcrun",
                "xcresulttool",
                "get",
                "test-results",
                "summary",
                "--path",
                str(result_bundle),
            ],
            check=False,
        )
        subprocess.run(
            [
                "xcrun",
                "xcresulttool",
                "get",
                "test-results",
                "tests",
                "--path",
                str(result_bundle),
                "--compact",
            ],
            check=False,
        )
        raise

    if args.skip_export:
        print(f"UI smoke result bundle: {result_bundle}")
        return

    subprocess.run(
        [
            "xcrun",
            "xcresulttool",
            "export",
            "attachments",
            "--path",
            str(result_bundle),
            "--output-path",
            str(attachments_dir),
        ],
        check=True,
    )
    print(f"Exported screenshot attachments: {attachments_dir}")


if __name__ == "__main__":
    main()
