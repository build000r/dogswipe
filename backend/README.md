# DogSwipe Backend

FastAPI starter for DogSwipe using the Sweet Potato `spaps-server-quickstart` package.

## Local Install

```bash
make backend-install-local
make backend-test
```

## API

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Shared quickstart health endpoint |
| `GET` | `/v1/discovery` | Profiles available for the swipe deck |
| `POST` | `/v1/swipes` | Record a swipe decision |
| `GET` | `/v1/matches` | Return matched profiles |
