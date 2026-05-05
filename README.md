# DogSwipe

DogSwipe is a production-oriented monorepo for a swipe-first iOS dog discovery app backed by a Sweet Potato/SPAPS-aligned FastAPI service.

Public repo: <https://github.com/build000r/dogswipe>

The repo is intentionally split into three testable surfaces:

| Surface | Path | Purpose |
| --- | --- | --- |
| iOS app | `apps/ios/DogSwipe` | SwiftUI app shell, generated with XcodeGen, backed by the local API client |
| Swift domain package | `packages/DogSwipeCore` | Matching, swipe state, API contracts, and domain models with fast `swift test` coverage |
| Python backend | `backend` | FastAPI + PostgreSQL starter using `spaps-server-quickstart` contracts |

## Quick Start

```bash
make generate-ios
make swift-test
make backend-install-local
make backend-test
```

`backend-install-local` uses a sibling Sweet Potato checkout at `../sweet-potato` so this workspace can track current SPAPS package contracts. For a clean public install, publish or install `spaps-server-quickstart~=0.5.1` and run `make backend-install`.

## Local Services

```bash
docker compose up --build
curl http://localhost:8000/health
```

The backend defaults to local development mode with auth disabled. Production deployments should set `SPAPS_AUTH_ENABLED=true`, `SPAPS_API_KEY`, `SPAPS_APPLICATION_ID`, and a managed PostgreSQL `DATABASE_URL`.

For local Docker development, `DOGSWIPE_AUTO_CREATE_SCHEMA=true` and `DOGSWIPE_SEED_SAMPLE_PROFILES=true` create the starter tables and seed sample profiles at API startup. Keep those flags off in production and run managed migrations instead.

The iOS target reads `DOGSWIPE_API_BASE_URL` from its generated Info.plist and defaults to `http://localhost:8000`, which works for simulator-local backend development. User-scoped routes derive identity from SPAPS auth when enabled; local development can use `X-DogSwipe-User-ID` while auth is disabled.

## Verification Gates

```bash
make test
make coverage
make drift
make crap
```

Target gates for this repo:

- Python coverage: `>=80%`
- Swift package tests: green via `swift test`
- UI drift: no unreviewed SwiftUI token drift outside design token files
- CRAP: scoped `FINAL_SCORE < 20`

## Build Vs Clone Decision

The placement decision is `NEW REPO`: this app owns a durable product boundary rather than fitting cleanly inside `htma_server` or `sweet-potato`. The build strategy is `BORROW + BUILD`: borrow the SPAPS/FastAPI quickstart pattern from `../htma_server` and `../sweet-potato`, build the app-specific iOS UX and dog discovery domain directly in this repo.

## Current Scope

The current app can load discovery profiles, record swipes, and fetch matches through the shared Swift API client. The attached design image from the original request is not available in this compacted context, so final visual parity remains an open design verification gate.
