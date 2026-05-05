# DogSwipe Vision

DogSwipe should feel like the fastest way to find the right local hotdog, not a restaurant directory with a dating-app skin.

## Product Thesis

Local food discovery breaks down because menus are scattered, craving fit is hard to compare, and nearby vendors are usually buried in generic map results. DogSwipe narrows that loop: people swipe through high-signal hotdog cards, the app explains price/distance/crave fit, and the backend records preference signals that can mature into vendor and route workflows.

## Minimum Winning Slice

The first production slice must prove three things:

1. A user can review a local hotdog profile, understand price/distance/crave fit, and make a swipe decision quickly.
2. Swipe state is deterministic, undoable, and testable outside the UI.
3. A SPAPS-aligned backend can expose discovery, swipe, and match endpoints without inventing a parallel auth stack.

## Non-Goals For The First Slice

- Vendor admin tooling
- Payments or booking
- Real-time chat
- Recommendation ML
- App Store release assets

These are valuable later, but they would dilute the core loop before the app has a reliable discovery contract.

## Quality Bar

- SwiftUI uses shared tokens for spacing, color, typography, radius, and controls.
- Core matching logic lives in a Swift package with unit tests.
- Backend routes are covered by API and service tests with coverage above 80%.
- Auth integration follows Sweet Potato contracts: JWTs for user-scoped routes, app keys for service calls, no local fake auth contract in production.
- Public docs distinguish implemented behavior from roadmap.
