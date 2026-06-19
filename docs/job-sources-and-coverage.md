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

Because v1 uses the **Assisted (Tier A + B)** model, *every* discovered job in a
covered country is appliable — Tier B (Carl pre-fills + user confirms) covers
any employer not on a supported ATS. So "Tier A coverage" only changes the share
that is fully one-tap auto, **not** whether Carl works in a market.

| Market | Discovery | Tier A auto-apply | Assisted (Tier B) | Verdict |
|--------|-----------|-------------------|-------------------|---------|
| **United States** | Adzuna US + USAJOBS | Greenhouse + Lever (concentrated here) | All employers | **Launch market** |
| **Canada** | Adzuna CA (+ US-remote roles open to CA) | Greenhouse/Lever Canadian employers (esp. tech) | All employers | **Launch market** |
| **UK** | Adzuna UK | Some Greenhouse/Lever | All employers | **Fast-follow** |
| **Australia** | Adzuna AU | Some Greenhouse/Lever | All employers | **Fast-follow** |
| Germany, France, Netherlands, etc. | Adzuna | Thinner ATS overlap | All employers | Works; auto-apply share lower |
| Other Adzuna countries (Austria, Belgium, Brazil, India, Italy, Mexico, NZ, Poland, Singapore, South Africa, Spain, Switzerland) | Adzuna | Sparse | All employers | Works; mostly assisted |

### Recommendation
- **v1 launch: United States + Canada.** Both have full discovery (Adzuna US/CA
  + USAJOBS for US federal) and full apply coverage via the Tier A + B model.
  Canadian users get the complete experience; US users simply have a higher
  share of fully hands-off (Tier A) auto-applies.
- **Fast-follow: UK, Australia.** Adzuna covers them well; same Tier A + B model.
- **Everywhere else in Adzuna's footprint:** Carl still works (discovery +
  assisted apply), but a larger share is Tier B until more ATS adapters land
  (Phase 2: Ashby/Workable/etc.). Don't *market* "fully automatic" there yet.

> Note: Adzuna's commercial agreement and the Greenhouse/Lever adapters cover
> US + Canada with the same integration work — there is **no extra source to
> sign or build** to support Canada at launch.

## Pre-launch to-dos this surfaces
- Sign **Adzuna commercial agreement** before launch (free tier is dev-only).
- Get a **USAJOBS API key**.
- Build per-employer **ATS adapters** (Greenhouse, Lever) behind a server proxy
  that holds keys and submits applications.
- A **dedupe layer** — the same role appears on Adzuna *and* on the employer's
  Greenhouse/Lever board; prefer the Tier-A apply path when both exist.
