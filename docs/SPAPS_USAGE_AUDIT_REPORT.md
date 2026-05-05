# SPAPS Usage Audit Report

Date: 2026-05-05

## Repo Inventory

| Repo | Signals | Findings |
| --- | --- | --- |
| `../htma_server` | `spaps`, `spaps-python-client`, `spaps-server-quickstart`, direct SPAPS API, local dev | One low-severity dependency drift finding |

## Findings

### Low: `spaps-server-quickstart` Version Drift

`../htma_server/pyproject.toml` declares `spaps-server-quickstart~=0.5.0`, while the active Sweet Potato checkout reports `0.5.1`.

Recommendation: DogSwipe should start on `spaps-server-quickstart~=0.5.1` and avoid copying older auth scaffolding.

## Applied Contract

DogSwipe follows the current quickstart contract:

- server-side app uses `spaps-server-quickstart`
- production auth should use `Authorization: Bearer <jwt>` via `SpapsAuthMiddleware`
- local dev may disable SPAPS auth explicitly
- no browser/client code should send a secret SPAPS API key
