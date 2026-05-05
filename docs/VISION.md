# DogSwipe Vision

DogSwipe should feel like the fastest way to find the right local hotdog, not a restaurant directory with a dating-app skin.

## Product Thesis

Local food discovery breaks down because menus are scattered, craving fit is hard to compare, and nearby vendors are usually buried in generic map results. DogSwipe narrows that loop: people swipe through high-signal hotdog cards, the app explains price/distance/crave fit, and the backend records preference signals that can mature into vendor and route workflows.

## Minimum Winning Slice

The first production slice must prove three things:

1. A user can review a local hotdog profile, understand price/distance/crave fit, and make a swipe decision quickly.
2. Swipe state is deterministic, undoable, and testable outside the UI.
3. A SPAPS-aligned backend can expose discovery, swipe, and match endpoints without inventing a parallel auth stack.

## Current Product Contract

- Discovery cards represent hotdogs, not venues: the primary object is a specific item from a vendor.
- A card must show name, style, price, signature notes, distance, walking time, vendor, crave score, and compact menu highlights when a bounded menu snapshot exists; when the app has current location permission, distance should be recomputed from profile coordinates rather than relying on static sample mileage, and users should be able to hand off to Apple Maps from coordinates or pickup address text.
- Cards without remote media still need a product-specific hotdog visual, and craving controls should persist as user-scoped preferences that filter/rank both backend discovery and the local Swift deck.
- Screenshot and demo fixtures must remain deterministic and hotdog-specific across Discover, Matches, Vendor, Review, and Profile so public app captures do not depend on live auth, location prompts, or localhost state.
- Positive swipes are intent signals. Matches are high-crave liked items, not social matches.
- Vendors can submit hotdog listings with menu/media metadata, optional coordinates, and pickup address text, use the iOS Vendor form to resolve pickup addresses into coordinates, refresh a bounded menu URL snapshot for their own listings, and revise change-requested listings back into review; configured admins can approve/reject/request edits and refresh stale vendor menu snapshots in bounded batches. Production can opt into the same stale-menu refresh as a bounded background worker, and the API can derive short menu highlights from those snapshots without turning DogSwipe into a full crawler.
- Production identity is backend-owned through SPAPS; the app may use a publishable key for native magic-link auth, handle `dogswipe://auth` and configured HTTPS universal-link returns, store access/refresh JWTs in Keychain, and send only user bearer tokens to the DogSwipe API.
- Local sample data is intentionally food-like and vendor-like so screenshots, demos, and API examples stay anchored to the hotdog product.

## Non-Goals For The First Slice

- Payments or booking
- Real-time chat
- Recommendation ML
- App Store signing and TestFlight automation
- Live routing beyond Apple Maps handoff
- Crawler-based menu indexing

These are valuable later, but they would dilute the core loop before the app has a reliable discovery contract.

## Quality Bar

- SwiftUI uses shared tokens for spacing, color, typography, radius, and controls.
- Core matching logic lives in a Swift package with unit tests.
- Backend routes are covered by API and service tests with coverage above 80%.
- Auth integration follows Sweet Potato contracts: JWTs for user-scoped routes, app keys for service calls, no local fake auth contract in production.
- iOS release-facing metadata includes a hotdog-specific app icon, accent color, privacy manifest for auth email and precise location use, associated-domains entitlement plumbing, and an Apple app-site association deploy template.
- CI blocks regressions in backend coverage, scoped CRAP score, SwiftUI drift, architecture-diagram preflight, deploy preflight, iOS release assets, iOS build/test gates, and screenshot UI smoke.
- Public docs distinguish implemented behavior from roadmap.
