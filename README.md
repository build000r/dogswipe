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
| Discovery | `GET /v1/discovery` returns available `HotdogProfile` records filtered by the user's saved max-distance/classic preferences and ranked by crave/distance fit; optional `latitude`/`longitude` query params recompute card distance from the user's current location; responses include deterministic walking-time estimates and menu highlights, and iOS cards can open Apple Maps directions from coordinates or address text. |
| Swipe state | Swift package owns deterministic deck advancement, undo, and positive-signal tracking. |
| Matches | `POST /v1/swipes` records likes/passes/super-likes; `GET /v1/matches` returns high-crave liked hotdogs. |
| Preferences | `GET /v1/preferences` and `PUT /v1/preferences` persist user-scoped craving controls under the same backend-owned identity boundary; the backend discovery route and Swift local deck scorer both consume the same contract. |
| Vendor submissions | `POST /v1/vendor/submissions` stores vendor-owned hotdog listings with optional coordinates and pickup address text as `pending_review`; the iOS Vendor form can resolve a pickup address into coordinates before submission; `GET /v1/vendor/submissions` returns only the current user's submissions; `PUT /v1/vendor/submissions/{id}` lets owners resubmit change-requested drafts; `POST /v1/vendor/submissions/{id}/ingest-menu` records an owner-scoped menu URL snapshot status/excerpt. |
| Admin review | Configured admins can list `GET /v1/admin/vendor/submissions`, approve reviewed hotdogs into discovery, reject bad listings, request vendor edits with review notes, or refresh stale vendor menu snapshots in bounded batches with `POST /v1/admin/vendor/menus/refresh`. |
| Auth boundary | User-scoped backend routes derive identity from SPAPS auth when enabled, with a local-only header fallback while auth is disabled. |
| iOS transport | The Profile tab can request SPAPS magic links with a publishable key, handle `dogswipe://auth` returns, store access/refresh JWTs in Keychain, and send only the access bearer to the DogSwipe API. |

Hotdog profile payloads use this snake_case backend contract:

```json
{
  "id": "hotdog-coney",
  "name": "Coney Classic",
  "style": "Chili dog",
  "price_dollars": 6.5,
  "signature_notes": "Beef frank, snap casing, chili, onion, and yellow mustard.",
  "distance_miles": 1.2,
  "latitude": 43.6539,
  "longitude": -79.3843,
  "walking_time_minutes": 24,
  "vendor_name": "Franklin Cart",
  "address_text": "100 Queen St W, Toronto, ON",
  "image_url": null,
  "menu_url": null,
  "menu_status": null,
  "menu_excerpt": null,
  "menu_highlights": [],
  "menu_checked_at": null,
  "media_alt_text": null,
  "crave_score": 0.91,
  "availability_status": "available",
  "review_note": null,
  "last_verified_at": null,
  "last_reviewed_at": null
}
```

Craving preferences use the same snake_case API contract:

```json
{
  "max_distance_miles": 10,
  "spicy_friendly": true,
  "classic_only": false
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

The backend defaults to local development mode with auth disabled. Production deployments should set `SPAPS_AUTH_ENABLED=true`, `SPAPS_API_KEY`, `SPAPS_APPLICATION_ID`, `DOGSWIPE_ADMIN_USER_IDS`, and a managed PostgreSQL `DATABASE_URL`.

For local Docker development, `DOGSWIPE_AUTO_CREATE_SCHEMA=true` and `DOGSWIPE_SEED_SAMPLE_PROFILES=true` create the starter tables and seed sample profiles at API startup. Keep those flags off in production and run managed migrations instead:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

Production deploy artifacts live in [deploy/README.md](deploy/README.md). The repo now includes a production Compose file, env template, pre/post deploy verification scripts, and a reverse-proxy site template. A live rollout still requires a skillbox overlay with the concrete host, deploy root, env source, domain, and health URL.

The iOS target reads `DOGSWIPE_API_BASE_URL` from its Info.plist and defaults to `http://localhost:8000`, which works for simulator-local backend development. It also reads `DOGSWIPE_SPAPS_API_BASE_URL`, `DOGSWIPE_SPAPS_PUBLISHABLE_KEY`, and `DOGSWIPE_SPAPS_ORIGIN` for native magic-link sign-in. For auth-enabled environments, configure a `spaps_pub_...` publishable key and matching origin; the app requests/verifies magic links through SPAPS, registers the `dogswipe://auth` URL scheme for link returns, stores access/refresh JWTs in Keychain, and injects only the access bearer through `DogSwipeAPIClient`. Discovery can request iOS when-in-use location permission and pass current coordinates to the backend so response distances reflect the user position. The Vendor form can resolve pickup address text through CoreLocation geocoding and prefill latitude/longitude before submission. Secret SPAPS API keys remain server-only.

Menu snapshots are intentionally bounded. Vendors and admins can refresh menu URLs on demand, and production can optionally enable `DOGSWIPE_MENU_REFRESH_ENABLED=true` to run the same stale-menu refresh in the API process with `DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS`, `DOGSWIPE_MENU_REFRESH_BATCH_SIZE`, and `DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS`. Discovery responses derive short `menu_highlights` from the latest snapshot excerpt so cards can surface menu signals without storing a separate crawler index.

## Verification Gates

```bash
make test
make coverage
make drift
make crap
make mmdx-preflight
make ios-release-assets
make ios-ui-test
make ios-screenshots
```

Target gates for this repo:

- Python coverage: `>=80%`
- Swift package tests: green via `swift test`
- UI drift: no unreviewed SwiftUI token drift outside design token files
- CRAP: scoped `FINAL_SCORE < 20`
- MMDX: architecture stack preflights cleanly
- Deploy preflight: production Compose config and env contract resolve without secrets
- iOS release assets: AppIcon catalog, accent color, and privacy manifest pass manifest verification
- iOS UI smoke: deterministic screenshot-mode launch covers Discover, Matches, Vendor, Review, and Profile
- iOS screenshots: exported XCTest attachments produce five local PNGs under `.build/ios-screenshots/attachments`

GitHub Actions enforces the same blocking gates for backend coverage, CRAP, MMDX architecture syntax, SwiftUI drift, deploy preflight, iOS release asset verification, iOS build/tests, and screenshot UI smoke.

Latest recorded gate results live in [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md).

## Build Vs Clone Decision

The placement decision is `NEW REPO`: this app owns a durable product boundary rather than fitting cleanly inside `htma_server` or `sweet-potato`. The build strategy is `BORROW + BUILD`: borrow the SPAPS/FastAPI quickstart pattern from `../htma_server` and `../sweet-potato`, build the app-specific iOS UX and local hotdog discovery domain directly in this repo.

## Current Scope

The current app can load local hotdog profiles, render cards with a local product visual when no image URL is available, request and verify SPAPS magic links including native `dogswipe://auth` returns, store access/refresh JWTs in Keychain, record swipes, persist shared craving controls that filter/rank discovery, use CoreLocation-backed coordinates for live distance ranking, show deterministic walking-time estimates, surface menu highlights from bounded snapshots, open Apple Maps directions from coordinates or pickup address text, resolve vendor pickup addresses into coordinates, submit and revise vendor-owned hotdog listings, refresh bounded menu URL snapshots as a vendor, refresh stale vendor menu snapshots as an admin or optional background worker, approve/reject/request edits as an admin, and fetch matches through the shared Swift API client. The iOS target includes a hotdog-specific AppIcon catalog, accent color, `PrivacyInfo.xcprivacy` declaration for auth email and precise location use, and deterministic screenshot-mode fixtures for UI smoke/screenshots. Backend migrations are managed through Alembic up to `0008`, local Docker development can auto-create and seed the starter data with explicit local-only flags, CI enforces the core quality gates, and production deploy artifacts are ready for a concrete skillbox target.

## Known Limits

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, env source, deploy root, and health URL.
- Final visual parity with the original reference image remains blocked because the image is not available in this context.
- Crawler-based menu indexing, universal-link polish, live routing beyond Apple Maps handoff, App Store signing, and TestFlight automation are future slices.

## About Contributions

Please don't take this the wrong way, but I do not accept outside contributions for any of my projects. I simply don't have the mental bandwidth to review anything, and it's my name on the thing, so I'm responsible for any problems it causes; thus, the risk-reward is highly asymmetric from my perspective. I'd also have to worry about other "stakeholders," which seems unwise for tools I mostly make for myself for free. Feel free to submit issues, and even PRs if you want to illustrate a proposed fix, but know I won't merge them directly. Instead, I'll have Claude or Codex review submissions via `gh` and independently decide whether and how to address them. Bug reports in particular are welcome. Sorry if this offends, but I want to avoid wasted time and hurt feelings. I understand this isn't in sync with the prevailing open-source ethos that seeks community contributions, but it's the only way I can move at this velocity and keep my sanity.
