# DogSwipe Deploy Runbook

DogSwipe is deploy-ready once a skillbox overlay names the production service
target. Until then, this directory is the deploy contract that an overlay should
point at.

## Required Overlay Fields

A live `deploy.services.dogswipe_api` entry should provide:

| Field | Expected value |
| --- | --- |
| `surface` | `docker_compose` |
| `repo_slug` | `build000r/dogswipe` |
| `repo_root` | `~/repos/dogswipe` |
| `deploy_root` | remote path, for example `/opt/dogswipe` |
| `compose_file` | `deploy/docker-compose.prod.yml` |
| `compose_project` | `dogswipe` |
| `compose_service` | `api` |
| `domain` | production API hostname |
| `production_domain` | `https://<domain>` |
| `health_url` | `https://<domain>/health` |
| `env_file` | remote `prod.env` path |

Start from [`deploy/skillbox-overlay.example.yaml`](skillbox-overlay.example.yaml),
copy it into `skillbox-config/clients/dogswipe/overlay.yaml`, replace the
host/domain/env placeholders, and validate it before attempting live rollout:

```bash
bash deploy/validate-skillbox-overlay.sh deploy/skillbox-overlay.example.yaml --allow-placeholders
bash deploy/validate-skillbox-overlay.sh /path/to/skillbox-config/clients/dogswipe/overlay.yaml
```

## Production Env

Create `deploy/prod.env` from `deploy/prod.env.example` on the deployment host.
Keep `DOGSWIPE_AUTO_CREATE_SCHEMA=false` and `DOGSWIPE_SEED_SAMPLE_PROFILES=false`
in production; run Alembic instead.

Required runtime values:

- `POSTGRES_PASSWORD`
- `DOGSWIPE_IMAGE`
- `DATABASE_URL`
- `REDIS_URL`
- `CORS_ALLOW_ORIGINS`
- `SPAPS_AUTH_ENABLED=true`
- `SPAPS_API_URL`
- `SPAPS_API_KEY`
- `SPAPS_APPLICATION_ID`
- `DOGSWIPE_ADMIN_USER_IDS`

Optional bounded menu refresh values:

- `DOGSWIPE_MENU_REFRESH_ENABLED=false` by default
- `DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS=3600`
- `DOGSWIPE_MENU_REFRESH_BATCH_SIZE=20`
- `DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS=24`

## Preflight

```bash
cp deploy/prod.env.example deploy/prod.env
export DOGSWIPE_IMAGE=ghcr.io/build000r/dogswipe:<tag>
export POSTGRES_PASSWORD='<strong-password>'
bash deploy/pre-deploy-checks.sh
```

The preflight checks Docker availability, Compose config, required env values,
SPAPS auth requirements, local-only flags, optional menu-refresh controls, and
the shared `reverse-proxy` network.

## Rollout Shape

1. Build and publish `backend/Dockerfile` as `DOGSWIPE_IMAGE`.
2. Copy `deploy/docker-compose.prod.yml` and `deploy/prod.env` to the deploy root.
3. Start database and Redis.
4. Run migrations:
   ```bash
   docker compose --env-file deploy/prod.env -f deploy/docker-compose.prod.yml -p dogswipe run --rm api alembic upgrade head
   ```
5. Start or restart the API:
   ```bash
   docker compose --env-file deploy/prod.env -f deploy/docker-compose.prod.yml -p dogswipe up -d
   ```
6. Link `deploy/reverse-proxy/dogswipe-api.conf.template` into the shared reverse proxy after substituting `DOGSWIPE_API_DOMAIN`.
7. Verify:
   ```bash
   PUBLIC_HEALTH_URL=https://<domain>/health bash deploy/post-deploy-verify.sh
   ```

## Known Block

No live deployment should run until the skillbox overlay supplies the concrete
host, deploy root, env source, production domain, and health URL. The current
repo can prove the container, migration, and Compose contract locally; it cannot
prove DNS, certificates, or production secrets by itself.
