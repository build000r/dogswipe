# DogSwipe Community-Credit Mechanism Ideas - Codex

Date: 2026-06-17

This is mechanism design, not legal advice. The design assumes the invariants in `docs/VISION.md`: credits are bought at par, real money enters only through purchase, participants must hold credits, there is no cash-out for anyone, credits are spent only on other people's offerings, all movements are signed append-only ledger entries, balances are derived, and confirmed hand-offs mint a small production bonus to the maker.

The key legal caution is that DogSwipe can easily look like stored value, prepaid access, a gift-card program, a money-transmission program, or a barter exchange if the mechanics drift. That does not mean "do not build it." It means the tokenomics should make the best legal argument true in product behavior: member-only, local, limited-purpose, no peer cash trading, no redemption, no investment language, no transferable token market, clear tax exports, segregated float, conservative balance caps, and counsel before public launch.

## Regulatory Guardrails Used In This Pass

- FinCEN treats money transmission broadly when a business accepts currency, funds, or value that substitutes for currency and transmits it to another person or place. Cross-maker redemption is the dangerous fact pattern.
- FinCEN's prepaid-access materials include closed-loop thresholds, but DogSwipe should not rely on a threshold alone because many unaffiliated makers and reloadable balances weaken the analogy.
- Federal gift-card rules restrict dormancy/inactivity fees and expiration; some states add cash-redemption rights for low gift-card balances. Therefore: do not demurrage or expire purchased credits. Use decay only on promotional, matched, or minted community lots, and still gate through counsel.
- IRS barter guidance treats barter value as potentially taxable, and barter exchanges can have reporting duties. DogSwipe should provide ledger/tax exports and avoid telling users credits make taxable value disappear.

Sources checked: FinCEN prepaid access guidance and final rule, FinCEN money-transmission guidance, CFPB Regulation E gift-card rules, California DFPI money-transmitter/stored-value pages, IRS Topic 420, and IRS Form 1099-B instructions.

## 30 Candidate Mechanisms Screened

### 1. Threshold Launch Batch

How it works: a neighborhood cell does not actually issue credits until it hits minimum viable density, for example 40 credit buyers, 15 makers, 50 posted offerings, and 200 committed credits. Users authorize a purchase pledge, makers pledge launch offerings, then DogSwipe captures purchases and issues credits only when the cell unlocks.

Why it helps: nobody has to be the first real buyer into an empty economy. The first day starts with both balances and supply.

User perception: "My card is not charged unless the block is actually live."

Implementation: launch-cell table, pledge ledger entries separate from settled purchases, payment authorization/capture idempotency, public progress meter, automatic pledge release if the threshold fails by a deadline.

Failure and gaming: thresholds can be too high, stale maker pledges can inflate density, and users can authorize then fail capture. Mitigate with small first cells, maker re-confirmation before capture, and conservative overbooking.

### 2. Pre-Funded Cell Matching Pool

How it works: the operator, a sponsor, a nonprofit, or early community members buy credits at par into a launch pool. First purchases in a cell are matched from that pool, often 1:1 up to a cap. Matching credits are not unbacked.

Why it helps: halves first-purchase friction and creates visible liquidity.

User perception: "The neighborhood is matching early buy-in."

Implementation: pool account, per-identity match limits, matched-credit lot tagging, pool countdown, no second match until the user completes a real receive hand-off.

Failure and gaming: Sybil accounts can farm matches. Mitigate with one match per payment instrument/phone/device cluster, smaller caps, and delayed eligibility for production bonuses on matched-credit claims.

### 3. Sponsor-Seeded Welcome Grants

How it works: a school, block club, mutual-aid group, or local patron buys credits at par and distributes small one-time grants to verified residents. Grants are spend-only, no cash-out, and cannot be transferred except through claims.

Why it helps: introduces credits to people who would not buy first, without counterfeiting credits.

User perception: "A local group put credits into the block fund for neighbors to try this."

Implementation: grant campaign ledger, eligibility rules, expiration only if legally allowed for promotional credits, sponsor transparency, no sponsor influence on discovery ranking.

Failure and gaming: grant capture by insiders and reputational concern that sponsors are buying attention. Mitigate by publishing campaign terms, capping grant size, and keeping sponsor effects out of ranking.

### 4. Gift-At-Purchase Split

How it works: when buying credits, a user can split part of the purchase into a one-hop gift to another verified neighbor. The dollars enter at par; the recipient gets credits but cannot re-gift them outside a claim.

Why it helps: one purchase creates two active wallets and makes credit purchase feel neighborly.

User perception: "I bought myself 10 credits and gave 3 to the new neighbor upstairs."

Implementation: purchase flow with recipient selection/invite, gift lot tagging, no self-gift, no repeat reciprocal gifts inside a short window.

Failure and gaming: circular gifting can approximate peer transfer. Mitigate by one-hop gifts, no gift-to-gift chaining, repeat-pair limits, and no production bonus on immediately reciprocal claims.

### 5. Maker Discount Coupons, Not Maker Scrip

How it works: makers can issue nontransferable coupons that reduce the credit price of their own offering. These are not credits, cannot circulate, cannot be sold, and do not appear as wallet balance.

Why it helps: handles the "seller-issued store coupon or scrip" question without creating a second currency or fragmenting unit-of-account.

User perception: "Maria is offering 2 credits off tomorrow's coffee," not "Maria issued money."

Implementation: coupon table, single-maker redemption scope, per-user limits, expiration as a coupon term, clear UI separation from credits.

Failure and gaming: fake list-price inflation before coupons. Mitigate with historical price display and category price medians.

### 6. Launch Drop Windows

How it works: the app schedules high-density launch windows, for example "Saturday 10-12: 30 neighbors offering coffee, dogs, produce." Credits are usable any time, but the launch event creates a reason to spend immediately.

Why it helps: concentrates supply and demand into the same hours, which matters more than raw signup count.

User perception: "There will actually be stuff to claim when I open the app."

Implementation: event cells, maker commitments, inventory caps, reminder notifications, post-event settlement and review prompts.

Failure and gaming: no-shows damage trust. Mitigate with small claim holds, reputation impact, and event hosts who verify readiness.

### 7. Buyer Wish Bounties

How it works: users post credit-backed requests like "8 credits for two sourdough muffins Sunday morning." Credits are reserved, makers can accept, and settlement happens through normal hand-off.

Why it helps: creates supply in response to actual demand, especially for net producers who have credits but nothing they want.

User perception: "I can ask the block for what I actually want."

Implementation: bounty escrow, maker accept/decline flow, fulfillment window, category tags, anti-spam limits.

Failure and gaming: impossible requests, private contract disputes, or bounty spam. Mitigate with templates, price guidance, reputation gates, and cancellation rules.

### 8. Vetted Block Captain Credits

How it works: manually trusted early makers receive small, pre-funded credits that must be spent on others within the launch period after they post or fulfill real offerings.

Why it helps: seed makers become buyers too, preventing the first supply wave from becoming a pile of dead balances.

User perception: "The first hosts got credits to explore the community, not to cash out."

Implementation: manual admin grant from a funded launch reserve, spend deadline only for promotional lots, and reporting of usage.

Failure and gaming: favoritism and idle grants. Mitigate with public criteria and small grants.

### 9. Verified Hand-Off Production Bonus

How it works: confirmed claims transfer the listed credit price from claimer to maker and mint a small bonus to the maker.

Why it helps: rewards production over passive buying and injects liquidity based on real activity.

User perception: "Making for neighbors earns a little extra."

Implementation: atomic claim settlement, hand-off confirmation, signed `production_bonus_mint` entry, versioned bonus formula.

Failure and gaming: collusive fake hand-offs. Mitigate with per-pair caps, proof-of-presence, dispute penalties, and bonus reduction on repeat pairs.

### 10. Community Issuance Budget

How it works: every mint must fit inside a published monthly issuance budget funded by yield, donations, operator capitalization, or a conservative fraction of active purchased-credit float.

Why it helps: prevents "free credit printing" while preserving the decided production bonus.

User perception: "Bonuses come from the community issuance budget, not from an invisible admin edit."

Implementation: budget ledger account, cap checks in the settlement transaction, dashboard showing minted/outstanding/burned lots.

Failure and gaming: too-tight caps stall bonuses; too-loose caps inflate prices. Mitigate with small pilot parameters and public monthly tuning.

### 11. Credit Lots By Origin

How it works: balances are derived from lots: purchased, earned transfer, production bonus, launch match, sponsor grant, voucher, refund, and correction. Spend ordering and decay rules depend on origin.

Why it helps: lets DogSwipe protect purchased credits while applying velocity pressure to promotional/minted credits.

User perception: wallet still shows one balance, with clear details only when needed.

Implementation: ledger lot IDs, origin metadata, FIFO or policy-based spend selection, balance views by lot class.

Failure and gaming: complexity and user confusion. Mitigate with simple wallet copy: "Bought credits never expire; community bonus credits move first."

### 12. Scarcity-Weighted Production Bonus

How it works: production bonus increases modestly when a category/cell has more demand than supply, and decreases when supply is saturated.

Why it helps: nudges makers toward undersupplied categories without central price control.

User perception: "Baked goods are in demand this week, so producing them earns a slightly larger bonus."

Implementation: rolling claim/search/wish/offering ratios, minimum sample size, capped multiplier, no multiplier for low-trust accounts.

Failure and gaming: makers miscategorize offerings to chase the multiplier. Mitigate with moderation, category confidence, and trimmed averages.

### 13. Quality-Gated Minting

How it works: new makers get the base production bonus only. Higher bonus tiers unlock after completed hand-offs with low disputes and decent two-way reviews.

Why it helps: reduces junk production created only to farm mints.

User perception: "Better community reliability earns better community bonuses."

Implementation: reputation score, dispute exclusions, delayed bonus unlock, appeal process.

Failure and gaming: incumbents get richer and newcomers struggle. Mitigate with a protected first-N-hand-offs path and category scarcity boosts for new supply.

### 14. Escrow-First Claim Settlement

How it works: claim credits move into escrow at claim time, not directly to the maker. On mutual confirmation, escrow releases to maker and triggers production mint. If the hand-off fails, credits return as credits.

Why it helps: reduces disputes and avoids admin-minted refunds.

User perception: "My credits are reserved, but the maker earns only after the hand-off."

Implementation: `claim_hold`, `claim_release`, `claim_refund_credit` ledger entries, timeout rules, admin correction entries.

Failure and gaming: claim spam can lock maker inventory. Mitigate with no-show penalties and claim frequency limits.

### 15. Proof-Of-Handoff Codes

How it works: the app generates a short hand-off code or QR token; both parties confirm in the pickup window. Optional coarse geofence/time proof supports anomaly review.

Why it helps: makes production mints harder to farm at scale.

User perception: quick, familiar pickup confirmation.

Implementation: one-time tokens, server validation, privacy-minimized location signals, manual dispute fallback.

Failure and gaming: colluders can still exchange codes. Mitigate with pair limits, reputation, and anomaly scoring.

### 16. Bonus-Lot Demurrage Only

How it works: purchased credits never expire and are never charged inactivity fees. Promotional, matched, and minted credits can decay or expire after clear periods if counsel approves. Ideally their idle timer resets when they move through a real hand-off.

Why it helps: creates velocity while avoiding the highest-risk version of demurrage on purchased stored value.

User perception: "Bought credits are yours; community bonus credits are meant to move."

Implementation: lot-origin decay job, wallet disclosures, warning notifications, `bonus_expired_burn` entries.

Failure and gaming: users may hoard purchased credits while cycling bonus credits. Mitigate with positive spend rewards and useful producer demand tools.

### 17. Reciprocity Score In Discovery

How it works: accounts that both give and take get a reciprocity badge and modest ranking benefit. It is not a hard block and does not require exact balance.

Why it helps: spending becomes socially and practically useful, not just economically optional.

User perception: "This maker is active in the community, not just extracting credits."

Implementation: rolling 90-day earn/spend ratio, minimum activity threshold, badge and tie-breaker in ranking.

Failure and gaming: micro-spends to farm score. Mitigate with meaningful-spend thresholds and no benefit for circular repeat pairs.

### 18. Spend Streak Rewards

How it works: users who claim from different makers over time earn small community-funded bonus lots or priority access to limited drops.

Why it helps: rewards velocity without threatening purchased principal.

User perception: "Trying neighbors' offerings is recognized."

Implementation: streak engine, diversity constraints, yield/issuance-funded rewards, hard monthly cap.

Failure and gaming: low-quality claim loops. Mitigate with completed reviews, counterpart diversity, and dispute exclusions.

### 19. Idle Balance Nudges

How it works: before any bonus-lot decay, the wallet suggests useful actions: sponsor a voucher, post a bounty, claim a category you like, or save a launch event.

Why it helps: converts hoarding into intentional spending without punitive first contact.

User perception: "The app helps me use my credits."

Implementation: balance aging, personalized recommendations, no dark patterns.

Failure and gaming: ignored prompts. Mitigate with better match quality rather than harsher penalties.

### 20. Slack-Time Price Boosts

How it works: makers can schedule off-peak discounts, and the community budget can add small bonus lots for claiming during low-velocity windows.

Why it helps: smooths activity across time and keeps claims flowing.

User perception: "Afternoon coffee is 1 credit off today."

Implementation: maker discount controls, budgeted claim rewards, anti-stack rules.

Failure and gaming: users wait only for discounts. Mitigate with limited windows and no permanent discount expectation.

### 21. Community Chest

How it works: burned promotional credits, voluntary round-ups, yield, and expired vouchers feed a transparent community chest. The chest funds grants, launch matches, dispute goodwill credits, and block events.

Why it helps: gives every non-user-owned credit sink an ethical home.

User perception: "Unused community credits go back to the block."

Implementation: chest ledger account, public inflow/outflow report, spend categories fixed in policy.

Failure and gaming: governance capture. Mitigate with caps, audits, and member voting for discretionary allocations.

### 22. Producer Wishboard

How it works: net producers get a first-class "what I want" board and can post recurring credit-backed requests. Discovery for other makers highlights these requests as production opportunities.

Why it helps: directly solves the net-producer dead-end by creating things surplus holders want to spend on.

User perception: "I can turn my extra credit balance into neighborhood demand."

Implementation: recurring bounties, price suggestions, maker accept workflow, escrow, outcome reviews.

Failure and gaming: wishboard gets dominated by high-balance users. Mitigate with per-user active bounty caps and category fairness.

### 23. One-Hop Sponsorship Vouchers

How it works: net producers can burn credits into small vouchers for other verified users. The recipient can spend the voucher on someone else's offering, not the sponsor's, and cannot transfer it again.

Why it helps: turns surplus into cold-start liquidity and social status without cash-out.

User perception: "A neighbor sponsored your first coffee."

Implementation: voucher creation burn, voucher redemption constraints, TTL for promotional voucher objects, no repeat sponsor-recipient loops.

Failure and gaming: off-platform sale of vouchers. Mitigate with low face values, one-hop redemption, and monitoring.

### 24. Community Supply Library

How it works: members can offer borrowable or shareable production inputs for credits: folding tables, insulated carriers, jars, garden surplus boxes, recipe kits, or kitchen time where lawful. The platform does not cash anyone out.

Why it helps: gives producers useful non-food ways to spend and lowers future production costs.

User perception: "I earned credits from coffee and used them to borrow a stockpot."

Implementation: supply/offering category, deposits in credits, sanitation/liability rules, availability calendar.

Failure and gaming: damaged goods and regulatory complexity around kitchen access. Mitigate with deposits, waivers, and only low-risk categories at launch.

### 25. Producer Bonus Redirect

How it works: high-balance net producers can redirect production bonuses to the Community Chest, a voucher campaign, or a specific bounty in exchange for visible patron status.

Why it helps: prevents very productive users from accumulating more credits than they can spend.

User perception: "I am still rewarded, but I can route the extra to the block."

Implementation: opt-in setting, per-claim redirect, badges, transparent beneficiary ledger.

Failure and gaming: status farming. Mitigate by tying status to actual confirmed hand-offs and redirect amount.

### 26. Block Party Absorption Events

How it works: scheduled high-capacity events accept credits from many users and distribute claims across multiple makers or community hosts.

Why it helps: absorbs surplus balances and creates social meaning around circulation.

User perception: "Credits bought a neighborhood breakfast table."

Implementation: event inventory, multi-maker settlement, attendance limits, safety review.

Failure and gaming: poor execution can destroy trust. Mitigate with small pilots and vetted hosts.

### 27. Community Credit Trust Or Cooperative

How it works: the float sits in a segregated account or trust for credit holders/community purposes. The operating company is the administrator, not owner of the float. No dividends, no operating payroll from principal, no cash-out, and public reconciliation.

Why it helps: solves the ethical float problem and strengthens the legal narrative that DogSwipe is a community-credit commons, not revenue extraction.

User perception: "My dollars are not DogSwipe revenue."

Implementation: legal entity/custodian, trust ledger, monthly reconciliation, annual review, liquidation plan that never pays users cash unless law forces a winding-down process.

Failure and gaming: form without substance. Mitigate with actual segregation, public reports, and counsel.

### 28. Member-Only Local Network And Caps

How it works: DogSwipe launches one jurisdiction/cell at a time. Makers and claimers are members of the same local program, accept the same terms, cannot transfer credits peer-to-peer, and face conservative purchase/balance/daily-load caps.

Why it helps: makes the loop narrower and less cash-like, reducing money-transmission and AML risk while improving community trust.

User perception: "This is for my neighborhood, not a global token."

Implementation: membership terms, cell IDs, residency/proximity checks, max balance, max daily purchase, no external wallet/export, no secondary market APIs.

Failure and gaming: users may find caps annoying; off-platform resale remains possible. Mitigate with caps high enough for normal use and monitoring for resale patterns.

### 29. Tax And Barter Reporting Center

How it works: DogSwipe gives users annual exports of earned/spent credits, fair-market-value estimates, and any required barter-exchange reporting. It avoids claiming credits are tax-free.

Why it helps: legal defensibility and user trust. It also discourages large pseudo-business activity disguised as casual barter.

User perception: "The app is honest that barter can have tax consequences."

Implementation: ledger export, 1099 readiness if required, maker thresholds, in-app education, accountant-friendly CSV.

Failure and gaming: tax friction may reduce participation. Mitigate with plain language and thresholds, but do not hide the issue.

### 30. Reference Basket And Price Bands

How it works: the app publishes category medians and a local reference basket, such as "10 credits usually buys 2 coffees and a hotdog this month." Makers still set prices, but the app warns about thin data and extreme outliers.

Why it helps: keeps the credit unit meaningful without central price fixing.

User perception: "I know roughly what credits are worth here."

Implementation: settled-claim medians, trimmed means, minimum sample sizes, category/cell confidence, pricing coach in maker posting flow.

Failure and gaming: collusion can move medians in thin markets. Mitigate with minimum sample sizes, outlier trimming, and human review in early cells.

## Final Top 5, Best To Worst

### 1. Community Credit Trust + Member-Only Local Network

How it works: DogSwipe should be structured as a local membership credit commons before tokenomics get clever. Every buyer and maker joins a bounded local program. The dollars from par purchases go into a segregated float account, trust, nonprofit fiscal-sponsor account, cooperative account, or equivalent counsel-approved structure. The operating company administers the ledger and app; it does not book the float principal as revenue. Makers are not random unaffiliated merchants in product behavior; they are program members accepting a shared community-credit rulebook. Credits cannot be withdrawn, transferred peer-to-peer, exported to wallets, sold on a market, or redeemed for cash. Launch with conservative caps: max daily purchase, max balance, max active voucher value, one jurisdiction at a time, no business-scale accounts until counsel approves the model.

Why it is best: this is the mechanism that makes every other mechanism less fragile. Without it, DogSwipe is just a stored-value program redeemable across many unaffiliated people with no cash-out, which is exactly the high-risk shape the vision warns about. The trust/network design answers the float-governance problem ethically: the float is a community liability, not free operating capital. It also helps unit stability because par remains par, balances stay small, and no one can create a secondary market. It helps gaming resistance because the system is local, member-scoped, capped, and not transferable.

User perception: "DogSwipe is a neighborhood credit commons. My buy-in is held for the community loop, not paid out to makers or captured as company revenue."

Implementation notes:

- Ledger accounts: user lots, community chest, launch pools, production mint budget, escrow, corrections.
- Reconciliation: `segregated_float_principal >= purchased_credit_liability + restricted_reserves` with a separate report for community-issued credits.
- Terms and product copy: no cash-out, no investment, no stored profit claim, no peer sales, no financial return.
- Controls: purchase caps, balance caps, no peer transfer route, no maker payout settings, no admin balance edits outside signed corrections.
- Governance: monthly public float/liability report, annual independent review, community allocation rules for yield or surplus.

Failure modes and gaming:

- Legal reality may still require money-transmitter, prepaid-access, gift-card, barter-exchange, tax, or charitable-solicitation compliance. This mechanism improves the facts; it does not waive law.
- A trust label without actual segregation would be worse than no label. Build the accounting before launch copy.
- Off-platform credit resale cannot be fully prevented. Keep credits local, nontransferable outside claims, capped, and useful mainly inside the community.

### 2. Threshold Launch Batch + Pre-Funded Matching Pool

How it works: do not open a neighborhood as an empty wallet screen. Open a cell only when it has enough committed buyers, makers, and offerings. Before threshold, users pledge a par purchase and makers pledge concrete launch offerings. At threshold, DogSwipe captures purchases, issues credits, releases a pre-funded matching pool, and schedules a launch drop window. The match pool is bought at par by the operator, sponsor, nonprofit, or donors before distribution. Example: first 60 users can buy up to 20 credits and receive up to 20 matched credits; matched credits are community lots, not purchased lots, and are only eligible for full benefits after a completed hand-off.

Why it is #2: it is the cleanest cold-start answer. It removes the first-mover problem without unbacked credits and without pretending empty supply is liquid. It turns launch into a collective unlock: money, credits, offerings, and attention arrive together. It also reduces legal and gaming risk because the matching pool is pre-funded at par and can be limited to one local cell.

User perception: "I am joining a batch with my neighbors. I will only be charged when there is enough real activity to spend credits."

Implementation notes:

- `launch_cell` thresholds: pledged credits, verified makers, active offerings, pickup windows, and minimum category diversity.
- Payment flow: authorize first, capture only at unlock, expire authorizations safely if the cell fails.
- Match ledger: `launch_pool_purchase` followed by `launch_match_grant`; no hidden mint.
- Anti-farm rules: one match per identity/payment instrument/device cluster; matched credits spend first; matched-credit claims receive reduced or delayed production bonus.
- Launch event: first-week drop windows that concentrate inventory and claims.

Failure modes and gaming:

- Too-high thresholds can make real neighborhoods look dead. Start with tiny cells, maybe one apartment building, office, school, or block club.
- Sponsors can distort community trust if they appear to buy influence. Sponsor dollars can fund pools but must not buy ranking.
- Sybil buyers can farm matches. The first match must be small, identity-bound, and gated by real hand-off activity.

### 3. Verified Hand-Off Mint With Issuance Budget, Lot Tracking, And Scarcity Multipliers

How it works: the already-decided production bonus should exist, but it should be boringly governed. A confirmed hand-off creates three events atomically: escrow release of the claim price to the maker, production bonus mint to the maker, and inventory/fulfillment completion. The bonus formula is versioned. A baseline bonus might be 10% of claim price with a small floor and ceiling. A scarcity multiplier can raise it when a category/cell has real unmet demand, but only within a published monthly community issuance budget. Every minted bonus is a distinct community-issued lot with an origin, policy version, and audit trail.

Why it is #3: production minting is the main liquidity engine and the strongest incentive alignment. Credits enter through buying, but the economy becomes lively only if producing is more rewarding than passively holding. The cap and lot design answer the hard issuance problem: new credits are not counterfeit because the policy, cap, source, and ledger reason are explicit. The scarcity multiplier sends liquidity where the community is short on supply.

User perception: "When I actually hand something off, the community gives me a little extra, especially if my category is needed."

Implementation notes:

- Settlement transaction requires enough claim escrow, valid hand-off confirmation, no self-deal, no blocked pair, and remaining mint budget.
- Formula inputs: claim price, category, cell, maker reputation, dispute rate, repeated-counterparty rate, promo-credit share of claim, and active issuance budget.
- Budget sources: float yield if allowed, donations, operator capitalization, or a strict percentage of active purchased-credit float approved by counsel.
- Lot metadata: `production_bonus`, policy version, category multiplier, source budget, expiry/decay policy if any.
- Dashboard: monthly minted, burned, outstanding community lots, category multipliers, and remaining budget.

Failure modes and gaming:

- Two accounts can trade junk goods to farm the bonus. Mitigate with per-pair frequency caps, reduced bonus on repeat counterparties, no/low bonus on claims funded mostly by launch matches, reputation thresholds, dispute review, and anomaly detection.
- Scarcity metrics can be gamed by fake searches or wishes. Use settled claims, verified wish bounties, and rolling windows rather than raw clicks.
- If the mint budget is too generous, prices inflate. If too tight, producers feel cheated. Start small and tune monthly.

### 4. Lot-Safe Velocity System: Purchased Credits Stay Perpetual, Community Lots Must Move

How it works: do not demurrage all balances. Treat purchased credits as protected principal: no expiry, no inactivity fee, no decay, and no surprise forfeiture. Apply velocity pressure only to community-issued lots: launch matches, sponsor grants, production bonuses, vouchers, and other promotional lots. These lots spend first by default. They can have a clear use-by period, idle decay, or conversion rule after legal review. The wallet frames it simply: "Bought credits stay yours. Community bonus credits are meant to circulate." Before any decay, the app prompts users to claim, post a bounty, sponsor a voucher, or fund a community event.

Why it is #4: it solves hoarding without picking the legally riskiest version of demurrage. In a no-cash-out loop, pure hoarding is deadly, but punishing purchased balances can collide with gift-card/prepaid rules and user trust. Lot-safe velocity creates pressure exactly where DogSwipe has the strongest moral claim: credits that the community issued as a bonus should either move or return to the community chest.

User perception: active users barely notice. Inactive users see a fair distinction between bought value and community bonus value.

Implementation notes:

- Derived balance still appears as one number, but details show lot origins.
- Spend ordering uses community lots first, then earned transfers, then purchased lots unless counsel or UX says otherwise.
- Decay events are signed burns into the Community Chest, not operator revenue.
- Warnings: 14-day and 3-day notices before bonus lots decay.
- Positive incentives: spend streaks, reciprocity badges, and event access should do more work than penalties.

Failure modes and gaming:

- Users may still hoard purchased credits. That is acceptable if caps are low and the economy has enough demand tools; do not solve it by endangering the legal model.
- Makers may dislike receiving community lots if they decay. Best version: decay is based on idle time and resets when the lot moves through verified hand-offs, so active makers are not punished.
- Micro-spends can reset idle timers. Require meaningful spends and diverse counterparties for resets or rewards.

### 5. Producer Demand Engine: Wish Bounties, Surplus Vouchers, And Reference Pricing

How it works: give net producers a way to turn surplus credits into the things they actually want. The core is a credit-backed wish bounty: "I will pay 8 credits for two muffins Sunday," "12 credits for garden tomatoes," "5 credits for a tested recipe card." Credits lock in escrow, makers accept, and settlement follows the normal hand-off flow. If a producer wants to be generous instead, they can burn credits into one-hop sponsorship vouchers for new or low-balance neighbors. The posting flow is anchored by a reference basket and category price bands from settled claims, so bounties and offerings share a stable sense of what a credit buys.

Why it is #5: it attacks the net-producer dead-end directly. A producer with 200 credits does not need a lecture about reciprocity; they need better things to spend on. Bounties create demand for other makers and reveal what the community is missing. Vouchers turn surplus into cold-start liquidity. Reference pricing keeps the unit of account stable without fixed prices.

User perception: "I made a lot for the neighborhood, and now I can ask the neighborhood for what I want." For recipients: "A neighbor sponsored my first bite."

Implementation notes:

- Bounty escrow: reserve credits at post time, release on confirmed hand-off, refund in credits on expiry/cancellation.
- Price coach: show local medians, confidence, and suggested ranges, not hard price controls.
- Voucher constraints: one-hop only, short TTL if promotional, no redemption at sponsor's own offerings, low face-value cap, no repeat sponsor/recipient loops.
- Producer health dashboard: earned, spent, surplus age, open bounties, sponsored vouchers, and suggested categories to request.
- Unit stability: publish a local basket like "10 credits usually buys 1 hotdog + 1 coffee" only when sample size is sufficient.

Failure modes and gaming:

- High-balance users can dominate the wishboard. Mitigate with active bounty caps, category rotation, and discovery fairness.
- Vouchers can be sold off-platform. Keep them small, one-hop, local, non-stackable, and monitor suspicious repeat patterns.
- Reference prices can be manipulated in thin markets. Use minimum sample sizes, trimmed medians, and "insufficient data" labels instead of false precision.

## Why These Five Fit Together

The stack is intentionally layered:

1. The trust/member network makes the float and legal posture credible.
2. The launch batch and matching pool create first liquidity without unbacked issuance.
3. The verified production mint rewards real creation and adds targeted liquidity.
4. Lot-safe velocity keeps community-issued credits moving without attacking purchased principal.
5. The producer demand engine gives surplus holders useful ways to spend and stabilizes credit meaning through reference prices.

The strongest rejected idea is broad demurrage on all balances. It is economically attractive but too legally and emotionally expensive for a credit bought at par with dollars. The safer DogSwipe version is sharper: never cash out, never expire bought credits, but make community-issued credits circulate or return to the community.

