# DogSwipe Vision

DogSwipe should feel like the fastest way to find the right local hotdog: a Tinder-style street-vendor pack for hotdogs, not a restaurant directory with a dating-app skin.

## Product Thesis

Local food discovery breaks down because menus are scattered, craving fit is hard to compare, and nearby vendors are usually buried in generic map results. DogSwipe narrows that loop: people swipe through high-signal hotdog cards, search bounded menu snapshots for craving terms, the app explains price/distance/crave fit, and the backend records preference signals that can mature into vendor and route workflows.

The visual thesis is product-first and playful without becoming a generic food feed: cream surfaces, red/mustard action colors, a script-like DogSwipe brand mark, a Chicago-style hero dog, a "Swipe right for hotdogs" control deck, and a match screen that turns a positive swipe into a concrete order CTA.

## Minimum Winning Slice

The first production slice must prove three things:

1. A user can review a local hotdog profile, understand price/distance/crave fit, and make a swipe decision quickly.
2. Swipe state is deterministic, undoable, and testable outside the UI.
3. A SPAPS-aligned backend can expose discovery, swipe, and match endpoints without inventing a parallel auth stack.

## Current Product Contract

- Discovery cards represent hotdogs, not venues: the primary object is a specific item from a vendor, with the hotdog image and item name carrying the first screen.
- A card must show name, style, price, signature notes, distance, walking time, vendor, crave score, and compact menu highlights when a bounded menu snapshot exists; users can search hotdog/menu fields by craving terms without requiring broad crawler indexing; when the app has current location permission, distance should be recomputed from profile coordinates rather than relying on static sample mileage, users should be able to preview a live walking route on the card, and full navigation should hand off to Apple Maps from coordinates or pickup address text.
- Cards without remote media still need a product-specific hotdog visual, and craving controls should persist as user-scoped preferences that filter/rank both backend discovery and the local Swift deck.
- Screenshot and demo fixtures must remain deterministic and hotdog-specific across Discover, Matches, Orders, Vendor, Review, and Profile so public app captures do not depend on live auth, location prompts, or localhost state.
- Positive swipes are intent signals. Matches are high-crave liked hotdogs, not social matches, and they should preserve the same practical context the user needed while swiping: current distance, walking time, a quick route preview, and Apple Maps directions.
- The match surface should feel like "It's a Match!" for a hotdog: show the hero dog, price, short ingredient notes, selectable add-ons, and a backend-owned order draft with immediate confirmation, a real bag count, and a My Orders list before payment or fulfillment workflows.
- Vendors can submit hotdog listings with menu/media metadata, optional coordinates, and pickup address text, use the iOS Vendor form to resolve pickup addresses into coordinates, refresh a bounded menu URL snapshot for their own listings, and revise change-requested listings back into review; configured admins can approve/reject/request edits and refresh stale vendor menu snapshots in bounded batches. Production can opt into the same stale-menu refresh as a bounded background worker, and the API can derive short menu highlights plus menu-query discovery from those snapshots without turning DogSwipe into a full crawler.
- Production identity is backend-owned through SPAPS; the public `spaps.app.json` descriptor fixes the application slug to `dogswipe` without storing keys, renders a supported `browser_auth` self-service registration payload for the private operator step, the app may use a publishable key for native magic-link auth, handle `dogswipe://auth` and configured HTTPS universal-link returns, store access/refresh JWTs in Keychain, and send only user bearer tokens to the DogSwipe API.
- Production telemetry must stay narrow and no-PII: screen views, swipes, auth button submissions, and match/order CTAs are enough for the first slice.
- Local sample data is intentionally food-like and vendor-like so screenshots, demos, and API examples stay anchored to the hotdog product.

## Non-Goals For The First Slice

- Payments, booking, or fulfillment-backed order management
- Real-time chat
- Recommendation ML
- Live App Store/TestFlight submission without Apple signing and App Store Connect credentials
- Full turn-by-turn navigation or route persistence beyond lightweight MapKit previews
- Broad crawler-based menu indexing beyond bounded snapshot search

These are valuable later, but they would dilute the core loop before the app has a reliable discovery contract.

## Release Reality

The application and deploy contract are on a real production host, but public proof is still edge-gated. The production host has the private DogSwipe env rendered, Alembic migrations applied through `0009`, Postgres, Redis, and the API container running healthy on the current GHCR full-SHA image, plus a staged DogSwipe reverse-proxy config and AASA payload. The current usable domain path is `dogswipe.buildooor.com`, which needs a DNS-edit-capable Cloudflare token or a manual `A` record to `104.131.188.214`; the discovered credentials can read the active `buildooor.com` zone but cannot write the DogSwipe record. If that domain stays canonical, the SPAPS app allowed origins also need `https://dogswipe.buildooor.com`. After DNS/SPAPS origin alignment, the remaining live work is certificate issuance, proxy enable/reload, public health/AASA verification, then the signed TestFlight handoff once Apple/App Store Connect credentials are available.

## Quality Bar

- SwiftUI uses shared tokens for spacing, color, typography, radius, and controls.
- Core matching logic lives in a Swift package with unit tests.
- Backend routes are covered by API and service tests with coverage above 80%.
- Auth integration follows Sweet Potato contracts: JWTs for user-scoped routes, app keys for service calls, no local fake auth contract in production.
- iOS release-facing metadata includes a hotdog-specific app icon, accent color, privacy manifest for auth email and precise location use, associated-domains entitlement plumbing, a renderable Apple app-site association deploy template, and non-secret signed-archive/TestFlight handoff targets.
- SwiftUI should preserve the street-vendor visual language from the DogSwipe reference surface: cream card stacks, mustard/red/pickle accents, compact chips, clear swipe controls, and no generic restaurant-directory chrome.
- CI blocks regressions in backend coverage, scoped CRAP score, SwiftUI drift, architecture-diagram preflight, SPAPS app contract and registration-payload render, deploy preflight/readiness, iOS release assets, iOS build/test gates, and screenshot UI smoke.
- Public docs distinguish implemented behavior from roadmap.
