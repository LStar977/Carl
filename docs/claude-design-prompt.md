# Claude Design Prompt — Carl iOS App

> Paste the section below into Claude Design to generate the screens.
> Decisions locked: **Assisted apply (Tier A + B) with a review/approval queue**
> and **credit packs** (pay per application). See `how-carl-works.md` for the
> full product spec.

---

## PROMPT

Design a polished, modern **iOS mobile app** called **Carl**.

**Concept:** Carl is a friendly AI with one job — to find the user a job. Carl
reads the user's resume, interviews them about what they want, searches real job
listings, finds roles they're a great fit for, and then prepares and submits
applications on their behalf. The brand is a *character*: Carl is warm, upbeat,
encouraging, lightly funny — a tireless friend in your corner. The app should
feel hopeful and momentum-building, never like a boring corporate job board.

**Visual direction:** Clean, friendly, premium consumer app (think Duolingo
warmth meets a fintech polish). A distinct Carl mascot/avatar that can show
states (greeting, thinking/searching, celebrating). Soft, optimistic color
palette with one strong accent color. Rounded cards, generous spacing, large
friendly type, delightful micro-animations. Support light and dark mode.

Design the following screens as a connected flow:

1. **Meet Carl (welcome).** First launch. Carl's avatar front and center, a
   speech bubble: *"Hi, I'm Carl, and I'm excited to find you a job."* A single
   warm CTA to begin. Conveys voice/personality (Carl talks).

2. **Carl interviews you (conversational intake).** A chat-style, one-question-
   at-a-time flow (not a long form). Carl asks: desired fields/job titles;
   location + remote/hybrid/on-site + open to relocating; desired pay (and a
   floor); years of experience/seniority; full-time/part-time/contract; work
   authorization; anything to avoid. Show friendly chips/quick-reply buttons and
   a progress indicator. Carl reacts encouragingly between answers.

3. **Resume upload.** Carl asks for the resume. Upload from Files/iCloud or
   photo. Then a "Carl is reading your resume" state, followed by a confirmation
   card showing what Carl learned (role, years, top skills) that the user can
   edit/confirm.

4. **Carl is searching (the magic moment).** A live, dynamic searching
   animation — Carl visibly working: scanning sources, a climbing match counter,
   subtle ticker of titles/companies being scanned. Builds anticipation.

5. **The reveal.** Big, celebratory: **"I found 312 jobs worth applying to in
   your area."** Carl celebrating. Below the headline, a teaser preview of 3–4
   real matches (company logo, job title, pay range, location, a small "great
   fit" badge) — partially visible/locked to motivate unlocking.

6. **Paywall (credit packs).** Lands right after the reveal at peak motivation.
   Sell **credits = applications**. Three packs (e.g. Starter 25, Popular 100
   [highlighted as best value], Pro 300) with price, per-application value, and a
   clear line: *"Carl only uses a credit when he actually submits an
   application."* Trust/reassurance row (cancel anytime, secure payment). Mention
   a small number of free applications to try Carl first.

7. **Carl is working / review & apply queue.** After unlocking, the core daily
   screen. A list of matched jobs Carl has prepared applications for. Each card:
   logo, title, company, pay, fit reason, and an application Carl pre-filled
   (resume mapped + AI-drafted answers/cover note) ready to review. Actions:
   **Confirm & Submit** per job, plus a **Confirm all / batch submit** option.
   Show a tab/filter for: Ready to review · Submitted · Responses. Each card can
   expand to preview the drafted answers before submitting. Carl's tone
   throughout is encouraging.

8. **Dashboard / progress (home).** The momentum screen. Hero stat: **"Carl
   applied to 47 jobs today"** with Carl celebrating. Stats: total applied,
   responses, interviews, credits remaining. A timeline/feed of recent activity
   ("Applied to Senior Designer at Acme · 2h ago"). Buttons to buy more credits
   and to keep reviewing the queue. Should feel rewarding to open daily.

9. **Application detail / tracking.** Tapping any application shows its full
   status (Applied → Viewed → Responded → Interview → Rejected), the job
   details, and what Carl submitted (answers, cover note).

10. **Settings / profile.** Edit resume & preferences, manage credits/purchase
    history, notifications, Carl's voice toggle, privacy & data, account.

Also include any small supporting states: a **buy-more-credits** sheet, an
**empty/all-caught-up** state for the queue ("Carl found you everything for now,
I'll keep looking"), and a **push notification** mockup ("Carl applied to 12
jobs today 🎉").

Make the whole thing feel like one charming character guiding the user from
hopeless ("ugh, applying to jobs") to hopeful ("Carl's on it"). Prioritize
clarity, warmth, and momentum.
