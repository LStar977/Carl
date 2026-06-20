# Carl — How the App Works

> Carl is an AI with one job: to find you a job.
> This document defines how the product works end-to-end so we can design the
> screens (Claude Design) and then build it.
>
> **Locked decisions:** apply engine = **Assisted (Tier A + B) with a review
> queue** for v1; monetization = **credit packs** (pay per application); launch
> markets = **United States + Canada** (see `job-sources-and-coverage.md`).

---

## 1. The one-sentence pitch

Carl reads your resume, learns what you want, finds jobs in your area you're
actually a good fit for, and applies to them for you — so you get interviews
without spending nights filling out the same form 300 times.

Two audiences, one product:
- **Job seekers** (no job) — urgency, volume, "just get me interviews."
- **Job upgraders** (have a job, want better) — selective, discreet, "only
  apply to things that beat what I have."

---

## 2. The core user journey (what the user sees)

This is the experience you described, tightened into a flow.

1. **Meet Carl.** App opens, Carl introduces himself with personality and (TTS)
   voice: *"Hi, I'm Carl, and I'm excited to find you a job."*
2. **Carl interviews you.** A short, friendly chat (not a boring form). He asks:
   - What kind of work / fields / job titles?
   - Where? (city + remote / hybrid / on-site, willing to relocate?)
   - Pay you want (and your floor)?
   - Seniority / years of experience?
   - Full-time, part-time, contract?
   - Work authorization (needed for eligibility filtering).
   - Anything to avoid (companies, night shifts, etc.)?
3. **Upload resume.** Carl parses it into a structured profile, confirms what he
   learned ("Got it — 4 years in marketing, last role at Acme"), and fills any
   gaps from the chat.
4. **Carl searches.** A live "searching" experience — Carl visibly works:
   scanning sources, filtering by fit, counting matches.
5. **The reveal.** *"I found 312 jobs worth applying to in your area."* Show a
   teaser of a few real matches (logos, titles, pay) so it feels real.
6. **Paywall.** User pays to unlock Carl actually applying (pricing in §6).
7. **Carl applies.** Carl works through the list. Progress is visible and
   addictive: *"Applied to 47 jobs today."*
8. **Track everything.** A dashboard of every application, its status (applied /
   viewed / responded / interview / rejected), and what to do next.

The emotional arc: *relief* (someone's handling this) → *proof* (real jobs, real
numbers) → *momentum* (watching the counter climb).

---

## 3. The hard truth: "applying for them" is the whole product

Everything except step 7 is straightforward. **Step 7 — actually submitting
applications — is where this product lives or dies**, and it's where most
"auto-apply" startups quietly cut corners. You need to go in with eyes open:

- **There is no single API to apply to all jobs.** Jobs live across LinkedIn,
  Indeed, ZipRecruiter, and dozens of ATS systems (Workday, Greenhouse, Lever,
  iCIMS, Taleo, Ashby, etc.). Each has different forms, logins, and screening
  questions.
- **The big aggregators forbid automation.** LinkedIn "Easy Apply" and Indeed
  "Quick Apply" are the obvious targets, but their Terms of Service prohibit
  bots/scraping, and LinkedIn in particular aggressively blocks and litigates.
  Building the core product on top of ToS violations is a real business risk.
- **Spam hurts the user.** Blasting 312 low-quality applications can damage the
  user's reputation with employers and get them auto-rejected. Volume without
  fit is a bad product even if it's technically impressive.
- **Quality answers need judgment.** Many applications have free-text screening
  questions ("Why do you want to work here?"), salary expectations, and
  knockout questions. These need tailored, per-job answers — this is exactly
  where an LLM (Claude) shines, but it's not "click submit."

**My recommendation: don't promise "fully autonomous, zero-touch, 312 in one
tap" on day one.** Instead, ship a tiered apply engine and be honest about which
tier each job is in. This is both safer and a better product.

### The apply engine — three tiers

| Tier | How Carl applies | Coverage | Risk |
|------|------------------|----------|------|
| **A. Official / API** | Submit through legitimate ATS apply endpoints and partner integrations (e.g. Greenhouse/Lever public boards, USAJobs, any aggregator with a real Apply API). | Medium | Low — fully sanctioned |
| **B. Carl-assisted apply** | Carl pre-fills the entire application (resume mapped to fields, tailored answers drafted by Claude) and the user taps **Confirm & Submit**. One tap per job, or batch-confirm. | High | Low — the human submits |
| **C. Fully automated** | Headless browser agent fills and submits with no human tap. | High but fragile | High — ToS, captchas, breakage |

Ship **A + B first.** Tier B still feels like magic — the user does seconds of
work instead of 30 minutes per app — while keeping you on the right side of ToS
and keeping application quality high. Layer in Tier C selectively later, only
where it's defensible (your own ATS partners, or sources that permit it).

This changes one thing in the UI: the paywall unlocks **"Carl prepares and
applies"** with a **review/approval queue**, not a literal black-box "311 done."
That queue is actually a *feature* — it's where the user sees Carl working and
stays engaged daily ("Applied to 47 today" comes from here).

> **Decision needed from you:** how aggressive do we go on auto-apply? My strong
> recommendation is A+B for v1. I've designed the rest around that, but it's
> easy to flex.

---

## 4. System architecture (how it actually works under the hood)

```
┌─────────────────────────────┐
│        iOS App (SwiftUI)     │  Carl persona, voice (TTS), chat intake,
│                              │  resume upload, search animation, reveal,
│                              │  paywall (StoreKit), review queue, dashboard,
│                              │  push notifications
└───────────────┬─────────────┘
                │ HTTPS (REST/GraphQL) + push
┌───────────────▼─────────────────────────────────────────────┐
│                         Backend API                          │
│  Auth · profiles · payments/credits · orchestration          │
├───────────┬───────────────┬──────────────┬──────────────────┤
│ Resume    │ Job Search &  │ Matching/    │ Apply Engine      │
│ Parser    │ Aggregation   │ Eligibility  │ (workers + queue) │
│ (Claude)  │ (source APIs) │ (Claude)     │ Tiers A/B/C       │
└───────────┴───────────────┴──────────────┴──────────────────┘
                │
        ┌───────▼────────┐   ┌──────────────┐   ┌───────────────┐
        │ Postgres        │   │ Object store │   │ External LLM  │
        │ users, jobs,    │   │ resumes,     │   │ (Claude API)  │
        │ applications    │   │ docs         │   │               │
        └─────────────────┘   └──────────────┘   └───────────────┘
```

### Components

1. **iOS app (SwiftUI).** All persona + UX. Carl's voice via on-device TTS for
   v1 (cheap, offline); upgrade to a branded voice (e.g. ElevenLabs) later.
   Keep the "brain" on the server so we can improve matching/applying without
   shipping app updates.

2. **Resume parser (Claude).** PDF/DOCX → structured profile: roles, skills,
   years, education, locations, seniority, achievements. Claude handles messy
   real-world resumes far better than regex parsers. Output is a JSON profile
   the user can review/edit.

3. **Job search & aggregation.** Pull listings from legitimate sources and
   normalize them into one schema. Start with sources that have real APIs and
   permissive terms:
   - Aggregator APIs: **Adzuna**, **USAJobs** (government), **Jooble**, etc.
   - ATS public boards: **Greenhouse**, **Lever**, **Ashby** job-board APIs.
   - Expand coverage over time; treat each source as a pluggable adapter.
   Cache + dedupe (the same job appears on many boards).

4. **Matching & eligibility (Claude + rules).** Two layers:
   - **Hard filters (rules):** location/remote, work authorization, comp floor,
     full/part-time, must-have certs. Removes the obviously ineligible.
   - **Fit scoring (Claude):** rank remaining jobs by how well the user's
     profile matches the JD, and *why*. This produces the honest "312 worth
     applying to" number — not "everything in a 50-mile radius."

5. **Apply engine (workers + queue).** The heart. A job queue processes
   applications:
   - **Tier A:** call the source's apply API.
   - **Tier B:** generate a complete pre-filled application + Claude-drafted
     answers/cover letter → push to the user's **review queue** → on Confirm,
     submit.
   - **Tier C (later):** browser-automation worker fills + submits.
   - Claude tailors a short cover note and screening answers per job from the
     user's profile. Every application is logged with status.

6. **Status tracking.** Where possible, ingest status (confirmation emails via a
   connected mailbox, ATS callbacks). Otherwise let the user mark outcomes.
   Feeds the dashboard and the daily "Carl applied to N jobs" notification.

7. **Payments.** Apple StoreKit (must use IAP for digital goods). Credits/packs
   = consumable IAP; subscriptions = auto-renewable. Server validates receipts
   and tracks the user's application credit balance.

---

## 5. Data model (starter)

- **User** — auth, contact, preferences (fields, titles, locations, comp, work
  type, authorization, exclusions), credit balance, subscription state.
- **Resume / Profile** — uploaded file ref + parsed structured profile (editable).
- **Job** — normalized listing: source, external id, title, company, location,
  remote type, comp (if available), description, apply method + tier, dedupe key.
- **Match** — user × job: fit score, reasons, eligible (bool), status
  (suggested / queued / awaiting-confirm / applied / responded / interview /
  rejected / closed).
- **Application** — the submission: tier used, answers/cover letter, submitted_at,
  status history, employer responses.
- **Transaction** — IAP purchases, credits granted/consumed.

---

## 6. Monetization

You said charge by number of applications — that maps cleanly to **credits**,
and I'd pair it with an optional subscription for retention.

- **Credit packs (consumable IAP):** e.g. 25 / 100 / 300 applications. One
  credit = one application Carl prepares + submits. Simple, matches your mental
  model, great for the one-time job seeker.
- **Subscription (auto-renewable IAP):** e.g. "Carl Pro" — N applications/month +
  premium features (priority queue, better-tailored answers, interview prep,
  branded voice). Better for upgraders who job-hunt passively over months.
- **Free tier / first taste:** the search + reveal ("312 jobs") is free — that's
  the hook. Maybe 1–3 free applications so they feel Carl work before paying.

Apple takes 15–30% of IAP; price with that in mind. The paywall lands right
after the reveal, when motivation peaks. **A credit is only consumed when an
application is actually submitted** — that's a fairness promise worth making
explicit (builds trust, reduces refund disputes).

---

## 7. Carl's personality

Carl is the moat — the brand is a *character*, not a dashboard.
- **Tone:** warm, upbeat, in-your-corner, lightly funny. A tireless friend who
  loves landing you interviews.
- **Voice:** literal TTS voice + consistent written voice ("I found...", "I
  applied to 47 today — let's keep going").
- **Behavior:** proactive and encouraging. Celebrates milestones. Never makes
  the user feel judged about their resume or gaps.
- **Honesty:** Carl tells the truth about fit ("This one's a stretch, but worth
  a shot") — that honesty is what makes the "312 worth applying to" believable.

---

## 8. Build phases

- **Phase 0 — Design (now):** finalize this flow → Claude Design produces the
  screens → review.
- **Phase 1 — MVP:** iOS app + backend; resume parsing; search from 2–3 source
  APIs; matching; reveal; paywall (credits); **Tier A + B apply** with review
  queue; dashboard + daily notification.
- **Phase 2:** more job sources; mailbox connect for auto status tracking;
  subscription tier; branded voice; interview prep.
- **Phase 3:** selective Tier C automation where defensible; analytics on what
  gets interviews; smarter tailoring.

---

## 9. Risks / open questions to decide before building

1. **Auto-apply aggressiveness** — recommend A+B (assisted) for v1. *(Your call.)*
2. **Job sources for v1** — which 2–3 we integrate first (drives real coverage).
3. **App Store review** — automating third-party sites can draw scrutiny; the
   assisted (Tier B) model is much safer to get approved.
4. **Privacy** — resumes are sensitive PII; need clear data handling + consent,
   especially if we connect a mailbox for status tracking.
5. **Pricing numbers** — exact pack sizes / prices / free allotment.

---

## 10. What's next

1. You confirm the **auto-apply approach** (recommend A+B) and rough **pricing**.
2. I write the **Claude Design prompt** describing every screen: meet-Carl,
   chat intake, resume upload, searching animation, the reveal, paywall, review
   queue / apply, and the "47 today" dashboard.
3. Claude Design produces the UI → we review → then we build Phase 1.
