# Deploying the Carl backend on Replit

The repo is import-and-run ready. Root `package.json` + `.replit` make Replit
install and start the backend in `server/` automatically.

## Steps

1. **Import** this GitHub repo into Replit.
2. **Add a PostgreSQL database** (Replit → Database/Storage → PostgreSQL). This
   sets `DATABASE_URL` automatically — the server detects it and persists all
   state (users, credits, applications…) across restarts/deploys. Without it the
   server still runs, but data resets on restart.
3. **Add Secrets** (Replit → Secrets):
   ```
   ATS_ENABLED=on
   INGEST_ENABLED=on
   AUTO_SEARCH_ENABLED=on
   ATS_BOARDS_PATH=data/boards.json
   APPLY_MODE=dry-run            # keep as dry-run — Carl must not auto-contact employers yet
   FREE_CREDITS=3
   APPSTORE_VERIFY=off           # turn on later, with the Apple root cert
   APPLE_BUNDLE_ID=com.carlapp.Carl
   CARL_MODEL=claude-haiku-4-5
   ANTHROPIC_API_KEY=...         # your key (real résumé parsing + drafting)
   USAJOBS_API_KEY=...           # optional (US federal jobs)
   USAJOBS_EMAIL=you@example.com # optional
   ```
4. **Deploy as a Reserved VM (always-on)** — NOT Autoscale. The background workers
   (ingestion + daily search) use in-process timers and need the process alive
   24/7; Autoscale would sleep and break them.
5. **Verify:** open `https://<your-deployment>/health` — `integrations.ats` should
   be `true`, and `llm` `true` once the Anthropic key is set. On startup the logs
   show `store: snapshot loaded from Postgres` (or "connected … fresh") and an
   `ingest: indexed N jobs…` line.
6. **Point the app at it:** send me the deployment URL (or set it yourself in
   `ios/Carl/Services/CarlAPI.swift`, the `#else` branch) so Release builds use it.

## Notes

- **Persistence model:** a single always-on instance holds state in memory and
  snapshots it to Postgres on a 5s tick, immediately after purchases, and on
  shutdown. Perfect for one Reserved VM. If you ever scale to multiple instances,
  move to a per-row relational schema (the `store.js` interface is the seam).
- **Keep `APPLY_MODE=dry-run`** until you intend to submit real applications.
- **Turn on receipt validation** (`APPSTORE_VERIFY=on`) once your IAPs exist and
  you've added `server/certs/AppleRootCA-G3.pem`.
