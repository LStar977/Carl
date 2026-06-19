# Carl

The friendly AI that finds you a job — then applies for you.

Carl reads your resume, learns what you want, finds great-fit jobs in your area,
and prepares + submits applications on your behalf so you get interviews without
spending nights filling out the same form 300 times.

## Repo layout

- **`ios/`** — the native SwiftUI iOS app (all 15 screens). See
  [`ios/README.md`](ios/README.md) to build and run.
- **`docs/`** — product + design specs:
  - [`how-carl-works.md`](docs/how-carl-works.md) — full product spec (journey,
    apply-engine tiers, architecture, monetization).
  - [`job-sources-and-coverage.md`](docs/job-sources-and-coverage.md) — job
    sources (Adzuna, USAJOBS, Greenhouse, Lever) + US/Canada launch coverage.
  - [`claude-design-prompt.md`](docs/claude-design-prompt.md) — the Claude Design
    brief the screens were generated from.

## Locked decisions (v1)

- **Apply engine:** assisted (Tier A official APIs + Tier B Carl-prepares /
  you-confirm) with a review queue.
- **Monetization:** credit packs (pay per application). A credit is only spent
  when Carl actually submits.
- **Launch markets:** United States + Canada.
- **Brand:** navy `#1B2A4A` + royal blue `#2563EB`, Plus Jakarta Sans, the
  briefcase-in-magnifier Carl mark.

## Status

The UI is built. Backend (resume parsing, job discovery/apply adapters, StoreKit,
tracking) is the next phase.
