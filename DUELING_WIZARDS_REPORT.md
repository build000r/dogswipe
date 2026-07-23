# Dueling Idea Wizards Report: DogSwipe Tokenomics

**Mode:** economic/tokenomics design duel (focused) · **Date:** 2026-06-17

## Executive Summary

Three independent models (Claude / cc, Codex GPT-5.5 / cod, Grok) each generated 30 candidate economic mechanisms for the DogSwipe barter-credit pivot, winnowed to a top 5, then adversarially scored the other two models' full lists 0–1000. Despite different biases, all three **converged on the same backbone**: a segregated community **float trust** (platform = administrator, not owner) under a **member-only local-cell** framing; **credit-lots-by-origin** so velocity pressure (decay/spend-first) hits only community-issued credits and **never purchased ones**; a **par-backed, hand-off-gated launch matching pool** for cold-start; a **budget-capped production mint**; and an **inverse-balance "spend-to-earn" bonus curve** as the smartest single lever against producer hoarding. Four-way convergence across models with different blind spots is the highest-confidence signal this method produces.

## Methodology
- Agents: Claude (cc), Codex gpt-5.5-xhigh (cod), Grok (headless sidecar)
- Ideas: 30 per model → top 5; full adversarial cross-scoring (each model scored the other two)
- Phases run: study → ideate → cross-score → synthesize. (Reveal/rebuttal/blind-spot rounds were not run.)

## Consensus Winners (high cross-model scores)

| # | Mechanism | cc | cod | grok | Verdict |
|---|-----------|----|----|------|---------|
| 1 | **Segregated community float trust + member-only local network** (platform administers, doesn't own; segregated/irrevocable; public reconciliation; member cells; conservative caps; non-transferable credits) | 780–820 | 900–915 | 871–912 | **STRONGEST — all 3 rank top.** The prerequisite that makes the closed loop legally credible and answers "platform holds everyone's money forever." |
| 2 | **Lot-safe velocity** — track credit lots by origin; apply demurrage / spend-first ONLY to community-issued lots (bonuses, grants, matches), **never to purchased credits** | 740–810 | self (803–811) | 728–811 | **STRONG.** The legal keystone: purchased credits carry gift-card/CARD-Act/prepaid protections; decaying them is illegal-ish and feels like theft. cc and grok both flag their own "demurrage-on-all" ideas as mistakes. |
| 3 | **Spend-to-Earn bonus curve** — scale the (already-decided) production bonus *inversely* to balance, so high-balance hoarders must spend before earning more | self | 845 | 834 | **STRONG.** Both opponents call it the smartest single economic lever; fixes net-producer hoarding with no demurrage, no second currency. |
| 4 | **Par-backed, hand-off-gated launch matching pool** (+ "threshold/charge-only-when-the-block-is-live") | 650–720 | self | 776–830 | **STRONG.** The consensus cold-start igniter: platform pre-funds a 1:1 match per neighborhood cell, gated by a real hand-off before the 2nd match (anti-Sybil). |
| 5 | **Budget-capped production mint** (published issuance budget + float-coverage cap + category-gap multipliers, all lot-tracked) | 750 | self (818–855) | 818 | **STRONG.** Governs the production bonus so minting is auditable, not magical. Caveat (all 3): keep the formula simple; scarcity multipliers are noisy in thin early markets. |
| 6 | **Producer demand engine** — wish bounties / wishboard + one-hop sponsorship vouchers + reference price basket | 660–720 | self (774) | 742–788 | **STRONG.** Attacks the net-producer dead-end at the root (create things surplus-holders want) and stabilizes the unit of account ("10 credits ≈ 3 coffees + a dog") without price controls. |

## Killed (low cross-model scores — strong agreement they're bad)

| Mechanism | cc | cod | grok | Why it dies |
|-----------|----|----|------|-------------|
| **Hard expiry / use-it-or-lose-it on purchased credits** | self | 160 | 156 | Confiscatory; almost certainly illegal for par stored value. The single worst idea. |
| **Scaling the production bonus *for* net producers** | self | 240 | 124 | Backwards — accelerates the surplus dead-end (the Ithaca-Hours/LETS failure mode). Note: the duel killed this while elevating its mirror image, the inverse-balance Spend-to-Earn curve. |
| **Maker-first posting escrow** (makers lock credits to post) | 340 | 300 | self | Inverts barter logic — forces makers to *buy* before they can *give*; chokes supply-side cold-start. |
| **Flat demurrage on all balances** | self | 430 | 274 | Same legal/trust problem as hard expiry, milder. |
| **Subjective "community contribution" minting** | self | 320 | 187 | Ungameable verification is fantasy; invites favoritism/fraud. |
| **Velocity lottery** | 370 | 220 | self | Gambling/sweepstakes law risk; wrong association for a money-adjacent product. |

## Key Disagreement (signal in the gap)
**Producer demurrage exemption** (Grok): Grok rated it ~580 (protect generous makers from decay); Claude rated it 470, arguing it's *counterproductive* — it removes spending pressure from exactly the users who most need to spend. **Resolution:** the duel supersedes both with the **Spend-to-Earn curve** (#3), which pushes producers to spend *without* taxing anyone. The disagreement surfaced the better mechanism.

Secondary: **yield-recycled issuance** (mint from float interest) scored well on elegance but all three flag it as *inert at small scale* (~$500/yr on a $10k float) — a good v2+ dial, not an MVP lever.

## Meta-Analysis (model biases)
- **Codex** brought the sharpest **legal/regulatory** rigor — it originated lot-safe demurrage, member-only framing, the trust/cooperative structure, and even barter tax-reporting. Bias: compliance/implementation depth.
- **Claude** brought the strongest **ethos/UX** mechanisms (Spend-to-Earn, Pay It Forward, staged "Neighborhood Kindling") but made the duel's biggest mistake (demurrage on all credits) — which Codex and Grok both caught.
- **Grok** brought the widest **cold-start creativity** (genesis pool, gift-at-purchase split, founding ladder) and the float-trust + yield idea, but was weakest on the purchased-vs-issued legal distinction.
- The fact that three differently-biased models independently converged on the same six-part backbone is why confidence is high.

## Recommended Tokenomics (composed from the winners)
A single coherent system:
1. **Foundation:** segregated, irrevocable community **float trust**; platform administers; public reconciliation; member-only local cells; conservative balance/purchase caps; non-transferable credits.
2. **Ledger:** credits carry an **origin lot** (purchased | production-bonus | grant | match | voucher). Purchased lots are inviolable.
3. **Mint:** production bonus on confirmed hand-off, under a **published issuance budget + float-coverage cap**, lot-tagged; (category-gap multiplier deferred until markets are thick).
4. **Velocity:** **spend community lots first**; gentle **demurrage on idle community lots only**; **Spend-to-Earn** inverse-balance bonus curve. Purchased credits never decay.
5. **Cold-start:** **par-backed, hand-off-gated launch match** per cell + threshold "charge when live"; one-hop sponsorship vouchers as surplus→newcomer bridge.
6. **Net-producer relief + unit-of-account:** wishboard/bounties + one-hop vouchers + reference price basket.
7. **Sinks:** demurraged/expired community lots → transparent **Community Chest** (grants, dispute goodwill), never operator revenue.

## Recommended Next Steps
- Fold the recommended design into `docs/VISION.md` (economic section) and the `bc-foundation-wallet-ledger` epic.
- New/!revised beads: credit-lots-by-origin · float-trust + reconciliation · launch match pool · governed mint (budget + float cap) · spend-to-earn curve · lot-safe demurrage · producer demand engine (bounties/vouchers/reference basket) · member-cell caps. The compliance epic (`bc-compliance-trust`) absorbs the trust/member-framing legal review.
