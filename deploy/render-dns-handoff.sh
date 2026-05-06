#!/usr/bin/env bash
set -euo pipefail

domain="${1:-${DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN:-}}"
zone="${DOGSWIPE_DNS_ZONE:-}"
deploy_ip="${DOGSWIPE_EXPECTED_A_RECORD:-${DOGSWIPE_DEPLOY_IP:-}}"
ttl="${DOGSWIPE_DNS_TTL:-300}"

valid_domain() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]] \
    && [[ "$value" != *..* ]]
}

valid_ipv4() {
  local value="$1"
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local octet
  local -a octets
  IFS=. read -r -a octets <<<"$value"
  for octet in "${octets[@]}"; do
    if ((10#$octet > 255)); then
      return 1
    fi
  done
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

record_name_for() {
  local value="$1"
  local zone_value="$2"
  if [[ "$value" == "$zone_value" ]]; then
    echo "@"
    return 0
  fi
  if [[ "$value" == *".$zone_value" ]]; then
    echo "${value%.$zone_value}"
    return 0
  fi
  return 1
}

if [[ -z "$domain" ]]; then
  echo "DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN or positional domain is required" >&2
  exit 1
fi

if ! valid_domain "$domain"; then
  echo "domain must be a DNS hostname: $domain" >&2
  exit 1
fi

if [[ -z "$zone" ]]; then
  zone="$(default_zone_for "$domain")"
fi

if ! valid_domain "$zone"; then
  echo "DOGSWIPE_DNS_ZONE is invalid: $zone" >&2
  exit 1
fi

if [[ "$domain" != "$zone" && "$domain" != *".$zone" ]]; then
  echo "domain must be inside DOGSWIPE_DNS_ZONE: $domain not in $zone" >&2
  exit 1
fi

if [[ -z "$deploy_ip" ]]; then
  echo "DOGSWIPE_EXPECTED_A_RECORD or DOGSWIPE_DEPLOY_IP is required" >&2
  exit 1
fi

if ! valid_ipv4 "$deploy_ip"; then
  echo "deploy IP must be an IPv4 address: $deploy_ip" >&2
  exit 1
fi

record_name="$(record_name_for "$domain" "$zone")"
health_url="https://$domain/health"
aasa_url="https://$domain/.well-known/apple-app-site-association"

cat <<EOF
DogSwipe DNS handoff

Create this public DNS record:

  Zone:  $zone
  Type:  A
  Name:  $record_name
  Value: $deploy_ip
  TTL:   $ttl

Use DNS-only mode until the reverse proxy, TLS, health endpoint, and Apple
app-site association URL have been verified. If the operator intentionally
uses a proxying DNS provider, keep the public URLs below as the source of truth.

Private release values that must stay aligned:

  DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=$domain
  DOGSWIPE_RELEASE_API_BASE_URL=https://$domain
  DOGSWIPE_RELEASE_AUTH_REDIRECT_URL=https://$domain/auth
  DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS=$domain
  PUBLIC_HEALTH_URL=$health_url
  PUBLIC_AASA_URL=$aasa_url

After the record propagates, run:

  DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=$domain \\
  DOGSWIPE_EXPECTED_A_RECORD=$deploy_ip \\
  make deploy-dns-preflight

After Compose, reverse proxy, and certificates are live, run:

  CHECK_PUBLIC_URLS=true \\
  DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=$domain \\
  DOGSWIPE_EXPECTED_A_RECORD=$deploy_ip \\
  PUBLIC_HEALTH_URL=$health_url \\
  PUBLIC_AASA_URL=$aasa_url \\
  make deploy-dns-preflight
EOF
