# `data/boards.json` — ATS board-token starter list

A curated list of ~250 US/Canada company board tokens (Toronto/Canada-heavy)
for Greenhouse, Lever and Ashby. It's merged with the built-in seed in
`src/data/boards.js` when you point the server at it:

```
ATS_BOARDS_PATH=data/boards.json
```

(already set in `.env.example`).

## Validate it

Run a one-off crawl to see which boards resolve and the real job counts:

```
ATS_BOARDS_PATH=data/boards.json npm run ingest
```

It prints the indexed job count, a per-source breakdown, and a sample. Tokens
that are stale/renamed/closed simply return nothing — safe to keep.

## Honesty note

These tokens are curated from publicly known companies on each ATS, **not**
live-verified one-by-one. Expect some misses; they degrade gracefully. The
`npm run ingest` output is the source of truth for what's actually live.

## Scaling to many thousands of companies

This file is the on-ramp, not the ceiling. To reach 20k+ companies / 1M+
postings, append a public ATS token crawl to the arrays here (same shape) and
turn on the background worker (`INGEST_ENABLED=on`). See
`docs/job-sources-and-coverage.md` → "Scaling to Indeed-class volume".
