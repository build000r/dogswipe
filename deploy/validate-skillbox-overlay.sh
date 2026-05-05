#!/usr/bin/env bash
set -euo pipefail

overlay_file="${1:-deploy/skillbox-overlay.example.yaml}"
allow_placeholders="${ALLOW_PLACEHOLDERS:-false}"

if [[ "${2:-}" == "--allow-placeholders" ]]; then
  allow_placeholders=true
fi

passed=0
failed=0

pass() {
  echo "PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "FAIL: $1" >&2
  failed=$((failed + 1))
}

require_pattern() {
  local label="$1"
  local pattern="$2"
  if grep -Eq "$pattern" "$overlay_file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "Validating DogSwipe skillbox overlay: $overlay_file"

if [[ -f "$overlay_file" ]]; then
  pass "overlay file exists"
else
  fail "overlay file exists"
  echo "Overlay validation summary: $passed passed, $failed failed"
  exit 1
fi

require_pattern "client id is dogswipe" '^[[:space:]]*id:[[:space:]]*dogswipe[[:space:]]*$'
require_pattern "cwd match includes dogswipe repo" '^[[:space:]]*-[[:space:]]*(~|/).*/dogswipe[[:space:]]*$'
require_pattern "deploy service exists" '^[[:space:]]*dogswipe_api:[[:space:]]*$'
require_pattern "surface is docker compose" '^[[:space:]]*surface:[[:space:]]*docker_compose[[:space:]]*$'
require_pattern "repo slug is public DogSwipe repo" '^[[:space:]]*repo_slug:[[:space:]]*build000r/dogswipe[[:space:]]*$'
require_pattern "compose file points at production compose" '^[[:space:]]*compose_file:[[:space:]]*deploy/docker-compose\.prod\.yml[[:space:]]*$'
require_pattern "compose project is dogswipe" '^[[:space:]]*compose_project:[[:space:]]*dogswipe[[:space:]]*$'
require_pattern "compose service is api" '^[[:space:]]*compose_service:[[:space:]]*api[[:space:]]*$'
require_pattern "health URL is present" '^[[:space:]]*health_url:[[:space:]]*https://[^[:space:]]+/health[[:space:]]*$'
require_pattern "env file is present" '^[[:space:]]*env_file:[[:space:]]*[^[:space:]]+prod\.env[[:space:]]*$'
require_pattern "CI workflow is present" '^[[:space:]]*ci_workflow:[[:space:]]*\.github/workflows/ci\.yml[[:space:]]*$'

if [[ "$allow_placeholders" == "true" ]]; then
  pass "placeholder values allowed for template validation"
else
  if grep -Eq 'replace-me|example\.com' "$overlay_file"; then
    fail "live overlay has no placeholder host/domain values"
  else
    pass "live overlay has no placeholder host/domain values"
  fi
fi

echo "Overlay validation summary: $passed passed, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
