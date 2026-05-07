# SPAPS Application Handoff

DogSwipe keeps the public application contract in [`../spaps.app.json`](../spaps.app.json)
and keeps raw SPAPS IDs and keys out of git. Use this runbook when an operator
is ready to provision the private `dogswipe` application row in Sweet Potato.

## Render The Payload

Set the production release values first:

```bash
export DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=<dogswipe-api-domain>
export DOGSWIPE_RELEASE_SPAPS_ORIGIN=https://<dogswipe-api-domain>
export DOGSWIPE_RELEASE_AUTH_REDIRECT_URL=https://<dogswipe-api-domain>/auth
export DOGSWIPE_RELEASE_AUTH_UNIVERSAL_LINK_HOSTS=<dogswipe-api-domain>
export IOS_RELEASE_BUNDLE_ID=com.build000r.dogswipe

make spaps-registration-payload > /tmp/dogswipe-spaps-application.json
```

The payload uses the current Sweet Potato `browser_auth` application blueprint
and layers DogSwipe native-iOS metadata into `settings.dogswipe`. It includes:

- `slug: dogswipe`
- HTTPS `allowed_origins` for the iOS `Origin` header and universal-link host
- `magic_link_redirect_url`, `password_reset_redirect_url`, and `email_redirect_url`
- `dogswipe://auth` as native app metadata
- `/auth` and `/auth/callback` AASA paths

For public template validation only:

```bash
ALLOW_PLACEHOLDERS=true make spaps-registration-payload
```

## Update An Existing App Origin

If the `dogswipe` app already exists and only needs the final HTTPS origin,
render an idempotent operator handoff instead of creating a second app:

```bash
DOGSWIPE_RELEASE_ASSOCIATED_DOMAIN=<dogswipe-api-domain> \
make spaps-origin-handoff > /tmp/dogswipe-spaps-origin.sql.txt
```

The output contains a read-only check and a transaction that merges the required
origin into `applications.allowed_origins` while preserving existing origins.
It does not contain SPAPS keys or database passwords. Review it, apply it from
the SPAPS production host, then rerun release readiness with the same origin.

For public template validation only:

```bash
ALLOW_PLACEHOLDERS=true make spaps-origin-handoff-template
```

## Create The SPAPS App

Authenticate to the SPAPS self-service console with the private password, then
submit the rendered payload:

```bash
export SPAPS_API_URL=https://api.sweetpotato.dev
export SPAPS_SELF_SERVICE_PASSWORD=<private-password>

export SPAPS_SELF_SERVICE_TOKEN="$(
  curl -sS -X POST "$SPAPS_API_URL/api/self-service/auth" \
    -H 'Content-Type: application/json' \
    -d "{\"password\":\"$SPAPS_SELF_SERVICE_PASSWORD\"}" \
    | jq -r '.data.token // .token'
)"

curl -sS -X POST "$SPAPS_API_URL/api/self-service/applications" \
  -H "Authorization: Bearer $SPAPS_SELF_SERVICE_TOKEN" \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/dogswipe-spaps-application.json \
  > /tmp/dogswipe-spaps-created.json
```

Do not commit `/tmp/dogswipe-spaps-created.json`. It contains one-time keys.

## Store Private Env Values

Map the response into the private env manager or ignored deployment env file:

```bash
export SPAPS_APPLICATION_ID="$(
  jq -r '.data.application.id // .application.id' /tmp/dogswipe-spaps-created.json
)"
export SPAPS_API_KEY="$(
  jq -r '.data.secret_key // .secret_key // .data.api_key // .api_key' /tmp/dogswipe-spaps-created.json
)"
export DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY="$(
  jq -r '.data.publishable_key // .publishable_key' /tmp/dogswipe-spaps-created.json
)"
```

`SPAPS_API_KEY` is server-only. `DOGSWIPE_RELEASE_SPAPS_PUBLISHABLE_KEY` is the
only SPAPS key that should reach the signed iOS build.

## Verify Handoff

Run the non-secret gates from this repo:

```bash
make spaps-app-contract
make spaps-origin-handoff-template
make deploy-release-readiness
```

Then verify the CLI can resolve the registered application slug:

```bash
node ../sweet-potato/packages/spaps/bin/spaps.js connect \
  --client-id dogswipe \
  --server-url "$SPAPS_API_URL"
```
