Reading the full prompt and both idea lists so I can score every mechanism fairly.
Checking VISION.md for hard invariants to ground the scoring.
# DogSwipe Tokenomics Idea Evaluation

Scoring criteria: economic soundness, real-world usefulness for neighbor barter, implementability, benefit vs. complexity/risk, and fidelity to no-cash-out + community-over-profit invariants. Scores are deliberately spread; many ideas have real flaws.

---

## CLAUDE (CC) — Final Five

### CC — Neighborhood Kindling
**Score: 782**

Sequenced, par-backed platform grants (supply first → subsidized first claims → hand-off-gated referrals) are a proven marketplace cold-start pattern that preserves 1:1 float backing. Stage 2 “First Bite Free” is high-leverage for onboarding, but it is the most farmable slice and burns real CAC (~$950/cell) without guaranteeing post-subsidy purchases.

**Biggest risk/flaw:** Coordinated multi-account farming of subsidized claims (Stage 2 especially), which can drain neighborhood budgets with fake circulation.

---

### CC — Spend-to-Earn Curve
**Score: 834**

Tuning the already-decided production bonus by inverse balance is elegant: one formula, low implementation cost, and it directly attacks net-producer hoarding without touching purchased principal or adding a second currency. It creates a natural spend→produce rhythm that fits barter psychology better than blunt demurrage.

**Biggest risk/flaw:** Alt-account or collusive circular claims to artificially drain balance before hand-offs, which is hard to stop completely without strong identity and counterparty-diversity rules.

---

### CC — Pay It Forward
**Score: 761**

The strongest ethos fit in either list: visible generosity, no cash-out, and a real spending channel for surplus holders that doubles as cold-start fuel after platform subsidies end. It is not a complete answer to the net-producer problem if neighbors simply do not offer what surplus holders want — charity is not reciprocity.

**Biggest risk/flaw:** Sponsored claims can crowd out paid claims and train users to wait for freebies unless caps, newcomer-only rules, and paid-first ordering are strict.

---

### CC — Dormancy-Triggered Demurrage with Community Renewal
**Score: 387**

Recycling idle credits into a community pool is ethically framed and economically sensible for abandoned balances, but applying demurrage to **all** credits — including dollar-purchased principal — is the wrong move for DogSwipe. Codex’s own regulatory read is right: gift-card/prepaid rules and user trust make this feel like confiscation of money users paid at par, even with a 90-day grace.

**Biggest risk/flaw:** Legal and reputational exposure from inactivity fees on par-purchased credits, which undermines the “your buy-in is safe” promise.

---

### CC — Float-as-Community-Trust with Transparent Stewardship
**Score: 871**

Load-bearing governance: segregated float, public reconciliation, shutdown plan, and interest-as-sustainability (not principal extraction) directly match VISION’s “community liability” framing. This is less tokenomics trickery than the foundation every other mechanism needs; without it, clever minting rules sit on shaky legal and ethical ground.

**Biggest risk/flaw:** “Trust” without real segregation, audits, and counsel-approved structure is worse than no trust — marketing that outruns accounting.

---

## CLAUDE (CC) — Rejected Candidates (25)

### CC — Founding-Member Signup Grant
**Score: 341** — Only works if platform-funded at par; otherwise unbacked issuance. Subsumed by Kindling anyway. **Flaw:** Signup-only grants invite multi-account farming with no hand-off proof.

### CC — Reciprocal Onboarding Pairs
**Score: 268** — High orchestration for a small neighborhood app; brittle at low density. **Flaw:** Matching pairs is ops-heavy and fails if one side ghosts.

### CC — Seller-Issued Scrip / Store Coupons
**Score: 412** — Risks a second quasi-currency and fragments unit-of-account. **Flaw:** Maker-issued scrip looks like stored value across merchants.

### CC — Invite-and-Grant Chain
**Score: 231** — Viral mechanics with compounding Sybil risk at small scale. **Flaw:** Referral chains are built for farming, not neighborly barter.

### CC — Neighborhood Launch Event
**Score: 318** — Good marketing, not an economic mechanism. **Flaw:** Non-scalable, high-touch, no persistent ledger effect.

### CC — Capped Production Bonus with Time Decay
**Score: 443** — Better than flat minting but penalizes consistent makers vs. spend-first designs. **Flaw:** Punishes the reliable hosts you want to keep.

### CC — Community Contribution Minting
**Score: 187** — Ungameable verification of “community contribution” is fantasy without trusted arbiters. **Flaw:** Subjective minting becomes politics or fraud.

### CC — Seasonal/Event Minting
**Score: 364** — Flavor, not structure; calendar-based unbacked issuance. **Flaw:** Inflation without activity grounding.

### CC — Matched Purchase Bonus (“Buy 10 Get 12”)
**Score: 398** — Inflationary discount with weak community signal. **Flaw:** Teaches users credits are not really 1:1 with dollars.

### CC — Referral Minting on First Hand-Off
**Score: 547** — Hand-off-gated referral is sound; Kindling Stage 3 does it with par funding. **Flaw:** Redundant with better-packaged Kindling design.

### CC — Flat Demurrage (Uniform Holding Tax)
**Score: 274** — Punishes legitimate savers and purchased principal alike. **Flaw:** Feels like theft; legal exposure on par purchases.

### CC — Use-it-or-Lose-it Hard Expiry
**Score: 156** — Blunt, hostile, and likely illegal for purchased stored value. **Flaw:** Directly violates user trust and probable gift-card rules.

### CC — Tiered Participation Benefits (Badges, Priority)
**Score: 491** — Useful social nudge but does not move credits economically. **Flaw:** Gamification without ledger effect solves the wrong layer.

### CC — Community-Wide Velocity Bonus
**Score: 296** — Free-rider problem: individuals cannot influence aggregate velocity. **Flaw:** No individual lever → no behavior change.

### CC — Contribution Score / Karma Parallel System
**Score: 322** — Two balances/scores confuse users for unclear payoff. **Flaw:** Parallel economy adds complexity without solving float/hoarding.

### CC — Spending Streaks with Multiplier
**Score: 518** — Positive reinforcement for velocity; low legal risk. **Flaw:** Does not fix net-producer dead-end when nothing desirable is listed.

### CC — Scaling Production Bonus for Net Producers
**Score: 124** — Accelerates accumulation — exactly backwards for this economy. **Flaw:** Makes the core structural problem worse.

### CC — Credit Gifting to Newcomers (Direct)
**Score: 385** — Gameable alt-farming; Pay It Forward is the guarded version. **Flaw:** Approximates peer transfer without hand-off proof.

### CC — Community Project Spending
**Score: 428** — Ethically aligned but needs logistics DogSwipe cannot deliver early. **Flaw:** Real-world fulfillment outside the app’s core loop.

### CC — Maker-to-Maker Exchange Surfacing
**Score: 562** — Strong product feature for cross-pollination, weak as standalone tokenomics. **Flaw:** Discovery UX, not issuance/velocity policy.

### CC — Producer Recognition / Hall of Fame
**Score: 391** — Social reward without economic relief for 200-credit surplus. **Flaw:** Vanity does not create things to spend on.

### CC — Prepaid-Card Regulatory Structure
**Score: 641** — Important legal framing, not a user-facing mechanism. **Flaw:** Counsel-dependent; product behavior must match the label.

### CC — Per-City Float Isolation
**Score: 598** — Sound ops/compliance practice for local cells. **Flaw:** Implementation detail, not an economic engine.

### CC — Credit-to-Effort Anchor (“1 credit = 15 min”)
**Score: 241** — Philosophically nice, practically unenforceable across cultures and offerings. **Flaw:** False precision creates conflict, not stability.

### CC — Anti-Inflation Price Ceiling per Category
**Score: 307** — Central admin judgment on neighbor prices is contentious and brittle. **Flaw:** Contentious governance + thin-market false precision.

---

## CODEX (COD) — 30 Screened Candidates

### COD — Threshold Launch Batch
**Score: 798** — “Charge only when the block is live” is the cleanest cold-start UX and avoids empty-wallet first movers. **Flaw:** Thresholds set too high make viable neighborhoods look dead forever.

### COD — Pre-Funded Cell Matching Pool
**Score: 776** — Par-backed 1:1 match halves entry friction without counterfeiting. **Flaw:** Sybil buyers farming matches unless identity-bound and hand-off-gated.

### COD — Sponsor-Seeded Welcome Grants
**Score: 712** — Local institutions buying at par fits community ethos better than operator subsidies alone. **Flaw:** Sponsor capture / “buying influence” reputational damage.

### COD — Gift-at-Purchase Split
**Score: 684** — One purchase, two active wallets; neighborly and ledger-clean. **Flaw:** Circular gifting rings approximate peer transfer.

### COD — Maker Discount Coupons, Not Maker Scrip
**Score: 623** — Clever separation from wallet balance avoids second currency. **Flaw:** List-price inflation before coupons games the discount.

### COD — Launch Drop Windows
**Score: 651** — Concentrates supply/demand in time — critical for pickup-window barter. **Flaw:** No-shows at events destroy trust fast.

### COD — Buyer Wish Bounties
**Score: 788** — Pulls supply toward actual demand; best direct fix for “I have credits, nothing I want.” **Flaw:** Disputes on bespoke requests and bounty spam in thin markets.

### COD — Vetted Block Captain Credits
**Score: 598** — Seeds makers-as-buyers; overlaps CC Kindling Stage 1. **Flaw:** Favoritism risk and manual ops do not scale.

### COD — Verified Hand-Off Production Bonus
**Score: 802** — Already decided in VISION; activity-grounded minting is the right liquidity engine. **Flaw:** Collusive fake hand-offs if confirmation is weak.

### COD — Community Issuance Budget
**Score: 745** — Published mint cap prevents runaway inflation and makes bonuses auditable. **Flaw:** Too-tight caps stall the economy; tuning is politically sensitive.

### COD — Credit Lots By Origin
**Score: 728** — Prerequisite infrastructure for legally safer velocity rules. **Flaw:** Lot accounting complexity and user confusion if UX is not ruthlessly simple.

### COD — Scarcity-Weighted Production Bonus
**Score: 671** — Steers production to thin categories without price fixing. **Flaw:** Category mislabeling to chase multipliers.

### COD — Quality-Gated Minting
**Score: 554** — Reduces junk-for-mint farming. **Flaw:** Incumbent advantage; newcomers struggle to break in.

### COD — Escrow-First Claim Settlement
**Score: 736** — Correct dispute architecture; credits reserved, maker paid on confirm. **Flaw:** Claim spam can lock maker inventory without strong no-show penalties.

### COD — Proof-of-Handoff Codes
**Score: 692** — Cheap anti-farm layer for production mints. **Flaw:** Colluders exchange codes anyway; adds friction for honest users.

### COD — Bonus-Lot Demurrage Only
**Score: 811** — The legally and ethically correct demurrage design for par-purchased credits. **Flaw:** Purchased-credit hoarding remains unsolved (must pair with demand tools + caps).

### COD — Reciprocity Score in Discovery
**Score: 583** — Social pressure without confiscation. **Flaw:** Micro-spend farming for ranking badges.

### COD — Spend Streak Rewards
**Score: 541** — Positive velocity nudge, low risk. **Flaw:** Circular low-quality claims can farm streaks.

### COD — Idle Balance Nudges
**Score: 497** — Cheap, friendly first intervention. **Flaw:** Ignored prompts do not move credits; not load-bearing alone.

### COD — Slack-Time Price Boosts
**Score: 529** — Smooths temporal mismatch in pickup-window barter. **Flaw:** Users learn to wait for discounts only.

### COD — Community Chest
**Score: 704** — Ethical sink for burned/expired community lots and yield. **Flaw:** Governance capture on discretionary allocations.

### COD — Producer Wishboard
**Score: 769** — First-class “what I want” for net producers; pairs naturally with bounties. **Flaw:** High-balance users can dominate discovery.

### COD — One-Hop Sponsorship Vouchers
**Score: 742** — Surplus → cold-start liquidity without cash-out; CC Pay It Forward in voucher form. **Flaw:** Off-platform voucher resale at small face values.

### COD — Community Supply Library
**Score: 446** — Expands spend options beyond food but adds liability, damage disputes, and kitchen-access regulation. **Flaw:** Operational and legal surface area far exceeds MVP scope.

### COD — Producer Bonus Redirect
**Score: 616** — Lets prolific makers route mints to chest/vouchers instead of hoarding. **Flaw:** Opt-in only — hoarders won’t opt in; status-farming risk.

### COD — Block Party Absorption Events
**Score: 588** — Ritualizes surplus spending; good community texture. **Flaw:** Poor execution or low-quality mass offerings erode trust.

### COD — Community Credit Trust or Cooperative
**Score: 883** — Same load-bearing layer as CC Float Trust; Codex pairs it with member framing. **Flaw:** Form without segregated accounts and audits is liability theater.

### COD — Member-Only Local Network and Caps
**Score: 857** — Makes the closed-loop legal story credible; caps reduce hoarding and AML shape risk. **Flaw:** Caps frustrate power users; off-platform resale still possible.

### COD — Tax and Barter Reporting Center
**Score: 673** — Honest compliance UX; discourages pseudo-business barter abuse. **Flaw:** Tax friction may chill casual participants (necessary tradeoff).

### COD — Reference Basket and Price Bands
**Score: 718** — Anchors credit meaning without central price fixing. **Flaw:** Thin-market medians are manipulable and misleading if shown with false confidence.

---

## CODEX (COD) — Final Top Five (Composite Bundles)

### COD — Community Credit Trust + Member-Only Local Network
**Score: 912**

The right foundation before clever minting: segregated float, member-scoped local cells, non-transferable credits, and conservative caps make every other mechanism less legally fragile. Bundling trust with network boundaries addresses VISION’s “many unaffiliated makers” warning directly.

**Biggest risk/flaw:** Trust label without real segregation, counsel sign-off, and behavioral enforcement is worse than no trust at all.

---

### COD — Threshold Launch Batch + Pre-Funded Matching Pool
**Score: 836**

Collective unlock (pledge → capture → match → launch window) is the most honest cold-start design: money, supply, and attention arrive together, and users are not charged into an empty economy. Par-funded matching preserves the 1:1 invariant.

**Biggest risk/flaw:** Threshold calibration — too ambitious kills momentum; too low launches hollow cells that still fail after match exhaustion.

---

### COD — Verified Hand-Off Mint with Issuance Budget, Lot Tracking, and Scarcity Multipliers
**Score: 818**

Governs the already-decided production bonus with caps, lot provenance, and demand-steering multipliers — the right way to make minting auditable rather than magical. Atomic escrow + mint + budget check is implementable on an append-only ledger.

**Biggest risk/flaw:** Formula complexity (scarcity × reputation × budget × lot class) creates tuning hell and opaque “why did I get 0.3 credits?” moments.

---

### COD — Lot-Safe Velocity System
**Score: 803**

The correct answer to hoarding in a par-purchase, no-cash-out system: protect purchased principal, spend community lots first, decay only promotional/minted credits after counsel. Pairs naturally with issuance budget and chest recycling.

**Biggest risk/flaw:** Purchased-credit hoarding remains structurally unaddressed; relies on caps, bounties, and spend incentives elsewhere.

---

### COD — Producer Demand Engine (Wish Bounties, Surplus Vouchers, Reference Pricing)
**Score: 774**

Attacks the net-producer dead-end at the root — create things surplus holders actually want to buy — rather than only punishing idle balances. Reference pricing stabilizes the unit of account without admin price controls.

**Biggest risk/flaw:** Thin early markets produce junk bounties, dominated wishboards, and unreliable reference baskets that mislead more than help.

---

## Cross-Model Summary

### Single strongest idea (both models)
**COD — Community Credit Trust + Member-Only Local Network (912)** — It is the prerequisite that makes every other mechanism legally credible, ethically legible, and harder to game; without bounded local membership and segregated float, DogSwipe reads as stored value across unaffiliated makers with no redemption story.

### Single weakest idea (both models)
**CC — Scaling Production Bonus for Net Producers (124)** — It explicitly rewards the users who already accumulate fastest, accelerating the complementary-currency failure mode (Ithaca Hours, LETS) that both models are trying to prevent.

---

## Brief comparative notes

- **Cold start:** COD’s threshold batch edges CC’s Kindling on user fairness (“not charged until live”), but CC’s supply-first sequencing and hand-off-gated referrals are strong; merging both is ideal.
- **Velocity / hoarding:** CC’s dormancy demurrage on all balances is the biggest finalist mistake; COD’s lot-safe approach is clearly superior for par-purchased credits.
- **Net-producer dead-end:** CC’s Spend-to-Earn is the smartest single economic lever; COD’s Producer Demand Engine is the best *product* answer. They complement each other.
- **Ethos:** CC’s Pay It Forward is the most emotionally resonant spending channel; COD embeds the same idea in vouchers and chest mechanics with more guardrails.
- **Governance:** Both Float/Trust designs score high; COD wins by explicitly coupling trust with member-only local network constraints.
