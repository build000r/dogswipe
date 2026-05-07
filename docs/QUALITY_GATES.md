# Quality Gates

Last verified: 2026-05-06

| Gate | Command | Result |
| --- | --- | --- |
| Swift package tests | `make swift-test` | 35 tests passed |
| iOS smoke build | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'generic/platform=iOS' build` | passed |
| iOS unit tests | `xcodebuild -quiet -project apps/ios/DogSwipe/DogSwipe.xcodeproj -scheme DogSwipe -destination 'platform=iOS Simulator,id=<available iPhone simulator UDID>' -only-testing:DogSwipeTests test` | passed |
| iOS screenshot UI smoke | `make ios-ui-test` | 8 isolated UI tests passed across Discover, draggable card advancement, Matches, match add-to-order, Orders, Vendor, Review, and Profile using direct screenshot-mode tab launches; Discover asserts visible `Live walk` and `Directions` route controls |
| iOS screenshot export | `make ios-screenshots` | 6 PNG attachments exported under `.build/ios-screenshots/attachments` |
| Backend API tests | `make backend-test` | 84 tests passed |
| Backend coverage | `make coverage` | 89.83% total coverage |
| Clean backend install | `python3.12 -m venv /tmp/... && pip install -e 'backend[test]'` | passed |
| Backend lint | `make lint` | passed |
| Backend typecheck | `make typecheck` | passed |
| Alembic migration smoke | `make backend-test` | migration test upgraded to `0009` and downgraded to `base` |
| Backend container build | `docker build -q backend` | built image `sha256:36e49501e78985bb76212fbb7498bac4662a19daf667dcd1618be3627777698e` |
| Backend container publish | GitHub Actions `25442723419` on `main` | pushed `ghcr.io/build000r/dogswipe:7e2a5221091fa40da0344e44ba6722858405dcf9` and `latest`; full-SHA tag has a readable Docker manifest with config digest `sha256:c6ec27bbbe0fffc5c77edb0e05dafde8be7eac2d4f775e61601bf612dda223a6` |
| Production Compose config | `make deploy-config` | passed |
| Deploy preflight | `make deploy-preflight` | CI runner: 18 passed, 1 expected warning for absent local `reverse-proxy` network, 0 failed; local private handoff preflight passes when the shared network exists |
| AASA render smoke | `make deploy-render-aasa AASA_APPLE_TEAM_ID=ABCDE12345` | rendered bundle-aware Apple app-site association payload |
| Release readiness | `make deploy-release-readiness ALLOW_PLACEHOLDERS=true ...` | 21 passed, 2 skipped, 0 failed, including SPAPS app contract and registration-payload verification; DNS is skipped unless `CHECK_DNS=true` |
| DNS handoff | `make deploy-dns-handoff-template`; `make deploy-dns-handoff DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=dogswipe.buildooor.com DOGSWIPE_EXPECTED_A_RECORD=104.131.188.214` | rendered the exact DNS A record, private release env alignment, and follow-up DNS/public-URL preflight commands without secrets; template path is now covered by CI |
| DNS preflight | `make deploy-dns-preflight-template`; manual probes for `buildooor.com` and `dogswipe.build000r.com` | template target proves the pass path with `example.com` and the expected authority-failure path with `dogswipe.invalid`; active zone case passed with 4 passed, 2 skipped, 0 failed; current DogSwipe candidate failed on missing `build000r.com` NS/SOA authority |
| Live readiness wrapper | `make deploy-live-readiness-template` | overlay, DNS, release-readiness, and optional private env/post-deploy skips ran in operator order without secrets |
| Private deploy handoff template | `make deploy-private-handoff-template` | rendered throwaway private overlay/env files, validated overlay, and ran deploy preflight with 19 passed, 0 warnings, 0 failed |
| Host bootstrap template | `make deploy-host-bootstrap-template` in GitHub Actions `25431174343` | installed non-secret deploy artifacts into a temporary host layout and verified deploy/env/data paths |
| Private release-readiness probe | non-repo overlay for `dogswipe.build000r.com` plus ignored SPAPS env values and `IOS_RELEASE_DEVELOPMENT_TEAM=84GGQ3RBDZ` | pre-DNS-gate probe passed with 21 passed, 1 skipped, 0 failed; no secrets printed. Current release-readiness can include DNS with `CHECK_DNS=true` once the canonical domain is live |
| Production host/DNS probe | deploy/`ssh-info` read-only status, host bootstrap apply, host-side deploy preflight, and DNS/health checks for `dogswipe.build000r.com` and `dogswipe.buildooor.com` | SPAPS host reachable and healthy over legacy key-backed SSH; non-secret DogSwipe deploy artifacts are installed under `/opt/dogswipe`; `/opt/envs/dogswipe` and the PostgreSQL data path exist; host-side template preflight passes; `dogswipe.build000r.com` unresolved; `build000r.com` has no public NS/SOA; `buildooor.com` is active on Cloudflare but has no `dogswipe` record |
| Cloudflare DNS credential probe | local ignored env-manager token, logged-in Wrangler OAuth, and constrained `build000r/buildooor` GitHub Actions DNS upsert | no token values printed or committed; local env-manager token failed `401`; Wrangler OAuth had zone read but DNS write failed `403`; buildooor Actions secret also failed the DNS upsert with `403`, so a DNS-edit-capable token or manual record is still required |
| Skillbox overlay template | `make deploy-overlay-template` | 15 passed, 0 failed |
| SwiftUI drift scan | `make drift` | 0 Swift findings |
| iOS release assets | `make ios-release-assets` | AppIcon, accent color, privacy manifest, associated-domains entitlement, bundle-aware Apple app-site association template, build-setting-backed auth config, and App Store Connect export option plists passed |
| CRAP score | `make crap` | `FINAL_SCORE: 9.00` |
| MMDX preflight | `make mmdx-preflight` | 3 charts passed |
| SPAPS app contract | `make spaps-app-contract` | public descriptor declares the `dogswipe` slug, env-only private key handoff, and renderable `browser_auth` self-service registration payload |
| CI quality enforcement | GitHub Actions `25465439287` for pushed `main` commit `b2d9384` | coverage XML feeds blocking CRAP; MMDX, SPAPS app contract, registration-payload validation, SwiftUI drift, deploy/AASA render, private handoff renderers, host bootstrap, DNS handoff template, DNS preflight template, live-readiness template, release-readiness, Docker build, conditional Docker publish, Swift package, durable order API/client changes, and iOS gates fail on regressions; `backend`, `swift-package`, and `ios` jobs all passed |
| SPAPS usage audit | `python3 ../sweet-potato/skills/sweet-potato-usage-audit/scripts/audit_sweet_potato_usage.py --sweet-potato-root ../sweet-potato .` | 0 high, 0 medium, 0 low |

## Current Product Evidence

- `DogSwipeAPIClient` decodes backend snake_case profile payloads.
- `DogSwipeAPIClient` encodes swipe requests without client-controlled user identity.
- `DogSwipeAPIClient` can attach a trimmed user bearer token from an injected provider and omits blank auth values.
- `spaps.app.json` gives the SPAPS CLI and release handoff a non-secret `dogswipe` application descriptor while requiring private env values for the raw application ID, server secret key, and publishable key.
- `make spaps-registration-payload` renders the non-secret Sweet Potato self-service application body with the supported `browser_auth` blueprint, HTTPS magic-link redirects, universal-link hosts, and native DogSwipe metadata.
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
- `POST /v1/orders` creates authenticated/local user-scoped order drafts from an orderable hotdog profile and canonical server add-ons; `GET /v1/orders` returns only the current user's durable drafts.
- The Matches tab supports selectable add-ons, saves the selected hotdog through the backend order API, updates the DogSwipe bag count from state instead of a hardcoded badge, and keeps the payment/fulfillment boundary out of the first slice.
- The My Orders tab lists durable backend drafts with hotdog, vendor, add-on summary, status, and total.
- The iOS Vendor form can resolve pickup address text into latitude/longitude through an injected CoreLocation geocoder with covered success/failure states.
- Hotdog profile payloads derive short `menu_highlights` from bounded menu snapshots; Swift decodes the array, the Discover screen can search those bounded menu/profile signals, and iOS discovery/vendor summaries display them.
- iOS native sign-in stores SPAPS access/refresh JWTs in Keychain, refreshes sessions, and injects only the access bearer into the shared API client.
- iOS registers `dogswipe://auth`, parses returned magic-link tokens from custom-scheme or configured HTTPS universal-link callbacks, and verifies deep links through `AuthSessionStore`.
- The iOS target includes a hotdog-specific AppIcon catalog, accent color, and `PrivacyInfo.xcprivacy` declaration for linked auth email and precise location data used only for app functionality; `make ios-release-assets` blocks missing icon slots, alpha-channel icons, privacy manifest drift, non-configurable auth build settings, and stale TestFlight export options.
- `--dogswipe-screenshot-mode` swaps in deterministic hotdog API fixtures, an in-memory token store, a static location provider, and direct initial-tab launches so isolated UI smoke/screenshots cover Discover, Matches, match add-to-order, Orders, Vendor, Review, and Profile without live auth, location prompts, localhost state, or tab-tap timing.
- The deterministic Discover and Matches fixtures now use the supplied DogSwipe reference direction: cream/red/mustard street-vendor chrome, Chicago Classic hero cards, wrapped hotdog chips/add-ons with no right-edge clipping, a draggable "Swipe right for hotdogs" control deck, and a match/order detail whose primary CTA clears the tab bar in exported screenshots.
- `DogSwipeAnalytics` emits a no-PII iOS contract for screen views, discovery swipes, auth submissions, and match/order CTAs; `docs/IOS_ANALYTICS.md` documents the allowed events.
- `POST /v1/vendor/submissions` stores authenticated vendor hotdog listings as `pending_review`; `GET`/`PUT /v1/vendor/submissions` are user-scoped and the iOS Vendor tab can revise change-requested listings.
- `POST /v1/vendor/submissions/{id}/ingest-menu` is owner-scoped, stores bounded menu URL snapshot status/excerpt/timestamp fields, and the iOS Vendor tab can refresh and render the snapshot state.
- `POST /v1/admin/vendor/menus/refresh` is admin-scoped, refreshes stale vendor menu snapshots in bounded batches, reports checked/refreshed/failed counts, and the iOS Admin tab can trigger the refresh.
- Configured admins can list pending vendor submissions, approve one into discovery, reject one, request edits with a review note, and production preflight requires `DOGSWIPE_ADMIN_USER_IDS` when SPAPS auth is enabled.
- Production deploy artifacts define the Compose stack, env contract, host bootstrap, DNS handoff renderer, DNS preflight, live-readiness wrapper, release-readiness checks, post-deploy verification, reverse-proxy template, bundle-aware Apple app-site association render path, and CI workflow.
- CI publishes a deterministic backend image tag to `ghcr.io/build000r/dogswipe:<full-git-sha>` plus `latest` for `main` pushes that change backend/deploy/runtime-relevant files; the current verified tag is `ghcr.io/build000r/dogswipe:7e2a5221091fa40da0344e44ba6722858405dcf9`.
- Private deploy handoff renderers write production env and skillbox overlay files to caller-provided private paths, set owner-only permissions, refuse stdout secret output, and are covered by `make deploy-private-handoff-template`.
- Signed iOS release handoff artifacts define `ios-release-archive`, `ios-testflight-export`, and `ios-testflight-upload` Make targets with build-setting-backed production API/SPAPS/universal-link inputs and App Store Connect export/upload option plists; Apple `.p8`, `.p12`, and `.mobileprovision` files are ignored.
- GitHub Actions enforces backend coverage XML generation, scoped CRAP threshold, MMDX architecture preflight, SPAPS app contract and registration-payload validation, SwiftUI drift, deploy preflight/readiness including host bootstrap, DNS handoff template, DNS preflight template, live-readiness template, and AASA template/render validation, iOS build/test gates, and screenshot UI smoke.
- A DogSwipe skillbox overlay template and validator exist so live deploy setup, including the AASA URL and Apple Team ID contract, can be checked without committing host secrets.
- The ignored local SPAPS handoff file contains non-placeholder private app values in this workspace, and a private release-readiness probe validates the app-side release contract for `dogswipe.build000r.com`; live DNS, private host env rendering, and reverse-proxy activation remain separate infrastructure work.
- The current Cloudflare auth available to this workspace is not sufficient for DNS edits: it can either fail auth entirely or read the `buildooor.com` zone without being allowed to upsert the DogSwipe A record.

## Known Blocks

- Live deployment, production SPAPS auth proof, and hosted universal-link activation are blocked until the canonical domain is real, the production host has the private DogSwipe env source, and the shared reverse proxy serves the API plus Apple app-site association payload. A fresh 2026-05-06 probe shows `build000r.com` has no public NS/SOA, `dogswipe.build000r.com` is unresolved, `buildooor.com` is active on Cloudflare without a DogSwipe subdomain, and the discovered Cloudflare credentials cannot edit DNS. The non-secret DogSwipe host paths and deploy artifacts are now installed, but the private env, proxy site, AASA payload, certificates, and DNS record are still pending.
- Live App Store signing and TestFlight upload remain blocked because bundle ownership, signing assets, and App Store Connect credentials are not available in this workspace.
