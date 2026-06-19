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

  applyMode: (process.env.APPLY_MODE || 'dry-run').toLowerCase(),
  freeCredits: Number(process.env.FREE_CREDITS || 3),
};

export const hasLLM = !!config.anthropicKey;
export const hasAdzuna = !!(config.adzunaAppId && config.adzunaAppKey);
export const hasUSAJobs = !!config.usajobsKey;
