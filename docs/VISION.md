# DogSwipe Vision

DogSwipe should feel like the fastest way to plug into your neighborhood's everyday generosity: a swipe-first way to discover what people nearby are making, growing, baking, or have spare of — and to claim it with community credits, not cash. It starts with hotdogs as the flagship category and generalizes to any neighborly offering. It is a local barter economy, not a marketplace optimized for profit.

## Product Thesis

Most "local commerce" apps push people toward running a business: list a product, take payment, optimize for margin. That framing crowds out the person who simply made extra coffee this morning, has a fun recipe to share, will be around tomorrow AM, and would happily hand a cup to a neighbor who'll appreciate it. DogSwipe is for that person and the neighbor on the other side of the swipe.

The loop is barter rebuilt for phones: neighbors post small offerings (a homemade item, extra produce, a signature recipe handed off warm), other neighbors swipe through high-signal cards ranked by craving fit and proximity, and a claim is settled in **credits** rather than dollars. The point is not to make money — it is to get people more ingrained in their community, to make reciprocity easy, and to keep value circulating locally instead of leaking out to payment rails and middlemen.

Hotdogs remain the flagship wedge and the brand: the Chicago-style hero dog, the cream surfaces, the mustard/red action colors, the "Swipe right" control deck. But underneath, the catalog is category-agnostic — a hotdog is just offering category #1. The visual identity stays product-first and playful; it should never feel like a generic restaurant directory or a fintech wallet app.

## The Economic Model (Closed-Loop Community Credits)

Credits are the only way to participate, and they are deliberately a one-way street into the community:

- **Buy in at par.** Credits are purchased 1:1 with dollars (e.g. $10 → 10 credits) through a real payment rail. This is the only place real money enters the system.
- **Hold to participate.** You must hold credits to take part — claiming an offering spends credits; participating is not free-riding.
- **No cash-out, for anyone.** Credits can never be withdrawn back to dollars — not by a buyer, not by a maker. The maker who hands off coffee earns credits and spends them on someone else's offering. Value circulates; it does not get extracted. This is the defining constraint, not a detail.
- **Spend only on others.** Credits are spent on other people's offerings, never self-dealt and never redeemed for fiat. The platform holds the float (the pooled dollars behind outstanding credits) as a community liability, not as revenue to be paid out.
- **Append-only truth.** Every purchase and every spend is a signed, append-only ledger entry. Balances are derived, never hand-edited. Double-spends and race conditions must be impossible by construction.

Tokenomics — issuance policy, demurrage/anti-hoarding, starter grants, pricing of credits, anti-gaming — are intentionally deferred. This document fixes the *invariants* (par purchase, no cash-out, spend-only, ledger-backed); the dials get tuned later.

> **Compliance is load-bearing, not paperwork.** A closed-loop store of value that is redeemable across many *unaffiliated* makers may fall outside common gift-card / closed-loop exemptions and toward money-transmitter / stored-value regulation. The no-cash-out invariant and the float-as-liability accounting are partly *why*; a bounded legal/compliance review gates public launch. Food-handed-between-strangers liability is likewise a conscious, documented decision, not an oversight.

## Minimum Winning Slice

The first production slice of the barter economy must prove four things end to end:

1. A neighbor can post a small local offering (starting with a hotdog, but the catalog is generic) with a pickup window and/or delivery option, and another neighbor can discover it by swiping on cards ranked by craving fit and proximity.
2. A claim settles in credits: the claimer must hold enough credits, the spend is atomic, the maker is credited, and an append-only ledger records both sides. No path withdraws credits to cash.
3. Credits can be bought 1:1 with dollars through a real payment rail, with idempotent settlement, and the platform's outstanding-credit float reconciles exactly to purchases minus nothing-cashed-out.
4. After a confirmed hand-off, both sides can review each other (giver ↔ receiver), and reputation surfaces back into discovery.

A SPAPS-aligned backend continues to own identity; the credit, ledger, and fulfillment systems are new and must not invent a parallel auth stack.

## Current Product Contract

- The primary object is a **local offering**: a specific item a neighbor is making available, carried on the first screen by its image and name. Hotdogs are the flagship category and seed catalog; offerings carry a `category` so the same surface serves coffee, baked goods, produce, or a shared recipe.
- A card shows name, category, **credit cost** (never a dollar price for the offering itself), maker, signature notes, distance, walking time, craving fit, pickup window and/or delivery availability, and compact highlights. Users can search offering fields by craving terms without broad crawler indexing. With location permission, distance is recomputed from offering coordinates; users can preview a live walking route; full navigation hands off to Apple Maps from coordinates or pickup address text.
- Add-ons are **maker-defined**, not a hardcoded hotdog topping list, and are priced in credits.
- Cards without remote media still need a product-specific visual; craving and category controls persist as user-scoped preferences that filter/rank both backend discovery and the local Swift deck.
- Screenshot and demo fixtures stay deterministic and remain hotdog-forward (flagship category) while exercising at least one non-hotdog category, across Discover, Matches, Wallet, Claim, Pickup/Hand-off, Review, Vendor, and Profile — without live auth, location prompts, payment, or localhost state.
- Positive swipes are intent signals. Matches are high-fit liked offerings and preserve the practical context the user needed while swiping: current distance, walking time, route preview, Apple Maps directions, and the pickup window.
- The match surface turns a positive swipe into a **claim**: show the offering, its credit cost, short notes, maker-defined add-ons, the pickup window or delivery option, and the current credit balance. Claiming spends credits atomically into a maker-credited, ledger-backed order with immediate confirmation, a real count, and a My Claims list. Hand-off is mutually confirmed before the order is considered complete and review-eligible.
- A **wallet** is first-class: balance, lifetime earned/spent, a buy-credits flow (1:1, par, real payment rail), and a ledger history. There is no withdraw/cash-out affordance anywhere — its absence is intentional and should be explained in-product.
- Makers can post offerings with media/metadata, optional coordinates, pickup address text and window, and an optional delivery option; resolve pickup addresses to coordinates on-device; and revise change-requested offerings back into review. Configured admins can approve/reject/request edits, moderate offerings, and adjust the ledger only through audited, append-only corrections (e.g. a disputed hand-off refunds **credits**, never cash).
- **Two-way reviews** are core trust: after a confirmed hand-off, giver and receiver can review each other; aggregate reputation surfaces in discovery. Reviews are gated to completed claims to limit gaming.
- Production identity stays backend-owned through SPAPS (slug `dogswipe`): publishable key for native magic-link auth, `dogswipe://auth` and configured HTTPS universal-link returns, access/refresh JWTs in Keychain, only user bearer tokens sent to the DogSwipe API.
- Production telemetry stays narrow and no-PII: screen views, swipes, auth submissions, claim/credit/review CTAs. Credit amounts may be counted; no payment-card or PII data is emitted.
- Local sample data is intentionally neighborly and category-diverse so screenshots, demos, and API examples stay anchored to the barter product, hotdog-flagship.

## Non-Goals For The First Slice

- **Cash-out, maker payouts, or any fiat withdrawal of credits.** This is a permanent invariant, not a deferred feature: credits are closed-loop by design.
- Variable or speculative credit pricing, demurrage, starter-grant economics, and other tokenomics dials (deferred, not abandoned).
- Maker-to-maker peer transfer of credits outside a claim (no informal credit trading that could mimic cash-out).
- Real-time chat.
- Recommendation ML beyond craving/category/proximity ranking and reputation.
- Public App Store review before the TestFlight build has been exercised on a physical device.
- Full turn-by-turn navigation or route persistence beyond lightweight MapKit previews.
- Broad crawler-based menu indexing beyond bounded snapshot search.

These are valuable or explicitly-rejected later, but pursuing them now would dilute the core barter loop before the credit and trust contracts are reliable.

## Release Reality

The pivot builds on a live production base. The application and deploy contract are on a real production host, the public edge is live through `https://dogswipe.buildooor.com`, Alembic migrations are applied (currently through `0009`), and Postgres, Redis, and the API container run healthy behind a Cloudflare Worker that subrequests a scoped DogSwipe origin on `api.sweetpotato.dev`. SPAPS origin alignment is live and `dogswipe 0.1.0` build 2 is valid in TestFlight; the remaining auth proof is a physical-device universal-link callback.

The barter economy is **net-new build on top of this base**: there is no wallet, ledger, credit-purchase rail, spend-only enforcement, two-way review system, or fulfillment/hand-off lifecycle today (orders currently capture as `draft` only, and pricing is display-only dollars). These are the substance of the next slices and must ship with their own migrations, tests, and proof gates. The dollar-price discovery/draft surface is treated as legacy to be migrated to credits, not extended.

## Quality Bar

- SwiftUI uses shared tokens for spacing, color, typography, radius, and controls; the street-vendor visual language (cream stacks, mustard/red/pickle accents, compact chips, clear swipe controls) is preserved while wallet/claim/review surfaces are added without fintech or directory chrome.
- Core matching and swipe logic lives in a Swift package with unit tests; the catalog generalization keeps it currency-agnostic and category-agnostic.
- **Ledger correctness is a release gate.** The credit ledger is append-only; balances are derived; spends are atomic; double-spend and concurrent-claim races are covered by tests; the no-cash-out invariant has explicit negative tests proving no endpoint or admin path returns credits to fiat; the platform float reconciles to outstanding credits.
- Credit purchase settlement is idempotent against duplicate webhooks/retries and is covered by tests.
- Two-way reviews are gated to confirmed hand-offs and covered by tests against self-review and pre-completion review.
- Backend routes are covered by API and service tests with coverage above 80%.
- Auth integration follows Sweet Potato contracts: JWTs for user-scoped routes, app keys for service calls, no local fake auth in production.
- A bounded compliance/legal review of the closed-loop credit model (money-transmitter / stored-value exposure, no-cash-out terms, food-handoff liability) is recorded and gates public launch; findings are reflected in product copy and Terms.
- iOS release-facing metadata includes the app icon, accent color, privacy manifest (auth email, precise location; plus any payment-rail disclosure for credit purchase), associated-domains plumbing, a renderable Apple app-site association template, and non-secret TestFlight handoff targets.
- CI blocks regressions in backend coverage, scoped CRAP score, SwiftUI drift, architecture-diagram preflight, SPAPS contract/registration-payload render, deploy preflight/readiness, iOS release assets, iOS build/test gates, ledger-invariant tests, and screenshot UI smoke.
- Public docs distinguish implemented behavior from roadmap, and clearly state that credits are non-withdrawable by design.
