# iOS Analytics Contract

DogSwipe's iOS analytics surface is intentionally small and contains no email addresses, coordinates, JWTs, SPAPS keys, or user-entered search text. Events are emitted through `DogSwipeAnalytics` and can be wired to a production sink without changing SwiftUI views.

| Event | When | Parameters |
| --- | --- | --- |
| `ios_screen_viewed` | Discover, Matches, Vendor, Review, or Profile appears | `screen` |
| `ios_discovery_swipe` | User records a pass, like, super-like, or undo-supported deck decision | `decision`, `profile_id` |
| `ios_auth_magic_link_requested` | User submits a magic-link request from Profile | `method=email_magic_link` |
| `ios_auth_magic_link_verify_submitted` | User submits or opens a magic-link verification token | `method=email_magic_link` |
| `ios_order_cta_tapped` | User taps the match detail order CTA | `profile_id` |
| `ios_match_keep_swiping_tapped` | User leaves the match detail to continue discovery | `profile_id` |

The unit test `testAnalyticsContractRecordsCanonicalEventsWithoutPII` guards the canonical event names and checks that sensitive fields such as `email`, `token`, `jwt`, `latitude`, and `longitude` are not emitted.
