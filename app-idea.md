I want to explore and potentially develop a mobile application for personal finance and expense tracking.

At the moment, I personally track my monthly expenses manually in Apple Notes. I keep a running list of everything I spend during the current month, but this process is inconvenient, difficult to analyze, and provides very little insight into my overall financial situation.

I am considering building a **native Apple-only personal finance application**, initially targeting iPhone and potentially expanding to iPad and Apple Watch later.

The core idea is to make personal finance tracking extremely simple and convenient, with a strong focus on understanding where your money goes during a specific month.

## Core concept

The application should allow users to:

* Manually add expenses and income.
* Automatically import eligible transactions from Apple Wallet where Apple's APIs and permissions allow this.
* Automatically categorize transactions.
* View total spending for the current month.
* See how much money has been spent in each category.
* Track recurring expenses and subscriptions.
* Track bills and monthly commitments.
* Track savings.
* Track investments and investment performance.
* Set monthly spending limits or budgets.
* Compare spending with previous months.
* Understand spending patterns and trends.
* Receive useful insights about their finances.

The application should prioritize **simplicity and speed**. Adding or reviewing an expense should require as little effort as possible.

## Apple ecosystem

One of the key differentiators I am considering is making the application **Apple-first / Apple-only**.

Please investigate Apple's current APIs and capabilities, especially **FinanceKit**, to determine exactly what financial data can be accessed from Apple Wallet, under what conditions, which countries and financial products are supported, and what technical and App Store requirements exist.

Do not assume that Apple Wallet provides unrestricted access to all card transactions.

I want you to clearly distinguish between:

* What is technically possible today.
* What is possible only for certain countries or financial products.
* What requires Apple's managed entitlements or approval.
* What is not currently possible.
* What alternative approaches could be used when direct access is unavailable.

## Investment tracking

Another important part of the idea is investment tracking.

For example, I would like the application to integrate with services such as **Trading 212** so users can see their investments alongside their everyday finances.

Investigate:

* Whether Trading 212 provides a public API suitable for this use case.
* What data can be accessed.
* Whether portfolio holdings, transactions, deposits, withdrawals, profit/loss and portfolio value can be synchronized.
* Whether there are API limitations or authentication requirements.
* Whether similar integrations exist in competing applications.
* What other popular investment platforms could potentially be integrated in the future.

Do not assume an integration is possible simply because an API or service exists. Verify the current capabilities and restrictions.

## Suggested financial categories

Please design a better category structure than the initial idea below.

At minimum, consider categories such as:

* Housing
* Utilities & bills
* Groceries
* Restaurants & food
* Transportation
* Shopping
* Subscriptions
* Entertainment
* Health
* Travel
* Education
* Insurance
* Taxes
* Debt / loans
* Savings
* Investments
* Income
* Other

Investigate how leading personal finance applications structure categories and recommend a category system that is simple enough for everyday users while still providing useful analytics.

## Monthly-first experience

One of the main product ideas is to make the **current month the central concept**.

When opening the application, the user should immediately understand:

* How much money came in this month.
* How much has been spent.
* How much remains.
* How much was invested.
* How much was saved.
* Where the money went.
* Which recurring payments are coming up.
* How the current month compares with previous months.

The goal is not to build an overly complicated accounting application.

The goal is to answer a simple question:

> **"Where did my money go this month, and how am I doing financially?"**

Please evaluate whether this positioning is strong enough to differentiate the product.

# Market research

I want a serious analysis of the existing market.

Research current competitors, including but not limited to:

* Copilot Money
* Monarch Money
* YNAB
* Rocket Money
* Quicken Simplifi
* Empower
* PocketGuard
* Any strong European or Apple-focused competitors you identify

For each relevant competitor, analyze:

* Target audience
* Platforms
* Pricing
* Core features
* Expense tracking
* Automatic transaction synchronization
* Apple Wallet / FinanceKit integration
* Bank integrations
* Investment tracking
* Subscription tracking
* Budgeting
* Analytics
* User experience
* Main strengths
* Main weaknesses
* Common user complaints
* Geographic availability
* European / EU support

Do not simply list features from marketing pages. Look for real user feedback and complaints from sources such as Reddit, App Store reviews, forums and independent reviews where possible.

## Competitive opportunity

After researching the market, answer:

**Why would someone use this application instead of Copilot, Monarch, YNAB or another established product?**

Identify potential gaps in the market.

Look specifically for opportunities around:

* Apple-only experience
* Simplicity
* Monthly financial overview
* European users
* EU currencies
* European banks
* Investment tracking
* Trading 212
* Privacy
* Local/on-device data processing
* Better UX
* Automated categorization
* AI-powered financial insights
* Subscription tracking
* Net worth tracking
* Household/couple finances

Do not force a differentiation strategy if the research does not support it.

If the market is already too crowded, say so.

# European market

I am particularly interested in the European market rather than building a product exclusively for the United States.

Investigate:

* EU open banking / PSD2 opportunities
* Availability of European bank integrations
* Multi-currency support
* EUR support
* European financial institutions
* GDPR and privacy considerations
* Whether existing competitors are strong or weak in Europe
* Whether there is a meaningful opportunity to build an Apple-first personal finance product for European users

Also investigate whether Bulgaria could be a useful initial market or testing ground.

# Business model

Explore possible monetization strategies:

* Free + Premium
* Monthly subscription
* Annual subscription
* One-time purchase
* Freemium with limited integrations
* Premium investment tracking
* Premium AI insights

Compare the approaches used by competitors and recommend the most realistic model.

# Product scope

After completing the research, propose:

### 1. Core value proposition

One clear statement explaining why the product should exist.

### 2. Target user

Describe the ideal first user.

### 3. Main user journey

Describe what happens from opening the app for the first time to successfully tracking finances.

### 4. MVP

Define the smallest version worth building.

Separate:

* Must-have
* Should-have
* Nice-to-have
* Do not build yet

### 5. Future roadmap

Suggest what could be added after the MVP.

### 6. Technical feasibility

Provide a high-level architecture suitable for a native Apple application.

Consider:

* Swift / SwiftUI
* FinanceKit
* CloudKit
* Local encrypted storage
* Authentication
* Backend services where necessary
* API integrations
* Trading 212
* Bank integrations
* Push notifications
* Apple Watch
* Widgets
* Siri / Shortcuts
* iCloud synchronization

Do not over-engineer the architecture.

# Most important question

At the end of the research, give me an honest assessment:

### Is this worth building?

Classify the idea as one of:

* **STRONG OPPORTUNITY**
* **PROMISING BUT NEEDS VALIDATION**
* **CROWDED — NEEDS A STRONGER DIFFERENTIATOR**
* **NOT WORTH BUILDING IN ITS CURRENT FORM**

Explain exactly why.

I do not want you to simply validate my idea.

I want you to challenge it and tell me if there is a genuine opportunity.

If you believe the idea should be changed, propose a better version of the product.

## Important research rules

* Use current information.
* Prefer official sources for APIs, platform capabilities, pricing and technical restrictions.
* Use independent reviews and user discussions for user sentiment.
* Clearly cite important claims.
* Do not invent statistics, integrations or capabilities.
* Clearly distinguish verified facts from assumptions.
* Consider the situation as of **2026**.
* Do not write application code yet.

The objective of this research is to determine whether I should invest significant time and effort into building this product and, if so, exactly what product I should build.
