#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-deploy/docker-compose.prod.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-dogswipe}"
ENV_FILE="${ENV_FILE:-deploy/prod.env}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT"}"
HEALTH_ENDPOINT="${HEALTH_ENDPOINT:-http://localhost:8000/health}"
PUBLIC_HEALTH_URL="${PUBLIC_HEALTH_URL:-}"
PUBLIC_AASA_URL="${PUBLIC_AASA_URL:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
IOS_RELEASE_BUNDLE_ID="${IOS_RELEASE_BUNDLE_ID:-com.build000r.dogswipe}"
EXPECTED_AASA_APP_ID="${EXPECTED_AASA_APP_ID:-}"

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

echo "Running DogSwipe post-deploy verification"

for service in api postgres redis; do
  if $COMPOSE_CMD ps "$service" 2>/dev/null | grep -q "Up"; then
    pass "$service container is running"
  else
    fail "$service container is not running"
    $COMPOSE_CMD logs "$service" --tail=40 2>&1 || true
  fi
done

if $COMPOSE_CMD exec -T api python -c "import urllib.request; urllib.request.urlopen('${HEALTH_ENDPOINT}', timeout=5).read()" >/dev/null; then
  pass "internal health endpoint responds"
else
  fail "internal health endpoint failed: $HEALTH_ENDPOINT"
fi

if $COMPOSE_CMD exec -T api alembic current 2>/tmp/dogswipe-alembic-current.log | grep -q "(head)"; then
  pass "database migration is at head"
else
  fail "database migration is not at head"
  cat /tmp/dogswipe-alembic-current.log >&2 || true
fi

if [[ -n "$PUBLIC_HEALTH_URL" ]]; then
  if curl -fsS "$PUBLIC_HEALTH_URL" >/dev/null; then
    pass "public health URL responds"
  else
    fail "public health URL failed: $PUBLIC_HEALTH_URL"
  fi
else
  echo "SKIP: PUBLIC_HEALTH_URL is not set"
fi

if [[ -n "$PUBLIC_AASA_URL" ]]; then
  aasa_payload="$(mktemp)"
  if curl -fsS "$PUBLIC_AASA_URL" -o "$aasa_payload" \
    && python3 -m json.tool "$aasa_payload" >/dev/null \
    && grep -q '"applinks"' "$aasa_payload"; then
    pass "public Apple app-site association responds"
    expected_app_id="$EXPECTED_AASA_APP_ID"
    if [[ -z "$expected_app_id" && -n "$APPLE_TEAM_ID" ]]; then
      expected_app_id="${APPLE_TEAM_ID}.${IOS_RELEASE_BUNDLE_ID}"
    fi
    if [[ -n "$expected_app_id" ]]; then
      if python3 - "$aasa_payload" "$expected_app_id" <<'PY'
import json
import sys

payload_path, expected = sys.argv[1:]
payload = json.loads(open(payload_path).read())
details = payload.get("applinks", {}).get("details", [])
app_ids = [app_id for detail in details for app_id in detail.get("appIDs", [])]
if expected not in app_ids:
    raise SystemExit(1)
PY
      then
        pass "public Apple app-site association includes expected app ID"
      else
        fail "public Apple app-site association missing expected app ID: $expected_app_id"
      fi
    else
      echo "SKIP: expected AASA app ID is not set"
    fi
  else
    fail "public Apple app-site association failed: $PUBLIC_AASA_URL"
  fi
  rm -f "$aasa_payload"
else
  echo "SKIP: PUBLIC_AASA_URL is not set"
fi

echo "Post-deploy summary: $passed passed, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
