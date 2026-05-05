# SPAPS Usage Audit Report

Date: 2026-05-05

## Repo Inventory

| Repo | Signals | Findings |
| --- | --- | --- |
| `dogswipe` | direct SPAPS API, SPAPS local-dev docs, `spaps-server-quickstart` | No scanner findings |

## Findings

### None: DogSwipe Matches The Current Quickstart Contract

The audit scanner reports `dogswipe` on `spaps-server-quickstart` with no high-, medium-, or low-severity findings. The active Sweet Potato checkout reports `spaps-server-quickstart` `0.5.1`, and DogSwipe declares `spaps-server-quickstart~=0.5.1`.

## Applied Contract

DogSwipe follows the current quickstart contract:

- server-side app uses `spaps-server-quickstart`
- production auth should use `Authorization: Bearer <jwt>` via `SpapsAuthMiddleware`
- local dev may disable SPAPS auth explicitly
- no browser/client code should send a secret SPAPS API key
- user-scoped swipes, matches, craving preferences, vendor submissions/resubmissions, and admin review routes derive identity from backend auth context
- iOS uses a SPAPS publishable key for magic-link auth, stores access/refresh JWTs in Keychain, and injects only the access bearer as `Authorization`
