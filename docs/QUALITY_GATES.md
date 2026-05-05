# Quality Gates

Last verified: 2026-05-05

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 8 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| Backend API tests | `make backend-test` | 8 tests passed |
| Backend coverage | `make coverage` | 91.79% total coverage |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| CRAP score | `make crap` | `FINAL_SCORE: 4.68` |
| MMDX preflight | `python3 ../opensource/skills/mmdx/scripts/mmd.py docs/architecture.mmdx --preflight-only` | 3 charts passed |

## Known Blocks

- Live deployment is blocked until a skillbox deploy overlay names a host, service, production origin, and health URL.
- Visual parity with the original reference image is blocked because the image is not available in this compacted context.
- App Store signing, app icons, and TestFlight automation are release-slice work, not part of this starter gate.
