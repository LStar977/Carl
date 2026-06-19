# START HERE — running Carl end-to-end

Everything you need, in order. Phases 1–2 get Carl running with **real, free
jobs** on your laptop in ~15 minutes. Phases 3–6 are the path to the App Store.

Prereqs: **Node 18+**, **Xcode 16+** (macOS), and Git.

---

## Phase 1 — Get it running locally (~10 min)

```bash
# 1. Get the code
git clone https://github.com/lstar977/carl.git
cd carl
git checkout claude/kind-johnson-nj1n6n

# 2. Start the backend (zero dependencies)
cd server
cp .env.example .env
npm start
```

You should see `Carl server on :8787 …`. In another terminal:

```bash
curl localhost:8787/health
```

`integrations.ats` should be `true`. Leave the server running.

```bash
# 3. Open the app
open ../ios/Carl.xcodeproj
```

In Xcode: pick an **iPhone simulator** → **Run**. The app boots into the flow:
Meet Carl → Interview → Resume → Searching → Reveal → Paywall → main app.
The simulator reaches your Mac's `localhost:8787` automatically, so it's already
talking to the backend.

> On a **physical** device instead of the simulator, set
> `CarlAPI.shared.baseURL` (in `ios/Carl/Services/CarlAPI.swift`) to your Mac's
> LAN IP, e.g. `http://192.168.1.50:8787`.

---

## Phase 2 — Turn on real, free jobs (no API keys, no cost)

Real listings come from public ATS boards (Greenhouse/Lever/Ashby). Edit
`server/.env`:

```
ATS_BOARDS_PATH=data/boards.json   # the ~250-company starter list (already set)
INGEST_ENABLED=on                  # background crawler → instant, indexed search
```

Restart the server (`Ctrl-C`, `npm start`). First validate what's actually live:

```bash
cd server
ATS_BOARDS_PATH=data/boards.json npm run ingest
```

This prints the real job count, a per-source breakdown, and a sample. Now searches
in the app return real jobs. **Set your city** in the Interview step (e.g.
Toronto) and the reveal/queue will be city-filtered (remote roles always included).

> Expected counts with 250 companies: tens of jobs for a niche role, more for a
> broad one. Phase 4 scales this up.

---

## Phase 3 — Add the brains (Anthropic) + USAJOBS (optional, ~10 min)

The app fully works without these (heuristics + mock drafting), but they make
résumé parsing and application drafting real. In `server/.env`:

```
ANTHROPIC_API_KEY=sk-ant-...        # console.anthropic.com
CARL_MODEL=claude-haiku-4-5         # cheapest good drafting model
USAJOBS_API_KEY=...                 # developer.usajobs.gov (free, US federal)
USAJOBS_EMAIL=you@example.com
```

Restart; `curl localhost:8787/health` should show `llm: true`, `usajobs: true`.

---

## Phase 4 — Scale to LOTS of jobs

Two ways, both built in:

**One-off bulk import** (do this once to jump from 250 → thousands of companies):

```bash
cd server
# preview what a public crawl yields, then import it
npm run import-boards -- <crawl-url-or-file> --dry-run
npm run import-boards -- <crawl-url-or-file>
npm run ingest          # re-validate the live count
```
The importer accepts JSON, CSV, bare token lists (add `greenhouse`/`lever`/`ashby`),
or even a page full of career-page URLs. Good source to start from:
`https://github.com/Feashliaa/job-board-aggregator` (20k+ companies).

**Auto-growing (set and forget)** — the roster updates itself weekly. In `.env`:

```
BOARD_SOURCES=https://<public-crawl-url>   # comma-separated for several
BOARD_REFRESH_HOURS=168                    # weekly
```
(Requires `INGEST_ENABLED=on`.) The server pulls these on startup + on the
interval, merges new companies, and re-indexes — no manual runs.

> Rough scale: ~3,000 companies ≈ hundreds of jobs per search; ~20,000 ≈ the full
> "thousands of appliable jobs" experience.

---

## Phase 5 — Ship it (App Store)

Follow **`docs/launch-runbook.md`** — it's the detailed checklist. The short
version:

1. **Deploy the backend** to a host (Render/Railway/Fly.io). Set all the `.env`
   vars there. Swap the in-memory store for **Postgres** (`server/src/store.js`
   is behind an interface for exactly this — needed before real scale/users).
2. **Point the app at it:** set `CarlAPI.shared.baseURL` to the deployed URL.
3. **App Store Connect:** register bundle id `com.carlapp.Carl`, create the app,
   add the three **Consumable** IAPs (ids must match `ios/Carl/Carl.storekit`).
4. **Receipt validation:** drop Apple Root CA-G3 in `server/certs/`, set
   `APPSTORE_VERIFY=on` (see `server/certs/README.md`).
5. **Privacy:** privacy policy + terms, App Privacy labels, in-app account
   deletion (résumés are sensitive — App Review checks this).
6. **TestFlight → submit.** In review notes, explain the assisted-apply model.

---

## Phase 6 — Go live on real applications (carefully)

`APPLY_MODE=dry-run` (the default) prepares and records applications but **never
contacts an employer** — credits are spent, nothing is sent. Only when you're
ready to apply for real:

```
APPLY_MODE=live
```
Start with a small daily volume you watch end-to-end. Tier-A (Greenhouse/Lever)
auto-submit via their APIs; Tier-B opens the pre-filled application for the user.

---

## Quick reference

| I want to… | Do this |
|---|---|
| Run backend | `cd server && npm start` |
| Health check | `curl localhost:8787/health` |
| See real job counts | `cd server && npm run ingest` |
| Add companies (once) | `npm run import-boards -- <url>` |
| Auto-grow companies | set `BOARD_SOURCES` in `.env` |
| Run the app | open `ios/Carl.xcodeproj` in Xcode → Run |
| Full ship checklist | `docs/launch-runbook.md` |
| Job sources explained | `docs/job-sources-and-coverage.md` |

**Test everything:** `cd server && npm test` (should print all checks passing).
