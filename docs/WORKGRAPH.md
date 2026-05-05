# DogSwipe Workgraph

Status key: `done`, `active`, `ready`, `blocked`.

| ID | Status | Depends On | Writes | Done When |
| --- | --- | --- | --- | --- |
| WG-001 Repo foundation | done | none | `.gitignore`, `README.md`, `docs/*`, `Makefile` | Git repo exists with public-ready docs, workgraph, and verification commands |
| WG-002 Swift core | done | WG-001 | `packages/DogSwipeCore/**` | `swift test` passes and core swipe logic is covered |
| WG-003 iOS shell | done | WG-002 | `apps/ios/DogSwipe/**` | XcodeGen project builds for generic iOS destination |
| WG-004 Python starter | done | WG-001 | `backend/**`, `docker-compose.yml` | FastAPI discovery/swipe API passes tests with coverage above 80 |
| WG-005 Quality gates | done | WG-002, WG-003, WG-004 | `.drift/**`, coverage artifacts | drift scan and CRAP score meet target gates |
| WG-006 Public repo + deploy | blocked | WG-005 | git remote, deployment overlay | public GitHub repo exists; live deploy remains blocked until an overlay identifies a safe target |
| WG-007 iOS API bridge | done | WG-002, WG-003, WG-004 | `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**` | iOS app has a tested API client and view models that call backend discovery, swipe, and match routes |

## Ready Frontier

The next ready work is to create a skillbox deploy overlay or continue deeper product slices: auth-gated user state, persistence/migrations, richer profile media, and shelter workflows.

## Risks

- The original visual reference image is unavailable in this context; final visual parity is blocked on reacquiring that asset or a written design brief.
- Deploy is blocked until a skillbox overlay names a concrete host, app URL, and health check target.
- App Store/TestFlight release is out of scope for this first skeleton until signing assets and bundle ownership are known.

## Remote Checkpoint

- Public repository: https://github.com/build000r/dogswipe
- First pushed commit: `dbf880b`
