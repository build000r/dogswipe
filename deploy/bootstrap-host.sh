#!/usr/bin/env bash
set -euo pipefail

apply=false

usage() {
  cat <<'EOF'
Usage: bash deploy/bootstrap-host.sh [--dry-run|--apply]

Creates the non-secret DogSwipe host directory layout and installs deploy
artifacts into DOGSWIPE_DEPLOY_ROOT. Dry-run is the default.

Environment:
  DOGSWIPE_DEPLOY_ROOT          default: /opt/dogswipe
  DOGSWIPE_ENV_FILE             default: /opt/envs/dogswipe/prod.env
  DOGSWIPE_STORAGE_ROOT         default: /mnt/volume_nyc3_cfo_v1
  DOGSWIPE_POSTGRES_DATA        default: $DOGSWIPE_STORAGE_ROOT/dogswipe/pgdata
  DOGSWIPE_INSTALL_AASA         default: false
  AASA_RENDER_PATH              default: .build/aasa/apple-app-site-association
EOF
}

for arg in "$@"; do
  case "$arg" in
    --apply)
      apply=true
      ;;
    --dry-run)
      apply=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

deploy_root="${DOGSWIPE_DEPLOY_ROOT:-/opt/dogswipe}"
env_file="${DOGSWIPE_ENV_FILE:-/opt/envs/dogswipe/prod.env}"
storage_root="${DOGSWIPE_STORAGE_ROOT:-/mnt/volume_nyc3_cfo_v1}"
postgres_data="${DOGSWIPE_POSTGRES_DATA:-$storage_root/dogswipe/pgdata}"
aasa_render_path="${AASA_RENDER_PATH:-.build/aasa/apple-app-site-association}"
install_aasa="${DOGSWIPE_INSTALL_AASA:-false}"

passed=0
warned=0

pass() {
  echo "PASS: $1"
  passed=$((passed + 1))
}

warn() {
  echo "WARN: $1" >&2
  warned=$((warned + 1))
}

is_true() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

require_absolute_path() {
  local label="$1"
  local value="$2"
  if [[ -z "$value" || "$value" != /* ]]; then
    echo "$label must be an absolute path: $value" >&2
    exit 1
  fi
}

run() {
  if [[ "$apply" == "true" ]]; then
    "$@"
  else
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  fi
}

ensure_dir() {
  local path="$1"
  local mode="${2:-0755}"
  run install -d -m "$mode" "$path"
  pass "directory ready: $path"
}

install_artifact() {
  local source="$1"
  local destination="$2"
  local mode="${3:-0644}"

  if [[ ! -f "$source" ]]; then
    echo "Missing deploy artifact: $source" >&2
    exit 1
  fi

  run install -d -m 0755 "$(dirname "$destination")"
  run install -m "$mode" "$source" "$destination"
  pass "artifact installed: $destination"
}

require_absolute_path "DOGSWIPE_DEPLOY_ROOT" "$deploy_root"
require_absolute_path "DOGSWIPE_ENV_FILE" "$env_file"
require_absolute_path "DOGSWIPE_STORAGE_ROOT" "$storage_root"
require_absolute_path "DOGSWIPE_POSTGRES_DATA" "$postgres_data"

echo "Running DogSwipe host bootstrap ($([[ "$apply" == "true" ]] && echo apply || echo dry-run))"

ensure_dir "$deploy_root" 0755
ensure_dir "$deploy_root/deploy" 0755
ensure_dir "$deploy_root/deploy/reverse-proxy" 0755
ensure_dir "$deploy_root/.well-known" 0755
ensure_dir "$(dirname "$env_file")" 0700
ensure_dir "$postgres_data" 0700

install_artifact "$repo_root/deploy/docker-compose.prod.yml" "$deploy_root/deploy/docker-compose.prod.yml"
install_artifact "$repo_root/deploy/prod.env.example" "$deploy_root/deploy/prod.env.example"
install_artifact "$repo_root/deploy/pre-deploy-checks.sh" "$deploy_root/deploy/pre-deploy-checks.sh" 0755
install_artifact "$repo_root/deploy/post-deploy-verify.sh" "$deploy_root/deploy/post-deploy-verify.sh" 0755
install_artifact "$repo_root/deploy/render-aasa.py" "$deploy_root/deploy/render-aasa.py" 0755
install_artifact "$repo_root/deploy/apple-app-site-association.template.json" "$deploy_root/deploy/apple-app-site-association.template.json"
install_artifact "$repo_root/deploy/reverse-proxy/dogswipe-api.conf.template" "$deploy_root/deploy/reverse-proxy/dogswipe-api.conf.template"

if is_true "$install_aasa"; then
  if [[ "$aasa_render_path" != /* ]]; then
    aasa_render_path="$repo_root/$aasa_render_path"
  fi
  install_artifact "$aasa_render_path" "$deploy_root/.well-known/apple-app-site-association"
  install_artifact "$aasa_render_path" "$deploy_root/apple-app-site-association"
else
  warn "AASA payload install skipped; set DOGSWIPE_INSTALL_AASA=true after rendering a production payload"
fi

if [[ ! -f "$env_file" ]]; then
  warn "production env file is not present yet: $env_file"
  warn "render it privately with deploy/render-prod-env.py before starting Compose"
else
  pass "production env file already exists: $env_file"
fi

echo "Host bootstrap summary: $passed passed, $warned warnings"
