# DSR Native Token Candidate

Date: 2026-06-01

DogSwipe remains a Design System Registry `native-token-candidate`, not a
`native-token-pilot`.

## Projection Record

| Field | Value |
| --- | --- |
| Candidate bead | `design-system-registry-epic-design-layer-fleet-oupw.13` |
| Adapter family | `swiftui-token` |
| Candidate tier | `native-token-candidate` |
| DSR generated source | `design-system-registry/registry/native-tokens/strike-mish.json` |
| DSR source item | `strike-mish` |
| DSR source checksum | `bf0e227a44ec5d84` |
| DSR artifact checksum | `f43aba2521d2c5f4` |
| Local adapter seam | `apps/ios/DogSwipe/DogSwipe/DesignSystem/DogSwipeTheme.swift` |
| Metadata guard | `apps/ios/DogSwipe/DogSwipeTests/DesignSystemTokenTests.swift` |
| Current proof status | `PROOF_ARTIFACT_MISSING` for a tracked DSR proof artifact |

## Stop Condition

This record only names the generated DSR native-token source and the local
SwiftUI adapter seam. It does not claim that DogSwipe consumes DSR token values
at runtime, and it does not satisfy `native-token-pilot`.

The missing proof artifact is a tracked native screenshot/build proof artifact
wired to a DSR adoption manifest. Until that artifact exists, the DSR fleet
audit should continue to report DogSwipe as `native-token-candidate`.

## Validation Path

DSR-side validation:

```bash
corepack pnpm native-token:check
corepack pnpm native-usage-audit:fleet
```

DogSwipe-side candidate scaffold validation:

```bash
make swift-test
```

Native build or screenshot proof candidates, when simulator/device access is
available:

```bash
make ios-ui-test
make ios-screenshots
```
