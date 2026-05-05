# Quality Gates

Last verified: 2026-05-05

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 30 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| iOS unit tests | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'platform=iOS Simulator,id=<available iPhone simulator UDID>' test` | passed |
| Backend API tests | `make backend-test` | 70 tests passed |
| Backend coverage | `make coverage` | 89.63% total coverage |
| Clean backend install | `python3.12 -m venv /tmp/... && pip install -e 'backend[test]'` | passed |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| Alembic migration smoke | `make backend-test` | migration test upgraded to `0008` and downgraded to `base` |
| Backend container build | `docker build -q backend` | built image `sha256:6fafce8f97eeeb5c6b0bcd32479eb30c1133b4d5083a6399a76aa4c571082320` |
| Production Compose config | `make deploy-config` | passed |
| Deploy preflight | `make deploy-preflight` | 17 passed, 0 warnings, 0 failed |
| Skillbox overlay template | `make deploy-overlay-template` | passed |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| iOS release assets | `make ios-release-assets` | passed |
| CRAP score | `make crap` | `FINAL_SCORE: 7.00` |
| MMDX preflight | `make mmdx-preflight` | 3 charts passed |
| CI quality enforcement | GitHub Actions `backend`, `swift-package`, and `ios` jobs | coverage XML feeds blocking CRAP; MMDX, SwiftUI drift, deploy, Swift package, and iOS gates fail on regressions; iOS prefers a modern simulator, preboots it, disables parallel test workers, and uses bounded destination/job/test timeouts |
| SPAPS usage audit | `python3 ../sweet-potato/skills/sweet-potato-usage-audit/scripts/audit_sweet_potato_usage.py --sweet-potato-root ../sweet-potato .` | 0 high, 0 medium, 0 low |

## Current Product Evidence

- `DogSwipeAPIClient` decodes backend snake_case profile payloads.
- `DogSwipeAPIClient` encodes swipe requests without client-controlled user identity.
- `DogSwipeAPIClient` can attach a trimmed user bearer token from an injected provider and omits blank auth values.
- `SPAPSAuthClient` requests and verifies magic links with a publishable key, optional native origin, and `dogswipe://auth` redirect URL, never a secret SPAPS API key.
- Product profiles represent local hotdogs with style, price, vendor, crave score, and availability fields.
- `DiscoverViewModel` loads profiles from the backend client and falls back to sample profiles when offline.
- `MatchesViewModel` fetches matches from the backend client and exposes a visible empty/loading/failure state.
- Local backend startup can create the starter schema and idempotently seed sample profiles when explicit local-only env flags are enabled.
- Optional backend menu refresh startup stays disabled by default; when enabled, the worker runs the same bounded stale-menu refresh contract with env-controlled interval, batch size, and max age.
- User-scoped backend routes prefer `AuthenticatedUser.user_id` from SPAPS middleware and reject forged `user_id` fields in swipe requests.
- Alembic owns the production schema path with a tested initial upgrade/downgrade migration.
- Hotdog cards render a local SwiftUI product visual when `image_url` is absent, and the profile tab exposes interactive craving controls backed by shared ranking preferences.
- `GET /v1/preferences` and `PUT /v1/preferences` persist user-scoped craving preferences; the Swift client and iOS store round-trip the same snake_case contract.
- `GET /v1/discovery` resolves the current user, accepts optional `latitude`/`longitude`, applies saved max-distance/classic filters, and shares the same ranking semantics as the Swift local deck scorer.
- Hotdog profile payloads include deterministic walking-time estimates derived from resolved distance; Swift decodes the field and falls back to local distance-based estimates for offline samples.
- iOS discovery can pass a CoreLocation coordinate to the backend, and vendor submissions can include optional hotdog coordinates for dynamic response distances.
- Hotdog profiles can include pickup address text, `DogSwipeCore` derives Apple Maps directions URLs from coordinates or address text, and iOS discovery/matches expose directions actions.
- The iOS Vendor form can resolve pickup address text into latitude/longitude through an injected CoreLocation geocoder with covered success/failure states.
- Hotdog profile payloads derive short `menu_highlights` from bounded menu snapshots; Swift decodes the array and iOS discovery/vendor summaries display those menu signals.
- iOS native sign-in stores SPAPS access/refresh JWTs in Keychain, refreshes sessions, and injects only the access bearer into the shared API client.
- iOS registers `dogswipe://auth`, parses returned magic-link tokens, and verifies deep links through `AuthSessionStore`.
- The iOS target includes a hotdog-specific AppIcon catalog, accent color, and `PrivacyInfo.xcprivacy` declaration for linked auth email and precise location data used only for app functionality; `make ios-release-assets` blocks missing icon slots, alpha-channel icons, and privacy manifest drift.
- `POST /v1/vendor/submissions` stores authenticated vendor hotdog listings as `pending_review`; `GET`/`PUT /v1/vendor/submissions` are user-scoped and the iOS Vendor tab can revise change-requested listings.
- `POST /v1/vendor/submissions/{id}/ingest-menu` is owner-scoped, stores bounded menu URL snapshot status/excerpt/timestamp fields, and the iOS Vendor tab can refresh and render the snapshot state.
- `POST /v1/admin/vendor/menus/refresh` is admin-scoped, refreshes stale vendor menu snapshots in bounded batches, reports checked/refreshed/failed counts, and the iOS Admin tab can trigger the refresh.
- Configured admins can list pending vendor submissions, approve one into discovery, reject one, request edits with a review note, and production preflight requires `DOGSWIPE_ADMIN_USER_IDS` when SPAPS auth is enabled.
- Production deploy artifacts define the Compose stack, env contract, preflight checks, post-deploy verification, reverse-proxy template, and CI workflow.
- GitHub Actions enforces backend coverage XML generation, scoped CRAP threshold, MMDX architecture preflight, SwiftUI drift, deploy preflight, and iOS build/test gates.
- A DogSwipe skillbox overlay template and validator exist so live deploy setup can be checked without committing host secrets.

## Known Blocks

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, and health URL.
- Visual parity with the original reference image is blocked because the image is not available in this compacted context.
- App Store signing, screenshots, and TestFlight automation remain release-slice work because bundle ownership and signing assets are not available in this workspace.
