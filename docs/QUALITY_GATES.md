# Quality Gates

Last verified: 2026-05-06

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 33 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| iOS unit tests | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'platform=iOS Simulator,id=<available iPhone simulator UDID>' -only-testing:DogSwipeTests test` | passed |
| iOS screenshot UI smoke | `make ios-ui-test` | 7 isolated UI tests passed across Discover, draggable card advancement, Matches, match add-to-order, Vendor, Review, and Profile using direct screenshot-mode tab launches; Discover asserts visible `Live walk` and `Directions` route controls |
| iOS screenshot export | `make ios-screenshots` | 5 PNG attachments exported under `.build/ios-screenshots/attachments` |
| Backend API tests | `make backend-test` | 75 tests passed |
| Backend coverage | `make coverage` | 89.61% total coverage |
| Clean backend install | `python3.12 -m venv /tmp/... && pip install -e 'backend[test]'` | passed |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| Alembic migration smoke | `make backend-test` | migration test upgraded to `0008` and downgraded to `base` |
| Backend container build | `docker build -q backend` | built image `sha256:36e49501e78985bb76212fbb7498bac4662a19daf667dcd1618be3627777698e` |
| Production Compose config | `make deploy-config` | passed |
| Deploy preflight | `make deploy-preflight` | 19 passed, 0 warnings, 0 failed |
| Skillbox overlay template | `make deploy-overlay-template` | 15 passed, 0 failed |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| iOS release assets | `make ios-release-assets` | AppIcon, accent color, privacy manifest, associated-domains entitlement, Apple app-site association template, build-setting-backed auth config, and App Store Connect export option plists passed |
| CRAP score | `make crap` | `FINAL_SCORE: 9.00` |
| MMDX preflight | `make mmdx-preflight` | 3 charts passed |
| CI quality enforcement | GitHub Actions `25417582380` `backend`, `swift-package`, and `ios` jobs | coverage XML feeds blocking CRAP; MMDX, SwiftUI drift, deploy, Swift package, and iOS gates fail on regressions; iOS prefers a modern simulator, preboots it, disables parallel test workers, uses bounded destination/job/test timeouts, and runs direct-tab screenshot UI smoke |
| SPAPS usage audit | `python3 ../sweet-potato/skills/sweet-potato-usage-audit/scripts/audit_sweet_potato_usage.py --sweet-potato-root ../sweet-potato .` | 0 high, 0 medium, 0 low |

## Current Product Evidence

- `DogSwipeAPIClient` decodes backend snake_case profile payloads.
- `DogSwipeAPIClient` encodes swipe requests without client-controlled user identity.
- `DogSwipeAPIClient` can attach a trimmed user bearer token from an injected provider and omits blank auth values.
- `SPAPSAuthClient` requests and verifies magic links with a publishable key, optional native origin, and `dogswipe://auth` redirect URL, never a secret SPAPS API key.
- `AuthSessionStore` can request SPAPS magic links with a configured HTTPS universal-link redirect URL, and `AuthDeepLink` only accepts universal auth callbacks from configured hosts.
- The iOS target includes `DogSwipe.entitlements` with `applinks:$(DOGSWIPE_ASSOCIATED_DOMAIN)`, and `make ios-release-assets` verifies the entitlement, build settings, Info.plist keys, AASA template, and App Store Connect export/upload option plists together.
- Product profiles represent local hotdogs with style, price, vendor, crave score, and availability fields.
- `DiscoverViewModel` loads profiles from the backend client and falls back to sample profiles when offline.
- `MatchesViewModel` fetches matches from the backend client with optional current coordinates and exposes a visible empty/loading/failure state.
- Local backend startup can create the starter schema and idempotently seed sample profiles when explicit local-only env flags are enabled.
- Optional backend menu refresh startup stays disabled by default; when enabled, the worker runs the same bounded stale-menu refresh contract with env-controlled interval, batch size, and max age.
- User-scoped backend routes prefer `AuthenticatedUser.user_id` from SPAPS middleware and reject forged `user_id` fields in swipe requests.
- Alembic owns the production schema path with a tested initial upgrade/downgrade migration.
- Hotdog cards render a local SwiftUI product visual when `image_url` is absent, and the profile tab exposes interactive craving controls backed by shared ranking preferences.
- `GET /v1/preferences` and `PUT /v1/preferences` persist user-scoped craving preferences; the Swift client and iOS store round-trip the same snake_case contract.
- `GET /v1/discovery` resolves the current user, accepts optional `latitude`/`longitude` and `menu_query`, applies saved max-distance/classic filters, searches bounded hotdog/menu fields, and shares the same ranking semantics as the Swift local deck scorer.
- `GET /v1/matches` resolves the current user, accepts optional `latitude`/`longitude`, rejects partial coordinate queries, and returns saved high-crave hotdogs with recomputed distance and walking-time fields.
- Hotdog profile payloads include deterministic walking-time estimates derived from resolved distance; Swift decodes the field and falls back to local distance-based estimates for offline samples.
- iOS discovery can pass a CoreLocation coordinate and menu query to the backend, and vendor submissions can include optional hotdog coordinates for dynamic response distances.
- Hotdog profiles can include pickup address text, `DogSwipeCore` derives Apple Maps directions URLs from coordinates or address text, and iOS discovery/matches expose visible route controls for live MapKit walking-route ETA/distance from the user's current location while preserving Apple Maps handoff.
- The Matches tab supports selectable add-ons, adds the selected hotdog to a local order draft, updates the DogSwipe bag count from state instead of a hardcoded badge, and keeps the payment/fulfillment boundary out of the first slice.
- The iOS Vendor form can resolve pickup address text into latitude/longitude through an injected CoreLocation geocoder with covered success/failure states.
- Hotdog profile payloads derive short `menu_highlights` from bounded menu snapshots; Swift decodes the array, the Discover screen can search those bounded menu/profile signals, and iOS discovery/vendor summaries display them.
- iOS native sign-in stores SPAPS access/refresh JWTs in Keychain, refreshes sessions, and injects only the access bearer into the shared API client.
- iOS registers `dogswipe://auth`, parses returned magic-link tokens from custom-scheme or configured HTTPS universal-link callbacks, and verifies deep links through `AuthSessionStore`.
- The iOS target includes a hotdog-specific AppIcon catalog, accent color, and `PrivacyInfo.xcprivacy` declaration for linked auth email and precise location data used only for app functionality; `make ios-release-assets` blocks missing icon slots, alpha-channel icons, privacy manifest drift, non-configurable auth build settings, and stale TestFlight export options.
- `--dogswipe-screenshot-mode` swaps in deterministic hotdog API fixtures, an in-memory token store, a static location provider, and direct initial-tab launches so isolated UI smoke/screenshots cover Discover, Matches, match add-to-order, Vendor, Review, and Profile without live auth, location prompts, localhost state, or tab-tap timing.
- The deterministic Discover and Matches fixtures now use the supplied DogSwipe reference direction: cream/red/mustard street-vendor chrome, Chicago Classic hero cards, a draggable "Swipe right for dogs" control deck, and a match/order detail.
- `DogSwipeAnalytics` emits a no-PII iOS contract for screen views, discovery swipes, auth submissions, and match/order CTAs; `docs/IOS_ANALYTICS.md` documents the allowed events.
- `POST /v1/vendor/submissions` stores authenticated vendor hotdog listings as `pending_review`; `GET`/`PUT /v1/vendor/submissions` are user-scoped and the iOS Vendor tab can revise change-requested listings.
- `POST /v1/vendor/submissions/{id}/ingest-menu` is owner-scoped, stores bounded menu URL snapshot status/excerpt/timestamp fields, and the iOS Vendor tab can refresh and render the snapshot state.
- `POST /v1/admin/vendor/menus/refresh` is admin-scoped, refreshes stale vendor menu snapshots in bounded batches, reports checked/refreshed/failed counts, and the iOS Admin tab can trigger the refresh.
- Configured admins can list pending vendor submissions, approve one into discovery, reject one, request edits with a review note, and production preflight requires `DOGSWIPE_ADMIN_USER_IDS` when SPAPS auth is enabled.
- Production deploy artifacts define the Compose stack, env contract, preflight checks, post-deploy verification, reverse-proxy template, Apple app-site association template, and CI workflow.
- Signed iOS release handoff artifacts define `ios-release-archive`, `ios-testflight-export`, and `ios-testflight-upload` Make targets with build-setting-backed production API/SPAPS/universal-link inputs and App Store Connect export/upload option plists; Apple `.p8`, `.p12`, and `.mobileprovision` files are ignored.
- GitHub Actions enforces backend coverage XML generation, scoped CRAP threshold, MMDX architecture preflight, SwiftUI drift, deploy preflight including AASA template validation, iOS build/test gates, and screenshot UI smoke.
- A DogSwipe skillbox overlay template and validator exist so live deploy setup, including the AASA URL and Apple Team ID contract, can be checked without committing host secrets.

## Known Blocks

- Live deployment and hosted universal-link activation are blocked until a skillbox deploy overlay names a host, service, production origin, Apple Team ID, health URL, and AASA URL.
- Live App Store signing and TestFlight upload remain blocked because bundle ownership, signing assets, and App Store Connect credentials are not available in this workspace.
