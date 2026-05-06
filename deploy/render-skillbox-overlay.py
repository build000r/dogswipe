#!/usr/bin/env python3
"""Render a private DogSwipe skillbox overlay without embedding app secrets."""

from __future__ import annotations

import argparse
import os
import re
import stat
import sys
from pathlib import Path


PLACEHOLDER_PATTERN = re.compile(r"(<[^>]+>|replace-me|example\.com)")
DOMAIN_PATTERN = re.compile(r"^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
TEAM_PATTERN = re.compile(r"^[A-Z0-9]{10}$")


def env_value(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def is_true(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


def release_domain() -> str:
    return env_value("DOGSWIPE_API_DOMAIN") or env_value("DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN")


def require_value(name: str, default: str = "") -> str:
    value = env_value(name, default)
    if not value:
        raise ValueError(f"{name} is required")
    if "\n" in value or "\r" in value:
        raise ValueError(f"{name} must not contain newlines")
    return value


def build_overlay() -> dict[str, str]:
    domain = release_domain()
    if not domain:
        raise ValueError("DOGSWIPE_API_DOMAIN or DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN is required")

    return {
        "droplet_ssh": require_value("DOGSWIPE_DEPLOY_SSH"),
        "droplet_ip": require_value("DOGSWIPE_DEPLOY_IP"),
        "ssh_key": env_value("DOGSWIPE_DEPLOY_SSH_KEY", "tailscale"),
        "reverse_proxy_root": env_value(
            "DOGSWIPE_REVERSE_PROXY_ROOT", "/opt/sweet-potato/deploy/reverse-proxy"
        ),
        "storage_root": env_value("DOGSWIPE_STORAGE_ROOT", "/mnt/volume_nyc3_cfo_v1"),
        "repo_root": env_value("DOGSWIPE_REPO_ROOT", "~/repos/dogswipe"),
        "deploy_root": env_value("DOGSWIPE_DEPLOY_ROOT", "/opt/dogswipe"),
        "env_file": env_value("DOGSWIPE_ENV_FILE", "/opt/envs/dogswipe/prod.env"),
        "domain": domain,
        "apple_team_id": require_value(
            "IOS_RELEASE_DEVELOPMENT_TEAM", env_value("AASA_APPLE_TEAM_ID")
        ),
    }


def validate_overlay(values: dict[str, str], allow_placeholders: bool) -> list[str]:
    failures: list[str] = []
    for key, value in values.items():
        if not value:
            failures.append(f"{key} is required")
        if not allow_placeholders and PLACEHOLDER_PATTERN.search(value):
            failures.append(f"{key} must not use placeholder values")

    if not DOMAIN_PATTERN.match(values["domain"]):
        failures.append("domain must be a DNS hostname")
    if not TEAM_PATTERN.match(values["apple_team_id"]):
        failures.append("apple_team_id must be a 10-character Apple Developer Team ID")
    if "@" not in values["droplet_ssh"]:
        failures.append("droplet_ssh must look like user@host")
    if not values["deploy_root"].startswith("/"):
        failures.append("deploy_root must be an absolute remote path")
    if not values["env_file"].startswith("/"):
        failures.append("env_file must be an absolute remote path")
    return failures


def render_overlay(values: dict[str, str]) -> str:
    domain = values["domain"]
    return f"""version: 1
client:
  id: dogswipe
  label: DogSwipe
  default_cwd: ~/repos/dogswipe
  repos: []
  logs: []
  context:
    cwd_match:
      - ~/repos/dogswipe

    deploy:
      droplet_ssh: {values["droplet_ssh"]}
      droplet_ip: {values["droplet_ip"]}
      ssh_key: {values["ssh_key"]}
      reverse_proxy_root: {values["reverse_proxy_root"]}
      storage_root: {values["storage_root"]}

      services:
        dogswipe_api:
          repo_root: {values["repo_root"]}
          mode_name: dogswipe
          surface: docker_compose
          repo_slug: build000r/dogswipe
          deploy_root: {values["deploy_root"]}
          compose_file: deploy/docker-compose.prod.yml
          compose_project: dogswipe
          compose_service: api
          domain: {domain}
          production_domain: https://{domain}
          health_url: https://{domain}/health
          aasa_url: https://{domain}/.well-known/apple-app-site-association
          apple_team_id: {values["apple_team_id"]}
          env_file: {values["env_file"]}
          ci_workflow: .github/workflows/ci.yml

  checks:
    - id: dogswipe-repo-root
      type: path_exists
      path: ~/repos/dogswipe
      required: true
      profiles:
        - core
      notes: DogSwipe repo must be mounted or cloned before deploy operations.
"""


def write_private_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    path.chmod(stat.S_IRUSR | stat.S_IWUSR)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render the private DogSwipe skillbox overlay from environment values."
    )
    parser.add_argument("--output", type=Path, help="private overlay output path")
    parser.add_argument(
        "--allow-placeholders",
        action="store_true",
        default=is_true(env_value("ALLOW_PLACEHOLDERS")),
        help="allow example values for template validation only",
    )
    parser.add_argument("--check", action="store_true", help="validate without writing")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        values = build_overlay()
    except ValueError as error:
        print(f"DogSwipe skillbox overlay render failed: {error}", file=sys.stderr)
        return 1

    failures = validate_overlay(values, args.allow_placeholders)
    if failures:
        print("DogSwipe skillbox overlay verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    if args.check:
        return 0
    if args.output is None:
        print("--output is required unless --check is used", file=sys.stderr)
        return 1
    if str(args.output) == "-":
        print("refusing to print private overlay to stdout", file=sys.stderr)
        return 1

    write_private_file(args.output, render_overlay(values))
    print(f"Wrote DogSwipe skillbox overlay: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
