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
| `GET` | `/v1/discovery` | Ranked local hotdogs available for the swipe deck |
| `POST` | `/v1/swipes` | Record a swipe decision for the authenticated/local user |
| `GET` | `/v1/matches` | Return high-crave liked hotdogs for the authenticated/local user |
| `GET` | `/v1/preferences` | Return user-scoped craving preferences |
| `PUT` | `/v1/preferences` | Save user-scoped craving preferences |
| `GET` | `/v1/vendor/submissions` | Return the authenticated/local user's submitted hotdog listings |
| `POST` | `/v1/vendor/submissions` | Submit a vendor-owned hotdog listing for review |
| `GET` | `/v1/admin/vendor/submissions` | Return pending vendor submissions for configured admins |
| `POST` | `/v1/admin/vendor/submissions/{id}/approve` | Approve a pending submission into discovery |

## Hotdog Profile Contract

`GET /v1/discovery` and `GET /v1/matches` return profiles shaped like this:

```json
{
  "id": "hotdog-coney",
  "name": "Coney Classic",
  "style": "Chili dog",
  "price_dollars": 6.5,
  "signature_notes": "Beef frank, snap casing, chili, onion, and yellow mustard.",
  "distance_miles": 1.2,
  "vendor_name": "Franklin Cart",
  "image_url": null,
  "menu_url": null,
  "media_alt_text": null,
  "crave_score": 0.91,
  "availability_status": "available",
  "last_verified_at": null
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

## Vendor Submission Contract

`POST /v1/vendor/submissions` accepts a hotdog listing draft, derives ownership from the backend auth context, and stores it as `pending_review` so it does not enter discovery until a configured admin approves it:

```json
{
  "name": "Boardwalk Snap",
  "style": "Classic cart dog",
  "price_dollars": 6.25,
  "signature_notes": "Griddled bun, beef frank, mustard, relish, and onion.",
  "distance_miles": 1.8,
  "vendor_name": "Boardwalk Dogs",
  "image_url": "https://cdn.example.com/boardwalk.jpg",
  "menu_url": "https://boardwalk.example.com/menu",
  "media_alt_text": "Classic hotdog on a paper tray"
}
```

`GET /v1/vendor/submissions` returns only submissions owned by the authenticated/local user. Client-supplied `user_id` fields are rejected.

## Admin Review Contract

Admin routes use the same backend-owned identity path and require the resolved user id to appear in `DOGSWIPE_ADMIN_USER_IDS`. In auth-disabled local mode, that default user is `local-dev-user`.

```json
{
  "crave_score": 0.86
}
```

`POST /v1/admin/vendor/submissions/{id}/approve` sets the listing to `available`, records `last_verified_at`, and lets the approved hotdog appear in discovery.

## Migrations

Production schema changes are managed by Alembic:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

Current head is `0004`, which adds vendor-owned hotdog submissions and menu/media metadata after user-scoped craving preferences.
