#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-deploy/docker-compose.prod.yml}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-dogswipe}"
ENV_FILE="${ENV_FILE:-deploy/prod.env}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT"}"

passed=0
failed=0
warned=0

pass() {
  echo "PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "FAIL: $1" >&2
  failed=$((failed + 1))
}

warn() {
  echo "WARN: $1" >&2
  warned=$((warned + 1))
}

env_value() {
  grep -E "^$1=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
}

echo "Running DogSwipe deploy preflight"

if command -v docker >/dev/null 2>&1; then
  pass "docker is installed"
else
  fail "docker is required"
fi

if [[ -f "$COMPOSE_FILE" ]]; then
  pass "compose file exists: $COMPOSE_FILE"
else
  fail "compose file missing: $COMPOSE_FILE"
fi

if [[ -f "$ENV_FILE" ]]; then
  pass "production env file exists: $ENV_FILE"
else
  fail "production env file missing: $ENV_FILE"
fi

if [[ -f "$ENV_FILE" ]]; then
  for var in DATABASE_URL REDIS_URL CORS_ALLOW_ORIGINS SPAPS_AUTH_ENABLED; do
    if [[ -n "$(env_value "$var")" ]]; then
      pass "$var is set"
    else
      fail "$var is required"
    fi
  done

  database_url="$(env_value DATABASE_URL)"
  if [[ "$database_url" == postgresql+asyncpg://* ]]; then
    pass "DATABASE_URL uses async PostgreSQL"
  else
    fail "DATABASE_URL must start with postgresql+asyncpg://"
  fi

  auth_enabled="$(env_value SPAPS_AUTH_ENABLED | tr '[:upper:]' '[:lower:]')"
  if [[ "$auth_enabled" == "true" || "$auth_enabled" == "1" ]]; then
    for var in SPAPS_API_URL SPAPS_API_KEY SPAPS_APPLICATION_ID; do
      if [[ -n "$(env_value "$var")" ]]; then
        pass "$var is set for SPAPS auth"
      else
        fail "$var is required when SPAPS_AUTH_ENABLED=true"
      fi
    done
    if [[ -n "$(env_value DOGSWIPE_ADMIN_USER_IDS)" ]]; then
      pass "DOGSWIPE_ADMIN_USER_IDS is set for review tools"
    else
      fail "DOGSWIPE_ADMIN_USER_IDS is required when SPAPS_AUTH_ENABLED=true"
    fi
  else
    warn "SPAPS_AUTH_ENABLED is not true; production user routes will not use SPAPS"
  fi

  for var in DOGSWIPE_AUTO_CREATE_SCHEMA DOGSWIPE_SEED_SAMPLE_PROFILES; do
    value="$(env_value "$var" | tr '[:upper:]' '[:lower:]')"
    if [[ "$value" == "false" || "$value" == "0" ]]; then
      pass "$var is disabled"
    else
      fail "$var must stay false in production"
    fi
  done

  menu_refresh_enabled="$(env_value DOGSWIPE_MENU_REFRESH_ENABLED | tr '[:upper:]' '[:lower:]')"
  if [[ "$menu_refresh_enabled" == "true" || "$menu_refresh_enabled" == "1" ]]; then
    for var in DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS DOGSWIPE_MENU_REFRESH_BATCH_SIZE DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS; do
      if [[ -n "$(env_value "$var")" ]]; then
        pass "$var is set for autonomous menu refresh"
      else
        fail "$var is required when DOGSWIPE_MENU_REFRESH_ENABLED=true"
      fi
    done
  else
    pass "DOGSWIPE_MENU_REFRESH_ENABLED is disabled unless explicitly enabled"
  fi
fi

if docker network inspect reverse-proxy >/dev/null 2>&1; then
  pass "reverse-proxy network exists"
else
  warn "reverse-proxy network is missing; create it before starting the stack"
fi

if [[ -f "$COMPOSE_FILE" && -f "$ENV_FILE" ]] && $COMPOSE_CMD config >/dev/null; then
  pass "docker compose config resolves"
else
  fail "docker compose config failed"
fi

echo "Preflight summary: $passed passed, $warned warnings, $failed failed"
if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
