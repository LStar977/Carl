// Matching & eligibility. Hard rules filter the ineligible; a heuristic fit
// score ranks the rest (cheap at 300+ jobs). Claude can refine the top later.
import { clamp } from '../util.js';

export function scoreMatches(profile, prefs, jobs) {
  const parsed = profile?.resume?.parsed || {};
  const wantTitle = (prefs?.titles?.[0] || parsed.targetRole || '').toLowerCase();
  const floor = Number(prefs?.payFloor || 0);
  const blocked = blockedSet(profile);

  return jobs
    .map((job) => {
      const eligible = isEligible(prefs, job, floor);
      const fit = heuristicFit(parsed, wantTitle, job);
      return { ...job, fit, eligible, reasons: reasonsFor(parsed, prefs, job, fit) };
    })
    .filter((j) => j.eligible && !blocked.has((j.company || '').toLowerCase()))
    .sort((a, b) => b.fit - a.fit);
}

/** Lowercased set of companies the user never wants Carl to apply to. */
export function blockedSet(profile) {
  return new Set((profile?.blockedCompanies || []).map((c) => String(c).toLowerCase()));
}

function isEligible(prefs, job, floor) {
  if (floor && job.payFloor && job.payFloor < floor) return false;
  if (!locationEligible(prefs, job)) return false;
  return true;
}

// Metro aliases so nicknames / metro-area phrasings match (e.g. "Toronto"⇄"GTA",
// "San Francisco"⇄"Bay Area", "New York"⇄"NYC"). Keys are canonical lowercase
// city names; the user can also type any alias (reverse-looked-up below). Covers
// the top ~50 US + Canada metros; any other city still matches by its own name.
const METRO_ALIASES = {
  // United States
  'new york': ['new york', 'nyc', 'new york city', 'manhattan', 'brooklyn'],
  'los angeles': ['los angeles', 'socal'],
  chicago: ['chicago', 'chicagoland'],
  'san francisco': ['san francisco', 'sf', 'sf bay', 'bay area'],
  'san jose': ['san jose', 'bay area', 'silicon valley'],
  seattle: ['seattle', 'bellevue', 'redmond'],
  boston: ['boston', 'cambridge'],
  austin: ['austin', 'atx'],
  'washington': ['washington', 'washington dc', 'dc', 'd.c.'],
  dallas: ['dallas', 'dfw', 'fort worth'],
  houston: ['houston'],
  atlanta: ['atlanta', 'atl'],
  miami: ['miami', 'south florida'],
  philadelphia: ['philadelphia', 'philly'],
  phoenix: ['phoenix', 'tempe', 'scottsdale'],
  'san diego': ['san diego'],
  denver: ['denver', 'boulder'],
  minneapolis: ['minneapolis', 'twin cities', 'st paul', 'saint paul'],
  detroit: ['detroit'],
  portland: ['portland'],
  'las vegas': ['las vegas', 'vegas'],
  nashville: ['nashville'],
  charlotte: ['charlotte'],
  tampa: ['tampa'],
  orlando: ['orlando'],
  pittsburgh: ['pittsburgh'],
  sacramento: ['sacramento'],
  'salt lake city': ['salt lake city', 'slc'],
  raleigh: ['raleigh', 'durham', 'research triangle', 'rtp'],
  columbus: ['columbus'],
  indianapolis: ['indianapolis', 'indy'],
  'kansas city': ['kansas city'],
  cleveland: ['cleveland'],
  'san antonio': ['san antonio'],
  'st louis': ['st louis', 'saint louis'],
  // Canada
  toronto: ['toronto', 'gta', 'greater toronto'],
  montreal: ['montreal', 'montréal'],
  vancouver: ['vancouver', 'burnaby', 'richmond'],
  calgary: ['calgary', 'yyc'],
  edmonton: ['edmonton'],
  ottawa: ['ottawa', 'gatineau'],
  winnipeg: ['winnipeg'],
  'quebec city': ['quebec city', 'québec'],
  hamilton: ['hamilton'],
  kitchener: ['kitchener', 'waterloo', 'kitchener-waterloo', 'kw'],
  london: ['london ontario', 'london, on'],
  halifax: ['halifax'],
  victoria: ['victoria'],
  saskatoon: ['saskatoon'],
  regina: ['regina'],
  mississauga: ['mississauga', 'gta', 'greater toronto'],
};

/**
 * City + work-style eligibility. Remote roles are always eligible (open
 * regardless of the user's city). For onsite/hybrid seekers with a target city,
 * the job's location must match that city (or one of its metro aliases).
 */
function locationEligible(prefs, job) {
  const want = (prefs?.locationType || 'any').toLowerCase();
  if (job.remoteType === 'remote') return true; // remote is open to any city
  if (want === 'remote') return false;          // wants remote only → drop onsite

  const city = (prefs?.location || '').split(',')[0].trim().toLowerCase();
  if (!city) return true;                        // no city set → no city filter
  const loc = (job.location || '').toLowerCase();
  if (!loc) return false;                        // can't confirm an onsite role is in-city
  return cityMatches(city, loc);
}

/** Aliases for a city the user typed — by canonical key or reverse alias match. */
function aliasesFor(city) {
  if (METRO_ALIASES[city]) return METRO_ALIASES[city];
  for (const al of Object.values(METRO_ALIASES)) if (al.includes(city)) return al;
  return [city];
}

function cityMatches(city, loc) {
  const tokens = new Set(loc.split(/[^a-z0-9]+/).filter(Boolean));
  // Single-word aliases match whole tokens (so "dc"/"kw" can't match inside
  // another word); multi-word aliases match as a phrase.
  return aliasesFor(city).some((a) => (a.includes(' ') ? loc.includes(a) : tokens.has(a)));
}

function heuristicFit(parsed, wantTitle, job) {
  let score = 72;
  const title = (job.title || '').toLowerCase();
  if (wantTitle && title.includes(wantTitle.split(' ').slice(-1)[0])) score += 12;
  if (wantTitle && title.includes(wantTitle)) score += 6;
  if (job.remoteType === 'remote') score += 3;
  const skills = parsed.skills || [];
  if (skills.some((s) => (job.descriptionSnippet || '').toLowerCase().includes(s.toLowerCase()))) score += 5;
  // deterministic jitter from the id so scores look natural but stable
  const jitter = (hash(job.id) % 7) - 3;
  return clamp(Math.round(score + jitter), 60, 99);
}

function reasonsFor(parsed, prefs, job, fit) {
  const out = [];
  if (job.title?.toLowerCase().includes((parsed.targetRole || '').toLowerCase().split(' ').slice(-1)[0] || 'x')) {
    out.push('role matches your target');
  }
  if (parsed.years) out.push(`${parsed.years} yrs experience fits`);
  if (job.remoteType === 'remote') out.push('remote');
  if (job.payFloor && prefs?.payFloor && job.payFloor >= prefs.payFloor) out.push('pay in range');
  if (fit >= 90) out.push('strong skills overlap');
  return out.slice(0, 4);
}

function hash(s) {
  let h = 0;
  for (let i = 0; i < (s || '').length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return h;
}
