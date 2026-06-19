# Carl — backend

The brains behind the app: résumé parsing, job discovery, fit matching, the
assisted apply engine, credits, and tracking. Plain Node (ESM) with **zero
dependencies** — runs as-is.

## Run

```bash
cd server
cp .env.example .env     # optional — works with no keys
npm start                # http://localhost:8787
npm run smoke            # end-to-end test of the whole flow
```

It runs fully **without any API keys** using deterministic mock data, so the app
is functional in development today. Add keys to `.env` to switch on real data:

| Key | Turns on |
|-----|----------|
| `ANTHROPIC_API_KEY` | Real résumé parsing, fit scoring, and application drafting (Claude). |
| `ADZUNA_APP_ID` / `ADZUNA_APP_KEY` | Real job discovery (Adzuna). |
| `USAJOBS_API_KEY` | US federal listings (USAJOBS). |

`APPLY_MODE=dry-run` (default) prepares and records applications but **never**
submits to a real employer. Set `APPLY_MODE=live` only when you intend to submit
Tier-A (Greenhouse/Lever) applications for real.

## API

All routes except `/health` and `/v1/auth/anon` require an `x-carl-token` header.

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/health` | Status + which integrations are live |
| `POST` | `/v1/auth/anon` | Create an anonymous user, get a token + free credits |
| `GET/PUT` | `/v1/profile` | Read / update preferences |
| `POST` | `/v1/resume` | Parse résumé text → structured profile |
| `POST` | `/v1/search` | Search + match → `{ count, avgFit, sources, topMatches }` (the reveal) |
| `GET`  | `/v1/queue` | Prepared applications awaiting confirmation (with drafts) |
| `POST` | `/v1/applications/:matchId/confirm` | Submit one (consumes 1 credit) |
| `POST` | `/v1/applications/confirm-all` | Submit everything ready |
| `GET`  | `/v1/applications/:id` | Application detail + status |
| `GET`  | `/v1/dashboard` | Stats + activity feed |
| `GET`  | `/v1/credits` | Balance + packs |
| `POST` | `/v1/credits/purchase` | Grant a pack (validate StoreKit receipt in prod) |

## Architecture

```
src/
  index.js            HTTP server + routing + handlers
  config.js           env + feature flags
  store.js            in-memory store (swap for Postgres later)
  llm.js              Claude (Anthropic Messages API) wrapper + JSON parsing
  data/mock.js        deterministic mock job universe (keyless fallback)
  adapters/           adzuna · usajobs (discovery) · greenhouse · lever (apply)
  services/           resume · jobs · match · apply · credits
test/smoke.mjs        end-to-end flow test
```

## Production TODO

- Swap the in-memory store for Postgres.
- Validate StoreKit receipts with Apple before granting credits.
- Sign the Adzuna commercial agreement; add real ATS apply credentials.
- Add auth (sign-in), rate limiting, and persistence for the apply queue/workers.
