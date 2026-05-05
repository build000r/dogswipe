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
| WG-008 Local backend runtime | done | WG-004 | `backend/**`, `.env.example`, `docker-compose.yml` | Fresh local PostgreSQL can be schema-created and seeded through explicit local-only settings |
| WG-009 Backend-owned user identity | done | WG-004, WG-007 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**` | User-scoped routes derive identity from SPAPS/local backend context instead of accepting app-supplied `user_id` payloads |
| WG-010 Managed database migrations | done | WG-004, WG-008 | `backend/alembic.ini`, `backend/migrations/**`, `backend/Dockerfile`, `Makefile` | Alembic can upgrade/downgrade the initial schema and production deploys have a migration command |
| WG-011 iOS bearer auth transport | done | WG-007, WG-009 | `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**` | Swift API calls can attach trimmed user bearer tokens through an injected provider without embedding SPAPS secrets |
| WG-012 Hotdog discovery pivot | done | WG-002, WG-004, WG-010 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Product contracts, sample data, migrations, tests, and app copy describe local hotdogs instead of the previous mistaken domain |
| WG-013 Hotdog UI hardening | done | WG-012 | `apps/ios/DogSwipe/**`, `docs/**` | Cards render a local hotdog visual when no image URL exists and the profile tab exposes shared craving controls covered by an iOS unit test |
| WG-014 User preference persistence | done | WG-009, WG-011, WG-013 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Craving controls round-trip through user-scoped backend preferences with migration, API, Swift client, and tests |
| WG-015 iOS auth session bootstrap | done | WG-011, WG-014 | `apps/ios/DogSwipe/**`, `docs/**` | The app stores user bearer JWTs in Keychain and injects them into discovery, swipe, match, and preference API clients without exposing SPAPS API keys |
| WG-016 Deploy contract | done | WG-006, WG-010 | `deploy/**`, `.github/**`, `Makefile`, `docs/**` | Production Compose, env template, pre/post verification scripts, reverse-proxy template, and CI preflight exist; live rollout remains overlay-gated |
| WG-017 Native SPAPS magic-link sign-in | done | WG-015 | `apps/ios/DogSwipe/**`, `docs/**` | The Profile tab can request and verify SPAPS magic links with a publishable key, store access/refresh JWTs in Keychain, refresh sessions, and keep manual bearer entry as an advanced fallback |
| WG-018 Vendor listing submissions | done | WG-014, WG-017 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Authenticated vendors can submit hotdog listings with menu/media metadata, list only their own submissions, and keep drafts out of discovery as `pending_review` |
| WG-019 Admin approval queue | done | WG-018 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `deploy/**`, `docs/**` | Configured admins can list pending vendor submissions, approve them into discovery, and production preflight requires an admin user contract |
| WG-020 Review moderation loop | done | WG-019 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Admins can reject or request edits with notes, vendors can resubmit change-requested listings, and only available hotdogs enter discovery |
| WG-021 Preference-aware discovery ranking | done | WG-014, WG-020 | `backend/**`, `packages/DogSwipeCore/**`, `docs/**` | Backend discovery and Swift local ranking both filter by saved max-distance/classic preferences before ordering local hotdog cards by crave/distance fit |
| WG-022 GPS-backed proximity | done | WG-021 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Hotdog profiles and vendor submissions can carry coordinates, iOS discovery can pass current CoreLocation coordinates, and backend discovery recomputes response distance before filtering/ranking |
| WG-023 Menu URL snapshots | done | WG-018, WG-022 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Vendors can refresh a bounded menu URL snapshot for their own hotdog listings, with stored status/excerpt/timestamp and iOS Vendor tab coverage |
| WG-024 Address directions handoff | done | WG-022, WG-023 | `backend/**`, `packages/DogSwipeCore/**`, `apps/ios/DogSwipe/**`, `docs/**` | Hotdog profiles and vendor submissions can carry pickup address text, Swift derives Apple Maps directions URLs from coordinates/address, and iOS discovery/matches expose directions actions |
| WG-025 Native auth deep links | done | WG-017 | `apps/ios/DogSwipe/**`, `docs/**` | The iOS app registers `dogswipe://auth`, sends it as the SPAPS magic-link redirect URL, parses returned token links, and verifies them through `AuthSessionStore` |

## Ready Frontier

The next ready work is to create a concrete skillbox deploy overlay or continue deeper product slices: server-side address geocoding/travel-time ranking, universal-link polish, release assets, and continuous menu crawling if the snapshot model proves useful.

## Risks

- The original visual reference image is unavailable in this context; final visual parity is blocked on reacquiring that asset or a written design brief.
- Live deploy is blocked until a skillbox overlay names a concrete host, deploy root, env source, production domain, and health check target.
- App Store/TestFlight release is out of scope for this first skeleton until signing assets and bundle ownership are known.

## Remote Checkpoint

- Public repository: https://github.com/build000r/dogswipe
- First pushed commit: `dbf880b`
