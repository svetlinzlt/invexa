# Personal Finance App — Research & Validation Report

**Working title:** Invexa (Apple-first, month-first personal finance for Europe)
**Prepared:** 13 August 2026
**Scope:** Market, technical feasibility (FinanceKit + Trading 212 + EU open banking), competitive gaps, MVP, and an honest build/no-build verdict.

> **How to read this report.** Claims are tagged so you can tell fact from guess:
> **[VERIFIED]** = checked against a source (cited). **[ASSUMPTION]** = reasonable inference, not confirmed. **[HYPOTHESIS]** = a bet that must be tested before you rely on it.

---

## 0. The bottom line up front

Your instinct — *"where did my money go this month, and how am I doing?"* — is a real, durable need, and the app you sketched is well-specified. But the research surfaces **one finding that breaks your headline differentiator**, and you asked me not to flatter you, so here it is plainly:

**Your central premise — "Apple-first, auto-import from Apple Wallet, aimed at European users" — does not technically hold in 2026.**

- **FinanceKit only works in the US and UK.** It is not available in the EU at all. **[VERIFIED]**
- In the **US**, FinanceKit exposes only **Apple Card, Apple Cash, and Apple Savings** — Apple's own products — not third-party bank cards. Apple Card doesn't even exist in Europe. **[VERIFIED]**
- In the **UK**, FinanceKit reaches real banks — but only because Apple layered it on top of **UK open banking**, and only for a fixed list of UK institutions. **[VERIFIED]**

So "auto-import from Apple Wallet" for a **European** user is essentially **zero coverage today**. To read a Bulgarian, German, or French user's bank transactions, you must use **PSD2 open-banking aggregators** (Tink, TrueLayer, GoCardless, etc.) — the *same* plumbing every competitor uses — which costs money and undercuts the "Apple-only / on-device / simple" story.

That doesn't kill the idea. It **changes what the idea has to be**. The honest opportunity is not "Apple exclusivity." It's **a beautifully simple, month-first, multi-currency, investment-aware tracker for European users, built on PSD2 — with Apple-native polish (Watch, Widgets, Shortcuts) as delight, not as the data moat.**

**Verdict: PROMISING — NEEDS VALIDATION** (details and the revised product in §11).

---

## 1. The idea, restated crisply

**Problem.** People who want to understand their monthly spending either use spreadsheets/Apple Notes (manual, no insight — your current situation) or heavyweight US-centric budgeting apps that sync poorly with European banks and treat investments as an afterthought.

**Proposed solution.** A native Apple app whose home screen answers one question per month: money in, money out, money left, invested, saved, and where it went — with recurring bills and month-over-month comparison, plus investment tracking (Trading 212).

**Core hypothesis (the one thing that must be true):**
> European iPhone users who currently track spending manually will connect their bank + broker and pay a subscription for a *simpler, month-first* experience — even though Emma, Monarch, YNAB and others already exist.

Everything below is really an effort to test that sentence.

---

## 2. Technical feasibility — the part that decides the product

### 2.1 Apple FinanceKit — what's actually possible

| Question | Answer | Tag |
|---|---|---|
| Which countries? | **US and UK only.** Expanded to the UK around WWDC 2025. **Not the EU.** | [VERIFIED] |
| What data in the US? | **Apple Card, Apple Cash, Apple Savings only** — Apple's own products, on-device, real-time. No third-party bank cards. | [VERIFIED] |
| What data in the UK? | Real banks (Barclays, HSBC, Lloyds, Monzo, NatWest, Santander, etc.) — but via **UK open banking**, for a fixed institution list. | [VERIFIED] |
| Requirements | iOS 17.4+, a **Financial Data entitlement** requested from Apple per bundle ID, granted to the Account Holder; app must be distributed via the US or UK App Store to use it. | [VERIFIED] |
| Reading arbitrary "cards in Apple Wallet" | **Not possible.** Wallet passes/loyalty/boarding cards and third-party payment cards are not exposed as transaction feeds. | [VERIFIED] |

**Implication:** As a data-acquisition strategy for **Europe**, FinanceKit contributes essentially nothing in 2026. As a *feature* for US/UK Apple-Card holders it's nice, but it can't be the backbone of a European product. Your own brief said "do not assume Apple Wallet provides unrestricted access" — correct instinct, and the research confirms the pessimistic case.

### 2.2 How you actually get European bank data: PSD2 aggregators

To read EU bank transactions you need a licensed **AISP** (Account Information Service Provider) or an aggregator that fronts one:

| Provider | EU strength | Pricing reality (2026) | Tag |
|---|---|---|---|
| **Tink** (Visa) | Strong in Nordics / DACH | Custom / enterprise, sales-led | [VERIFIED] |
| **TrueLayer** | Strong UK/IE, decent EU | Structured published tiers | [VERIFIED] |
| **GoCardless / Nordigen** | Solid EU mid-market | **"Free forever" is gone; stopped onboarding new Bank Account Data customers** | [VERIFIED] |
| **Plaid** | Improving, uneven in EU | Custom/enterprise | [VERIFIED] |
| Smaller/self-serve (e.g. open-banking.io) | Varies | ~€3/mo self-serve tiers reported | [ASSUMPTION] |

**Key consequence:** the old indie hack — "use Nordigen's free tier" — **is closed.** Bank connectivity is now a real per-connection cost you must pass on to users. This is the single biggest change to your economics and it argues *for* a paid subscription, not a free app.

### 2.3 Trading 212 integration — possible, but awkward

| Question | Answer | Tag |
|---|---|---|
| Is there a public API? | **Yes** — a public REST API in **beta**, plus manual CSV export. Both free. | [VERIFIED] |
| What data? | Portfolio positions (qty, avg price, P/L), order history, dividends, cash transactions; Pies create/read/update/delete. Supports Invest & ISA accounts. | [VERIFIED] |
| How does a user authenticate? | User generates a personal **API key/secret** inside the T212 app (Settings → API (Beta) → accept risk warning → generate). | [VERIFIED] |
| Is there OAuth / an official partner program? | **No.** Trading 212 has **no official third-party partnerships** and explicitly warns users about sharing keys. There is no "Connect with Trading 212" OAuth button. | [VERIFIED] |
| Aggregator alternative | **SnapTrade** offers a T212 integration (and other brokers) as a paid aggregation layer. | [VERIFIED] |

**Implication for UX and risk:**
- The clean "tap to connect your broker" flow **does not exist**. Each user must manually generate and paste an API key — a friction point *and* a trust/security liability (you'd be storing broker credentials that carry order permissions).
- Because it's **beta with no partner agreement**, T212 could change scopes, rate-limit, or revoke API access with no notice. Building a headline feature on it is a **dependency risk (HIGH)**.
- A safer path: use **SnapTrade** as the broker-aggregation layer (adds cost, adds other brokers too), or ship T212 as a "power-user, paste-your-key" premium extra rather than a core promise.

### 2.4 The rest of the Apple stack (all standard, low risk)

- **SwiftUI** app; **SwiftData/Core Data** for the local store; **CloudKit** for private per-user iCloud sync (no server to run, GDPR-friendly since data stays in the user's iCloud). **[ASSUMPTION — appropriate default]**
- **Widgets** (month summary), **Apple Watch** complication (spent-this-month), **App Intents / Shortcuts / Siri** ("add €12 lunch"), local notifications for upcoming bills. These are genuine, cheap-to-build Apple delighters and are where "Apple-first" *should* mean something.
- A **thin backend is unavoidable** the moment you add PSD2 or SnapTrade — aggregator tokens and webhooks can't live purely on-device. Keep it minimal (a small serverless API + secrets vault), not a data lake.

**Feasibility summary:** The Apple-native shell is easy and pleasant. The hard, costly, risky parts are exactly the two you're most excited about — **EU bank import** (needs paid PSD2, not FinanceKit) and **Trading 212** (no OAuth, beta, no partnership).

---

## 3. Market & competitive landscape

The category is **crowded in the US** and **noticeably thinner, but not empty, in Europe.**

| App | Platforms | Price (2026) | EU coverage | Investments | Notable weakness |
|---|---|---|---|---|---|
| **Copilot Money** | Apple-only (iOS/Mac) | ~$95/yr | **US + Canada only — no EU** | Yes | Beautiful UI, **weak budgeting**; irrelevant to EU | 
| **Monarch Money** | iOS/Android/web | ~$99.99/yr (Plus $199) | Partial UK/EU via Plaid, **inconsistent** | Yes | Sync gaps (2FA brokers); price | 
| **YNAB** | iOS/Android/web | $14.99/mo or ~$109/yr | Best of the US set for UK/EU, still limited | Weak | Steep learning curve; method-heavy, not "glance" | 
| **Rocket Money** | iOS/Android/web | Freemium + paid | US-centric | Limited | Upsell-heavy; bill-negotiation focus | 
| **Quicken Simplifi** | iOS/Android/web | ~$2–4/mo | US-centric | Some | Aging brand feel | 
| **Empower (Personal Capital)** | iOS/Android/web | Free (sells advisory) | US only | Strong | Lead-gen for wealth mgmt | 
| **PocketGuard** | iOS/Android | Freemium | US-centric | Weak | Thin analytics | 
| **Emma** | iOS/Android | Freemium + paid | **Strong** — UK-origin, growing EU, multi-currency | Some | Not Apple-native; feature-broad, UX busy | 
| **Wallet by BudgetBakers** | iOS/Android/web | Freemium + paid | **Strong** — 15k+ institutions, EU-wide | Basic | Cross-platform, not Apple-polished | 
| **Spendee** | iOS/Android | Freemium | Good — 2.5k+ banks | Basic | — | 

*Sources per §12. Prices/coverage are point-in-time (2026) and shift; re-verify before quoting.* **[VERIFIED where cited]**

**What the reviews say (user sentiment):** Copilot = gorgeous, budgeting weak; Monarch = capable but sync flakiness with some accounts/2FA brokers; YNAB = powerful but a *methodology* people bounce off, not a glanceable overview. The common thread: **the polished ones are US-only, and the EU-capable ones (Emma, Wallet, Spendee) are cross-platform and UX-busy — none is a truly Apple-native, month-first, "glance and go" product for Europe.**

### 3.1 Where the genuine gap is

- **Copilot's design quality + Europe** — nobody occupies this. Copilot proved Apple-only can win on feel, then locked itself to the US.
- **Month-first "glance" simplicity** — YNAB/Monarch are power tools; the "just tell me how this month is going" niche is underserved.
- **Investments *beside* everyday money for retail EU investors** — most trackers bolt on holdings crudely; a clean net-worth + monthly-cashflow + Trading 212 view is differentiated **if** the T212 dependency is managed.
- **Privacy / on-device / iCloud-only** — a credible EU angle given GDPR sensibilities, *provided* you're honest that bank sync still routes through a licensed AISP.

**Where there is *no* real gap:** raw feature count, US market, and "Apple Wallet auto-import" (doesn't work in EU). Don't compete there.

---

## 4. Categories — recommended structure

Your list is good but slightly too long for a "simple" app. Recommended: **~12 top-level categories**, each with light subcategories, plus system buckets that are *not* spending:

**Spending (the pie):** Housing · Utilities & Bills · Groceries · Eating Out · Transport · Shopping · Health · Entertainment & Subscriptions · Travel · Education · Other.
**System (kept out of "spent this month"):** Income · Transfers · Savings · Investments · Debt/Loan payments · Taxes.

Rationale: users conflate *spending* with *money movement*. Treating Savings/Investments/Transfers/Debt as **non-expense flows** is what makes "where did my money go" honest — this is a subtle correctness point most simple trackers get wrong, and a place you can be *better*, not just prettier. **[ASSUMPTION — validate with 5 target users]**

---

## 5. Positioning & value proposition

**One sentence:** *"The month-first money app for Europe — open your iPhone, see exactly how this month is going, including your investments, in five seconds."*

Is "month-first" enough to differentiate? **On its own, no** — it's a framing, easily copied. It becomes defensible only bundled with: **(EU/multi-currency bank coverage) + (Apple-native craft) + (retail investment view) + (privacy posture).** That *combination*, aimed at Europe, is a position no incumbent currently holds. **[HYPOTHESIS]**

---

## 6. MVP — the smallest thing that tests the hypothesis

**Cut the scope hard.** The hypothesis is "EU users will connect accounts and pay for month-first simplicity." You do **not** need investments, Watch, or PSD2 to test the *core* of that.

**Must-have (MVP):**
- Fast **manual** add for expense/income (Shortcuts + widget + one-tap) — this alone beats Apple Notes and validates the habit **with zero aggregator cost.**
- **Auto-categorization** (rules + on-device heuristics).
- **Month-first home:** in / out / left / by-category / recurring due / vs-last-month.
- Recurring & subscription tracking (manual + detected).
- Multi-currency + EUR/BGN as first-class.
- iCloud/CloudKit private sync; local encrypted store.

**Should-have (fast follow):**
- **One PSD2 provider, one country** (start where coverage is best/cheapest — likely a single aggregator + Bulgaria/DACH pilot) behind the paywall.
- Monthly insights ("subscriptions up 18%").

**Nice-to-have:**
- Trading 212 (paste-key, premium, clearly labeled beta) or SnapTrade.
- Apple Watch complication, richer widgets, Siri phrases.

**Do NOT build yet:**
- FinanceKit US/Apple-Card import (no EU value).
- Multi-country PSD2 rollout, AI advice, household/couples, investment performance analytics, iPad-optimized UI.

**Why this order:** the manual-first MVP is buildable in weeks, costs ~nothing per user, and answers the *only* question that matters — will people actually track, glance, and pay — before you commit to expensive PSD2 contracts.

---

## 7. Monetization

Comparable apps sit at **~$95–110/yr** (Copilot, Monarch, YNAB). Free-with-ads doesn't fit a privacy-positioned finance app, and **PSD2/broker aggregation now carries real per-user cost**, so a free tier must be feature-limited.

**Recommended:** **Freemium → subscription.**
- **Free:** manual tracking, month view, categories, iCloud sync. (Great funnel; near-zero marginal cost.)
- **Premium (~€3–5/mo or ~€35–45/yr):** automatic bank sync (PSD2), investment tracking, advanced insights, multiple accounts.
- Price *below* US incumbents to fit EU willingness-to-pay and undercut Monarch/Copilot. **[HYPOTHESIS — test with a pricing page]**

Avoid one-time purchase: your per-user aggregator cost is **recurring**, so revenue must be too.

---

## 8. Risks (ranked)

| Risk | Level | Note |
|---|---|---|
| **FinanceKit ≠ EU data** — headline differentiator invalid | **HIGH** | Already realized. Reposition (done in this report). |
| **Adoption** — will manual-trackers switch & pay vs. free Emma/Notes? | **HIGH** | The real killer. Test before building sync. |
| **PSD2 cost & integration** — pricing, coverage gaps, re-consent every 90 days (SCA) | **HIGH** | Recurring cost; UX friction from mandated re-auth. |
| **Trading 212 dependency** — beta API, no partnership, paste-key friction | **HIGH** | Make it optional/premium; consider SnapTrade. |
| **Crowded category** | **MEDIUM** | Real, but EU + Apple-native is genuinely underserved. |
| **Regulatory/GDPR + handling financial data** | **MEDIUM** | Manageable with AISP-via-aggregator + iCloud-only storage; get terms right. |
| **Apple entitlement/App Store review for finance** | **MEDIUM** | FinanceKit entitlement + finance-app scrutiny; plan lead time. |
| **Solo/small-team scope** | **MEDIUM** | The full brief is a multi-year product; MVP discipline is essential. |

---

## 9. Validation plan (spend days, not weeks)

1. **Landing page + waitlist** — pitch "month-first money app for Europe, with investments." Measure email conversion by country. (Cost: ~€0, ~1 week.)
2. **5–8 user interviews** with people who currently track manually (you're user #1). Confirm the Savings/Investments-as-non-expense insight and the "glance in 5s" need.
3. **Clickable prototype** (Figma) of the month-first home — test comprehension: can someone answer "how am I doing?" in one glance?
4. **Pricing fake-door:** show the €3–5/mo premium tier on the landing page; measure "start free trial" clicks.
5. **Two integration spikes (no product code):**
   - Register with **one PSD2 aggregator**, confirm real per-connection pricing and Bulgarian/target-bank coverage.
   - Generate a **Trading 212 API key**, pull your own portfolio, confirm fields, rate limits, and stability. Evaluate SnapTrade as a fallback.
6. **Ship the manual-only MVP** to TestFlight and watch **7-day retention** — do people come back and log?

Green-light heavy PSD2 investment only after (1)/(4) show demand and (5) confirms unit economics.

---

## 10. Suggested first milestones (not code)

1. Landing page + waitlist + pricing fake-door live; start collecting EU signups.
2. 5–8 interviews + clickable month-first prototype validated.
3. Manual-first MVP (SwiftUI + SwiftData + CloudKit + Widget + Shortcut) on TestFlight.
4. One-country PSD2 spike: confirmed coverage, price, and a working sandbox connection.
5. Trading 212 (or SnapTrade) spike: your own portfolio rendered, dependency risk assessed.

---

## 11. Final recommendation

### Verdict: **PROMISING — NEEDS VALIDATION**

**Why not "STRONG":** your stated differentiator (Apple-Wallet-auto-import, Apple-only, for Europe) is **factually unavailable in 2026** — FinanceKit is US/UK-only and, in the US, Apple's-own-products-only. The economics also shifted: the free open-banking on-ramp (Nordigen) is gone, so bank sync is a paid, recurring cost. And the category is crowded.

**Why not "WEAK" or "DO NOT BUILD":** there is a **real, under-occupied position** — *Copilot-grade Apple-native craft + month-first simplicity + multi-currency EU coverage + a clean retail-investment view + a privacy posture* — that **no current app holds**. Copilot locked itself to the US; Emma/Wallet/Spendee cover the EU but aren't Apple-native or "glanceable." Your problem is real and you are your own first user.

**The reframed product to build:**
> Not "the Apple-Wallet app." Instead: **a month-first, multi-currency personal finance app for European iPhone users**, launched *manual-first* to prove the habit and pricing, then adding **PSD2 bank sync** (one country at a time) and an **optional Trading 212 / SnapTrade** investment view — with Apple-native Widgets, Watch, and Shortcuts as the craft layer that makes it feel effortless.

**Do this next:** run §9 steps 1, 4, and 5 first. They cost days and directly test the two things that could sink you — *demand* and *unit economics* — before you write meaningful code.

### Biggest open questions still unanswered
1. Will manual-trackers actually **pay** in Europe, where free Emma/Wallet exist? (Test: pricing fake-door + retention.)
2. What's the **real per-connection PSD2 cost** for your target countries, and does €3–5/mo cover it at your expected scale?
3. Is **Bulgaria** a viable pilot — do the local banks have good aggregator coverage, and is the paying market large enough, or is it only a test bed before DACH/Nordics?
4. Can the **Trading 212** paste-key flow convert without scaring users, or must you pay for SnapTrade from day one?

---

## 12. Sources

**Apple FinanceKit**
- [Apple Developer — Get started with FinanceKit](https://developer.apple.com/financekit)
- [Apple Developer — FinanceKit documentation](https://developer.apple.com/documentation/FinanceKit)
- [WWDC24 — Meet FinanceKit](https://developer.apple.com/videos/play/wwdc2024/2023/)
- [WWDC25 — What's new in Apple Pay](https://developer.apple.com/videos/play/wwdc2025/201/)
- [TechCrunch — Apple releases API to fetch Apple Card/Cash transactions](https://techcrunch.com/2024/03/06/apple-releases-a-new-api-to-fetch-transactions-from-apple-card-and-apple-cash/)
- [MacStories — FinanceKit opens real-time Apple Card/Cash/Savings data](https://www.macstories.net/linked/financekit-opens-real-time-apple-card-apple-cash-and-apple-savings-transaction-data-to-third-party-apps/)
- [Finovate — Who needs open banking when you have Apple FinanceKit?](https://finovate.com/who-needs-open-banking-when-you-have-apple-financekit/)
- [Moneko — How to sync Apple Wallet with your budget (2026)](https://moneko.io/blogs/apple-wallet-sync-2026)

**Trading 212 API**
- [Trading 212 Public API docs](https://docs.trading212.com/api)
- [Trading212 Public API reference](https://t212public-api-docs.redoc.ly/)
- [Trading 212 Help Centre — API key](https://helpcentre.trading212.com/hc/en-us/articles/14584770928157-Trading-212-API-key)
- [SnapTrade — Trading 212 integration](https://snaptrade.com/brokerage-integrations/trading212-api)
- [Trading 212 Community — Current API functionality](https://community.trading212.com/t/current-api-functionaliy/90129)

**EU open banking / PSD2**
- [DEV — Comparing European Open Banking API providers in 2026 (Plaid, TrueLayer, Tink, GoCardless)](https://dev.to/johnfrandsen/comparing-european-open-banking-api-providers-in-2026-plaid-truelayer-tink-gocardless-125c)
- [Open Banking Tracker — providers directory](https://openbankingtracker.com/open-banking-providers)
- [Freenance — PSD2 & Open Banking EU 2026 explained](https://freenance.io/fintech/psd2-open-banking-eu-2026-explained-aspsp-aisp-pisp-what-it-means-personal-finance-apps-guide/)

**Competitors & sentiment**
- [WalletGrower — YNAB vs Monarch vs Copilot (2026)](https://walletgrower.com/compare/ynab-vs-monarch-vs-copilot)
- [x1wealth — Monarch vs Copilot Money (2026)](https://x1wealth.com/compare/copilot-vs-monarch)
- [Wall Street Survivor — Rocket Money vs Monarch (+YNAB, Simplifi, Copilot)](https://www.wallstreetsurvivor.com/rocket-money-vs-monarch/)
- [Era — Era vs Monarch vs Copilot vs YNAB (2026)](https://era.app/articles/era-vs-monarch-vs-copilot-vs-ynab/)
- [Freenance — Best personal finance apps in Europe 2026](https://freenance.io/budgeting/best-personal-finance-apps-europe/)
- [Monavio — Best budgeting apps for Europe (2026)](https://monavio.app/blog/best-budget-apps-europe/)
- [Finny — Best euro expense trackers 2026](https://getfinny.app/blog/best-euro-expense-trackers-2026)
- [Beancount forum — Copilot vs Monarch vs YNAB discussion](https://beancount.io/forum/t/copilot-vs-monarch-vs-ynab-which-premium-budget-app-is-worth-it/98)

*Point-in-time figures (pricing, country coverage, API beta status) drift quickly — re-verify anything you'll base a real decision on.*
