// Seed list of public ATS "board tokens" Carl reads for real, free listings.
//
// Every company self-hosts its open roles on an applicant-tracking system (ATS).
// Greenhouse, Lever and Ashby each expose a PUBLIC job-board JSON feed keyed by
// the company's board token (usually its slug) — no API key, no OAuth, and no
// commercial agreement. `searchATS` (../adapters/ats.js) reads these in parallel.
//
// Greenhouse + Lever also expose a programmatic apply endpoint, so jobs from
// them are Tier A (Carl can auto-submit). Ashby is discovery-only here (Tier B:
// Carl prepares the application and the user taps to send).
//
// This is a STARTER set of well-known US/Canada employers. Unknown, renamed or
// closed boards simply return nothing (the fetch fails gracefully), so it's safe
// to grow this list aggressively — more tokens = more real listings. Public
// crawls of Greenhouse/Lever/Ashby tokens exist if you want to bulk-expand it,
// or set the env var to point at your own list (see ../config.js: ATS_BOARDS_PATH).
export const ATS_BOARDS = {
  // boards-api.greenhouse.io/v1/boards/<token>/jobs
  greenhouse: [
    'airbnb', 'stripe', 'dropbox', 'robinhood', 'coinbase', 'databricks',
    'instacart', 'doordash', 'gitlab', 'reddit', 'pinterest', 'brex', 'gusto',
    'plaid', 'asana', 'figma', 'discord', 'twitch', 'lyft', 'cloudflare',
    'samsara', 'ramp', 'affirm', 'sofi', 'flexport', 'benchling', 'webflow',
  ],
  // api.lever.co/v0/postings/<token>?mode=json
  lever: [
    'netflix', 'nuro', 'eaze', 'sandboxvr', 'palantir', 'kojo', 'attentive',
    'voleon', 'matchgroup', 'lever', 'shieldai', 'leaplabs',
  ],
  // api.ashbyhq.com/posting-api/job-board/<token>
  ashby: [
    'ramp', 'linear', 'vercel', 'posthog', 'hex', 'replicate', 'clay',
    'elevenlabs', 'baseten', 'modal', 'runwayml', 'mercury', 'notion', 'cohere',
  ],
};
