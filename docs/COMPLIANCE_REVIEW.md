# DogSwipe Compliance Review — Closed-Loop Community Credits

> **Status:** Initial bounded review. This document identifies regulatory exposure areas and flags where qualified legal counsel is required. It does **not** constitute legal advice and must not be treated as a compliance clearance.
>
> **Review date:** 2026-07-04
>
> **Scope:** U.S. federal and state regulatory exposure for the DogSwipe closed-loop credit model as described in [VISION.md](VISION.md). International jurisdictions are out of scope.

---

## 1. Product Model Summary (As Designed)

| Property | Value |
| --- | --- |
| Credit purchase | 1:1 with USD through a real payment rail |
| Cash-out | **Never** — not for buyers, not for makers |
| Redemption | Spent only on other users' offerings; no self-dealing |
| Float | Pooled dollars held as community liability, not platform revenue |
| Ledger | Append-only; balances derived, never hand-edited |
| Participants | Unaffiliated individual makers and claimers |
| Categories | Hotdogs (flagship), any neighborly offering (food, baked goods, produce, etc.) |

## 2. Money Transmission / Stored-Value Exposure

**Confidence: LOW — legal counsel required before any public launch decision.**

### Federal (FinCEN / BSA)

The Bank Secrecy Act defines a "money transmitter" as a person who transfers funds or value substitutes on behalf of the public. FinCEN has issued guidance (FIN-2019-G001, FIN-2013-G001) clarifying that certain closed-loop payment systems may fall outside money-transmitter registration if value is redeemable only with the issuer or a limited network the issuer controls.

**Key risk factor:** DogSwipe credits are redeemable across **unaffiliated** makers — individual neighbors who are not agents or employees of the platform. This "open-loop-like" redemption pattern within a nominally closed-loop system is the central ambiguity. FinCEN guidance distinguishes between:

- Closed-loop (single issuer, redeemable only with that issuer or its agents) — typically exempt
- Open-loop (redeemable at unaffiliated third parties) — typically requires MSB registration

DogSwipe sits in a gray area: the platform issues and controls credits, but they are spent with independent makers.

**Flags for counsel:**
- Does the unaffiliated-maker redemption pattern push DogSwipe from closed-loop exemption into MSB/money-transmitter territory under FinCEN rules?
- Does the no-cash-out invariant meaningfully reduce transmission risk, or is the "substitution of value" between users sufficient to trigger registration?
- If credits are never convertible to fiat, does that change the "funds or value that substitutes for currency" analysis?

### State Money Transmitter Licensing

**Confidence: LOW — state-by-state analysis required.**

Most U.S. states have their own money-transmitter statutes, many broader than the federal definition. Several states (e.g., New York BitLicense, California DFPI) have extended transmitter definitions to cover stored value, digital currencies, or payment instruments that may capture closed-loop credits redeemable across unaffiliated parties.

**Flags for counsel:**
- State-by-state licensing analysis is required for any state where DogSwipe operates (initially: user's home state for MVP, expanding with user base)
- Several states have specific closed-loop exemptions with varying definitions of "closed loop" — counsel must evaluate whether DogSwipe's multi-maker model qualifies
- Surety bond, net-worth, and examination requirements vary by state and may be prohibitive for an early-stage product

## 3. Stored-Value / Prepaid Access Regulation

**Confidence: MEDIUM — the product likely falls within prepaid-access definitions, but exemptions may apply.**

Under federal Regulation E (12 CFR 1005) and the Prepaid Rule (effective 2019), a "prepaid account" includes funds stored electronically and redeemable at multiple unaffiliated merchants. If DogSwipe credits qualify as prepaid access:

- Regulation E consumer protections (error resolution, periodic statements, fee disclosures) would apply
- FinCEN's prepaid-access rules (31 CFR 1010.100(ff)(4)) would require registration and recordkeeping

**Potential exemptions to evaluate:**
- Closed-loop exemption under Reg E: limited to cards/codes redeemable at a single merchant or affiliated group. Multi-maker likely does not qualify.
- Low-value exemption: accounts with balances that cannot exceed a certain threshold may have reduced obligations. Could be designed in.

**Flags for counsel:**
- Does the no-cash-out constraint remove DogSwipe from the prepaid-access definition, or does the ability to purchase credits with fiat and redeem them for goods satisfy the definition regardless?
- Could a per-account balance cap create a viable low-value exemption path?
- What consumer disclosures are required for the credit purchase flow?

## 4. Gift Card / Promotional Credit Statutes

**Confidence: MEDIUM — gift-card statutes are narrower, but some states sweep broadly.**

Federal gift-card rules under the CARD Act (15 U.S.C. § 1693l-1) restrict expiration dates and fees on "gift certificates, store gift cards, and general-use prepaid cards." Some state escheatment laws require unused stored value to be remitted to the state after dormancy periods.

**Analysis:**
- DogSwipe credits are not marketed as gift cards, but state definitions vary — some define any prepaid mechanism for goods/services as a gift card or gift certificate
- The no-cash-out, no-expiration design may conflict with state escheatment requirements that mandate either redemption for cash or remittance of abandoned balances to the state
- Float held as "community liability" may itself trigger escheatment obligations on dormant accounts

**Flags for counsel:**
- Review applicable state escheatment statutes for stored-value obligations
- Determine whether DogSwipe credits fall within gift-card definitions in key operating states
- Design dormancy/escheatment policy before launch if required

## 5. Food Safety and Liability

**Confidence: MEDIUM — this is a conscious design decision that needs documented risk acceptance and appropriate disclosures.**

DogSwipe facilitates food being prepared and handed between individuals who are not licensed food establishments. This raises:

### Cottage Food Laws

Most U.S. states have "cottage food" laws permitting individuals to sell certain home-prepared foods (typically non-potentially-hazardous items: baked goods, jams, candies) without a food establishment license, subject to:

- Annual revenue caps (commonly $25,000–$75,000, varies by state)
- Labeling requirements (ingredient list, allergen warnings, "made in a home kitchen" disclaimer)
- Restrictions on potentially hazardous foods (anything requiring temperature control: meat, dairy, eggs) — **hotdogs likely fall outside cottage food exemptions in most states** as a potentially hazardous food

### Platform Liability

- DogSwipe does not prepare, inspect, or handle food — it is a discovery/matching platform
- Section 230 may provide some protection for user-generated content, but does not cover product liability for physical harm
- Terms of service should clearly disclaim food safety responsibility while providing maker guidance
- Insurance considerations: general liability and possibly product liability coverage

**Flags for counsel:**
- Are hotdogs (the flagship category) legally saleable under cottage food laws in target states, or does the platform need to restrict to non-hazardous categories initially?
- What disclaimers and maker acknowledgments are required to limit platform liability?
- Does the credit-based (non-cash) transaction model change the "sale" analysis under cottage food laws, or does any value exchange trigger the same requirements?
- Should the platform require makers to self-certify compliance with local food safety laws?

## 6. Consumer Protection and Terms

**Confidence: HIGH — these are largely within the platform's control to design correctly.**

Regardless of regulatory classification, the following consumer-facing obligations apply:

| Obligation | Status | Action |
| --- | --- | --- |
| Terms of Service | Not yet drafted | Must clearly state: credits are non-refundable to cash, no cash-out ever, platform holds float as liability, food safety is maker's responsibility |
| Privacy Policy | Not yet drafted | Must cover: identity data (SPAPS), location data, transaction/ledger data, analytics events. No PII in analytics is a design advantage. |
| Refund/dispute policy | Designed (credit-only refunds) | Document that disputes result in credit refunds, never cash refunds. Ensure this is prominently disclosed pre-purchase. |
| Fee disclosures | N/A currently | If any fees are added (transaction fees, credit purchase surcharges), Reg E and state consumer protection laws require clear pre-transaction disclosure |
| Accessibility | iOS standard | VoiceOver, Dynamic Type compliance for iOS surfaces |

**Flags for counsel:**
- Draft Terms of Service with explicit no-cash-out language, credit purchase terms, dispute resolution, and food safety disclaimers
- Draft Privacy Policy covering all data categories
- Review state-specific consumer protection requirements for prepaid/stored-value products

## 7. Tax Implications

**Confidence: LOW — requires tax counsel.**

- **Makers:** Credits earned by fulfilling offerings may constitute taxable income even though they cannot be converted to cash. The IRS generally taxes barter transactions at fair market value (IRC § 61, Rev. Rul. 79-24). If credits are purchased at par (1:1 with dollars), the FMV argument is straightforward.
- **Platform:** Float held as liability has its own tax treatment. Interest earned on float deposits is platform income.
- **1099 reporting:** If maker earnings exceed $600/year in credit value, the platform may have 1099-K or 1099-MISC reporting obligations.

**Flags for counsel:**
- Confirm barter-income treatment for credit earnings
- Determine 1099 reporting thresholds and obligations
- Design maker onboarding to collect necessary tax information (TIN/SSN) if reporting is required
- Evaluate whether the non-convertibility of credits affects FMV determination

## 8. Compliance Roadmap (Recommended Sequencing)

This is an engineering/product recommendation for sequencing legal work, not legal advice.

| Priority | Item | Rationale | Gate |
| --- | --- | --- | --- |
| **P0** | Money-transmission analysis (federal + home-state) | Determines whether the product can launch at all in its current form | Blocks public launch |
| **P0** | Stored-value / prepaid-access classification | Determines consumer-protection obligations and registration requirements | Blocks public launch |
| **P1** | Food safety / cottage food analysis (home state) | Determines whether hotdog flagship is viable or must be restricted to non-hazardous categories | Blocks public launch with hotdog category |
| **P1** | Terms of Service + Privacy Policy | Required for any consumer-facing product | Blocks public launch |
| **P2** | Tax / 1099 reporting obligations | Can be deferred to post-MVP if earnings are below reporting thresholds initially | Blocks scaling |
| **P2** | State-by-state expansion analysis | Required when expanding beyond initial operating state | Blocks geographic expansion |
| **P3** | Gift-card / escheatment analysis | Required for dormant-account handling; can be designed in later if accounts have activity requirements | Blocks long-term operation |

## 9. Design Decisions That Help

The following product-design choices reduce (but do not eliminate) regulatory risk:

1. **No cash-out invariant** — Removes the most obvious money-transmission trigger (transferring value back to fiat). Does not eliminate all transmission risk.
2. **Append-only ledger** — Provides the audit trail that any regulatory examination would require.
3. **Credits at par** — Simplifies FMV calculations for tax purposes. No speculative pricing.
4. **No peer-to-peer credit transfer** — Credits cannot be sent between users outside a claim. Prevents informal cash-out markets.
5. **Balance caps** (if implemented) — Could create viable low-value exemptions under prepaid-access rules.
6. **Per-user identity** — SPAPS-backed identity supports KYC-adjacent requirements if needed.

## 10. Design Decisions That Hurt

1. **Unaffiliated makers** — The central value proposition (anyone can be a maker) is also the central compliance challenge. It pushes the system toward open-loop classification.
2. **Food as flagship** — Food-between-strangers carries inherent liability that non-food categories avoid. Potentially hazardous foods (hotdogs) are especially challenging.
3. **Float as liability** — Correct accounting treatment, but creates ongoing obligation that must be managed (segregated accounts, escheatment, etc.).

---

> **Bottom line:** The DogSwipe credit model is designed with the right instincts (no cash-out, append-only ledger, par pricing, no peer transfer), but the unaffiliated-maker redemption pattern creates genuine regulatory ambiguity that cannot be resolved by engineering alone. A qualified fintech/payments attorney must evaluate the money-transmission and stored-value classification before public launch. Food safety counsel should evaluate the hotdog-flagship viability under cottage food laws. Neither question has an obvious answer from public guidance alone — this is exactly the kind of fact pattern that requires professional legal analysis.
