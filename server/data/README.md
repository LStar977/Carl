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
postings, **import a public ATS token crawl** with the bundled importer — it
merges into this file and de-dupes:

```
npm run import-boards -- <source-url-or-file> [greenhouse|lever|ashby] [--dry-run]
```

The importer accepts almost any shape — our `{greenhouse:[],lever:[],ashby:[]}`
JSON, an array of `{ats, token}` objects, a bare token list (pass the provider),
a CSV, or even raw text/HTML containing career-page URLs (it pulls tokens out of
`greenhouse.io` / `lever.co` / `ashbyhq.com` links). Examples:

```
# a public crawl that already tags provider + token
npm run import-boards -- https://example.com/ats-companies.json

# a plain newline list of Greenhouse companies
npm run import-boards -- ./greenhouse-companies.txt greenhouse

# preview first
npm run import-boards -- ./list.json --dry-run
```

Then turn on the background worker (`INGEST_ENABLED=on`) and validate live
coverage with `npm run ingest`. See `docs/job-sources-and-coverage.md` →
"Scaling to Indeed-class volume".

## Auto-growing the list (no manual runs)

To have the roster grow on its own, set `BOARD_SOURCES` to one or more public
crawl URLs (and `INGEST_ENABLED=on`). The server fetches them on startup and
every `BOARD_REFRESH_HOURS` (default weekly), merges new tokens into the live
list, and re-indexes — so the company count climbs without you running
`import-boards`. Manual `import-boards` and auto-refresh can be used together.
