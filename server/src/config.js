// Centralised configuration, read from the environment with safe defaults.
// Optionally loads a local .env file (no dependency on dotenv).
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
try {
  const raw = readFileSync(join(root, '.env'), 'utf8');
  for (const line of raw.split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && process.env[m[1]] === undefined) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
} catch { /* no .env file — fine */ }

export const config = {
  port: Number(process.env.PORT || 8787),

  anthropicKey: process.env.ANTHROPIC_API_KEY || '',
  model: process.env.CARL_MODEL || 'claude-sonnet-4-6',
  fastModel: process.env.CARL_FAST_MODEL || 'claude-haiku-4-5-20251001',

  adzunaAppId: process.env.ADZUNA_APP_ID || '',
  adzunaAppKey: process.env.ADZUNA_APP_KEY || '',

  usajobsKey: process.env.USAJOBS_API_KEY || '',
  usajobsEmail: process.env.USAJOBS_EMAIL || '',

  // Free public-ATS discovery (Greenhouse/Lever/Ashby boards). On by default —
  // it needs no key and no commercial agreement. Set ATS_ENABLED=off to disable.
  atsEnabled: (process.env.ATS_ENABLED || 'on').toLowerCase() !== 'off',
  // Optional JSON file of extra board tokens to merge in (for scaling beyond the
  // built-in seed list). See server/src/data/boards.js.
  atsBoardsPath: process.env.ATS_BOARDS_PATH || '',

  // Background ingestion worker: crawl all boards into the index on a schedule so
  // searches are instant and can scale to a huge token list. Off by default
  // (small lists serve fine via live fetch); turn on in production.
  ingestEnabled: (process.env.INGEST_ENABLED || 'off').toLowerCase() === 'on',
  ingestIntervalMin: Number(process.env.INGEST_INTERVAL_MIN || 360),
  ingestConcurrency: Number(process.env.INGEST_CONCURRENCY || 20),

  // Self-updating company roster: comma-separated public crawl URLs the server
  // pulls on startup + every BOARD_REFRESH_HOURS, merging new tokens into the
  // live list. Requires the ingestion worker to be on. Empty = manual only.
  boardSources: (process.env.BOARD_SOURCES || '').split(',').map((s) => s.trim()).filter(Boolean),
  boardRefreshHours: Number(process.env.BOARD_REFRESH_HOURS || 168),

  applyMode: (process.env.APPLY_MODE || 'dry-run').toLowerCase(),
  freeCredits: Number(process.env.FREE_CREDITS || 3),

  // App Store receipt validation.
  appstoreVerify: (process.env.APPSTORE_VERIFY || 'off').toLowerCase(), // 'off' | 'on'
  appleBundleId: process.env.APPLE_BUNDLE_ID || 'com.carlapp.Carl',
  appleRootCert: loadRootCert(),
};

function loadRootCert() {
  const path = process.env.APPLE_ROOT_CA_PATH || join(root, 'certs', 'AppleRootCA-G3.pem');
  try { return readFileSync(path, 'utf8'); } catch { return ''; }
}

export const hasLLM = !!config.anthropicKey;
export const hasAdzuna = !!(config.adzunaAppId && config.adzunaAppKey);
export const hasUSAJobs = !!config.usajobsKey;
export const hasATS = config.atsEnabled;
