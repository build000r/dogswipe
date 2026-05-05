# Quality Gates

Last verified: 2026-05-05

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 14 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| iOS unit tests | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'platform=iOS Simulator,name=iPhone 17' test` | passed |
| Backend API tests | `make backend-test` | 20 tests passed |
| Backend coverage | `make coverage` | 93.28% total coverage |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| Alembic migration smoke | `DATABASE_URL=sqlite+aiosqlite:////tmp/dogswipe-hotdog-migrate-smoke.sqlite make migrate` | upgraded to `0002`; `make migration-current` reports `0002 (head)` |
| Backend container build | `docker build -q backend` | built image `sha256:b37eb3b0724f9d31648a50446c272778e28d964f7b2f042faef40128c0b18e5e` |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| CRAP score | `make crap` | `FINAL_SCORE: 5.00` |
| MMDX preflight | `python3 ../opensource/skills/mmdx/scripts/mmd.py docs/architecture.mmdx --preflight-only` | 3 charts passed |

## Current Product Evidence

- `DogSwipeAPIClient` decodes backend snake_case profile payloads.
- `DogSwipeAPIClient` encodes swipe requests without client-controlled user identity.
- `DogSwipeAPIClient` can attach a trimmed user bearer token from an injected provider and omits blank auth values.
- Product profiles represent local hotdogs with style, price, vendor, crave score, and availability fields.
- `DiscoverViewModel` loads profiles from the backend client and falls back to sample profiles when offline.
- `MatchesViewModel` fetches matches from the backend client and exposes a visible empty/loading/failure state.
- Local backend startup can create the starter schema and idempotently seed sample profiles when explicit local-only env flags are enabled.
- User-scoped backend routes prefer `AuthenticatedUser.user_id` from SPAPS middleware and reject forged `user_id` fields in swipe requests.
- Alembic owns the production schema path with a tested initial upgrade/downgrade migration.
- Hotdog cards render a local SwiftUI product visual when `image_url` is absent, and the profile tab exposes interactive craving controls backed by shared ranking preferences.

## Known Blocks

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, and health URL.
- Visual parity with the original reference image is blocked because the image is not available in this compacted context.
- App Store signing, app icons, and TestFlight automation are release-slice work, not part of this starter gate.
