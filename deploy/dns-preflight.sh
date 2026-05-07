#!/usr/bin/env bash
set -euo pipefail

domain="${1:-${DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN:-}}"
zone="${DOGSWIPE_DNS_ZONE:-}"
expected_records="${DOGSWIPE_EXPECTED_A_RECORD:-${DOGSWIPE_DEPLOY_IP:-}}"
check_public_urls="${CHECK_PUBLIC_URLS:-false}"
require_host_record="${REQUIRE_HOST_RECORD:-true}"
dns_resolver="${DOGSWIPE_DNS_RESOLVER:-}"
public_curl_resolve="${PUBLIC_CURL_RESOLVE:-}"

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

has_command() {
  command -v "$1" >/dev/null 2>&1
}

dig_lookup() {
  if [[ -n "$dns_resolver" ]]; then
    dig "@$dns_resolver" "$@"
  else
    dig "$@"
  fi
}

valid_domain() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]] \
    && [[ "$value" != *..* ]]
}

default_zone_for() {
  local value="$1"
  local label_count
  label_count="$(awk -F. '{print NF}' <<<"$value")"
  if [[ "$label_count" -lt 2 ]]; then
    return 1
  fi
  awk -F. '{print $(NF-1) "." $NF}' <<<"$value"
}

echo "Running DogSwipe DNS preflight"

if [[ -z "$domain" ]]; then
  fail "DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN or positional domain is required"
elif valid_domain "$domain"; then
  pass "domain has valid DNS hostname shape"
else
  fail "domain must be a DNS hostname"
fi

if ! has_command dig; then
  fail "dig is required for DNS preflight"
fi

if [[ "$check_public_urls" == "true" ]] && ! has_command curl; then
  fail "curl is required when CHECK_PUBLIC_URLS=true"
fi

if [[ "$failed" -eq 0 ]]; then
  if [[ -z "$zone" ]]; then
    zone="$(default_zone_for "$domain")"
  fi

  if valid_domain "$zone"; then
    pass "DNS zone candidate has valid hostname shape"
  else
    fail "DNS zone candidate is invalid: $zone"
  fi
fi

if [[ "$failed" -eq 0 ]]; then
  ns_records="$(dig_lookup +short NS "$zone" || true)"
  soa_record="$(dig_lookup +short SOA "$zone" || true)"
  if [[ -n "$ns_records" || -n "$soa_record" ]]; then
    pass "DNS zone has public NS/SOA authority"
  else
    fail "DNS zone has no public NS/SOA authority: $zone"
  fi
fi

if [[ "$failed" -eq 0 ]]; then
  a_records="$(dig_lookup +short A "$domain" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || true)"
  aaaa_records="$(dig_lookup +short AAAA "$domain" | sed -n '/:/p' || true)"
  if [[ -n "$a_records" || -n "$aaaa_records" ]]; then
    pass "domain resolves to at least one A/AAAA record"
  elif [[ "$require_host_record" == "true" ]]; then
    fail "domain has no A/AAAA record: $domain"
  else
    skip "domain A/AAAA record check disabled"
  fi
fi

if [[ "$failed" -eq 0 && -n "$expected_records" ]]; then
  matched="false"
  normalized_expected="${expected_records//,/ }"
  for expected in $normalized_expected; do
    while IFS= read -r actual; do
      if [[ "$actual" == "$expected" ]]; then
        matched="true"
      fi
    done <<<"$a_records"
  done

  if [[ "$matched" == "true" ]]; then
    pass "domain A record matches expected deploy IP"
  else
    fail "domain A records do not match expected deploy IP(s): $expected_records"
  fi
elif [[ -z "$expected_records" ]]; then
  skip "expected deploy IP check is not set"
fi

if [[ "$check_public_urls" == "true" && "$failed" -eq 0 ]]; then
  public_health_url="${PUBLIC_HEALTH_URL:-https://$domain/health}"
  public_aasa_url="${PUBLIC_AASA_URL:-https://$domain/.well-known/apple-app-site-association}"
  curl_args=()
  if [[ -n "$public_curl_resolve" ]]; then
    curl_args=(--resolve "$public_curl_resolve")
  fi

  if curl "${curl_args[@]}" -fsS "$public_health_url" >/dev/null; then
    pass "public health URL responds"
  else
    fail "public health URL failed: $public_health_url"
  fi

  if curl "${curl_args[@]}" -fsS "$public_aasa_url" >/dev/null; then
    pass "public Apple app-site association URL responds"
  else
    fail "public Apple app-site association URL failed: $public_aasa_url"
  fi
else
  skip "public health/AASA URL checks disabled"
fi

echo "DNS preflight summary: $passed passed, $skipped skipped, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
