// Free public-ATS job discovery — REAL listings, no API key, no commercial deal.
//
// Reads the public job-board JSON that Greenhouse, Lever and Ashby expose for
// each company token (see ../data/boards.js), normalises everything into Carl's
// job shape, and keeps roles that fit the user's target title + launch market
// (US/Canada). Greenhouse & Lever carry the structured ids their apply adapters
// need, so those jobs are Tier A (auto-apply); Ashby is Tier B (1-tap).
import { fetchJSON, uid } from '../util.js';
import { ATS_BOARDS } from '../data/boards.js';

const PER_BOARD_CAP = 100; // keep one giant board from dominating the results
const CACHE_TTL_MS = 10 * 60 * 1000; // re-fetch a board at most every 10 min
const boardCache = new Map(); // url -> { at, jobs }

// Title words that describe seniority/structure, not the role itself.
const STOP = new Set([
  'senior', 'junior', 'mid', 'staff', 'lead', 'principal', 'sr', 'jr',
  'i', 'ii', 'iii', 'the', 'of', 'and', 'a', 'an',
]);

// Locations that are clearly outside the US/Canada launch market.
const NON_NA = [
  /\bunited kingdom\b/, /\blondon\b/, /\bengland\b/, /\bireland\b/, /\bdublin\b/,
  /\bindia\b/, /\bbangalore\b/, /\bbengaluru\b/, /\bhyderabad\b/, /\bpune\b/,
  /\bgermany\b/, /\bberlin\b/, /\bmunich\b/, /\bfrance\b/, /\bparis\b/,
  /\bspain\b/, /\bmadrid\b/, /\bnetherlands\b/, /\bamsterdam\b/, /\bpoland\b/,
  /\bsingapore\b/, /\baustralia\b/, /\bsydney\b/, /\bjapan\b/, /\btokyo\b/,
  /\bbrazil\b/, /\bmexico\b/, /\beurope\b/, /\bemea\b/, /\bapac\b/, /\b(uk|eu)\b/,
];

/**
 * Search every seeded board in parallel and return normalised, market-filtered
 * jobs plus a per-source count. Network failures degrade to an empty list.
 */
export async function searchATS(prefs, boards = ATS_BOARDS) {
  const tasks = [];
  for (const token of boards.greenhouse || []) tasks.push(fetchBoard('greenhouse', token));
  for (const token of boards.lever || []) tasks.push(fetchBoard('lever', token));
  for (const token of boards.ashby || []) tasks.push(fetchBoard('ashby', token));

  const settled = await Promise.all(tasks);
  const jobs = filterJobs(settled.flat(), prefs);
  return { jobs, sources: countBySource(jobs) };
}

async function fetchBoard(provider, token) {
  const url = boardURL(provider, token);
  const hit = boardCache.get(url);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.jobs;

  const { ok, json } = await fetchJSON(url);
  if (!ok) return []; // don't cache failures — a board may just be slow right now
  let jobs = [];
  try {
    if (provider === 'greenhouse') jobs = mapGreenhouse(token, json);
    else if (provider === 'lever') jobs = mapLever(token, json);
    else if (provider === 'ashby') jobs = mapAshby(token, json);
  } catch { /* malformed board payload — skip */ }
  boardCache.set(url, { at: Date.now(), jobs });
  return jobs;
}

function boardURL(provider, token) {
  if (provider === 'greenhouse') return `https://boards-api.greenhouse.io/v1/boards/${token}/jobs?content=true`;
  if (provider === 'lever') return `https://api.lever.co/v0/postings/${token}?mode=json`;
  return `https://api.ashbyhq.com/posting-api/job-board/${token}?includeCompensation=true`;
}

// MARK: normalisers (pure — exported for tests)

export function mapGreenhouse(token, json) {
  if (!Array.isArray(json?.jobs)) return [];
  const company = companyName(token);
  return json.jobs.slice(0, PER_BOARD_CAP).map((j) =>
    normalize({
      source: 'greenhouse', sourceName: 'Greenhouse', tier: 'A',
      externalId: String(j.id), title: j.title, company,
      location: j.location?.name || '',
      description: stripHTML(j.content),
      applyUrl: j.absolute_url,
      greenhouse: { boardToken: token, jobId: String(j.id) },
    }),
  );
}

export function mapLever(token, json) {
  if (!Array.isArray(json)) return [];
  const company = companyName(token);
  return json.slice(0, PER_BOARD_CAP).map((p) => {
    const cat = p.categories || {};
    const pay = leverPay(p.salaryRange);
    return normalize({
      source: 'lever', sourceName: 'Lever', tier: 'A',
      externalId: String(p.id), title: p.text, company,
      location: cat.location || (cat.allLocations || [])[0] || '',
      remoteHint: /remote/i.test(cat.workplaceType || ''),
      description: p.descriptionPlain || stripHTML(p.description),
      applyUrl: p.hostedUrl || p.applyUrl,
      payText: pay.text, payFloor: pay.floor, country: p.country,
      lever: { site: token, postingId: String(p.id) },
    });
  });
}

export function mapAshby(token, json) {
  if (!Array.isArray(json?.jobs)) return [];
  const company = companyName(token);
  return json.jobs.slice(0, PER_BOARD_CAP).map((j) => {
    const pay = ashbyPay(j.compensation);
    return normalize({
      source: 'ashby', sourceName: 'Ashby', tier: 'B',
      externalId: String(j.id), title: j.title, company,
      location: j.location || j.address?.postalAddress?.addressLocality || '',
      remoteHint: j.isRemote === true,
      description: j.descriptionPlain || stripHTML(j.descriptionHtml),
      applyUrl: j.applyUrl || j.jobUrl,
      payText: pay.text, payFloor: pay.floor,
    });
  });
}

function normalize(o) {
  const title = cleanTitle(o.title);
  const remoteType = detectRemote(o.location, o.remoteHint, title);
  return {
    id: uid('job'),
    source: o.source,
    sourceName: o.sourceName,
    externalId: o.externalId,
    title,
    company: o.company,
    avatarColor: o.source, // 'greenhouse' | 'lever' | 'ashby' map to brand colors
    location: o.location || (remoteType === 'remote' ? 'Remote' : ''),
    remoteType,
    payText: o.payText || '',
    payFloor: o.payFloor || 0,
    descriptionSnippet: (o.description || '').replace(/\s+/g, ' ').trim().slice(0, 240),
    applyTier: o.tier,
    applyUrl: o.applyUrl || '',
    country: o.country,
    greenhouse: o.greenhouse,
    lever: o.lever,
    dedupeKey: `${o.company}|${title}`.toLowerCase(),
  };
}

// MARK: filtering (pure — exported for tests)

export function filterJobs(jobs, prefs) {
  const kw = titleKeywords(prefs);
  return jobs.filter((j) => titleMatches(j.title, kw)).filter((j) => marketOk(j));
}

export function titleKeywords(prefs) {
  const raw = (prefs?.titles?.[0] || prefs?.targetRole || '').toLowerCase();
  const words = raw.split(/[^a-z0-9+]+/).filter((w) => w && !STOP.has(w));
  return { primary: words[words.length - 1] || '', all: words };
}

export function titleMatches(title, kw) {
  if (!kw.primary) return true; // no target title yet — keep everything
  return (title || '').toLowerCase().includes(kw.primary);
}

export function marketOk(job) {
  const loc = (job.location || '').toLowerCase();
  if (!loc) return true; // unknown location — keep (often remote)
  if (job.country && !['US', 'CA'].includes(String(job.country).toUpperCase())) return false;
  return !NON_NA.some((re) => re.test(loc));
}

// MARK: small helpers

function detectRemote(location, hint, title) {
  const s = `${location} ${title}`.toLowerCase();
  if (hint === true || /remote|anywhere|distributed/.test(s)) return 'remote';
  if (/hybrid/.test(s)) return 'hybrid';
  return 'onsite';
}

function leverPay(r) {
  if (!r || !r.min || r.min < 1000) return { text: '', floor: 0 }; // skip hourly/empty
  const k = (n) => Math.round(n / 1000);
  const floor = k(r.min);
  return { text: `$${floor}–${k(r.max || r.min)}k`, floor };
}

function ashbyPay(c) {
  const summary = c?.compensationTierSummary || c?.summary || '';
  if (!summary) return { text: '', floor: 0 };
  const m = summary.match(/\$?\s*([\d.]+)\s*[kK]/);
  return { text: summary.replace(/\s+/g, ' ').trim(), floor: m ? Math.round(Number(m[1])) : 0 };
}

function stripHTML(s) {
  return (s || '')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>') // decode encoded tags (Greenhouse) first
    .replace(/<[^>]+>/g, ' ') // then strip real tags
    .replace(/&amp;/g, '&')
    .replace(/&#39;|&rsquo;|&lsquo;|&apos;/g, "'").replace(/&quot;|&ldquo;|&rdquo;/g, '"')
    .replace(/&nbsp;/g, ' ').replace(/&[a-z]+;/g, ' ');
}

function cleanTitle(s) {
  return (s || '').replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}

function companyName(token) {
  return token.split(/[-_]/).map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

function countBySource(jobs) {
  const m = new Map();
  for (const j of jobs) m.set(j.sourceName, (m.get(j.sourceName) || 0) + 1);
  return [...m.entries()].map(([name, found]) => ({ name, found }));
}
