# DogSwipe Barter Economy: Tokenomics Mechanism Design

## Candidate Pool (30 mechanisms evaluated, 5 selected)

Before the final five, a brief accounting of the 30 candidates considered and why 25 were cut.

### Candidates considered and rejected

| # | Mechanism | Problem | Why rejected |
|---|-----------|---------|-------------|
| 1 | Founding-member signup grant | Cold start | Unbacked unless platform-funded; subsumed by #1 below |
| 2 | Reciprocal onboarding pairs | Cold start | Orchestration complexity for marginal gain |
| 3 | Seller-issued scrip / store coupons | Cold start | Interesting but complex; duplicates Pay It Forward without the community warmth |
| 4 | Invite-and-grant chain | Cold start | Multi-account farming risk outweighs viral benefit at small scale |
| 5 | Neighborhood launch event | Cold start | High-touch and non-scalable; good marketing, not a mechanism |
| 6 | Capped production bonus with time decay | Minting | Penalizes consistent makers; Spend-to-Earn is strictly better |
| 7 | Community contribution minting | Minting | Ungameable verification is impossible without a trusted arbiter |
| 8 | Seasonal/event minting | Minting | Nice flavor but not load-bearing; creates unbacked credits for calendar reasons |
| 9 | Matched purchase bonus ("buy 10 get 12") | Minting | Inflationary with no community-building signal; just a discount |
| 10 | Referral minting on first hand-off | Cold start | Better than signup-only referrals but subsumed by Kindling stage 3 |
| 11 | Flat demurrage (uniform holding tax) | Hoarding | Punishes active savers and new purchasers alike; feels like theft |
| 12 | Use-it-or-lose-it hard expiry | Hoarding | Blunt; dormancy-triggered demurrage is strictly better (graduated, with warning) |
| 13 | Tiered participation benefits (badges, priority) | Hoarding | Nice gamification but doesn't move credits; non-economic |
| 14 | Community-wide velocity bonus | Velocity | Free-rider problem: individuals can't influence the aggregate |
| 15 | Contribution score / karma parallel system | Velocity | Adds conceptual complexity; users now track two balances for unclear benefit |
| 16 | Spending streaks with multiplier | Velocity | Positive reinforcement but doesn't solve the net-producer problem |
| 17 | Scaling production bonus for net producers | Net producer | Accelerates accumulation — the opposite of what's needed |
| 18 | Credit gifting to newcomers (direct) | Net producer | Gameable (farm alts); Pay It Forward is the same idea with guardrails |
| 19 | Community project spending | Net producer | Requires real-world logistics the platform can't yet deliver |
| 20 | Maker-to-maker exchange surfacing | Net producer | Good product feature, not an economic mechanism |
| 21 | Producer recognition / hall of fame | Net producer | Social reward alone doesn't solve a structural economic problem |
| 22 | Prepaid-card regulatory structure | Float | Legal strategy, not a mechanism; informs #5 below |
| 23 | Per-city float isolation | Float | Good ops practice but not a mechanism; belongs in implementation |
| 24 | Credit-to-effort anchor ("1 credit = 15 min") | Stability | Philosophically appealing; practically unenforceable and culturally variable |
| 25 | Anti-inflation price ceiling per category | Stability | Blunt, contentious, requires ongoing admin judgment calls |

---

## The Final Five

These five mechanisms are designed to work as a **reinforcing system**, not independent patches. Each feeds into the others:

```
Dollar purchases ──→ Float Trust (backs credits)
                         │
Kindling grants ────→ Initial credit flow ──→ First transactions
                         ↑                          │
Community Renewal Pool ──┘                          ↓
         ↑                              Production bonus
         │                         (tuned by Spend-to-Earn)
    Dormancy                               │
    demurrage                              ↓
         ↑                          Net-producer surplus
         │                                 │
    Idle credits ←── Accumulation ←────────┘
                          │
                          ↓
                   Pay It Forward ──→ More claims ──→ More hand-offs ──→ cycle
```

---

### 1. "Neighborhood Kindling" — Platform-Seeded Supply-First Grants at Par

**Problem addressed:** Cold start (primary), velocity (secondary)

**The core insight:** Every two-sided marketplace cold start has been solved by the platform subsidizing one side. The question is which side, how much, and how to maintain the 1:1 backing invariant while doing it. The answer: the platform itself buys credits at par — real dollars go into the float — and distributes them through a sequenced ignition protocol that favors supply first.

**How it works:**

The platform treasury purchases credits at par before any user does. These credits enter the float like any other purchase: real dollars back every granted credit at 1:1. The invariant is maintained because the platform is a buyer, not a money printer.

Credits are distributed through three stages, each less subsidized than the last:

*Stage 1 — Founding Makers (pre-launch, supply-side seeding):* The platform identifies 10-20 prospective makers per neighborhood through direct outreach (food vendor associations, Instagram hotdog cart accounts, local food blogger networks, farmers' market contacts). Each maker who posts their first admin-approved offering receives a Founding Maker grant of 10 credits. They can now claim others' offerings with real credits. Supply exists before demand arrives.

*Stage 2 — First Bite Free (launch week, demand-side ignition):* The first 50 claims in a neighborhood are platform-subsidized. The claimer pays 0 credits; the maker receives the full credit cost plus production bonus, funded by the platform. This lets newcomers experience the barter loop without buying in. After their first free claim, they see a balance of 0 and a prompt: "Enjoyed that? Buy credits to claim more — or post your own offering to earn some."

*Stage 3 — Referral Matching (weeks 2-4, viral growth):* When an existing user refers someone who completes their first hand-off (as either side), both the referrer and the new user receive 3 credits. This is funded from the platform treasury, not minted. The trigger is a completed hand-off, not a signup — so farming requires actually showing up and exchanging food.

Each stage burns down a predetermined per-neighborhood budget. When the budget is exhausted, organic credit purchases and production bonuses sustain the economy — or the neighborhood isn't viable yet and the platform learns that cheaply.

**Why it helps:** Breaks the chicken-and-egg by sequencing: supply first (makers have listings and credits), then demand ignition (free first claims), then viral growth (referral matching). Each stage is strictly less subsidized. The economy either achieves escape velocity or the platform learns the neighborhood needs more supply diversity before retrying.

**User perception:** Founding makers feel valued and recruited, not targeted by a coupon blast. First-time claimers feel welcomed, not sold to. Referrers feel like community builders. The "Founding Maker" designation becomes social proof in the community.

**Failure modes:**
- *Multi-account farming:* Mitigation — phone verification, per-device limits, and admin approval on first listings. The hand-off completion trigger for Stage 3 makes farming require physical presence, which is expensive to fake.
- *Low-effort garbage listings for grant farming:* Mitigation — admin approval gate on all Stage 1 offerings. Founding Makers are hand-recruited, not self-selected.
- *Economy doesn't self-sustain after grants run out:* This is a product-market fit signal, not a mechanism failure. If nobody wants to buy credits after experiencing the loop for free, the problem is supply quality or community fit, and no mechanism fixes that.
- *Cost overrun:* Hard caps per neighborhood (e.g., $500 for Stage 1, $300 for Stage 2, $150 for Stage 3 = ~$950 total per neighborhood launch). This is a known customer acquisition cost.

**Gaming vectors:** A coordinated group could farm Stage 2 subsidies by creating multiple accounts and claiming each other's offerings. Counter: rate-limit claims per IP/device, require minimum 24h between first listing and first receivable claim, and flag accounts that only claim during the subsidy window and go dormant after.

**Implementation complexity:** Low-medium. Requires a "platform treasury" account in the ledger, a grant-type ledger entry, per-neighborhood budget tracking, and a subsidy flag on claims. All append-only, all auditable.

---

### 2. "Spend-to-Earn Curve" — Inverse-Balance Production Bonus

**Problem addressed:** Anti-hoarding (primary), net-producer dead-end (primary), velocity (primary)

**The core insight:** The production bonus (already decided: completing a hand-off mints credits to the maker) is the single most powerful lever in the system because it's the only non-purchase source of new credits. If this bonus is flat, it accelerates the net-producer problem: makers who give more than they take accumulate faster and faster. But if the bonus is *inversely proportional to your current balance*, it transforms accumulation from a dead end into a spending incentive. Rational makers spend down their balance before their next hand-off to maximize their bonus.

**How it works:**

The production bonus multiplier is computed from the maker's credit balance at the moment of hand-off completion:

```
bonus_rate = BASE_RATE * max(FLOOR, 1.0 - (balance / SOFT_CAP))
```

Where:
- `BASE_RATE` = 20% of the offering's credit cost (tunable)
- `SOFT_CAP` = 50 credits (tunable per community)
- `FLOOR` = 0.10 (10% — the bonus never reaches zero; producing always earns *something*)

Example with a 5-credit offering:

| Maker's balance | Multiplier | Bonus earned |
|----------------|-----------|-------------|
| 0 | 1.00 | 1.00 credit |
| 10 | 0.80 | 0.80 |
| 25 | 0.50 | 0.50 |
| 40 | 0.20 | 0.20 |
| 50+ | 0.10 (floor) | 0.10 |

A maker with 0 credits earns a full 1-credit bonus on a 5-credit offering. A maker sitting on 50+ credits earns only 0.10. To get back to the full bonus, they need to spend.

The bonus is a new `mint_production_bonus` ledger entry — append-only, auditable, clearly distinguished from purchases and spends. The balance used for the calculation is recorded on the entry for auditability.

**Why it helps:** Solves three problems simultaneously:

1. *Anti-hoarding:* Hoarding credits directly reduces your earning power. The rational response is to spend.
2. *Net-producer dead-end:* The maker who's been giving away hotdogs and has 80 credits doesn't earn nearly as much per hand-off. They're strongly incentivized to find offerings to claim — other makers' coffee, bread, produce — which drives the cross-pollination that makes a barter community feel alive.
3. *Velocity:* Every maker now has a reason to spend before producing. This creates a natural rhythm: spend → produce → earn well → spend → repeat.

**User perception:** Framed positively: "Your production bonus is highest when you're actively participating in the community — spending credits on your neighbors' offerings." Not framed as a penalty for having credits, but as a reward for being a well-rounded community member. The UI shows your current bonus multiplier and what it would be at a lower balance: "Spend 15 more credits and your next production bonus jumps from 0.5x to 0.8x."

**Failure modes:**
- *Makers raise prices to compensate:* If a maker raises their offering from 5 to 10 credits to get a bigger absolute bonus, the base rate applies to the higher price, but the claimer pays more. Peer pricing transparency (see unit-of-account discussion) makes this visible and socially costly. And the percentage bonus is the same regardless of price, so the incentive to inflate is weak.
- *Makers stop producing when balance is high:* This is actually fine — it means they're spending, which is what we want. When their balance drops, they'll produce again.
- *SOFT_CAP set wrong:* Too low → makers feel punished after just a few hand-offs. Too high → the incentive is too weak to change behavior. Start with 50, observe median maker balance after 30 days, and adjust. The parameter is community-tunable, not hardcoded.

**Gaming vectors:**
- *Alt-account spending:* A maker creates Account B, posts a dummy offering, and claims it from Account A to drain their balance before hand-offs. Counter: self-claim prevention already extends to same-device/same-phone accounts. Flag accounts with suspiciously low offer diversity (only one offering, always claimed by the same few accounts).
- *Circular flow:* Maker A and Maker B agree to claim each other's offerings repeatedly just to keep balances low. Counter: this is actually fine — they're transacting, which drives the economy. It only becomes a problem if the offerings are fraudulent (no real food changes hands). The mutual hand-off confirmation requirement and review system make this costly to sustain without real exchanges.

**Implementation complexity:** Low. One additional query (maker balance) during the production-bonus ledger entry. The bonus formula is pure arithmetic. The SOFT_CAP is a settings value. Everything else is existing ledger infrastructure.

---

### 3. "Pay It Forward" — Sponsored Claims

**Problem addressed:** Net-producer dead-end (primary), cold start (secondary), community ethos (primary)

**The core insight:** The net-producer problem killed most complementary currencies (Ithaca Hours, LETS systems, local scrip). The business that accepted too many local credits and couldn't spend them eventually stopped accepting them. In DogSwipe's economy, the maker who has 200 credits and doesn't want anyone else's coffee is at a dead end — and they're exactly the kind of generous, high-contribution community member you can't afford to lose.

The solution: let them give those credits away in a way that feels good, is publicly celebrated, and actually helps the community. Pay It Forward turns excess credits from a dead end into a community-building gesture.

**How it works:**

Three modes, ordered by implementation priority:

*Mode 1 — Open Sponsorship:* A user with credits can tap "Pay It Forward" on any offering and fund the next N claims (1-5). The next person to claim that offering pays 0 credits; the sponsor's credits are spent. The maker still earns the credit cost + production bonus. The offering card shows "1 sponsored claim available — paid forward by [Name or Anonymous]."

*Mode 2 — Named Sponsorship:* A user can send a specific person a sponsored claim: "I'm covering your next claim on Maria's empanadas." The recipient sees a notification and can claim for free. If unclaimed after 7 days, credits return to the sponsor.

*Mode 3 — Community Pot:* A user can contribute credits to a neighborhood-wide community pot. Credits from the pot are distributed as small subsidies (1-2 credits off) on random offerings, making the whole neighborhood feel more accessible. The pot is capped to prevent dumping.

A "Pay It Forward" feed in the app shows recent sponsorships: "Jake paid forward 3 coffees at Maria's stand." "Anonymous covered the next claim at Tony's hotdog cart." This creates social proof, warmth, and a reason to open the app.

Ledger entries: A `spend_sponsorship` entry debits the sponsor. When the sponsored claim happens, a `claim_sponsored` entry creates the order with a reference to the sponsorship. The maker's `earn` entry and production bonus are standard. Every step is append-only and auditable.

**Why it helps:**
- *Net-producer dead-end:* A maker sitting on 200 credits can sponsor 40 claims and become a community hero. Their credits are gone, their bonus multiplier is back up (synergy with Spend-to-Earn), and they've created 40 new hand-offs that generate community engagement.
- *Cold start:* Sponsored claims are indistinguishable from Kindling subsidies to the recipient. As the platform-funded Kindling stages run out, community-funded Pay It Forward takes over organically.
- *Community ethos:* This is the mechanism most aligned with the "community over profit" vision. It makes generosity visible, celebrated, and structurally useful.

**User perception:** Pure positive. "Pay It Forward" is universally understood and appreciated. The sponsor feels generous. The recipient feels welcomed. The maker feels valued (their offering was worth sponsoring). Nobody feels penalized.

**Failure modes:**
- *Only net-producers use it, and they run out of goodwill:* If Pay It Forward is the ONLY way net-producers can spend, it's charity, not participation. That's why Spend-to-Earn exists in parallel — it incentivizes finding things to buy, not just giving credits away. Pay It Forward is a pressure release valve, not the primary spending channel.
- *Gaming: Maker A sponsors claims on Maker A's own offerings through an intermediary:* Counter — the sponsor cannot be the maker of the sponsored offering. Flag sponsor-maker pairs with high frequency for review.
- *Sponsored claims crowd out paid claims:* If an offering always has sponsored claims available, nobody ever pays. Counter — cap sponsored claims per offering per week. Make paid claims fill first, then sponsored. Or make sponsored claims only available to users with balance below a threshold (newcomers).

**Gaming vectors:**
- *Circular sponsorship:* A and B sponsor each other's offerings to keep balances low and production bonuses high. Counter: same as Spend-to-Earn — this is actually transacting, which is fine as long as real food changes hands. If it's fraudulent, the review system and hand-off confirmation catch it.
- *Dump credits to inflate production bonus:* A maker dumps 100 credits into the community pot just before a hand-off to get the maximum bonus. Counter: the Spend-to-Earn balance check happens at hand-off time, so this works — but the maker has genuinely given away 100 credits to the community, which is the desired behavior. The "gaming" here is the mechanism working as intended.

**Implementation complexity:** Medium. Requires a sponsorship entity linking sponsor, offering, and claim. Three new ledger entry types. A feed query. UI for the sponsorship flow. But no new economic primitives — it's just a payment variant.

---

### 4. Dormancy-Triggered Demurrage with Community Renewal

**Problem addressed:** Anti-hoarding (primary), cold start sustainability (secondary)

**The core insight:** In a no-cash-out system, the main hoarding failure mode isn't rational accumulation (there's no investment return) — it's abandonment. Users who bought credits, tried the app, and drifted away leave credits permanently frozen. Over time, a growing fraction of outstanding credits are effectively dead, but they still back real dollars in the float. This is a liquidity drain.

Flat demurrage (a uniform holding tax) solves this but punishes everyone, including active savers who just haven't found the right offering yet. The right design: demurrage that triggers ONLY on genuinely dormant accounts, with generous grace periods and clear warnings, and that recycles credits back into the community rather than destroying them.

**How it works:**

Every user has a `last_active_at` timestamp, updated on any qualifying transaction: claim, hand-off (either side), credit purchase, or Pay It Forward sponsorship. Posting an offering also counts (you're contributing supply, even if you haven't transacted).

Demurrage rules:
1. **Grace period:** 90 days of inactivity before demurrage activates. This is deliberately generous — three months of complete inactivity before any effect.
2. **Warning:** At 60 days inactive, the user receives a push notification and in-app banner: "Your DogSwipe credits have been idle for 60 days. Claim an offering, post something, or pay it forward to keep them active. After 90 days of inactivity, idle credits are slowly recycled into the community."
3. **Rate:** After 90 days, 3% of the balance above a de minimis floor (5 credits) is debited per month. A `demurrage_recycle` ledger entry moves the credits to the Community Renewal Pool.
4. **Reset:** Any qualifying transaction resets the 90-day clock completely. One claim, one hand-off, one sponsorship — and the clock starts over.
5. **De minimis exemption:** Balances of 5 credits or fewer are never touched. Someone who bought $5 of credits and drifted away loses nothing meaningful.

The Community Renewal Pool is a system account that funds:
- Kindling grants for new neighborhoods (extending mechanism #1)
- Pay It Forward community pot contributions (extending mechanism #3)
- Seasonal community challenges ("DogSwipe Week: double production bonuses")

The pool balance and distributions are reported in the quarterly float transparency report (mechanism #5).

**Why it helps:**
- *Anti-hoarding:* Truly dormant credits are slowly recycled rather than permanently frozen. This maintains effective liquidity.
- *Cold start sustainability:* The Community Renewal Pool creates a self-funding source for Kindling grants. As the network grows and some users churn, their idle credits fund the next neighborhood's launch. The system becomes self-sustaining.
- *Float accuracy:* Outstanding credits more accurately reflect active community participation, making float reconciliation more meaningful.

**User perception:** The 60-day warning is the key UX moment. Most users who care will transact before 90 days. For those who don't, the framing matters: "Your idle credits are being recycled back into the community" is very different from "We're taking your credits." The in-app explanation: "Credits are for participating, not parking. When credits sit idle for 3+ months, a small portion is recycled into community grants for new neighbors and Pay It Forward sponsorships."

**Failure modes:**
- *Users perceive it as theft despite framing:* The 90-day grace, 60-day warning, de minimis exemption, and community-benefit framing mitigate this. Users who feel strongly can make one transaction every 89 days. If they care enough to do that, they're engaged enough.
- *Clock-reset gaming:* Users make a tiny transaction every 89 days to avoid demurrage. Counter: this is fine — any transaction, even small, means they're minimally engaged. If desired, require a minimum transaction value (e.g., 1 credit) for clock reset, but this is probably unnecessary complexity.
- *Demurrage creates a "run on the bank" feeling:* Users rush to spend before demurrage hits, which is... actually what we want. This is the mechanism working.

**Gaming vectors:** Minimal. The only "game" is making a small transaction every 89 days, which is active participation. An automated system that makes token transactions on behalf of inactive users would be detectable (same offering, same maker, same amount, every 89 days) and blockable.

**Implementation complexity:** Low-medium. A daily or weekly batch job checks `last_active_at` and applies demurrage entries. Push notification at 60 days. A `community_renewal_pool` system account. All append-only.

---

### 5. Float-as-Community-Trust with Transparent Stewardship

**Problem addressed:** Float governance (primary), legal/regulatory positioning (primary), community trust (primary)

**The core insight:** The no-cash-out invariant means the platform accumulates real dollars permanently. In a successful community, this float grows monotonically (credits are purchased but never redeemed). This creates three problems: legal exposure (money-transmitter and stored-value regulation), ethical obligation (whose money is it?), and operational temptation (the platform sitting on a growing pile of cash it could misuse). The mechanism must address all three simultaneously.

The structural answer: the float is not the platform's money. It is a community trust, legally segregated, with a defined purpose, transparent reporting, and a shutdown plan.

**How it works:**

*Legal structure:*
The float is held in a segregated custodial account (or trust account, depending on jurisdiction) that is legally distinct from the platform's operating funds. The account is governed by a simple community trust charter:

> "These funds exist solely to back outstanding community credits and to benefit the DogSwipe community. They shall not be used for platform operations, executive compensation, investor distributions, or any purpose other than backing credits and community benefit as defined herein."

The platform is the trustee/custodian, not the owner. This distinction matters for money-transmitter analysis: the platform does not "receive money for the purpose of transmitting it" — it receives money for the purpose of issuing a non-redeemable, non-transferable community participation token. The money sits in trust as backing, and the token cannot be redeemed for the money. This is closer to a donation with a benefit than a stored-value instrument.

*Interest allocation:*
The float earns interest (even in a low-rate environment, a growing float generates meaningful income over time). Interest is allocated:
- 60% → platform operating costs (servers, admin, compliance, moderation). This is the platform's sustainable revenue model — not the float principal, but the interest on it. The community's participation funds the infrastructure that serves it.
- 40% → Community Renewal Pool (as credits, purchased at par from the float's interest income). This creates a self-funding, inflation-neutral source of new credits backed by real interest dollars.

*Transparency:*
Quarterly in-app report:
- Total float balance (dollars held)
- Total outstanding credits
- Reconciliation: float = sum of all credit purchases - interest withdrawn for operations - interest converted to community credits. (In practice, float >= outstanding credits because interest income adds to the pool.)
- Interest earned and allocation breakdown
- Community Renewal Pool: credits distributed, neighborhoods funded, sponsorships enabled

*Shutdown plan:*
If the platform ceases operations:
1. Outstanding credits are forgiven (they were never cashable — users accepted this at purchase).
2. The float is donated to a designated local community nonprofit (named in the charter, updateable by community vote).
3. The shutdown plan is disclosed in Terms and in the trust charter from day one.

*Regulatory positioning:*
The key legal argument (to be validated by counsel, per the VISION doc's compliance gate):

Credits are NOT a stored-value instrument because:
- They cannot be redeemed for cash by anyone, ever
- They cannot be transferred between users (only spent on offerings through the platform)
- They have no secondary market (non-transferable, non-redeemable)
- The platform does not transmit money between users — it issues a participation token and holds the backing in trust

Credits are also NOT a multi-merchant gift card because:
- Makers are not "merchants" in a commercial relationship with the platform
- There is no merchant agreement, no revenue share, no payment processing
- The platform does not settle funds to makers — makers earn credits, not dollars
- The no-cash-out invariant means credits cannot become dollars for anyone

The strongest framing: credits are a "closed-loop community participation token" more analogous to arcade tokens or event tickets than to prepaid cards or money transmission. The trust structure reinforces this: the dollars are not "held for transmission" — they are permanently backing a non-redeemable community instrument.

The weakest point in this argument: the "many unaffiliated makers" element. If regulators view each maker as a separate merchant accepting a common stored-value instrument, the closed-loop exemption may not apply. Counter-arguments: makers don't "accept" credits as payment for goods (which would make them merchants) — they participate in a community barter exchange. There is no commercial relationship between the platform and any maker. The platform doesn't intermediate payments; it runs a closed-loop barter community.

This is the area that MUST go through the bounded legal/compliance review gate in the VISION doc before public launch. The trust structure is the best structural answer the platform can provide, but it doesn't substitute for legal counsel.

**Why it helps:**
- *Float governance:* The trust structure makes the float's purpose, constraints, and oversight explicit. The platform cannot quietly use the float for operations.
- *Legal positioning:* Every structural choice (non-redeemable, non-transferable, trust-held, transparent) supports the "closed-loop community participation token" framing that is most likely to avoid money-transmitter classification.
- *Community trust:* Transparent reporting and a defined shutdown plan build confidence. Users know their purchase dollars back a community trust, not a startup's runway.
- *Sustainable operations:* The interest allocation gives the platform a revenue model that scales with community participation without extracting from the community.

**User perception:** In-product copy: "When you buy credits, your dollars go into a community trust that backs every credit in circulation. They're never used for our operations — only the interest earned supports the platform. Your purchase powers the community, and you can see exactly how in our quarterly transparency report."

**Failure modes:**
- *Legal structure doesn't prevent regulatory action:* True. The trust is the best structural argument, but regulators may disagree. Mitigation: this is why the compliance review gates public launch. If the answer is "you need a money-transmitter license," the trust structure makes compliance easier (the float is already segregated and auditable).
- *Float interest is too small to fund operations:* At small scale, yes. The platform needs other funding (venture, grants, or the founder's day job) until the float is large enough. This is a business model risk, not a mechanism failure.
- *Platform temptation to raid the trust:* Legal segregation makes this fraud, not just bad judgment. The public reporting makes it visible. This is as strong a protection as a small platform can provide.

**Gaming vectors:** None at the user level — this is a platform governance mechanism, not a user-facing incentive. The only "gaming" risk is the platform itself violating the trust, which is addressed by legal structure and transparency.

**Implementation complexity:** Medium-high, but mostly legal/financial rather than software. The software components are: a `platform_treasury` account, interest income ledger entries, a quarterly report generator, and Terms of Service language. The hard work is setting up the actual trust account and getting legal counsel on the regulatory positioning.

---

## System Dynamics: How the Five Interact

The five mechanisms form a self-reinforcing economic loop:

**Credit creation:** Credits enter through purchases (user-funded) and production bonuses (system-minted, tuned by Spend-to-Earn).

**Credit circulation:** Spend-to-Earn creates a natural spend-produce-earn rhythm. Pay It Forward gives net producers a meaningful spending channel. Both drive velocity.

**Credit recycling:** Dormancy demurrage slowly reclaims truly idle credits into the Community Renewal Pool. The pool funds Kindling grants for new neighborhoods and Pay It Forward subsidies, creating a self-sustaining growth engine.

**Dollar backing:** The Float Trust holds all purchase dollars permanently. Interest funds operations (sustainability) and new community credits (growth). The trust structure supports the regulatory argument that this is a closed-loop community instrument, not money transmission.

**Feedback loops:**
1. More participation → more hand-offs → more production bonuses → more credits to spend → more claims → more participation
2. Net-producer surplus → Pay It Forward → newcomer onboarding → more diverse supply → more spending opportunities for net producers → surplus reduction
3. Dormancy → credit recycling → Community Renewal Pool → Kindling grants → new community members → more offerings → less dormancy
4. Growing float → more interest → more community credits → more Kindling → faster neighborhood launches → more purchases → growing float

**Natural stabilizers:**
- Spend-to-Earn prevents runaway accumulation
- Dormancy demurrage prevents liquidity freezing
- Pay It Forward prevents net-producer exit
- Kindling prevents cold-start death spirals
- Float Trust prevents governance collapse

The system is designed so that no single mechanism is load-bearing alone. If demurrage proves too unpopular, Pay It Forward and Spend-to-Earn still drive velocity. If Pay It Forward adoption is low, Spend-to-Earn still solves the net-producer problem. Each mechanism has independent value and compound value in combination.

---

## Tunable Parameters (Starting Values, All Adjustable)

| Parameter | Starting value | Governs |
|-----------|---------------|---------|
| `BASE_PRODUCTION_BONUS_RATE` | 20% of offering credit cost | How much new credit minting per hand-off |
| `SPEND_TO_EARN_SOFT_CAP` | 50 credits | Balance at which bonus floor kicks in |
| `SPEND_TO_EARN_FLOOR` | 10% of base rate | Minimum bonus even at high balance |
| `DEMURRAGE_GRACE_DAYS` | 90 | How long before dormancy triggers |
| `DEMURRAGE_WARNING_DAYS` | 60 | When to warn about upcoming demurrage |
| `DEMURRAGE_RATE_MONTHLY` | 3% | How fast idle credits recycle |
| `DEMURRAGE_EXEMPT_BALANCE` | 5 credits | De minimis floor never touched |
| `KINDLING_FOUNDING_MAKER_GRANT` | 10 credits | Per-maker cold-start grant |
| `KINDLING_FIRST_BITE_SUBSIDY_COUNT` | 50 per neighborhood | How many free first claims |
| `KINDLING_REFERRAL_GRANT` | 3 credits per side | Referral matching amount |
| `PAY_IT_FORWARD_MAX_PER_OFFERING_WEEK` | 5 sponsored claims | Prevent crowding out paid claims |
| `FLOAT_INTEREST_OPS_SHARE` | 60% | Interest to platform operations |
| `FLOAT_INTEREST_COMMUNITY_SHARE` | 40% | Interest to Community Renewal Pool |
