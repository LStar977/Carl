// Public ATS "board tokens" Carl reads for real, free listings.
//
// Every company self-hosts its open roles on an applicant-tracking system (ATS).
// Greenhouse, Lever and Ashby each expose a PUBLIC job-board JSON feed keyed by
// the company's board token (usually its slug) — no API key, no OAuth, and no
// commercial agreement. `searchATS` (../adapters/ats.js) reads these in parallel.
//
// Greenhouse + Lever also expose a programmatic apply endpoint, so jobs from
// them are Tier A (Carl can auto-submit). Ashby is discovery-only here (Tier B).
//
// SCALING: the built-in list below is a curated starter (well-known US/Canada
// employers, including Toronto/Canadian ones). To go big — public crawls cover
// 20,000+ companies / 1M+ live postings — point ATS_BOARDS_PATH at a JSON file
// of the shape { "greenhouse": [...], "lever": [...], "ashby": [...] } and it is
// merged in. Unknown/closed boards simply return nothing (fail gracefully), so
// it's safe to load a huge list. NOTE: live-fetching tens of thousands of boards
// per search is not viable — large lists need the background ingestion worker
// (see docs/job-sources-and-coverage.md → "Scaling to Indeed-class volume").
import { readFileSync } from 'node:fs';

const BUILTIN = {
  // boards-api.greenhouse.io/v1/boards/<token>/jobs
  greenhouse: [
    // US tech
    'airbnb', 'stripe', 'dropbox', 'robinhood', 'coinbase', 'databricks',
    'instacart', 'doordash', 'gitlab', 'reddit', 'pinterest', 'brex', 'gusto',
    'plaid', 'asana', 'figma', 'discord', 'twitch', 'lyft', 'cloudflare',
    'samsara', 'affirm', 'sofi', 'flexport', 'benchling', 'webflow', 'datadog',
    'mongodb', 'twilio', 'hashicorp', 'confluent', 'elastic', 'snyk', 'gong',
    'lattice', 'airtable', 'calendly', 'whatnot', 'rippling', 'scaleai',
    'anduril', 'niantic', 'chime', 'betterup', 'faire', 'mercury', 'retool',
    // Canada
    'shopify', 'wealthsimple', 'clio', 'ada', 'league', 'wattpad', 'kobo',
    'properly', 'jobber', 'hopper', 'koho',
  ],
  // api.lever.co/v0/postings/<token>?mode=json
  lever: [
    'netflix', 'nuro', 'eaze', 'sandboxvr', 'palantir', 'kojo', 'attentive',
    'voleon', 'matchgroup', 'shieldai', 'leaplabs', 'plaid', 'spotify',
    // Canada
    'lighthouse', 'getfront', 'ada-cx',
  ],
  // api.ashbyhq.com/posting-api/job-board/<token>
  ashby: [
    'ramp', 'linear', 'vercel', 'posthog', 'hex', 'replicate', 'clay',
    'elevenlabs', 'baseten', 'modal', 'runwayml', 'mercury', 'notion', 'cohere',
    'openai', 'anthropic', 'ramp', 'deel', 'gitpod', 'browserbase', 'together',
    // Canada
    'cohere', '1password', 'float', 'vidyard',
  ],
};

function dedupe(arr) {
  return [...new Set(arr.filter(Boolean).map((s) => s.trim().toLowerCase()))];
}

/** Built-in defaults merged with an optional external token file (ATS_BOARDS_PATH). */
function load() {
  let ext = {};
  const path = process.env.ATS_BOARDS_PATH;
  if (path) {
    try { ext = JSON.parse(readFileSync(path, 'utf8')) || {}; }
    catch (e) { console.warn(`ATS_BOARDS_PATH not loaded (${path}): ${e.message}`); }
  }
  return {
    greenhouse: dedupe([...(BUILTIN.greenhouse), ...(ext.greenhouse || [])]),
    lever: dedupe([...(BUILTIN.lever), ...(ext.lever || [])]),
    ashby: dedupe([...(BUILTIN.ashby), ...(ext.ashby || [])]),
  };
}

export const ATS_BOARDS = load();
