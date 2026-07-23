Reading the project docs first so the economic mechanisms align with DogSwipe's pivot and constraints.
I read `docs/VISION.md` and `README.md` carefully. `AGENTS.md` is not present in this repo. The vision doc fixes the invariants (par purchase, no cash-out, spend-only-on-others, append-only ledger, float as community liability) and already commits to a small production bonus mint on confirmed hand-off. Below: 30 candidate mechanisms, then the top 5.

---

## 30 Candidate Mechanisms

### Cold-start (1–8)

**1. Neighborhood Genesis Matching Pool**  
*How:* First $X of par purchases in a new geographic cell get a 1:1 platform match (buy 10 → receive 20). Match credits are pre-funded from a launch reserve (operator par purchase into trust), not unbacked mint.  
*Why:* Solves empty-wallet chicken-and-egg without asking anyone to be first alone.  
*Failure/gaming:* Multi-account farming; match exhausts before real density. Mitigate: one match per verified identity, match unlocks only after first completed hand-off.

**2. Maker-First Posting Escrow**  
*How:* Posting an offering locks 2–5 credits in escrow; returned on fulfilled hand-off or partial forfeit on no-show.  
*Why:* Puts credits into circulation immediately; signals serious listings on day one.  
*Failure/gaming:* Wealthy users spam listings. Mitigate: cap active listings per user, escrow scales with reputation.

**3. Reciprocity Pledge Credits**  
*How:* New users receive 3 non-transferable pledge credits usable only after completing one receive + one give hand-off within 14 days.  
*Why:* Bootstraps both sides of the loop with a commitment device.  
*Failure/gaming:* Fake hand-offs between sock puppets. Mitigate: mutual confirmation + geo/time window + review gating.

**4. Gift-at-Purchase Split**  
*How:* Credit purchase UI offers “gift half to a neighbor” — still 1:1 par, but ledger splits at purchase.  
*Why:* Bilateral liquidity from the first dollar in; feels neighborly not promotional.  
*Failure/gaming:* Circular gifting rings. Mitigate: gifts only to distinct verified accounts, no round-trip within 30 days.

**5. Sponsor-a-Block (Local Business Par Bundles)**  
*How:* A café sponsors “10-credit neighbor packs” sold at par; sponsor’s marketing budget pre-funds a neighborhood grant pool distributed as match or gift.  
*Why:* External goodwill funds float without violating closed-loop spend rules.  
*Failure/gaming:* Pay-to-win discovery placement. Mitigate: sponsor affects grants only, not ranking.

**6. Founding Hand-off Ladder**  
*How:* First N confirmed hand-offs in a cell earn amplified production bonus (e.g. 2× for hand-offs 1–50).  
*Why:* Concentrates early minting on proven activity, not idle accounts.  
*Failure/gaming:* Collusion to farm early bonuses. Mitigate: cap per user, decay schedule, category diversity requirement.

**7. Time-Boxed Welcome Pricing Floor**  
*How:* Launch week: platform suggests 1-credit floor offerings in seed categories; discovery boosts affordable listings.  
*Why:* Lowers first-spend friction when nobody knows “what a credit means.”  
*Failure/gaming:* Race to bottom quality. Mitigate: floor is suggestion not mandate; reputation weight rises after week 1.

**8. Block Captain Seed Grants**  
*How:* Trusted early makers (manually vetted) receive one-time 15-credit grants from launch reserve, spendable only on others’ offerings within 30 days.  
*Why:* Ensures visible supply before mass buyer adoption.  
*Failure/gaming:* Captain hoards or colludes. Mitigate: spend-only-on-others enforced in ledger; idle grant expires.

---

### Minting & issuance (9–14)

**9. Hand-off Production Bonus (baseline)**  
*How:* On mutually confirmed hand-off, maker receives list price + small minted bonus (e.g. +0.5–2 credits by category).  
*Why:* Rewards production over pure buying; adds liquidity without purchase.  
*Failure/gaming:* Self-dealing via alt accounts. Mitigate: no self-claims, device/identity heuristics, anomaly review.

**10. Float-Coverage Mint Cap**  
*How:* `max_outstanding_credits = dollar_float + scheduled_mint_liability`; any mint rejected if it breaches ratio.  
*Why:* Keeps every credit philosophically backed; prevents runaway issuance.  
*Failure/gaming:* Stalls economy if cap too tight. Mitigate: dynamic cap tied to 90-day velocity.

**11. Yield-Recycled Issuance**  
*How:* Interest on segregated float (T-bills/money market) mints credits monthly, distributed only via activity rules (bonuses, grants, velocity rewards).  
*Why:* Non-purchase issuance backed by real economic yield, not fiction.  
*Failure/gaming:* Yield treated as profit. Mitigate: legal charter requires 100% recycle into circulation.

**12. Referral Mint on First Hand-off**  
*How:* Referrer receives small mint only when referee completes first verified hand-off (not at signup).  
*Why:* Ties issuance to real economic proof.  
*Failure/gaming:* Referral farms. Mitigate: one referral bonus per identity, diminishing returns.

**13. Category Scarcity Multiplier**  
*How:* Production bonus scales up when category supply in cell is below demand (claims > offerings).  
*Why:* Directs minting where liquidity is thinnest.  
*Failure/gaming:* Category manipulation. Mitigate: multi-week rolling averages, admin override.

**14. Seasonal Issuance Events**  
*How:* “Harvest week” — bonus pool mint capped at min(verified_handoffs × k, yield_reserve).  
*Why:* Predictable liquidity pulses without permanent inflation.  
*Failure/gaming:* Timing exploits. Mitigate: announce schedule, per-user caps.

---

### Anti-hoarding & velocity (15–20)

**15. Idle Balance Demurrage**  
*How:* Balances above personal median + threshold lose 1–2%/month if no spend in 30 days.  
*Why:* Classic Gesell velocity tool; hoarding has cost.  
*Failure/gaming:* Punishes legitimate savers planning a big claim. Mitigate: exempt first $20, demurrage only on excess.

**16. Producer Demurrage Exemption**  
*How:* Net producers (30-day gives > takes) pay zero demurrage on earned credits.  
*Why:* Don’t tax the people you need most.  
*Failure/gaming:* Brief production spikes to reset exemption. Mitigate: rolling 90-day window.

**17. Rolling Spend Ratio for Discovery Rank**  
*How:* Users with spend/earn ratio below 0.3 over 60 days get deprioritized in maker visibility tools, not blocked.  
*Why:* Social pressure to circulate without confiscation.  
*Failure/gaming:* Gaming via micro-spends. Mitigate: minimum meaningful spend threshold.

**18. Claim Commitment Hold**  
*How:* Claim spends credits immediately but locks small hold (10%) until hand-off confirm; released to maker on completion.  
*Why:* Reduces frivolous claims that freeze credits; increases effective velocity.  
*Failure/gaming:* Claim-and-ghost. Mitigate: forfeit hold on no-show, reputation hit.

**19. Use-it-or-Sponsor Prompt**  
*How:* At 60 days idle above 90th percentile balance, app prompts sponsor-voucher creation or category pool donation.  
*Why:* Nudge before demurrage bites; frames hoarding as community opportunity.  
*Failure/gaming:* Ignore prompts. Mitigate: pair with demurrage.

**20. Velocity Lottery (Community Promo Pool)**  
*How:* Monthly drawing for featured offering; entries earned by spend above threshold. Pool funded by demurrage + yield.  
*Why:* Makes spending slightly fun without cash prizes.  
*Failure/gaming:* Sybil entries. Mitigate: one entry per verified user per month.

---

### Net-producer dead-end (21–25)

**21. Producer Surplus Sponsorship Vouchers**  
*How:* Net producers mint transferable 3–5 credit vouchers from balance, redeemable only on others’ offerings, max 2/month.  
*Why:* Converts unspendable surplus into cold-start fuel for neighbors.  
*Failure/gaming:* Voucher black market approximating cash-out. Mitigate: non-transferable beyond one hop, expire in 14 days, no peer cash trades.

**22. Category Community Pools**  
*How:* Excess credits donated to “Tuesday Coffee Fund” auto-claimed by regulars on a schedule.  
*Why:* Collective absorption of surplus into neighborhood ritual.  
*Failure/gaming:* Pool capture by clique. Mitigate: transparent ledger, round-robin eligibility.

**23. Bilateral Taste Matching**  
*How:* Discovery prioritizes offerings aligned with producer’s stated preferences (“you make coffee, here’s nearby baking”).  
*Why:* Fixes match quality, the real reason credits go unspent.  
*Failure/gaming:* Preference spam. Mitigate: preference limits, decay unused prefs.

**24. Block Party Burn Events**  
*How:* Scheduled high-capacity offerings (50 hotdogs at 5 credits) absorb collective surplus; producers co-host.  
*Why:* Ritualizes surplus spending as community celebration.  
*Failure/gaming:* Low-quality mass production. Mitigate: reputation-weighted hosting slots.

**25. Honor Producer Streaks (non-monetary)**  
*How:* Visible streaks, “block hero” badges, early access to posting slots — parallel to credits.  
*Why:* Makes production meaningful when credit balance is useless.  
*Failure/gaming:* Vanity without substance. Mitigate: badges require confirmed hand-offs only.

---

### Float governance & compliance (26–28)

**26. Segregated Irrevocable Community Float Trust**  
*How:* All par purchases land in a statutory trust; platform is administrator not owner; charter forbids distribution to shareholders.  
*Why:* Strongest legal framing for no-cash-out stored value across unaffiliated makers.  
*Failure/gaming:* Trust form without substance. Mitigate: annual audit, public reconciliation report.

**27. Program-Administrator (Not Transmitter) Terms Architecture**  
*How:* Credits defined as limited-purpose accounting rights to request neighbor offerings; purchase characterized as joining a mutual-aid program.  
*Why:* Supports narrow regulatory argument with behavior to match (no redemption, no peer cash exchange).  
*Failure/gaming:* Terms without enforcement. Mitigate: product copy, code, and ops all align.

**28. Surplus Float Charter (Demurrage + Expiry Sink)**  
*How:* Credits removed by demurrage/expiry reduce liability; corresponding dollars fund local nonprofit services or community events, never user payout.  
*Why:* Ethical home for float drift; avoids indefinite orphan liability.  
*Failure/gaming:* Nonprofit capture. Mitigate: community vote on recipients, capped annual outflow.

---

### Unit-of-account stability (29–30)

**29. Category Median Price Bands**  
*How:* Weekly computed median ± band per category per cell; offerings outside band get “unusual price” flag and discovery deprioritization (not blocking).  
*Why:* Anchors credit meaning without central price fixing.  
*Failure/gaming:* Collusion on median. Mitigate: trimmed mean, minimum sample size.

**30. Neighbor Basket Reference Index**  
*How:* Wallet shows “your balance ≈ 3 coffees + 1 dog at median prices”; index updated weekly from settled claims.  
*Why:* Users perceive stable purchasing power even when individual prices vary.  
*Failure/gaming:* Misleading if thin market. Mitigate: show confidence interval when N < 10.

---

## Top 5 Mechanisms (Best → Worst)

### 1. Segregated Community Float Trust + Yield-Recycled Activity Issuance

**How it works:** Every par purchase deposits dollars into a segregated, irrevocable trust (or equivalent regulated custodial account) held for the benefit of all credit holders. The operating company is *program administrator*, not owner of the float. Trust charter: (a) no redemption to users ever, (b) no dividends to shareholders, (c) surplus only via documented community allocations. Float principal earns safe yield (Treasury/money-market). Yield mints a bounded monthly credit pool distributed *only* through activity-linked rules: production bonuses, launch matching, velocity rewards, dispute refunds (credits only). Every mint carries a ledger reason code and counts against a published `float_coverage_ratio`.

**Why it’s #1:** This is the load-bearing mechanism. It simultaneously answers float governance (#5), principled issuance (#2), and cold-start funding (#1) without breaking par at the purchase boundary or sneaking in cash-out. Purchased credits remain 1:1 backed by trust principal; minted credits are backed by (i) scheduled production-liability reserves and (ii) yield — a second, transparent layer users can understand as “community growth,” not counterfeit money. Legally and ethically, it frames DogSwipe as administering neighborly accounting rights, not operating a withdrawable wallet. Yield recycling reinforces community-over-profit: the float works for the neighborhood while sitting idle.

**User perception:** “My credits are real community money held in trust for all of us; the app can’t run off with it or pay shareholders from my $10.” Yield-funded bonuses feel like the community pool growing through participation, not inflation.

**Implementation:** Trust formation + custodian + monthly reconciliation (`trust_principal == outstanding_purchased_credits + mint_liability_reserve`). Ledger tags: `purchase`, `spend`, `production_mint`, `yield_mint`, `demurrage_burn`, `grant`. Public dashboard: float, outstanding credits, coverage ratio.

**Failure modes:** Legal cost and state-by-state variance; yield rates negligible at small scale; operator temptation to commingle funds. **Gaming:** N/A at mechanism level — failure is organizational (commingling, charter drift). Mitigate with audit, single-state pilot, conservative mint caps.

---

### 2. Verified Hand-off Production Mint with Float-Coverage Cap & Category Gap Multipliers

**How it works:** On mutually confirmed hand-off, maker receives claim price (ledger transfer from claimer) **plus** a small minted production bonus. Bonus base rate is fixed (e.g. 10–20% of claim price, floor/ceiling in credits). **Gap multiplier:** if category demand exceeds supply in the cell (rolling 14-day claims/offers ratio), bonus scales up modestly (e.g. 1.0× → 1.5×). **Hard cap:** total outstanding credits ≤ trust principal + approved mint liability schedule; if a mint would breach, bonus truncates or queues to next period. Mint entries are signed, append-only, and auditable.

**Why it’s #2:** This is the economy’s engine — it’s already decided in vision and directly attacks liquidity (#2), producer incentive (#4), and thin-market cold-start (#1 via gap multiplier). Tying mint to *verified hand-offs* grounds issuance in real neighborly production, not signup spam. The float cap prevents runaway inflation that would destroy unit meaning (#6). Gap multipliers steer production toward underserved categories without central planning.

**User perception:** “Making for neighbors pays a little extra — especially when nobody else is offering salsa this week.” Producers feel rewarded; buyers see a living marketplace, not a static store.

**Implementation:** Hand-off confirmation triggers atomic spend + credit + mint in one transaction. Category stats job every night. Bonus formula in config, versioned. Negative tests: no mint without confirm, no mint on self-deal.

**Failure modes:** Colluding pairs farm bonuses with junk offerings. **Gaming:** Sock-puppet hand-offs, disposable low-quality listings. Mitigate: identity signals, minimum offering lifetime before claim, reputation decay on disputes, per-pair frequency limits, bonus reduction for repeat counterparties.

---

### 3. Launch Cell Matching Pool (Time-Bounded, Hand-off-Gated Par Match)

**How it works:** Each new geographic cell opens with a finite **matching pool** (e.g. 500 credits), pre-funded by operator par purchase into the trust (same as any user buy). For the first 90 days or until pool depletion: each user’s **first** par purchase up to $20 is matched 1:1 (pay $15 → receive 30 credits). Matched credits are tagged `launch_match` and are spendable immediately, but the user cannot make a second matched purchase until they complete **one verified receive hand-off**. Pool depletes visibly in-app (“$312 of neighbor match left on your block”).

**Why it’s #3:** Best cold-start mechanism that respects invariants. Nobody must “go first” alone — the match halves effective price of entry. Because match funds are par-purchased into trust first, they’re not counterfeit. Hand-off gate ensures matches convert to real circulation, not hoarded doubles. Time and pool bounds prevent perpetual subsidy. Works synergistically with #1 (trust-funded) and #2 (hand-offs prove activity).

**User perception:** “My block is bootstrapping — the first neighbors get a boost, but I have to actually show up and claim something.” Feels fair and temporary, not a giveaway scam.

**Implementation:** Cell geofence registry, per-user `first_match_used` flag, pool ledger account, spend tagging. UI countdown. When pool empty, pure par only.

**Failure modes:** Pool exhausts before critical mass; wealthy users buy max match and leave. **Gaming:** Multi-account match farming. Mitigate: one match per verified identity, device fingerprinting heuristics, match credits excluded from any future peer transfer, optional phone verification at purchase.

---

### 4. Idle Demurrage with Producer Exemption → Community Chest Recycling

**How it works:** Credits above a soft floor (e.g. first 15 credits exempt) that have had **no outbound spend in 45 days** incur monthly demurrage of 1.5% on the excess portion. **Producer exemption:** accounts with net production (credits earned from hand-offs > credits spent) over a rolling 90-day window pay zero demurrage on earned credits (purchased credits above floor still demurrage if idle). Demurraged credits are **burned** (liability reduced) and simultaneously re-minted into a **Community Chest** account used only for: sponsorship vouchers (#21), block events, dispute goodwill grants — never operator payroll, never user fiat.

**Why it’s #4:** Directly solves hoarding (#3) in a no-cash-out world where “why spend?” is existential. Exemption protects net producers (#4) from the worst dead-end feeling (“I gave too much and now I’m taxed”). Recycling burned credits into Community Chest avoids awkward trust principal / liability mismatch — demurrage is a intentional liability sunset, with ethical reuse per float charter (#28). Creates predictable velocity without punishing active participants.

**User perception:** Active neighbors: unaffected. Couch hoarders: gentle pressure. Generous makers: protected. Demurrage isn’t “the platform taking your money” — it’s “idle credits go back to the block fund.”

**Implementation:** Nightly job: compute idle excess, apply demurrage, append `demurrage_burn` + `chest_mint` entries. Wallet shows “last spend 38 days ago — 1.5% neighbor fund contribution next week if idle.” Producer badge explains exemption.

**Failure modes:** Angry users at first demurrage tick; accounting complexity when burning purchased vs minted credits. **Gaming:** Micro-spends to reset idle clock; brief production to claim exemption. Mitigate: demurrage on 45-day window not monthly touch; exemption requires sustained production ratio; micro-spend threshold (<2 credits) doesn’t reset.

---

### 5. Producer Surplus Sponsorship Vouchers (One-Hop, Short-TTL)

**How it works:** Users with balance > 2× their 90-day average spend AND net producer status may create **sponsorship vouchers** (3–5 credits, max 2/month): burns from their balance, mints a voucher code/credit object redeemable by **one other verified user** on any offering except the sponsor’s own. Vouchers expire in 14 days; non-transferable after first redemption; cannot be consolidated or sold (ledger enforces one-hop). Discovery surfaces “neighbor-sponsored bites” for new users with low balances.

**Why it’s #5 (still strong, but narrower):** Elegant relief valve for net-producer dead-end (#4) that * strengthens* cold-start (#1) by piping surplus to credit-poor neighbors. Fully respects no-cash-out: vouchers are spend-only-on-others, same as all credits. Turns “I have 200 credits and nothing I want” into “I’m buying coffee for the new family on the block.” Less foundational than #1–#4 because it only helps after surplus exists, and it doesn’t address float law or baseline issuance.

**User perception:** Producers become patrons — status and generosity without cash extraction. New neighbors feel welcomed. Aligns with community-over-money ethos.

**Implementation:** `create_voucher` burns balance, mints `voucher:{id}` with constraints; redemption spends voucher atomically on claim. API rejects voucher peer-to-peer transfer, stacking, or maker self-redemption.

**Failure modes:** Voucher gray market ( “I’ll give you $2 for your 5-credit voucher” off-platform). Thin voucher supply if producer exemption in #4 works too well. **Gaming:** Sock-puppet redemption. Mitigate: redeemer cannot be repeat counterparty to sponsor in 60 days; off-platform cash deals are ToS violation not solvable in code; cap voucher face value.

---

## Why This Stack Hangs Together

| Problem | Primary mechanisms |
|--------|---------------------|
| Cold-start | #3 match pool, #5 vouchers, #2 gap multiplier |
| Minting / backing | #1 trust + yield, #2 hand-off mint + cap |
| Anti-hoarding / velocity | #4 demurrage, #2 continuous spend incentive via bonuses |
| Net-producer dead-end | #4 exemption, #5 vouchers, #2 production mint |
| Float governance | #1 trust charter, #4 chest recycling |
| Unit stability | #2 mint cap, #29–#30 (median bands + basket UI) as complementary dials |

The ranking reflects leverage and load-bearingness: **trust architecture** and **activity-grounded minting** define whether the system is legally credible and economically real; **launch match** ignites the loop; **demurrage + exemption** keeps credits moving without punishing makers; **sponsorship vouchers** handle the long-tail surplus case with neighborly grace rather than extraction.
