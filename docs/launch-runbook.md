# Carl — Launch Runbook

Everything left to take Carl from "works in dev" to "live on the App Store."
Most of this is external setup (accounts, keys, hosting, review) rather than
code. Work top to bottom; each phase is roughly independent but ordered by
dependency.

**Where things stand:** the app + backend are feature-complete and run end-to-end
in dev using mock job data and `APPLY_MODE=dry-run`. The items below switch on
real data, real money, real applications, and ship it.

---

## Phase 0 — Accounts you'll need

- [ ] **Apple Developer Program** membership ($99/yr) — you have this.
- [ ] **Anthropic API** account (console.anthropic.com) — for résumé parsing,
      matching, and drafting.
- [ ] **(Free, no account)** Public ATS boards (Greenhouse/Lever/Ashby) are the
      default job source — real listings, no key, no agreement. Just grow the
      company list in `server/src/data/boards.js`.
- [ ] **USAJOBS** API key (developer.usajobs.gov) — US federal listings (free).
- [ ] *(Optional)* **Adzuna developer** account + **commercial agreement** —
      only for breadth beyond the seeded ATS boards; not a launch blocker.
- [ ] A **hosting** provider for the backend (Render / Railway / Fly.io / a VPS).
- [ ] A **Postgres** database (most hosts offer one-click).
- [ ] A **domain** for the API (e.g. `api.carl.app`) — optional but recommended.

---

## Phase 1 — Real data sources

1. [ ] **Free ATS boards (real listings, $0):** already on by default
       (`ATS_ENABLED=on`). Open `server/src/data/boards.js` and **expand the
       company token list** — every US/CA company on Greenhouse/Lever/Ashby you
       add yields more real listings, no key required. This alone gives the app
       real jobs at launch.
2. [ ] **Anthropic:** create an API key. Pick a model (default `claude-sonnet-4-6`;
       `claude-haiku-4-5` is the cheaper drafting option).
3. [ ] **USAJOBS:** request an API key (provide the contact email it asks for).
4. [ ] *(Optional)* **Adzuna:** register for `app_id` + `app_key`, then **email
       Adzuna to sign a commercial-use agreement** (free tier is dev-only) — only
       if you want listings beyond the seeded boards. Can take time; not required
       to launch.
5. [ ] Put what you have in `server/.env` (see `server/.env.example`):
   ```
   ANTHROPIC_API_KEY=...
   USAJOBS_API_KEY=...      USAJOBS_EMAIL=you@example.com
   # optional: ADZUNA_APP_ID=...   ADZUNA_APP_KEY=...
   ```
6. [ ] Verify: `cd server && npm start`, hit `GET /health` — `integrations`
       should show `ats: true` (and `llm/usajobs: true` once keyed). Run a search
       and confirm real listings come back from the ATS boards.

> The free ATS boards need no keys, so real listings work out of the box. If a
> source returns nothing (e.g. egress blocked, or a board closed), the backend
> falls back to deterministic mock data so the app never breaks.

---

## Phase 2 — Backend: production-ready

1. [ ] **Swap the in-memory store for Postgres.** `server/src/store.js` is behind
       a small interface on purpose — reimplement those methods against Postgres
       (users, profiles, jobs, matches, applications, activity, transactions,
       used-transaction ids). Nothing else needs to change.
2. [ ] **Add real auth.** Today users are anonymous tokens. Add sign-in (Apple
       sign-in pairs well) so a user's profile/credits persist across devices.
3. [ ] **Harden:** rate limiting, request logging, error monitoring (Sentry),
       and CORS locked to your app's needs.
4. [ ] **Deploy.** Set all env vars on the host. Keep `APPLY_MODE=dry-run` for
       now. Note the public URL.
5. [ ] **Point the app at it:** set `CarlAPI.shared.baseURL` to the deployed URL
       (`ios/Carl/Services/CarlAPI.swift`) — ideally via a build setting so debug
       uses localhost and release uses production.

---

## Phase 3 — App Store Connect setup

1. [ ] **Bundle ID:** register `com.carlapp.Carl` (or your chosen id) under
       Certificates, Identifiers & Profiles. If you change it, update
       `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project and `APPLE_BUNDLE_ID` in
       the backend.
2. [ ] **Create the app** in App Store Connect (name "Carl", primary category
       e.g. Business / Productivity).
3. [ ] **In-App Purchases** — create three **Consumable** products with IDs that
       exactly match the app + `.storekit` config:
   - `com.carlapp.credits.starter` — Starter · 25 — $19
   - `com.carlapp.credits.popular` — Popular · 110 — $59
   - `com.carlapp.credits.pro` — Pro · 340 — $149
       Fill in display name, description, review screenshot. Submit them **with**
       the app's first review.
4. [ ] **Tax & banking** (Agreements, Tax, and Banking) — required before IAPs
       can be sold.

---

## Phase 4 — StoreKit live + receipt validation

1. [ ] **Sandbox test first:** with the IAPs created, test purchases on a real
       device using a Sandbox Apple ID (Settings → Developer). The local
       `Carl.storekit` config is only for the simulator; real products load on
       device.
2. [ ] **Turn on receipt validation** (`server/src/appstore.js` is ready):
   - Download **Apple Root CA - G3** (PEM) → `server/certs/AppleRootCA-G3.pem`
     (see `server/certs/README.md`).
   - Set `APPSTORE_VERIFY=on` and `APPLE_BUNDLE_ID=<your bundle id>`.
   - Sandbox + production transactions verify against Apple's chain; replay is
     blocked by transaction id.
3. [ ] (Optional, stronger) Add App Store Server Notifications so refunds/
       chargebacks can claw back credits.

---

## Phase 5 — Privacy, legal & compliance

Carl handles résumés (sensitive personal data) and applies on a user's behalf —
take this seriously; it's also an App Review focus.

1. [ ] **Privacy Policy** + **Terms of Service** (host them; link in-app and in
       App Store Connect). Cover: résumé storage, what's sent to Anthropic, that
       Carl submits applications on the user's behalf, and data retention.
2. [ ] **App Privacy "nutrition labels"** in App Store Connect — declare the data
       you collect (résumé/contact/usage) and how it's used.
3. [ ] **Account deletion** in-app (Apple requires it for accounts) + a backend
       endpoint that purges the user's data.
4. [ ] **Consent**: explicit opt-in before Carl applies on the user's behalf, and
       clear copy that a credit is only spent on a real submission.
5. [ ] If you connect a mailbox for status tracking later, that needs its own
       consent + scoped access.

---

## Phase 6 — Build, TestFlight, submit

1. [ ] **App icon** — done (generated from the brand mark). Confirm it renders.
2. [ ] **Screenshots** for required device sizes (6.7" + others) — capture the
       hero flow: Meet Carl → Reveal ("312 jobs") → Queue → Dashboard.
3. [ ] **Metadata:** subtitle, description, keywords, support URL, marketing URL.
4. [ ] **Archive & upload** a Release build to App Store Connect; distribute via
       **TestFlight** and run the whole flow on real devices.
5. [ ] **Submit for review.** In review notes, explain the assisted-apply model
       (Carl prepares applications; the user confirms / official APIs submit) and
       provide a demo account + how to reach the paywall.

---

## Phase 7 — Go live on real applications (carefully)

`APPLY_MODE=dry-run` records applications without contacting employers. Only flip
to `live` when you intend to submit for real.

1. [ ] Implement/verify the **Tier-A submit adapters** with real credentials
       (`server/src/adapters/greenhouse.js`, `lever.js`) and add more ATS
       coverage (Ashby, Workable) as desired.
2. [ ] Decide the **Tier-B assisted** UX: deep-link the user to the pre-filled
       application to send (the "1-tap apply" path already badged in the queue).
3. [ ] Start with a **small daily cap** and a few real submissions you watch
       end-to-end before scaling. Confirm credits are only spent on real sends.
4. [ ] Set `APPLY_MODE=live`.

---

## Phase 8 — Post-launch

- [ ] Monitor: errors, search/apply success rates, conversion, refunds.
- [ ] Add more job sources / ATS adapters to widen auto-apply coverage.
- [ ] A/B test the paywall and the searching/reveal moment (the variations are
      why we designed two of each).
- [ ] Expand markets beyond US + Canada once the loop is proven.

---

## Quick reference

| Thing | Where |
|---|---|
| App entry / flow | `ios/Carl/AppFlow.swift`, `CarlApp.swift` |
| API client / base URL | `ios/Carl/Services/CarlAPI.swift` |
| Session + state | `ios/Carl/Services/CarlStore.swift` |
| IAP product ids | `ios/Carl/Carl.storekit`, `StoreService.swift` |
| Backend config | `server/src/config.js`, `server/.env.example` |
| Receipt validation | `server/src/appstore.js`, `server/certs/` |
| Apply engine | `server/src/services/apply.js`, `server/src/adapters/` |
| Tests | `server/test/` (`npm test`) |
