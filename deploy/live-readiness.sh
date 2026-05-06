#!/usr/bin/env bash
set -euo pipefail

overlay_file="${DEPLOY_OVERLAY_FILE:-deploy/skillbox-overlay.example.yaml}"
domain="${DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN:-}"
allow_placeholders="${ALLOW_PLACEHOLDERS:-false}"
check_asc_key="${CHECK_ASC_KEY:-false}"
check_public_urls="${CHECK_PUBLIC_URLS:-false}"
run_deploy_preflight="${RUN_DEPLOY_PREFLIGHT:-false}"
run_post_deploy_verify="${RUN_POST_DEPLOY_VERIFY:-false}"

echo "Running DogSwipe live readiness"

if [[ -z "$domain" ]]; then
  echo "DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN is required" >&2
  exit 1
fi

if [[ "$allow_placeholders" == "true" ]]; then
  bash deploy/validate-skillbox-overlay.sh "$overlay_file" --allow-placeholders
else
  bash deploy/validate-skillbox-overlay.sh "$overlay_file"
fi

CHECK_PUBLIC_URLS="$check_public_urls" \
  bash deploy/dns-preflight.sh "$domain"

ALLOW_PLACEHOLDERS="$allow_placeholders" \
  CHECK_ASC_KEY="$check_asc_key" \
  CHECK_DNS=false \
  CHECK_PUBLIC_URLS="$check_public_urls" \
  bash deploy/release-readiness.sh "$overlay_file"

if [[ "$run_deploy_preflight" == "true" ]]; then
  ENV_FILE="${ENV_FILE:-${DOGSWIPE_ENV_FILE:-deploy/prod.env}}" \
    DOGSWIPE_ENV_FILE="${DOGSWIPE_ENV_FILE:-${ENV_FILE:-deploy/prod.env}}" \
    bash deploy/pre-deploy-checks.sh
else
  echo "SKIP: deploy preflight is disabled; set RUN_DEPLOY_PREFLIGHT=true"
fi

if [[ "$run_post_deploy_verify" == "true" ]]; then
  bash deploy/post-deploy-verify.sh
else
  echo "SKIP: post-deploy verification is disabled; set RUN_POST_DEPLOY_VERIFY=true"
fi

echo "DogSwipe live readiness complete"
