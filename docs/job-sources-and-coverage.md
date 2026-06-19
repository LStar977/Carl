# Carl — Job Sources & Location Coverage (v1 research)

Researched 2026-06. This determines **where Carl can operate** and **how the
two halves of the engine (find vs. apply) map onto real APIs.**

## The key insight: "find" and "apply" are different source sets

- **Discovery sources** tell us a job exists (and feed the "312 jobs worth
  applying to" number). They are broad but generally **cannot submit an
  application** — they hand you a redirect URL to the employer's site.
- **Apply sources** are per-employer ATS APIs that **do** accept a real
  application submission. These are narrower but are what makes Carl's Tier A
  (official auto-apply) legitimate.

Carl's job is to discover broadly, then route each match:
- Job lives on a supported ATS (Greenhouse/Lever) → **Tier A auto-apply (API)**.
- Everything else → **Tier B assisted** (Carl pre-fills + drafts answers, user
  taps Confirm; we open the employer's redirect URL).

## Sources

### 0. Public ATS boards — DISCOVERY **and** APPLY (free, primary) ✅
- Greenhouse, Lever and Ashby each publish a **public job-board JSON feed** per
  company — **no API key, no OAuth, no commercial agreement**:
  - `https://boards-api.greenhouse.io/v1/boards/{token}/jobs?content=true`
  - `https://api.lever.co/v0/postings/{token}?mode=json`
  - `https://api.ashbyhq.com/posting-api/job-board/{token}`
- Carl reads a curated list of company tokens in parallel (`server/src/data/boards.js`),
  normalises them, and filters to the user's target title + US/Canada market.
- **This is the cheapest real-listings path: $0.** It's also the *best* one,
  because the same companies' Greenhouse/Lever feeds are exactly where Carl can
  **auto-apply (Tier A)** — discovery and apply are the same source. Ashby is
  discovery-only here → Tier B (1-tap).
- **Coverage:** every company on those ATSs that we have a token for — heavily
  US/Canada tech + startups. More tokens = more listings; unknown/closed boards
  fail gracefully (return nothing), so the list is safe to grow aggressively.
- **Role for Carl:** the **default, free, real-data engine.** On by default
  (`ATS_ENABLED=on`); runs first so its Tier-A copies win de-duplication.

> Trade-off: coverage is only as wide as the seeded token list (no single
> "search everything" endpoint). Adzuna below fills that gap when you want
> breadth beyond the boards you've seeded — but it's **optional**, not required.

### 1. Adzuna — DISCOVERY (broad, optional)
- RESTful job-search API; returns listings + salary/market data and a
  **redirect URL to apply on the original site**. **No apply/submit endpoint.**
- **Coverage: 19 countries** — Australia, Austria, Belgium, Brazil, Canada,
  France, Germany, India, Italy, Mexico, Netherlands, New Zealand, Poland,
  Singapore, South Africa, Spain, Switzerland, **United Kingdom, United States**.
- Free developer tier with rate limits; **commercial use needs an agreement** —
  must contact Adzuna before using it in production.
- **Role for Carl:** *optional* breadth on top of the free ATS boards + salary/
  market context. Not required for launch — enable it once the (paid) commercial
  agreement is signed if you want listings beyond the seeded boards.

### 2. USAJOBS — DISCOVERY (US federal)
- Official US Office of Personnel Management API. Free with an API key.
  Rich structured data (duties, qualifications, how-to-apply). ~2.85M postings.
- **Coverage: United States federal jobs only.** Application itself completes on
  USAJOBS.gov (no third-party submit API).
- **Role for Carl:** high-trust US government listings; Tier B assisted apply.

### 3. Greenhouse Job Board API — APPLY (Tier A) ✅
- Per-company public board (`board_token`). Has a real **submit endpoint**:
  `POST https://boards-api.greenhouse.io/v1/boards/{token}/jobs/{id}` — accepts
  multipart form-data incl. **resume/cover-letter upload**, employment history,
  screening + demographic answers, referral source.
- Basic-auth Job Board API key; **must be proxied through our server** (never
  expose the key in-app).
- **Coverage:** companies using Greenhouse (Greenhouse cites ~7,500+ orgs;
  heavy in US tech — Stripe, Figma, Coinbase, etc.). Postings seen across 200+
  countries but **concentrated in the US**.
- **Role for Carl:** real one-call auto-apply where the employer uses Greenhouse.

### 4. Lever Postings API — APPLY (Tier A) ✅
- Per-company postings API with an **"Apply to a Posting" endpoint**. Required
  fields: name + email (employers can require more — coordinate per account).
  JSON or multipart (multipart for resume upload). De-dupes candidates by email.
- **Coverage:** companies using Lever (US-concentrated tech/startups).
- **Role for Carl:** real auto-apply where the employer uses Lever.

> Ashby is already wired for discovery (Tier B). Workable, Recruitee and
> SmartRecruiters also expose public job-board APIs — good additions to widen
> free discovery and (for those with submit endpoints) Tier-A apply coverage.

## Where Carl will work (location coverage)

Coverage is strongest where **discovery AND apply overlap**:

Because v1 uses the **Assisted (Tier A + B)** model, *every* discovered job in a
covered country is appliable — Tier B (Carl pre-fills + user confirms) covers
any employer not on a supported ATS. So "Tier A coverage" only changes the share
that is fully one-tap auto, **not** whether Carl works in a market.

| Market | Discovery | Tier A auto-apply | Assisted (Tier B) | Verdict |
|--------|-----------|-------------------|-------------------|---------|
| **United States** | Free ATS boards + USAJOBS (Adzuna optional) | Greenhouse + Lever (concentrated here) | All employers | **Launch market** |
| **Canada** | Free ATS boards (+ US-remote roles open to CA) | Greenhouse/Lever Canadian employers (esp. tech) | All employers | **Launch market** |
| **UK** | Adzuna UK | Some Greenhouse/Lever | All employers | **Fast-follow** |
| **Australia** | Adzuna AU | Some Greenhouse/Lever | All employers | **Fast-follow** |
| Germany, France, Netherlands, etc. | Adzuna | Thinner ATS overlap | All employers | Works; auto-apply share lower |
| Other Adzuna countries (Austria, Belgium, Brazil, India, Italy, Mexico, NZ, Poland, Singapore, South Africa, Spain, Switzerland) | Adzuna | Sparse | All employers | Works; mostly assisted |

### Recommendation
- **v1 launch: United States + Canada.** Launch on the **free public ATS boards**
  (Greenhouse + Lever + Ashby) plus USAJOBS — **$0, real listings, no commercial
  agreement, and the Greenhouse/Lever feeds double as the Tier-A auto-apply
  path.** Canadian users get the complete experience; US users simply have a
  higher share of fully hands-off (Tier A) auto-applies.
- **Adzuna is optional breadth, not a launch blocker.** Sign its commercial
  agreement later if you want listings beyond the seeded boards; until then the
  free boards + USAJOBS carry the product.
- **Fast-follow: UK, Australia.** Adzuna covers them well; same Tier A + B model.
- **Everywhere else in Adzuna's footprint:** Carl still works (discovery +
  assisted apply), but a larger share is Tier B until more ATS adapters land
  (Phase 2: Ashby/Workable/etc.). Don't *market* "fully automatic" there yet.

> Note: the free ATS boards cover US + Canada with the same integration work —
> there is **no extra source to sign or build** to support Canada at launch, and
> **nothing to pay**.

## Scaling to Indeed-class volume

Indeed (~30M+ listings) is built by crawling the whole web plus a large paid
ingestion/sales operation. You can't reproduce that for free — and most of that
count is duplicates, staffing-agency reposts, and jobs with no programmatic
apply. Carl optimises for **appliable** jobs instead. Two levers:

1. **Free, large, appliable index (recommended — and now built).** Public crawls
   of ATS tokens cover **20,000+ companies / 1M+ live postings** across
   Greenhouse/Lever/Ashby. Drop a token list at `ATS_BOARDS_PATH` (JSON:
   `{greenhouse:[],lever:[],ashby:[]}`) and it merges with the built-in seed.
   You **cannot** live-fetch tens of thousands of boards per search, so a
   **background ingestion worker** (`server/src/services/ingest.js`) crawls every
   board on a schedule (bounded concurrency) into the job index; `searchJobs`
   then serves from the index instantly, narrowed by title, with city/pay/work-
   style filtering in `scoreMatches`. Turn it on with `INGEST_ENABLED=on`
   (`INGEST_INTERVAL_MIN`, `INGEST_CONCURRENCY` tune it); validate a token list
   with `npm run ingest`; `GET /health` reports the index size + age.
   **Postgres step:** the index lives in the store interface (`store.setJobIndex`/
   `getJobIndex`), so moving to a `jobs` table queried by `WHERE city/title/pay`
   is a store swap — the worker and search code don't change.
2. **Paid aggregator breadth.** Adzuna (or similar) already indexes Indeed-class
   volume behind a commercial agreement — fastest way to a huge raw count, but it
   costs money and those jobs are mostly Tier B (redirect, not auto-apply).

City filtering already works across all sources (`services/match.js`): remote
roles are always eligible; onsite/hybrid roles must match the user's city (with
metro aliases, e.g. Toronto/GTA).

## Pre-launch to-dos this surfaces
- **Grow the ATS token list** (`server/src/data/boards.js`) — the free,
  primary source. More US/CA company tokens = more real listings, zero cost.
- Get a **USAJOBS API key** (free) for US federal listings.
- Hold the **Greenhouse/Lever board API keys** server-side for live Tier-A
  submission (discovery needs no key; submitting an application does).
- *(Optional, later)* Sign the **Adzuna commercial agreement** for breadth
  beyond the seeded boards (free tier is dev-only).
- A **dedupe layer** — the same role can appear on multiple sources; prefer the
  Tier-A apply path when both exist (already handled in `services/jobs.js`).
