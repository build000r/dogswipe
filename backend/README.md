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
  "crave_score": 0.91,
  "availability_status": "available"
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

## Migrations

Production schema changes are managed by Alembic:

```bash
DATABASE_URL=postgresql+asyncpg://... make migrate
DATABASE_URL=postgresql+asyncpg://... make migration-current
```

Current head is `0003`, which adds user-scoped craving preferences after the hotdog profile pivot.
