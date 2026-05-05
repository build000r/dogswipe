# Quality Gates

Last verified: 2026-05-05

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 16 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| iOS unit tests | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'platform=iOS Simulator,name=iPhone 17' test` | passed |
| Backend API tests | `make backend-test` | 25 tests passed |
| Backend coverage | `make coverage` | 89.17% total coverage |
| Clean backend install | `python3.12 -m venv /tmp/... && pip install -e 'backend[test]'` | passed |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| Alembic migration smoke | `DATABASE_URL=sqlite+aiosqlite:////tmp/dogswipe-preferences-migrate-smoke.sqlite make migrate` | upgraded to `0003`; `make migration-current` reports `0003 (head)` |
| Backend container build | `docker build -q backend` | built image `sha256:a60d19614623df59ea07e8927b404bc7ea9243cc3598fc69cc0a5cd1209a29ce` |
| Production Compose config | `make deploy-config` | passed |
| Deploy preflight | `make deploy-preflight` | 15 passed, 0 warnings, 0 failed |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| CRAP score | `make crap` | `FINAL_SCORE: 5.00` |
| MMDX preflight | `python3 ../opensource/skills/mmdx/scripts/mmd.py docs/architecture.mmdx --preflight-only` | 3 charts passed |

## Current Product Evidence

- `DogSwipeAPIClient` decodes backend snake_case profile payloads.
- `DogSwipeAPIClient` encodes swipe requests without client-controlled user identity.
- `DogSwipeAPIClient` can attach a trimmed user bearer token from an injected provider and omits blank auth values.
- `SPAPSAuthClient` requests and verifies magic links with a publishable key and optional native origin, never a secret SPAPS API key.
- Product profiles represent local hotdogs with style, price, vendor, crave score, and availability fields.
- `DiscoverViewModel` loads profiles from the backend client and falls back to sample profiles when offline.
- `MatchesViewModel` fetches matches from the backend client and exposes a visible empty/loading/failure state.
- Local backend startup can create the starter schema and idempotently seed sample profiles when explicit local-only env flags are enabled.
- User-scoped backend routes prefer `AuthenticatedUser.user_id` from SPAPS middleware and reject forged `user_id` fields in swipe requests.
- Alembic owns the production schema path with a tested initial upgrade/downgrade migration.
- Hotdog cards render a local SwiftUI product visual when `image_url` is absent, and the profile tab exposes interactive craving controls backed by shared ranking preferences.
- `GET /v1/preferences` and `PUT /v1/preferences` persist user-scoped craving preferences; the Swift client and iOS store round-trip the same snake_case contract.
- iOS native sign-in stores SPAPS access/refresh JWTs in Keychain, refreshes sessions, and injects only the access bearer into the shared API client.
- Production deploy artifacts define the Compose stack, env contract, preflight checks, post-deploy verification, reverse-proxy template, and CI workflow.

## Known Blocks

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, and health URL.
- Visual parity with the original reference image is blocked because the image is not available in this compacted context.
- App Store signing, app icons, and TestFlight automation are release-slice work, not part of this starter gate.
