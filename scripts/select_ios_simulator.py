#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import asdict, dataclass


PREFERRED_NAMES = (
    "iPhone 17 Pro",
    "iPhone 17",
    "iPhone 16 Pro",
    "iPhone 16",
    "iPhone 16e",
    "iPhone 15 Pro",
    "iPhone 15",
    "iPhone 14 Pro",
    "iPhone 14",
)


@dataclass(frozen=True)
class SelectedSimulator:
    udid: str
    name: str
    runtime: str


def select_simulator() -> SelectedSimulator:
    data = json.loads(
        subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "--json"],
            text=True,
        )
    )
    devices: list[tuple[str, dict[str, object]]] = []
    for runtime, runtime_devices in data["devices"].items():
        for device in runtime_devices:
            if device.get("isAvailable") and str(device.get("name", "")).startswith("iPhone"):
                devices.append((runtime, device))

    if not devices:
        raise SystemExit("No available iPhone simulators found")

    devices.sort(key=lambda item: runtime_version(item[0]), reverse=True)
    selected = None
    for name in PREFERRED_NAMES:
        selected = next((item for item in devices if item[1]["name"] == name), None)
        if selected:
            break
    if selected is None:
        selected = next((item for item in devices if "SE" not in str(item[1]["name"])), devices[0])

    runtime, device = selected
    return SelectedSimulator(
        udid=str(device["udid"]),
        name=str(device["name"]),
        runtime=runtime,
    )


def runtime_version(runtime: str) -> tuple[int, ...]:
    match = re.search(r"iOS-(\d+(?:-\d+)*)$", runtime)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("-"))


def main() -> None:
    parser = argparse.ArgumentParser(description="Select a stable available iPhone simulator.")
    parser.add_argument("--json", action="store_true", help="Print the selected simulator as JSON.")
    args = parser.parse_args()

    selected = select_simulator()
    if args.json:
        print(json.dumps(asdict(selected), sort_keys=True))
        return
    print(f"{selected.udid}|{selected.name}|{selected.runtime}", end="")


if __name__ == "__main__":
    main()
