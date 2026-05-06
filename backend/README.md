# DogSwipe Backend

FastAPI + PostgreSQL backend for DogSwipe, a swipe-first local hotdog discovery app. It uses the Sweet Potato `spaps-server-quickstart` package for service settings, health checks, and SPAPS auth integration.

## Local Install

```bash
make backend-install-local
make backend-test
```

## API

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Shared quickstart health endpoint |
| `GET` | `/v1/discovery` | Preference-filtered local hotdogs available for the swipe deck; accepts optional `latitude` and `longitude` query params |
| `POST` | `/v1/swipes` | Record a swipe decision for the authenticated/local user |
| `GET` | `/v1/matches` | Return high-crave liked hotdogs for the authenticated/local user |
| `GET` | `/v1/preferences` | Return user-scoped craving preferences |
| `PUT` | `/v1/preferences` | Save user-scoped craving preferences |
| `GET` | `/v1/vendor/submissions` | Return the authenticated/local user's submitted hotdog listings |
| `POST` | `/v1/vendor/submissions` | Submit a vendor-owned hotdog listing for review |
| `PUT` | `/v1/vendor/submissions/{id}` | Revise an owned pending or change-requested listing |
| `POST` | `/v1/vendor/submissions/{id}/ingest-menu` | Fetch and store a bounded menu URL snapshot for an owned listing |
| `GET` | `/v1/admin/vendor/submissions` | Return pending vendor submissions for configured admins |
| `POST` | `/v1/admin/vendor/submissions/{id}/approve` | Approve a pending submission into discovery |
| `POST` | `/v1/admin/vendor/submissions/{id}/request-changes` | Send a pending submission back to the vendor with a note |
| `POST` | `/v1/admin/vendor/submissions/{id}/reject` | Reject a pending submission with a note |

## Hotdog Profile Contract

`GET /v1/discovery` and `GET /v1/matches` return profiles shaped like this:

```json
{
  "id": "hotdog-chicago",
  "name": "Chicago Classic",
  "style": "Chicago style",
  "price_dollars": 6.49,
  "signature_notes": "All-beef dog, mustard, relish, onions, tomato, sport peppers, pickle spear, celery salt.",
  "distance_miles": 0.3,
  "latitude": 41.8837,
  "longitude": -87.6248,
  "walking_time_minutes": 6,
  "vendor_name": "Street Vendor Pack",
  "address_text": "35 E Randolph St, Chicago, IL",
  "image_url": null,
  "menu_url": null,
  "menu_status": null,
  "menu_excerpt": null,
  "menu_highlights": ["Mild", "All-Beef", "Crunchy", "Popular"],
  "menu_checked_at": null,
  "media_alt_text": "Chicago-style hotdog with mustard, relish, onions, tomato, sport peppers, pickle spear, and celery salt.",
  "crave_score": 0.94,
  "availability_status": "available",
  "review_note": null,
  "last_verified_at": null,
  "last_reviewed_at": null
}
```

`POST /v1/swipes` accepts only `profile_id` and `decision`. Client-supplied `user_id` fields are rejected; production identity comes from SPAPS middleware, and local development can use `X-DogSwipe-User-ID` only while auth is disabled.

## Preference Contract

`GET /v1/preferences` and `PUT /v1/preferences` are user-scoped through the same backend-owned identity path as swipes and matches:

```json
{
  "max_distance_miles": 10,
  "spicy_friendly": true,
  "classic_only": false
}
```

Client-supplied `user_id` fields are rejected here too.

`GET /v1/discovery` resolves the same current user, loads saved preferences, removes hotdogs beyond `max_distance_miles`, removes non-classic items when `classic_only` is true, then ranks the remaining cards by crave score, distance fit, and spicy/classic fit. If the client supplies `latitude` and `longitude`, the backend recomputes each coordinate-backed profile's `distance_miles` from that user location before filtering/ranking. Profiles without coordinates keep their stored fallback distance. That keeps backend discovery aligned with the Swift `MatchScorer` used by the local deck and offline fallback data.

## Vendor Submission Contract

`POST /v1/vendor/submissions` accepts a hotdog listing draft, derives ownership from the backend auth context, and stores it as `pending_review` so it does not enter discovery until a configured admin approves it:

```json
{
  "name": "Boardwalk Snap",
  "style": "Classic cart dog",
  "price_dollars": 6.25,
  "signature_notes": "Griddled bun, beef frank, mustard, relish, and onion.",
  "distance_miles": 1.8,
  "latitude": 43.6532,
  "longitude": -79.3832,
  "vendor_name": "Boardwalk Dogs",
  "address_text": "100 Queen St W, Toronto, ON",
  "image_url": "https://cdn.example.com/boardwalk.jpg",
  "menu_url": "https://boardwalk.example.com/menu",
  "media_alt_text": "Classic hotdog on a paper tray"
}
```

`address_text` is optional display text for the pickup location. If coordinates are present, iOS prefers those for Apple Maps directions; otherwise it falls back to the address text. The backend treats geocoding as a client/provider concern; the iOS Vendor form can resolve pickup address text into coordinates before submission.

`GET /v1/vendor/submissions` returns only submissions owned by the authenticated/local user. `PUT /v1/vendor/submissions/{id}` lets that owner revise `pending_review` or `changes_requested` listings and returns the listing to `pending_review`. Client-supplied `user_id` fields are rejected.

`POST /v1/vendor/submissions/{id}/ingest-menu` is owner-scoped. If the listing has a `menu_url`, the backend performs a bounded HTTP(S) fetch, extracts a short text snapshot from HTML or plain text, and stores `menu_status`, `menu_excerpt`, and `menu_checked_at` on the profile. Response payloads also derive short `menu_highlights` from the latest excerpt for card display. Supported status values are `ok`, `missing_url`, `invalid_url`, `fetch_failed`, and `empty`. Revising a listing clears any stale menu snapshot fields.

## Admin Review Contract

Admin routes use the same backend-owned identity path and require the resolved user id to appear in `DOGSWIPE_ADMIN_USER_IDS`. In auth-disabled local mode, that default user is `local-dev-user`.

```json
{
  "crave_score": 0.86
}
```

`POST /v1/admin/vendor/submissions/{id}/approve` sets the listing to `available`, records `last_verified_at`, and lets the approved hotdog appear in discovery.

Rejection and edit requests use a required review note:

```json
{
  "review_note": "Add a current menu URL before review."
}
```

`POST /v1/admin/vendor/submissions/{id}/request-changes` sets `changes_requested`, stores the note for the vendor, and removes the listing from the pending admin queue until the owner resubmits it. `POST /v1/admin/vendor/submissions/{id}/reject` sets `rejected`; rejected listings stay out of discovery and are not editable through the owner resubmission endpoint.

## Migrations

Production schema changes are managed by Alembic:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

Current head is `0008`, which adds optional pickup address text for profile display and iOS Maps directions fallback.
