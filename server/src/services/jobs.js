// Job discovery: aggregate real sources when available, otherwise mock.
import { hasATS, hasAdzuna, hasUSAJobs } from '../config.js';
import { searchATS } from '../adapters/ats.js';
import { searchAdzuna } from '../adapters/adzuna.js';
import { searchUSAJobs } from '../adapters/usajobs.js';
import { generateMockJobs, mockSourceCounts } from '../data/mock.js';

export async function searchJobs(prefs) {
  let jobs = [];
  const sources = [];

  // Free, real listings from public ATS boards — no key, no commercial deal.
  // Runs first so its Tier-A (auto-appliable) copies win de-duplication.
  if (hasATS) {
    const { jobs: atsJobs, sources: atsSources } = await searchATS(prefs);
    jobs = jobs.concat(atsJobs);
    sources.push(...atsSources);
  }
  if (hasAdzuna) {
    const a = await searchAdzuna(prefs);
    jobs = jobs.concat(a);
    sources.push({ name: 'Adzuna', found: a.length });
  }
  if (hasUSAJobs) {
    const u = await searchUSAJobs(prefs);
    jobs = jobs.concat(u);
    sources.push({ name: 'USAJOBS', found: u.length });
  }

  // Fall back to the mock universe if no real source returned anything.
  if (jobs.length === 0) {
    jobs = generateMockJobs(prefs, 312);
    sources.push(...mockSourceCounts());
  }

  return { jobs: dedupe(jobs), sources };
}

function dedupe(jobs) {
  const seen = new Set();
  return jobs.filter((j) => {
    const key = j.dedupeKey || `${j.company}|${j.title}`.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    // Prefer the Tier-A (auto-appliable) copy when the same job appears twice.
    return true;
  });
}
