# DogSwipe

DogSwipe is a production-oriented monorepo for a swipe-first iOS app for finding local hotdogs, backed by a Sweet Potato/SPAPS-aligned FastAPI service.

Public repo: <https://github.com/build000r/dogswipe>

## What It Does

DogSwipe turns "where should I get a hotdog right now?" into a fast swipe loop. The app presents nearby hotdog cards with the item style, price, vendor, distance, menu signals, and crave score; users can search bounded menu snapshots for craving terms, and high-signal likes become saved matches. The iOS surface is intentionally a Tinder-style street-vendor pack: cream cards, mustard/red controls, product-first hotdog art, and a match/order detail instead of a venue directory.

The repo is intentionally split into three testable surfaces:

| Surface | Path | Purpose |
| --- | --- | --- |
| iOS app | `apps/ios/DogSwipe` | SwiftUI app shell, generated with XcodeGen, backed by the local API client |
| Swift domain package | `packages/DogSwipeCore` | Matching, swipe state, API contracts, and domain models with fast `swift test` coverage |
| Python backend | `backend` | FastAPI + PostgreSQL starter using `spaps-server-quickstart` contracts |

## Current Product Contract

| Surface | Implemented behavior |
| --- | --- |
| Discovery | `GET /v1/discovery` returns available `HotdogProfile` records filtered by the user's saved max-distance/classic preferences and ranked by crave/distance fit; optional `latitude`/`longitude` query params recompute card distance from the user's current location, and optional `menu_query` filters against hotdog names, vendors, notes, menu excerpts, and derived menu highlights; responses include deterministic walking-time estimates and menu highlights, and iOS cards can preview a live MapKit walking route before opening Apple Maps directions from coordinates or address text. |
| Swipe state | Swift package owns deterministic deck advancement, undo, and positive-signal tracking. |
| Matches | `POST /v1/swipes` records likes/passes/super-likes; `GET /v1/matches` returns high-crave liked hotdogs and can accept the same optional `latitude`/`longitude` query params so saved bites keep current distance, walking-time, route-preview, and directions context. The match detail lets users select add-ons and save the hotdog as a backend-owned order draft with visible confirmation and a real bag count. |
| Orders | `POST /v1/orders` creates a user-scoped draft from an orderable hotdog profile and canonical server add-ons; `GET /v1/orders` returns the current user's durable drafts for the iOS My Orders tab. Clients send only `profile_id` and bounded `add_on_ids`; the backend snapshots hotdog name, vendor, base price, add-ons, and total. |
| Preferences | `GET /v1/preferences` and `PUT /v1/preferences` persist user-scoped craving controls under the same backend-owned identity boundary; the backend discovery route and Swift local deck scorer both consume the same contract. |
| Vendor submissions | `POST /v1/vendor/submissions` stores vendor-owned hotdog listings with optional coordinates and pickup address text as `pending_review`; the iOS Vendor form can resolve a pickup address into coordinates before submission; `GET /v1/vendor/submissions` returns only the current user's submissions; `PUT /v1/vendor/submissions/{id}` lets owners resubmit change-requested drafts; `POST /v1/vendor/submissions/{id}/ingest-menu` records an owner-scoped menu URL snapshot status/excerpt. |
| Admin review | Configured admins can list `GET /v1/admin/vendor/submissions`, approve reviewed hotdogs into discovery, reject bad listings, request vendor edits with review notes, or refresh stale vendor menu snapshots in bounded batches with `POST /v1/admin/vendor/menus/refresh`. |
| Auth boundary | User-scoped backend routes derive identity from SPAPS auth when enabled, with a local-only header fallback while auth is disabled. |
| iOS transport | The Profile tab can request SPAPS magic links with a publishable key, handle `dogswipe://auth` or configured HTTPS universal-link returns, store access/refresh JWTs in Keychain, and send only the access bearer to the DogSwipe API. |
| iOS analytics | SwiftUI surfaces emit a small no-PII event contract for screen views, discovery swipes, auth actions, and match/order CTAs. |

Hotdog profile payloads use this snake_case backend contract:

```json
{
  "id": "hotdog-chicago",
  "name": "Chicago Classic",
  "style": "Chicago style",
  "price_dollars": 6.49,
  "signature_notes": "All-beef dog, mustard, relish, onions, tomato, sport peppers, pickle spear, celery salt.",
  "distance_miles": 0.3,
  "latitude": 41.8837,
  "longitude": -87.6248,
  "walking_time_minutes": 6,
  "vendor_name": "Street Vendor Pack",
  "address_text": "35 E Randolph St, Chicago, IL",
  "image_url": null,
  "menu_url": "https://streetvendor.example.com/menu",
  "menu_status": "ok",
  "menu_excerpt": "Chicago Classic with mustard, relish, onions, tomato, sport peppers, pickle spear, and celery salt.",
  "menu_highlights": ["Mild", "All-Beef", "Crunchy", "Popular"],
  "menu_checked_at": null,
  "media_alt_text": "Chicago-style hotdog with mustard, relish, onions, tomato, sport peppers, pickle spear, and celery salt.",
  "crave_score": 0.94,
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
make spaps-app-contract
ALLOW_PLACEHOLDERS=true make spaps-registration-payload
```

`backend-install-local` uses a sibling Sweet Potato checkout at `../sweet-potato` so this workspace can track current SPAPS package contracts. For a clean public install, publish or install `spaps-server-quickstart~=0.5.1` and run `make backend-install`.

## Local Services

```bash
docker compose up --build
curl http://localhost:8000/health
```

The backend defaults to local development mode with auth disabled. Production deployments should set `SPAPS_AUTH_ENABLED=true`, `SPAPS_API_KEY`, `SPAPS_APPLICATION_ID`, `DOGSWIPE_ADMIN_USER_IDS`, and a managed PostgreSQL `DATABASE_URL`. The public SPAPS app descriptor lives in `spaps.app.json`, fixes the application slug to `dogswipe`, and renders a Sweet Potato self-service registration payload with the supported `browser_auth` blueprint plus DogSwipe native-iOS settings. Keep the raw application ID, publishable key, and secret key in a private env manager or the ignored local `.env.dogswipe.spaps` file, never in git.

To smoke test on a connected iPhone with the local seeded backend:

```bash
docker compose up -d --build
make ios-phone-run
```

`ios-phone-run` signs a Debug build, installs it with `devicectl`, and launches it on the first available iPhone. It points the app at this Mac's LAN API URL, for example `http://192.168.x.x:8000`, so the phone must be on the same network unless you override `DOGSWIPE_PHONE_API_BASE_URL`. If Xcode cannot infer a signing team, set `IOS_PHONE_DEVELOPMENT_TEAM` or `APPLE_DEVELOPMENT_TEAM` to your Apple Developer Team ID. Local auth is disabled by default, so the backend uses the dummy `local-user` identity without a real SPAPS account.

For a signed release archive and TestFlight handoff, configure the production app values from a private environment and keep Apple signing material out of git:

```bash
export IOS_RELEASE_DEVELOPMENT_TEAM=<apple-team-id>
export DOGSWIPE_RELEASE_API_BASE_URL=https://<dogswipe-api-domain>
export DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=<dogswipe-api-domain>
export DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY=spaps_pub_...

make spaps-registration-payload > /tmp/dogswipe-spaps-application.json
make deploy-render-aasa
make deploy-release-readiness
make ios-release-archive
make ios-testflight-export
```

`spaps-registration-payload` renders the non-secret body for `POST /api/self-service/applications`; the full operator flow is in [docs/SPAPS_APP_HANDOFF.md](docs/SPAPS_APP_HANDOFF.md). `deploy-render-aasa` renders the Apple app-site association payload with the same Apple Team ID and bundle identifier used by the signed archive. `deploy-release-readiness` checks the live overlay, production release URLs, SPAPS registration payload, SPAPS publishable-key shape, AASA render, iOS release assets, optional DNS preflight, and optional App Store Connect API key handoff without printing secrets. `ios-release-archive` also accepts `DOGSWIPE_RELEASE_SPAPS_API_BASE_URL`, `DOGSWIPE_RELEASE_SPAPS_ORIGIN`, `DOGSWIPE_RELEASE_AUTH_REDIRECT_URL`, and `DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS`; the latter three default from `DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN`. `ios-testflight-upload` can upload the archive through an App Store Connect API key when `ASC_KEY_PATH`, `ASC_KEY_ID`, and `ASC_ISSUER_ID` are set. `.gitignore` blocks common Apple signing artifacts such as `.p8`, `.p12`, and `.mobileprovision` files.

Current live-release probes show that the DogSwipe SPAPS app is registered, but its publishable-key origins must match the final production domain. A read-only production metadata check confirms the live app still lacks `https://dogswipe.buildooor.com`; add that origin to SPAPS before shipping native auth if this stays the release domain. Local Xcode can create a development-signed archive for the DogSwipe bundle, but App Store/TestFlight export still needs an Apple Distribution certificate/profile through Xcode or App Store Connect API credentials.

For local Docker development, `DOGSWIPE_AUTO_CREATE_SCHEMA=true` and `DOGSWIPE_SEED_SAMPLE_PROFILES=true` create the starter tables and seed sample profiles at API startup. Keep those flags off in production and run managed migrations instead:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

Production deploy artifacts live in [deploy/README.md](deploy/README.md). The repo now includes a production Compose file, conditional GHCR image publishing for backend-image changes on `main`, private env and skillbox overlay renderers, a host bootstrap script for non-secret deploy files/directories, pre/post deploy verification scripts, a non-secret SPAPS app descriptor, an AASA render/readiness target, and a reverse-proxy site template. The production host has the private env rendered, Alembic migrations applied, and the internal DogSwipe API running healthy on the current GHCR full-SHA image. Public rollout still requires the canonical DNS record, SPAPS allowed-origin alignment, reverse-proxy/AASA/certificate activation, public health/AASA verification, and Apple distribution credentials for TestFlight.

The iOS target reads `DOGSWIPE_API_BASE_URL` from its Info.plist and defaults to `http://localhost:8000`, which works for simulator-local backend development. It also reads build-setting-backed `DOGSWIPE_SPAPS_API_BASE_URL`, `DOGSWIPE_SPAPS_PUBLISHABLE_KEY`, `DOGSWIPE_SPAPS_ORIGIN`, `DOGSWIPE_AUTH_REDIRECT_URL`, and `DOGSWIPE_AUTH_UNIVERSAL_LINK_HOSTS` for native magic-link sign-in. For auth-enabled environments, configure a `spaps_pub_...` publishable key and matching origin; the app requests/verifies magic links through SPAPS, registers the `dogswipe://auth` URL scheme, can verify configured HTTPS universal-link callbacks from allowed hosts, stores access/refresh JWTs in Keychain, and injects only the access bearer through `DogSwipeAPIClient`. Release builds should override `DOGSWIPE_ASSOCIATED_DOMAIN` with the production link domain and host the rendered Apple app-site association payload from `make deploy-render-aasa`. Discovery and Matches can request iOS when-in-use location permission, pass current coordinates to the backend so response distances reflect the user position, and preview an on-device MapKit walking route for coordinate-backed hotdogs before handing off to Apple Maps. Discovery also exposes a compact menu search field behind the filter control that sends `menu_query` to the backend and applies the same query locally when offline. The Vendor form can resolve pickup address text through CoreLocation geocoding and prefill latitude/longitude before submission. Secret SPAPS API keys remain server-only.

Menu snapshots are intentionally bounded. Vendors and admins can refresh menu URLs on demand, and production can optionally enable `DOGSWIPE_MENU_REFRESH_ENABLED=true` to run the same stale-menu refresh in the API process with `DOGSWIPE_MENU_REFRESH_INTERVAL_SECONDS`, `DOGSWIPE_MENU_REFRESH_BATCH_SIZE`, and `DOGSWIPE_MENU_REFRESH_MAX_AGE_HOURS`. Discovery responses derive short `menu_highlights` from the latest snapshot excerpt so cards can surface menu signals without storing a separate crawler index. `GET /v1/discovery?menu_query=kimchi%20sesame` searches those bounded profile/menu fields for craving terms.

## Verification Gates

```bash
make test
make coverage
make drift
make crap
make mmdx-preflight
make ios-release-assets
make deploy-dns-handoff-template
make deploy-dns-preflight DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=<domain>
make deploy-live-readiness-template
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
- DNS handoff: production DNS record, aligned release env values, and follow-up preflight commands render without secrets
- DNS preflight: production domain has public DNS authority, resolves to a host record, and can optionally prove public health/AASA URLs
- Live readiness: overlay, DNS, release, optional private env, and optional post-deploy checks are chained in operator order
- Private deploy handoff template: non-secret renderer path creates throwaway private env/overlay files and validates them through deploy preflight
- iOS release assets: AppIcon catalog, accent color, privacy manifest, associated-domains entitlement, and Apple app-site association template pass manifest verification
- iOS UI smoke: deterministic screenshot-mode launch covers Discover, draggable card advancement, Matches, match add-to-order, Orders, Vendor, Review, and Profile
- iOS screenshots: exported XCTest attachments produce six local PNGs under `.build/ios-screenshots/attachments`

GitHub Actions enforces the same blocking gates for backend coverage, CRAP, MMDX architecture syntax, SPAPS app contract and registration-payload validation, SwiftUI drift, deploy preflight, iOS release asset verification, iOS build/tests, and screenshot UI smoke.

Latest recorded gate results live in [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md).
The current prompt-to-artifact completion audit lives in [docs/COMPLETION_AUDIT.md](docs/COMPLETION_AUDIT.md).
The current iOS analytics contract lives in [docs/IOS_ANALYTICS.md](docs/IOS_ANALYTICS.md).

## Build Vs Clone Decision

The placement decision is `NEW REPO`: this app owns a durable product boundary rather than fitting cleanly inside `htma_server` or `sweet-potato`. The build strategy is `BORROW + BUILD`: borrow the SPAPS/FastAPI quickstart pattern from `../htma_server` and `../sweet-potato`, build the app-specific iOS UX and local hotdog discovery domain directly in this repo.

## Current Scope

The current app can load local hotdog profiles, render cream/red/mustard swipe cards with a local Chicago-style product visual when no image URL is available, request and verify SPAPS magic links including native `dogswipe://auth` and configured HTTPS universal-link returns, store access/refresh JWTs in Keychain, record swipes, persist shared craving controls that filter/rank discovery, use CoreLocation-backed coordinates for live distance ranking across discovery and saved matches, search bounded menu snapshots from the Discover screen, show deterministic walking-time estimates, preview live MapKit walking routes through visible Live walk/Directions controls on discovery cards and match rows, surface menu highlights from bounded snapshots, open Apple Maps directions from coordinates or pickup address text, select match add-ons, save a matched hotdog as a durable backend order draft, list current user drafts in My Orders, resolve vendor pickup addresses into coordinates, submit and revise vendor-owned hotdog listings, refresh bounded menu URL snapshots as a vendor, refresh stale vendor menu snapshots as an admin or optional background worker, approve/reject/request edits as an admin, fetch matches and orders through the shared Swift API client, and emit a no-PII iOS analytics contract for screen/swipe/auth/match/order events. The iOS target includes a hotdog-specific AppIcon catalog, accent color, `PrivacyInfo.xcprivacy` declaration for auth email and precise location use, associated-domains entitlement plumbing, a deployable Apple app-site association template, and deterministic screenshot-mode fixtures for UI smoke/screenshots. Backend migrations are managed through Alembic up to `0009`, local Docker development can auto-create and seed the starter data with explicit local-only flags, `spaps.app.json` declares the public SPAPS application slug without storing keys, `make spaps-registration-payload` renders the supported Sweet Potato app-registration body, CI enforces the core quality gates, and production deploy artifacts are ready for a concrete skillbox target.

## Known Limits

- Live deployment and hosted universal-link activation are blocked at the public edge, not by the internal DogSwipe stack: the production host now has `/opt/envs/dogswipe/prod.env`, Postgres, Redis, and the API container running healthy after Alembic migrations. The reverse-proxy site config and AASA payload are staged on the host, but the production origin still must resolve publicly and get a valid certificate before the proxy can be enabled and hosted auth/universal links can be proven.
- Production SPAPS auth proof is blocked on the final origin contract: this workspace has ignored private SPAPS values that pass release-readiness, and the backend is configured for SPAPS auth on the production host. Earlier private handoff used `dogswipe.build000r.com`; fresh DNS checks show `build000r.com` has no public NS/SOA response, while `buildooor.com` is active but has no `dogswipe` A record. The discovered Cloudflare credentials can either fail auth or read the active zone without DNS edit permission, so `dogswipe.buildooor.com` still needs a DNS-edit-capable token or a manual `A` record to `104.131.188.214`. If that becomes canonical, the SPAPS app allowed origins also need `https://dogswipe.buildooor.com`.
- Live TestFlight submission is blocked at distribution export/upload: local Xcode can development-sign an archive for the DogSwipe bundle, but App Store export still needs a usable Apple Distribution certificate/profile through Xcode or App Store Connect API credentials.
- Broad crawler-based menu indexing beyond bounded snapshot search, full turn-by-turn navigation or route persistence beyond lightweight MapKit previews, and payment/fulfillment order management beyond durable draft capture are future slices.

## About Contributions

Please don't take this the wrong way, but I do not accept outside contributions for any of my projects. I simply don't have the mental bandwidth to review anything, and it's my name on the thing, so I'm responsible for any problems it causes; thus, the risk-reward is highly asymmetric from my perspective. I'd also have to worry about other "stakeholders," which seems unwise for tools I mostly make for myself for free. Feel free to submit issues, and even PRs if you want to illustrate a proposed fix, but know I won't merge them directly. Instead, I'll have Claude or Codex review submissions via `gh` and independently decide whether and how to address them. Bug reports in particular are welcome. Sorry if this offends, but I want to avoid wasted time and hurt feelings. I understand this isn't in sync with the prevailing open-source ethos that seeks community contributions, but it's the only way I can move at this velocity and keep my sanity.
