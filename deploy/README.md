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
| `aasa_url` | `https://<domain>/.well-known/apple-app-site-association` |
| `apple_team_id` | Apple Developer Team ID for the associated-domain app ID |
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

The production SPAPS application slug is `dogswipe`. Its raw application ID,
publishable key, and secret key should come from the private deployment env
source; this public repo must only carry env variable names and templates.

Optional bounded menu refresh values:

- `DOGSWIPE_MENU_REFRESH_ENABLED=false` by default
- `DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS=3600`
- `DOGSWIPE_MENU_REFRESH_BATCH_SIZE=20`
- `DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS=24`

## Universal Links

The iOS project includes an associated-domains entitlement that resolves
`applinks:$(DOGSWIPE_ASSOCIATED_DOMAIN)` at build time. For a production build,
set `DOGSWIPE_ASSOCIATED_DOMAIN` to the same domain used by the public API or
auth frontdoor, set `DOGSWIPE_AUTH_REDIRECT_URL=https://<domain>/auth`, and set
`DOGSWIPE_AUTH_UNIVERSAL_LINK_HOSTS=<domain>` in the app Info.plist/build
configuration.

Generate the deployed Apple app-site association file from
[`deploy/apple-app-site-association.template.json`](apple-app-site-association.template.json)
by replacing `${APPLE_TEAM_ID}` with the Apple Developer Team ID and
`${IOS_BUNDLE_ID}` with the exact bundle identifier used for the signed archive:

```bash
AASA_APPLE_TEAM_ID=<apple-team-id> \
IOS_RELEASE_BUNDLE_ID=com.build000r.dogswipe \
make deploy-render-aasa
```

The rendered payload is written to `.build/aasa/apple-app-site-association` by
default. Copy that payload to the web root expected by the reverse-proxy
template. The reverse proxy serves the rendered file from both:

- `https://<domain>/.well-known/apple-app-site-association`
- `https://<domain>/apple-app-site-association`

## iOS Archive And TestFlight Handoff

The public repo carries non-secret archive/export scaffolding only. Signed
archive creation requires the private Apple Developer Team ID plus the production
DogSwipe API and SPAPS publishable-key values:

```bash
IOS_RELEASE_DEVELOPMENT_TEAM=<apple-team-id> \
DOGSWIPE_RELEASE_API_BASE_URL=https://<domain> \
DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=<domain> \
DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY=spaps_pub_... \
make ios-release-archive
```

`make ios-testflight-export` exports the archive with
[`ios-export-options.app-store-connect.plist`](ios-export-options.app-store-connect.plist).
`make ios-testflight-upload` uploads the archive with
[`ios-export-options.testflight-upload.plist`](ios-export-options.testflight-upload.plist)
when `ASC_KEY_PATH`, `ASC_KEY_ID`, and `ASC_ISSUER_ID` are provided from a
private App Store Connect API key source. Apple `.p8`, `.p12`, and
`.mobileprovision` files are ignored by git.

## Preflight

```bash
cp deploy/prod.env.example deploy/prod.env
export DOGSWIPE_IMAGE=ghcr.io/build000r/dogswipe:<tag>
export POSTGRES_PASSWORD='<strong-password>'
bash deploy/pre-deploy-checks.sh
```

The preflight checks Docker availability, Compose config, required env values,
SPAPS auth requirements, local-only flags, optional menu-refresh controls, the
Apple app-site association template, and the shared `reverse-proxy` network.

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
   PUBLIC_HEALTH_URL=https://<domain>/health \
     PUBLIC_AASA_URL=https://<domain>/.well-known/apple-app-site-association \
     APPLE_TEAM_ID=<apple-team-id> \
     IOS_RELEASE_BUNDLE_ID=com.build000r.dogswipe \
     bash deploy/post-deploy-verify.sh
   ```

## Known Block

No live deployment should run until the skillbox overlay supplies the concrete
host, deploy root, env source, production domain, Apple Team ID, health URL, and
AASA URL. The current repo can prove the container, migration, universal-link
asset template/render path, and Compose contract locally; it cannot prove DNS,
certificates, Apple account ownership, or production secrets by itself.
