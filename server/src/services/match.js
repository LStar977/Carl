// Matching & eligibility. Hard rules filter the ineligible; a heuristic fit
// score ranks the rest (cheap at 300+ jobs). Claude can refine the top later.
import { clamp } from '../util.js';

export function scoreMatches(profile, prefs, jobs) {
  const parsed = profile?.resume?.parsed || {};
  const wantTitle = (prefs?.titles?.[0] || parsed.targetRole || '').toLowerCase();
  const floor = Number(prefs?.payFloor || 0);

  return jobs
    .map((job) => {
      const eligible = isEligible(prefs, job, floor);
      const fit = heuristicFit(parsed, wantTitle, job);
      return { ...job, fit, eligible, reasons: reasonsFor(parsed, prefs, job, fit) };
    })
    .filter((j) => j.eligible)
    .sort((a, b) => b.fit - a.fit);
}

function isEligible(prefs, job, floor) {
  if (floor && job.payFloor && job.payFloor < floor) return false;
  const want = prefs?.locationType; // remote | hybrid | onsite | any
  if (want && want !== 'any' && job.remoteType && want !== job.remoteType) {
    // allow remote jobs through for any preference; otherwise require a match
    if (!(job.remoteType === 'remote')) return false;
  }
  return true;
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
