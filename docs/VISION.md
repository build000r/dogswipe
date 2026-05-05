# DogSwipe Vision

DogSwipe should feel like the fastest humane way to find the right dog, not a catalog with a dating-app skin.

## Product Thesis

Adoption discovery breaks down because profiles are scattered, compatibility is hard to compare, and shelters cannot tell which interest is serious. DogSwipe narrows that loop: people swipe through high-signal dog cards, the app explains compatibility, and the backend records preference signals that can mature into shelter workflows.

## Minimum Winning Slice

The first production slice must prove three things:

1. A user can review a dog profile, understand fit, and make a swipe decision quickly.
2. Swipe state is deterministic, undoable, and testable outside the UI.
3. A SPAPS-aligned backend can expose discovery, swipe, and match endpoints without inventing a parallel auth stack.

## Non-Goals For The First Slice

- Shelter admin tooling
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
