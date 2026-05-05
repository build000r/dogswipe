# DogSwipe

DogSwipe is a production-oriented monorepo for a swipe-first iOS app for finding local hotdogs, backed by a Sweet Potato/SPAPS-aligned FastAPI service.

Public repo: <https://github.com/build000r/dogswipe>

## What It Does

DogSwipe turns "where should I get a hotdog right now?" into a fast swipe loop. The app presents nearby hotdog cards with the item style, price, vendor, distance, and crave score; swipes are recorded through the backend and high-signal likes become saved matches.

The repo is intentionally split into three testable surfaces:

| Surface | Path | Purpose |
| --- | --- | --- |
| iOS app | `apps/ios/DogSwipe` | SwiftUI app shell, generated with XcodeGen, backed by the local API client |
| Swift domain package | `packages/DogSwipeCore` | Matching, swipe state, API contracts, and domain models with fast `swift test` coverage |
| Python backend | `backend` | FastAPI + PostgreSQL starter using `spaps-server-quickstart` contracts |

## Current Product Contract

| Surface | Implemented behavior |
| --- | --- |
| Discovery | `GET /v1/discovery` returns ranked `HotdogProfile` records from PostgreSQL. |
| Swipe state | Swift package owns deterministic deck advancement, undo, and positive-signal tracking. |
| Matches | `POST /v1/swipes` records likes/passes/super-likes; `GET /v1/matches` returns high-crave liked hotdogs. |
| Auth boundary | User-scoped backend routes derive identity from SPAPS auth when enabled, with a local-only header fallback while auth is disabled. |
| iOS transport | `DogSwipeAPIClient` can attach user bearer tokens through an injected provider without embedding SPAPS API keys. |

Hotdog profile payloads use this snake_case backend contract:

```json
{
  "id": "hotdog-coney",
  "name": "Coney Classic",
  "style": "Chili dog",
  "price_dollars": 6.5,
  "signature_notes": "Beef frank, snap casing, chili, onion, and yellow mustard.",
  "distance_miles": 1.2,
  "vendor_name": "Franklin Cart",
  "image_url": null,
  "crave_score": 0.91,
  "availability_status": "available"
}
```

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

For local Docker development, `DOGSWIPE_AUTO_CREATE_SCHEMA=true` and `DOGSWIPE_SEED_SAMPLE_PROFILES=true` create the starter tables and seed sample profiles at API startup. Keep those flags off in production and run managed migrations instead:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

The iOS target reads `DOGSWIPE_API_BASE_URL` from its generated Info.plist and defaults to `http://localhost:8000`, which works for simulator-local backend development. User-scoped routes derive identity from SPAPS auth when enabled; local development can use `X-DogSwipe-User-ID` while auth is disabled. For auth-enabled environments, initialize `DogSwipeAPIClient` with an authorization-token provider that returns a user bearer token, not a SPAPS API key.

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

Latest recorded gate results live in [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md).

## Build Vs Clone Decision

The placement decision is `NEW REPO`: this app owns a durable product boundary rather than fitting cleanly inside `htma_server` or `sweet-potato`. The build strategy is `BORROW + BUILD`: borrow the SPAPS/FastAPI quickstart pattern from `../htma_server` and `../sweet-potato`, build the app-specific iOS UX and local hotdog discovery domain directly in this repo.

## Current Scope

The current app can load local hotdog profiles, render cards with a local product visual when no image URL is available, record swipes, adjust shared craving controls, and fetch matches through the shared Swift API client. Backend migrations are managed through Alembic up to `0002`, and local Docker development can auto-create and seed the starter data with explicit local-only flags.

## Known Limits

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, and health URL.
- Final visual parity with the original reference image remains blocked because the image is not available in this context.
- Real vendor onboarding, live menu inventory, location services, and App Store/TestFlight release assets are future slices.

## About Contributions

Please don't take this the wrong way, but I do not accept outside contributions for any of my projects. I simply don't have the mental bandwidth to review anything, and it's my name on the thing, so I'm responsible for any problems it causes; thus, the risk-reward is highly asymmetric from my perspective. I'd also have to worry about other "stakeholders," which seems unwise for tools I mostly make for myself for free. Feel free to submit issues, and even PRs if you want to illustrate a proposed fix, but know I won't merge them directly. Instead, I'll have Claude or Codex review submissions via `gh` and independently decide whether and how to address them. Bug reports in particular are welcome. Sorry if this offends, but I want to avoid wasted time and hurt feelings. I understand this isn't in sync with the prevailing open-source ethos that seeks community contributions, but it's the only way I can move at this velocity and keep my sanity.
