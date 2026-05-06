#!/usr/bin/env bash
set -euo pipefail

overlay_file="${1:-deploy/skillbox-overlay.example.yaml}"
allow_placeholders="${ALLOW_PLACEHOLDERS:-false}"
check_asc_key="${CHECK_ASC_KEY:-false}"
check_dns="${CHECK_DNS:-false}"

passed=0
failed=0
skipped=0

pass() {
  echo "PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "FAIL: $1" >&2
  failed=$((failed + 1))
}

skip() {
  echo "SKIP: $1"
  skipped=$((skipped + 1))
}

env_value() {
  local name="$1"
  printf '%s' "${!name:-}"
}

require_env() {
  local label="$1"
  local name="$2"
  if [[ -n "$(env_value "$name")" ]]; then
    pass "$label is set"
  else
    fail "$label is required"
  fi
}

require_pattern() {
  local label="$1"
  local name="$2"
  local pattern="$3"
  local value
  value="$(env_value "$name")"
  if [[ -z "$value" ]]; then
    fail "$label is required"
  elif [[ "$value" =~ $pattern ]]; then
    pass "$label has valid shape"
  else
    fail "$label has invalid shape"
  fi
}

require_not_placeholder() {
  local label="$1"
  local name="$2"
  local value
  value="$(env_value "$name")"
  if [[ "$allow_placeholders" == "true" ]]; then
    pass "$label placeholder check skipped for template mode"
  elif [[ "$value" =~ replace-me|example\.com|spaps_pub_example ]]; then
    fail "$label must not use placeholder values"
  else
    pass "$label is not a placeholder"
  fi
}

require_file() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    pass "$label exists"
  else
    fail "$label is missing"
  fi
}

echo "Running DogSwipe release readiness"

if [[ "$allow_placeholders" == "true" ]]; then
  if bash deploy/validate-skillbox-overlay.sh "$overlay_file" --allow-placeholders; then
    pass "skillbox overlay template validates"
  else
    fail "skillbox overlay template validation failed"
  fi
else
  if bash deploy/validate-skillbox-overlay.sh "$overlay_file"; then
    pass "live skillbox overlay validates"
  else
    fail "live skillbox overlay validation failed"
  fi
fi

if python3 scripts/verify_spaps_app_contract.py >/dev/null; then
  pass "SPAPS app contract verifies"
else
  fail "SPAPS app contract verification failed"
fi

if python3 scripts/render_spaps_registration_payload.py --check >/dev/null; then
  pass "SPAPS registration payload renders"
else
  fail "SPAPS registration payload render failed"
fi

require_pattern "Apple Developer Team ID" IOS_RELEASE_DEVELOPMENT_TEAM '^[A-Z0-9]{10}$'
require_pattern "iOS release bundle ID" IOS_RELEASE_BUNDLE_ID '^[A-Za-z0-9][A-Za-z0-9.-]+[A-Za-z0-9]$'
require_pattern "DogSwipe API base URL" DOGSWIPE_RELEASE_API_BASE_URL '^https://[^[:space:]]+$'
require_pattern "associated domain" DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
require_pattern "SPAPS API base URL" DOGSWIPE_RELEASE_SPAPS_API_BASE_URL '^https://[^[:space:]]+$'
require_pattern "SPAPS publishable key" DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY '^spaps_pub_[A-Za-z0-9._-]+$'
require_pattern "SPAPS origin" DOGSWIPE_RELEASE_SPAPS_ORIGIN '^https://[^[:space:]]+$'
require_pattern "auth redirect URL" DOGSWIPE_RELEASE_AUTH_REDIRECT_URL '^https://[^[:space:]]+$'
require_pattern "auth universal link hosts" DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS '^[A-Za-z0-9.,-]+$'

require_not_placeholder "DogSwipe API base URL" DOGSWIPE_RELEASE_API_BASE_URL
require_not_placeholder "associated domain" DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN
require_not_placeholder "SPAPS publishable key" DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY

if [[ "$(env_value IOS_RELEASE_BUNDLE_ID)" == *..* ]]; then
  fail "iOS release bundle ID must not contain empty labels"
else
  pass "iOS release bundle ID labels are non-empty"
fi

if python3 - \
  "$(env_value DOGSWIPE_RELEASE_AUTH_REDIRECT_URL)" \
  "$(env_value DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS)" <<'PY'
import sys
from urllib.parse import urlparse

redirect_url, hosts_csv = sys.argv[1:]
host = urlparse(redirect_url).hostname
hosts = {item.strip() for item in hosts_csv.split(",") if item.strip()}
if not host or host not in hosts:
    raise SystemExit(1)
PY
then
  pass "auth redirect host is allowed as a universal-link host"
else
  fail "auth redirect host must be listed in DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS"
fi

aasa_payload="$(mktemp)"
trap 'rm -f "$aasa_payload"' EXIT
if python3 deploy/render-aasa.py \
  --apple-team-id "$(env_value IOS_RELEASE_DEVELOPMENT_TEAM)" \
  --bundle-id "$(env_value IOS_RELEASE_BUNDLE_ID)" \
  --output "$aasa_payload" >/dev/null; then
  pass "Apple app-site association renders from release team and bundle ID"
else
  fail "Apple app-site association render failed"
fi

if python3 scripts/verify_ios_release_assets.py >/dev/null; then
  pass "iOS release assets verify"
else
  fail "iOS release assets verification failed"
fi

require_file "App Store Connect export options" "deploy/ios-export-options.app-store-connect.plist"
require_file "TestFlight upload options" "deploy/ios-export-options.testflight-upload.plist"

if [[ "$check_asc_key" == "true" ]]; then
  require_env "App Store Connect API key path" ASC_KEY_PATH
  require_env "App Store Connect API key ID" ASC_KEY_ID
  require_env "App Store Connect issuer ID" ASC_ISSUER_ID
  if [[ -n "$(env_value ASC_KEY_PATH)" && -f "$(env_value ASC_KEY_PATH)" ]]; then
    pass "App Store Connect API key file exists"
  else
    fail "App Store Connect API key file is required when CHECK_ASC_KEY=true"
  fi
else
  skip "App Store Connect API key file check is disabled"
fi

if [[ "$check_dns" == "true" ]]; then
  if bash deploy/dns-preflight.sh "$(env_value DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN)"; then
    pass "DNS preflight passes"
  else
    fail "DNS preflight failed"
  fi
else
  skip "DNS preflight is disabled"
fi

echo "Release readiness summary: $passed passed, $skipped skipped, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
