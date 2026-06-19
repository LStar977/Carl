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

### 1. Adzuna — DISCOVERY (broad)
- RESTful job-search API; returns listings + salary/market data and a
  **redirect URL to apply on the original site**. **No apply/submit endpoint.**
- **Coverage: 19 countries** — Australia, Austria, Belgium, Brazil, Canada,
  France, Germany, India, Italy, Mexico, Netherlands, New Zealand, Poland,
  Singapore, South Africa, Spain, Switzerland, **United Kingdom, United States**.
- Free developer tier with rate limits; **commercial use needs an agreement** —
  must contact Adzuna before launch.
- **Role for Carl:** primary discovery engine + salary/market context.

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

> Ashby, Workable, Recruitee also expose public job-posting APIs — good Phase-2
> additions to widen Tier-A apply coverage.

## Where Carl will work (location coverage)

Coverage is strongest where **discovery AND apply overlap**:

| Market | Discovery | Tier A auto-apply | Verdict |
|--------|-----------|-------------------|---------|
| **United States** | Adzuna US + USAJOBS | Greenhouse + Lever (concentrated here) | **Best — full loop. Launch here.** |
| **UK** | Adzuna UK | Some Greenhouse/Lever | **Strong fast-follow** |
| **Canada** | Adzuna CA | Some Greenhouse/Lever | **Strong fast-follow** |
| **Australia** | Adzuna AU | Some Greenhouse/Lever | **Strong fast-follow** |
| Germany, France, Netherlands, Ireland*, etc. | Adzuna | Thinner ATS overlap | Discovery + Tier B works; auto-apply spotty |
| Other Adzuna countries (Austria, Belgium, Brazil, India, Italy, Mexico, NZ, Poland, Singapore, South Africa, Spain, Switzerland) | Adzuna | Sparse | Discovery + Tier B only |

\*Ireland not in Adzuna's 19; revisit with another source later.

### Recommendation
- **v1 launch: United States only.** It's the one market where discovery *and*
  real auto-apply (Greenhouse/Lever) both land — so Carl's core promise actually
  works end to end, and App Store review is cleanest.
- **Fast-follow: UK, Canada, Australia.** Adzuna covers them well and Tier B
  (assisted) works everywhere; Tier A kicks in for any Greenhouse/Lever employer.
- **Everywhere else in Adzuna's footprint:** technically we can show matches and
  do assisted apply, but auto-apply coverage is thin — don't market auto-apply
  there until ATS coverage is added (Phase 2: Ashby/Workable/etc.).

## Pre-launch to-dos this surfaces
- Sign **Adzuna commercial agreement** before launch (free tier is dev-only).
- Get a **USAJOBS API key**.
- Build per-employer **ATS adapters** (Greenhouse, Lever) behind a server proxy
  that holds keys and submits applications.
- A **dedupe layer** — the same role appears on Adzuna *and* on the employer's
  Greenhouse/Lever board; prefer the Tier-A apply path when both exist.
