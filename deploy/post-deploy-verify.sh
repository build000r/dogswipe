#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-deploy/docker-compose.prod.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-dogswipe}"
ENV_FILE="${ENV_FILE:-deploy/prod.env}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT"}"
HEALTH_ENDPOINT="${HEALTH_ENDPOINT:-http://localhost:8000/health}"
PUBLIC_HEALTH_URL="${PUBLIC_HEALTH_URL:-}"

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

echo "Post-deploy summary: $passed passed, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
