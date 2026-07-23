# DogSwipe Tokenomics Ideas: Scored Evaluation

Scorer: Claude (CC)
Date: 2026-06-17

Scoring criteria: idea quality and insight, real-world utility for a neighbor-to-neighbor barter product, implementation practicality, benefit-to-complexity ratio, and adherence to no-cash-out invariant and community-over-money ethos. Scale: 0 (worst) to 1000 (best).

---

## COD (Codex) Candidates 1-30

### COD-1: Threshold Launch Batch
**Score: 650**
Clever elimination of the first-mover problem — nobody pays until a neighborhood has critical mass. But it has a meta-cold-start problem: how do you get 40 buyers to pledge in a neighborhood where nobody has heard of you? You need marketing to fill the threshold, which is the same cold-start problem one level up. The pledge-then-capture payment flow also adds real complexity.
**Biggest risk:** Thresholds that are too high kill viable neighborhoods; thresholds too low don't solve the empty-economy problem they're designed to prevent.

### COD-2: Pre-Funded Cell Matching Pool
**Score: 720**
Proven, simple, par-backed. The "no second match until real hand-off" gate is a smart anti-farming detail that most matching-pool designs miss. Cost scales linearly with neighborhoods but that's a known customer-acquisition expense. Solid.
**Biggest risk:** Sybil account farming — one person with multiple phones and payment methods can drain the pool.

### COD-3: Sponsor-Seeded Welcome Grants
**Score: 570**
Sound in theory but depends entirely on external sponsors existing, caring, and having budget. For a pre-launch app with no track record, finding sponsors is its own chicken-and-egg problem. The mechanism works; the precondition is the hard part.
**Biggest risk:** Sponsors want influence (ranking, visibility, branding) in return, which conflicts with community-over-profit ethos.

### COD-4: Gift-At-Purchase Split
**Score: 700**
Elegant and genuinely neighborly. One purchase creates two active wallets. The "no gift-to-gift chaining" constraint is correctly identified. This has real viral potential in a hyperlocal context ("I bought credits and sent some to you next door").
**Biggest risk:** Circular gifting between two accounts approximates peer transfer, which weakens the closed-loop regulatory argument.

### COD-5: Maker Discount Coupons, Not Maker Scrip
**Score: 620**
Smart distinction — coupons that reduce credit price are categorically different from maker-issued scrip that acts as a second currency. This avoids the "fragmented unit of account" problem. But it's incremental and adds a whole coupon subsystem for modest benefit.
**Biggest risk:** List-price inflation before couponing (mark up to 8, coupon 3 off, claim "50% off!") — a well-known retail dark pattern.

### COD-6: Launch Drop Windows
**Score: 540**
Good operational idea — concentrating supply and demand into scheduled windows makes thin markets feel alive. But this is an events/marketing tactic, not an economic mechanism. It doesn't change incentives or credit flow; it coordinates timing.
**Biggest risk:** No-shows from makers who committed to launch windows destroy trust in the critical early period.

### COD-7: Buyer Wish Bounties
**Score: 720**
Genuinely useful for the net-producer problem. A maker sitting on 200 credits can post "8 credits for muffins Sunday" and create demand. The escrow design is sound. This also reveals what the community actually wants, which is valuable market signal for other makers.
**Biggest risk:** Devolves into a services marketplace ("20 credits to mow my lawn") which changes the regulatory picture and the community feel.

### COD-8: Vetted Block Captain Credits
**Score: 550**
Manual vetting is unscalable. Favoritism risk is real. The spend-deadline on promotional lots is good, but this is basically a weaker version of the matching pool with added subjectivity about who deserves to be a "captain."
**Biggest risk:** Perceived favoritism — who decides which makers are "trusted" and deserving of free credits?

### COD-9: Verified Hand-Off Production Bonus
**Score: 590**
Necessary but not novel — this is implementing the already-decided production bonus with proper escrow and confirmation. Good specification of the mechanics, but every team building this system would arrive at this design.
**Biggest risk:** Collusive fake hand-offs between two accounts. The per-pair caps and anomaly detection are the right mitigations but hard to tune at small scale.

### COD-10: Community Issuance Budget
**Score: 690**
Publishing a monthly cap on all minting is good governance. It prevents "free credit printing" while making the mint policy legible to the community. The dashboard concept (minted/outstanding/burned) adds transparency.
**Biggest risk:** Cap set too tight stalls the economy during growth; set too loose and credit meaning erodes. Requires constant human judgment to tune.

### COD-11: Credit Lots By Origin
**Score: 740**
This is the key enabling infrastructure for Codex's entire approach. Tagging credits by origin (purchased, earned, bonus, grant) and applying different rules per lot is what makes "demurrage only on bonus lots" possible. Without this, you can't distinguish purchased stored value (legally protected) from community-issued bonuses (can decay). It's infrastructure, not user-facing, but it's load-bearing.
**Biggest risk:** Complexity leaking into the user experience. The wallet must show one balance with simple details; if users need to understand lot mechanics, adoption suffers.

### COD-12: Scarcity-Weighted Production Bonus
**Score: 640**
Market-like signal without central price control. Directing production toward undersupplied categories is economically sound. But thin-market metrics are noisy, and category manipulation (miscategorizing offerings to chase the multiplier) is hard to prevent with automated systems.
**Biggest risk:** In a thin early-stage market, scarcity metrics based on a handful of claims are statistically meaningless and can send misleading signals.

### COD-13: Quality-Gated Minting
**Score: 570**
Rewarding track record with higher bonuses sounds fair but creates an incumbency advantage. New makers with no history get lower bonuses, making the ramp-up harder. The "protected first-N-hand-offs path" mitigates this but adds complexity.
**Biggest risk:** Rich-get-richer dynamic where established makers accumulate faster, worsening the net-producer problem for the most active contributors.

### COD-14: Escrow-First Claim Settlement
**Score: 540**
Basic escrow is expected infrastructure, not a novel mechanism. Every version of this system would put credits in escrow until hand-off confirmation. Well-specified but not a differentiating idea.
**Biggest risk:** Claim spam locking maker inventory. A malicious user could lock multiple offerings by claiming and never showing up.

### COD-15: Proof-Of-Handoff Codes
**Score: 490**
Useful UX feature with minimal economic mechanism substance. QR codes at hand-off are standard for delivery apps. Colluders who are physically co-located can trivially exchange codes, so this doesn't meaningfully deter farming.
**Biggest risk:** False sense of security — the proof is easy to satisfy for anyone physically present, which includes colluders.

### COD-16: Bonus-Lot Demurrage Only
**Score: 780**
The single most legally astute idea in the entire COD document. Federal gift-card rules and state prepaid-access laws restrict dormancy fees and expiration on purchased stored value. By applying decay only to community-issued lots (production bonuses, launch matches, grants) and never touching purchased credits, DogSwipe stays on the right side of the regulatory line while still creating velocity pressure. The framing is perfect: "Bought credits stay yours; community bonus credits are meant to move." This is the idea that makes the entire demurrage question tractable.
**Biggest risk:** Users may still hoard purchased credits indefinitely, since those are protected. If purchased credits dominate the money supply, the bonus-lot demurrage alone may not create enough velocity.

### COD-17: Reciprocity Score In Discovery
**Score: 570**
Soft social pressure for balanced participation without financial punishment. But the signal is weak — a modest discovery ranking benefit won't change economic behavior. And micro-spend gaming to inflate the score is easy.
**Biggest risk:** Penalizes newcomers who have only consumed (they haven't had time to produce) and have a low reciprocity score.

### COD-18: Spend Streak Rewards
**Score: 510**
Positive reinforcement for spending diversity. But the rewards need to come from somewhere (issuance budget), and the gaming vector (low-quality claim loops just to hit the streak) directly undermines quality.
**Biggest risk:** Users make throwaway claims they don't actually want just to maintain a streak. This creates fake velocity without real community value.

### COD-19: Idle Balance Nudges
**Score: 450**
This is a push notification, not an economic mechanism. "Hey, you have credits — want to spend them?" is good UX but does not change incentive structures. Easily ignored.
**Biggest risk:** Notification fatigue. Users tune out nudges, and persistent nudging feels like spam.

### COD-20: Slack-Time Price Boosts
**Score: 460**
Off-peak discounts and bonus lots for slow periods. Smoothing temporal demand is a real problem, but this is a modest operational feature, not a core economic mechanism. Users waiting for discounts may dampen full-price demand.
**Biggest risk:** Trains users to wait for deals rather than claiming at posted prices, undermining price stability.

### COD-21: Community Chest
**Score: 650**
Good governance infrastructure. Every credit sink (burned lots, expired vouchers, round-ups) needs an ethical home, and a transparent community fund is the right answer. The fund-allocation problem (who decides how to spend the chest) is real but manageable.
**Biggest risk:** Governance capture — a small group decides how the chest is spent, favoring their own interests.

### COD-22: Producer Wishboard
**Score: 680**
Same concept as COD-7 (Buyer Wish Bounties) but explicitly targeted at net producers. The "I can turn my extra credit balance into neighborhood demand" framing is correct and useful.
**Biggest risk:** Dominated by high-balance users, crowding out regular community members' wishes.

### COD-23: One-Hop Sponsorship Vouchers
**Score: 660**
Turns net-producer surplus into cold-start fuel for newcomers. The one-hop constraint prevents circulation as a second currency. The social visibility ("a neighbor sponsored your first coffee") is community-aligned.
**Biggest risk:** Off-platform sale of vouchers ("I'll give you $2 for your 5-credit voucher") — impossible to prevent fully in code, must rely on low face values, short TTL, and ToS.

### COD-24: Community Supply Library
**Score: 370**
Interesting concept (borrow tables, carriers for credits) but wildly impractical. Liability for damaged goods, logistics of physical lending, sanitation rules for food equipment, and regulatory complexity around kitchen sharing are all substantial. Way beyond anything a neighborhood credit app should attempt at MVP or even v2.
**Biggest risk:** A single damaged or contaminated shared item creates a liability nightmare that could sink the entire platform.

### COD-25: Producer Bonus Redirect
**Score: 510**
Opt-in redirection of production bonuses to the community chest. The concept is fine but adoption will be near-zero without strong social incentives. Why would a maker voluntarily give up earned credits?
**Biggest risk:** Nobody opts in. The mechanism exists on paper but has no behavioral effect.

### COD-26: Block Party Absorption Events
**Score: 480**
Scheduled events that absorb surplus credits. Community-building in theory, execution-dependent in practice. One bad block party (food quality, turnout, logistics) damages trust disproportionately in a small community.
**Biggest risk:** Poor execution of a single event destroys community trust during the critical early phase.

### COD-27: Community Credit Trust Or Cooperative
**Score: 780**
The right governance answer. Float in segregated trust, platform as administrator not owner, public reconciliation. This is COD's most important structural insight and it's correct: without this, the float is just a startup's cash pile with no protection for the community.
**Biggest risk:** Trust form without actual segregation and audit is worse than no trust — it creates false confidence.

### COD-28: Member-Only Local Network And Caps
**Score: 700**
Conservative caps (max balance, max daily purchase, one jurisdiction at a time) reduce regulatory exposure and make the "closed-loop" argument stronger. The member-only framing changes the legal analysis: these are program members, not unaffiliated merchants. Smart positioning.
**Biggest risk:** Caps set too low frustrate legitimate power users; caps set too high don't meaningfully reduce regulatory exposure.

### COD-29: Tax And Barter Reporting Center
**Score: 580**
Legally responsible and trust-building. The IRS barter-exchange reporting angle is genuinely important and rarely discussed in community-currency design. But this is a compliance requirement, not an economic mechanism.
**Biggest risk:** Tax friction deters participation. Honest disclosure about tax consequences ("your barter income may be taxable") may scare off casual participants.

### COD-30: Reference Basket And Price Bands
**Score: 650**
"10 credits usually buys 2 coffees and a hotdog this month" — anchors credit meaning without price fixing. The minimum sample size and outlier trimming are correctly identified requirements. Practical and useful.
**Biggest risk:** Thin-market collusion — a handful of makers could manipulate median prices by coordinating their pricing.

---

## COD Top 5

### COD Top 1: Community Credit Trust + Member-Only Local Network
**Score: 820**
The single most important structural decision across both documents. Combines the trust governance (#27) with member-only framing and conservative caps (#28). Without this foundation, every other mechanism is legally fragile. The key insight is that the member-only framing changes the regulatory analysis: "program members accepting a shared community-credit rulebook" is categorically different from "unaffiliated merchants accepting a multi-merchant stored-value instrument." The legal reasoning throughout is thorough and correct. This is governance architecture, not a user-facing mechanism, but it's the mechanism that makes every other mechanism defensible.
**Biggest risk:** Legal cost and state-by-state variance. A trust structure doesn't guarantee regulatory exemption; it improves the argument.

### COD Top 2: Threshold Launch Batch + Pre-Funded Matching Pool
**Score: 730**
Good combination of the threshold concept with matching-pool funding. The sequenced approach (pledge, threshold, capture, match, launch event) is well-designed. But the threshold component inherits the meta-cold-start problem: you need to convince 40 strangers to pledge before any of them have experienced the product.
**Biggest risk:** The threshold creates a visible failure mode — neighborhoods that never reach the unlock become evidence that "nobody wants this," even if the threshold was just set too high.

### COD Top 3: Verified Hand-Off Mint With Issuance Budget, Lot Tracking, And Scarcity Multipliers
**Score: 750**
Thorough and well-integrated specification of the production bonus ecosystem. The lot-tracking infrastructure (#11) is the enabler that makes COD Top 4 possible. The scarcity multiplier sends useful market signals. The issuance budget provides governance. This is what "boringly governed" minting should look like.
**Biggest risk:** Scarcity metrics in thin early-stage markets are unreliable — basing minting multipliers on noisy data from 20 claims in a category could amplify errors rather than correcting imbalances.

### COD Top 4: Lot-Safe Velocity System
**Score: 810**
The best economic mechanism in either document. The legal reasoning is impeccable: federal gift-card rules and state prepaid-access laws restrict dormancy fees and expiration on purchased stored value, so demurrage on purchased credits is legally dangerous. Community-issued credits (production bonuses, grants, matches) don't have those protections because they weren't "purchased." By splitting the treatment — purchased credits are perpetual, community lots must circulate — DogSwipe gets velocity pressure exactly where it's legally safe and leaves purchased value untouched. The "Bought credits stay yours; community bonus credits are meant to move" framing is honest, defensible, and user-friendly. This insight alone justifies the lot-tracking infrastructure.
**Biggest risk:** If purchased credits dominate the money supply, bonus-lot demurrage alone may not create enough velocity. The system depends on production bonuses and grants being a significant fraction of outstanding credits.

### COD Top 5: Producer Demand Engine (Wish Bounties, Surplus Vouchers, Reference Pricing)
**Score: 700**
Comprehensive attack on the net-producer dead-end. Bounties create demand from surplus holders, vouchers distribute surplus to newcomers, and reference pricing stabilizes the unit of account. Each component is individually sound and they compose well.
**Biggest risk:** The wishboard could be dominated by high-balance users posting luxury requests ("15 credits for artisanal sourdough"), crowding out everyday community needs and making the app feel exclusive.

---

## GROK Candidates 1-30

### GROK-1: Neighborhood Genesis Matching Pool
**Score: 710**
Same concept as COD-2 with similar strengths. The hand-off gate before second match is a good anti-farming detail. Well-specified.
**Biggest risk:** Multi-account farming — the most common attack on matching pools is a single person with multiple identities.

### GROK-2: Maker-First Posting Escrow
**Score: 340**
Actively counterproductive. Requiring makers to lock 2-5 credits as escrow to post an offering means makers need to BUY credits before they can GIVE to the community. A neighbor with extra coffee who hasn't bought credits yet can't even list their offering. This inverts the barter logic — the whole point is that producing earns credits, but this mechanism requires credits to start producing. It worsens the cold-start problem.
**Biggest risk:** New makers who want to contribute but haven't purchased credits are locked out of posting. The mechanism punishes the exact behavior (production) the economy needs most.

### GROK-3: Reciprocity Pledge Credits
**Score: 550**
Interesting commitment device — 3 credits usable only after completing both a give and a receive within 14 days. Forces the full loop. But the conditional unlock is confusing for users ("Why can't I spend these?"), and 14 days is a tight window in a thin market. If there's nothing you want to claim in 14 days, the pledge expires and you've had a bad first experience.
**Biggest risk:** Users who can't find anything to claim within 14 days lose their pledge credits, creating a negative first impression.

### GROK-4: Gift-at-Purchase Split
**Score: 700**
Same as COD-4. Elegant, neighborly, viral. Same circular-gifting concern.
**Biggest risk:** Circular gifting approximating peer transfer weakens the closed-loop regulatory argument.

### GROK-5: Sponsor-a-Block (Local Business Par Bundles)
**Score: 550**
External business sponsors funding neighborhood grants. Practically useful but introduces commercial interests into a community-over-money system. "Sponsor affects grants only, not ranking" is the right guardrail but hard to enforce when a cafe wants to know what their sponsorship bought.
**Biggest risk:** Local businesses expect marketing ROI from sponsorship, creating tension between commercial and community values.

### GROK-6: Founding Hand-off Ladder
**Score: 620**
Amplified production bonus (2x) for the first 50 hand-offs in a cell. Concentrates early minting on proven activity. The time-bounded nature prevents permanent subsidy. Good incentive alignment.
**Biggest risk:** Collusion to be among the first 50 — two users making rapid fake hand-offs to capture the amplified bonus before legitimate activity begins.

### GROK-7: Time-Boxed Welcome Pricing Floor
**Score: 480**
Platform-suggested 1-credit floor offerings during launch week. The intention (lower first-spend friction) is right, but platform-suggested pricing contradicts the "makers set their own prices" principle. And discovery boosting affordable listings penalizes makers who price fairly.
**Biggest risk:** Race to bottom — everyone prices at 1 credit during launch, establishing a norm that credits are nearly free, making it hard to raise prices later.

### GROK-8: Block Captain Seed Grants
**Score: 550**
Same concept as COD-8. Manual vetting, favoritism risk, unscalable.
**Biggest risk:** Perceived favoritism in "captain" selection.

### GROK-9: Hand-off Production Bonus (baseline)
**Score: 580**
Describing the already-decided production bonus. Necessary specification, not a novel idea.
**Biggest risk:** Self-dealing via alt accounts.

### GROK-10: Float-Coverage Mint Cap
**Score: 680**
Ties maximum outstanding credits to float plus scheduled mint liability. Concrete formula that prevents runaway issuance. Good.
**Biggest risk:** Too-tight cap stalls the economy during growth phases; too-loose cap erodes credit meaning.

### GROK-11: Yield-Recycled Issuance
**Score: 670**
Interest on segregated float mints credits distributed via activity rules. Elegant: non-purchase issuance backed by real yield. But yield at small scale is negligible (5% on a $10K float is $500/year — enough for 50 credits in a year, barely meaningful).
**Biggest risk:** Negligible yield at small scale creates a mechanism that exists in theory but produces almost nothing in practice for years.

### GROK-12: Referral Mint on First Hand-off
**Score: 590**
Tying referral rewards to completed hand-offs (not signups) is the right trigger. Standard viral mechanic with the correct activation condition.
**Biggest risk:** Referral farms with sock-puppet accounts completing staged hand-offs.

### GROK-13: Category Scarcity Multiplier
**Score: 640**
Same as COD-12. Market signal without price control. Thin-market noise is the concern.
**Biggest risk:** Category manipulation (relabeling offerings to chase the multiplier).

### GROK-14: Seasonal Issuance Events
**Score: 440**
"Harvest week" bonus pools are fun flavor but not structurally important. Predictable timing enables gaming (stockpile offerings for harvest week). The cap at min(verified_handoffs x k, yield_reserve) is sensible but the mechanism is decorative, not load-bearing.
**Biggest risk:** Users concentrate activity into event windows and go dormant between them, creating feast-famine cycles.

### GROK-15: Idle Balance Demurrage
**Score: 440**
Aggressive version of demurrage: 1-2%/month after only 30 days of inactivity. "Personal median + threshold" is complex to compute and explain. Most critically, this applies to ALL credits including purchased ones, which creates legal risk under gift-card and prepaid-access regulations that COD correctly identifies and GROK does not address. The 30-day window is too short — many people go a month without thinking about a neighborhood barter app.
**Biggest risk:** Demurrage on purchased credits may violate federal gift-card rules (CARD Act) and state prepaid-access laws, creating legal exposure that undermines the entire platform.

### GROK-16: Producer Demurrage Exemption
**Score: 470**
Well-intentioned but conceptually flawed. The net-producer problem is that makers ACCUMULATE excess credits they can't spend. Exempting net producers from demurrage on earned credits means their surplus grows unchecked — the exemption removes the one pressure mechanism that might motivate spending. This protects the wrong thing: it should encourage net producers to spend, not insulate them from consequences of not spending.
**Biggest risk:** Directly exacerbates the net-producer dead-end by removing spending pressure from the exact users who most need it.

### GROK-17: Rolling Spend Ratio for Discovery Rank
**Score: 560**
Deprioritizing hoarders in discovery is mild social pressure. But a spend/earn ratio below 0.3 could penalize a new maker who's just completed several hand-offs and hasn't had time to spend yet. The 60-day rolling window helps but doesn't fully solve this.
**Biggest risk:** New active makers get deprioritized because they haven't had time to spend their first earnings, creating a discouraging onboarding experience.

### GROK-18: Claim Commitment Hold
**Score: 420**
A 10% hold on top of the claim price until hand-off completion. Confusing UX ("I'm paying 5 credits but 5.5 are being taken?"), adds complexity to the claim flow, and the anti-frivolous-claim benefit is marginal. The existing escrow-until-hand-off already handles the incentive alignment.
**Biggest risk:** Users don't understand why more credits are held than the listed price, creating confusion and distrust at the most important moment — the claim.

### GROK-19: Use-it-or-Sponsor Prompt
**Score: 490**
A nudge toward sponsorship voucher creation when balance is idle. Slightly better than COD-19 (idle nudges) because it suggests a specific productive action (sponsoring). But still a notification, not an economic mechanism.
**Biggest risk:** Easily ignored. The users most likely to respond to nudges are the least likely to be hoarding.

### GROK-20: Velocity Lottery (Community Promo Pool)
**Score: 370**
Monthly lottery for a "featured offering" with entries earned by spending. Lotteries have their own legal complications in many US jurisdictions (gambling laws, sweepstakes regulations). The prize (featured offering) is a weak incentive. And the word "lottery" has negative connotations in a community-trust context.
**Biggest risk:** State gambling and sweepstakes laws may apply. A "lottery" is exactly the wrong association for a platform already navigating money-transmitter and stored-value regulation.

### GROK-21: Producer Surplus Sponsorship Vouchers
**Score: 660**
Same concept as COD-23 with more specific constraints (balance > 2x average spend, net producer status, max 2/month). The constraints are well-calibrated. The 14-day TTL prevents accumulation.
**Biggest risk:** Off-platform sale of vouchers for cash, which can't be fully prevented in code.

### GROK-22: Category Community Pools
**Score: 500**
"Tuesday Coffee Fund" auto-claimed by regulars. Community ritual is nice in theory, but auto-claiming contradicts the intentional, swipe-first discovery ethos. And pool capture by cliques is likely in small communities where the same 5 people always claim.
**Biggest risk:** Clique capture — the same group of insiders auto-claim from the pool, creating an exclusive club within the community.

### GROK-23: Bilateral Taste Matching
**Score: 580**
Discovery that surfaces offerings matching a producer's stated preferences. This is a genuine insight: the real reason net producers don't spend is often that there's nothing they want, and better match quality is the fix. But this is a product/recommendation feature, not an economic mechanism.
**Biggest risk:** Users game preference settings to see everything, reducing the signal to noise.

### GROK-24: Block Party Burn Events
**Score: 480**
Same as COD-26. High-capacity events absorbing surplus. Execution-dependent.
**Biggest risk:** Low-quality mass production ("50 hotdogs" that are undercooked) damages the community brand.

### GROK-25: Honor Producer Streaks (non-monetary)
**Score: 430**
Badges and "block hero" status for producers. Social recognition is nice but doesn't solve the structural economic problem of accumulating unspendable credits. If your credits are useless, a badge doesn't make them useful.
**Biggest risk:** Vanity without substance. Badges don't pay for bread — the net-producer problem is economic, not psychological.

### GROK-26: Segregated Irrevocable Community Float Trust
**Score: 780**
Same governance insight as COD-27. Correct and important. The "irrevocable" qualifier is a good addition — it prevents the platform from unwinding the trust later when the float is tempting.
**Biggest risk:** Trust form without actual fund segregation and audit is worse than no trust.

### GROK-27: Program-Administrator (Not Transmitter) Terms Architecture
**Score: 600**
Smart legal framing: credits as "limited-purpose accounting rights to request neighbor offerings," purchase as "joining a mutual-aid program." But this is legal strategy expressed in Terms of Service, not a product mechanism. The insight that "terms without enforcement" is worse than nothing is correct — the product behavior must match the framing.
**Biggest risk:** Regulators look at substance over form. If the product behaves like stored-value despite the Terms calling it "mutual-aid accounting rights," the Terms won't save you.

### GROK-28: Surplus Float Charter (Demurrage + Expiry Sink)
**Score: 540**
Credits removed by demurrage reduce credit liability; corresponding dollars fund local nonprofits. Ethical home for orphan float. But the nonprofit-selection governance problem is real and potentially contentious.
**Biggest risk:** Nonprofit capture — who picks the recipient nonprofit, and how do you prevent the platform or a clique from directing community funds to their preferred charity?

### GROK-29: Category Median Price Bands
**Score: 640**
Same concept as COD-30. "Unusual price" flag with discovery deprioritization (not blocking) is the right enforcement level — information, not mandate. Correctly specified.
**Biggest risk:** Thin-market collusion on median prices.

### GROK-30: Neighbor Basket Reference Index
**Score: 620**
"Your balance = 3 coffees + 1 dog at median prices" is user-friendly and intuitive. The confidence interval for thin markets (N < 10) is a good detail. Minor mechanism, but good UX.
**Biggest risk:** Misleading in thin or rapidly changing markets. Users make spending decisions based on a "basket" that doesn't reflect current supply.

---

## GROK Top 5

### GROK Top 1: Segregated Community Float Trust + Yield-Recycled Activity Issuance
**Score: 790**
Very similar to COD Top 1 but with yield recycling instead of member-only framing. The trust structure is correct. Yield recycling as a minting source is elegant but its practical impact is negligible at small scale. The "100% recycle into circulation" charter provision is important. Where this falls short of COD Top 1: it lacks the member-only local network framing that changes the regulatory analysis. The "program administrator, not transmitter" argument is stronger when combined with explicit membership structure and conservative caps. COD identifies this and GROK doesn't.
**Biggest risk:** Yield is negligible at small scale ($500/year on a $10K float), making the recycled issuance mechanism practically inert for the first several years.

### GROK Top 2: Verified Hand-off Production Mint with Float-Coverage Cap & Category Gap Multipliers
**Score: 720**
Well-specified production bonus with float-coverage cap and gap multiplier. Similar to COD Top 3 but without the lot-tracking infrastructure that enables differentiated treatment. The float-coverage formula (`outstanding_credits <= trust_principal + approved_mint_liability`) is a clean constraint.
**Biggest risk:** Without lot tracking, the float-coverage ratio conflates purchased and minted credits, making it harder to reason about what's backed by dollars versus what's backed by economic activity.

### GROK Top 3: Launch Cell Matching Pool (Time-Bounded, Hand-off-Gated Par Match)
**Score: 710**
Well-designed cold-start mechanism. The hand-off gate before second matched purchase is the key differentiator from naive matching pools. The visible pool countdown creates healthy urgency. Simpler than COD Top 2 (no threshold batch component), which is both a strength (easier to execute) and a weakness (doesn't solve the "launching into emptiness" problem).
**Biggest risk:** Pool exhausts before critical mass is reached, leaving late joiners without the matching benefit that early adopters received, creating perceived unfairness.

### GROK Top 4: Idle Demurrage with Producer Exemption -> Community Chest Recycling
**Score: 590**
The Community Chest recycling is sound. The 45-day window with micro-spend threshold is well-specified. But two fundamental problems sink this: (1) applying demurrage to purchased credits creates legal risk under gift-card and prepaid regulations that this document never addresses — COD's lot-safe approach correctly avoids this; (2) the producer exemption protects net producers from the spending pressure that might actually solve their accumulation problem. The exemption is compassionate but economically counterproductive.
**Biggest risk:** Legal exposure from demurrage on purchased stored value. COD correctly identifies that purchased credits may have gift-card regulatory protections. GROK ignores this entirely.

### GROK Top 5: Producer Surplus Sponsorship Vouchers (One-Hop, Short-TTL)
**Score: 660**
Good relief valve for net-producer surplus. The eligibility constraints (balance > 2x average spend AND net producer status, max 2/month) are specific and well-calibrated. The 14-day TTL prevents voucher hoarding. One-hop, non-transferable, not redeemable at sponsor's own offerings — all the right constraints. Less ambitious than COD Top 5 (which bundles bounties, vouchers, and reference pricing) but more focused.
**Biggest risk:** Voucher gray market — "I'll give you $2 cash for your 5-credit voucher" off-platform. Code can't prevent this; only low face values and short TTLs limit the damage.

---

## Overall Verdict

### Strongest Single Idea Across Both Models

**COD Top 4: Lot-Safe Velocity System (Score: 810)**

This is the most genuinely novel and legally astute insight in either document. The recognition that purchased stored value has gift-card regulatory protections (CARD Act, state prepaid laws) while community-issued credits do not is the single most important distinction for making demurrage work in a US-regulated environment. "Never expire purchased credits; only apply velocity pressure to community-issued lots" resolves the central tension between wanting credit circulation and respecting the legal and ethical status of money people paid in. Neither GROK nor most community-currency designers make this distinction, and its absence is why many demurrage proposals are either legally dangerous or ethically uncomfortable. COD's lot-tracking infrastructure (#11) enables this, and the system-level composition (lot-safe demurrage feeding a Community Chest that funds cold-start grants) is elegant. The idea is practical to implement, legally sound, and directly addresses the hardest design tension in the system.

### Weakest Single Idea Across Both Models

**GROK-2: Maker-First Posting Escrow (Score: 340)**

Requiring makers to lock credits as escrow just to post an offering means they must BUY credits before they can GIVE to the community. This inverts the fundamental barter logic — production should be the path INTO the economy, not something gated behind a purchase. A neighbor with extra coffee and zero credits cannot even list their offering. The mechanism actively worsens cold start and punishes exactly the generosity the platform exists to enable.
