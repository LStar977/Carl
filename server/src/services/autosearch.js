// Automatic + on-demand "find new jobs": re-runs a user's search, adds only
// genuinely new matches to their queue (deduped against everything already
// matched or applied), and logs an activity. The scheduler runs this for every
// set-up user on an interval — "Carl works while you sleep" — while the manual
// "Find more jobs" button calls findNewMatches for one user.
//
// It only FINDS; nothing is auto-submitted, so the "a credit is only spent when
// you confirm" promise holds — new matches land in the review queue.
import { config } from '../config.js';
import { store } from '../store.js';
import { searchJobs } from './jobs.js';
import { scoreMatches } from './match.js';
import { uid, nowISO } from '../util.js';

const keyOf = (job) => (job.dedupeKey || `${job.company}|${job.title}`).toLowerCase();
const MAX_NEW = 12;

/** Add up to MAX_NEW brand-new matches for one user. Returns how many were added. */
export async function findNewMatches(user) {
  const profile = store.getProfile(user.id);
  if (!profile) return 0;
  const prefs = { ...(profile.prefs || {}), targetRole: profile.resume?.parsed?.targetRole };

  const { jobs } = await searchJobs(prefs);
  const scored = scoreMatches(profile, prefs, jobs);

  // Everything already matched (incl. applied) so we never resurface a job.
  const seen = new Set(store.getMatches(user.id).map((m) => keyOf(m.job)));
  const fresh = [];
  for (const j of scored) {
    const k = keyOf(j);
    if (seen.has(k)) continue;
    seen.add(k);
    fresh.push(j);
    if (fresh.length >= MAX_NEW) break;
  }
  if (fresh.length === 0) return 0;

  const newMatches = fresh.map((j) => ({ id: uid('match'), status: 'suggested', fit: j.fit, reasons: j.reasons, job: j }));
  store.setMatches(user.id, [...newMatches, ...store.getMatches(user.id)]);
  store.addActivity(user.id, {
    id: uid('act'), type: 'found', dot: 'royal',
    text: `Carl found ${fresh.length} new ${fresh.length === 1 ? 'match' : 'matches'}`, ts: nowISO(),
  });
  return fresh.length;
}

let running = false;
export async function runAutoSearchOnce() {
  if (running) return;
  running = true;
  try {
    for (const user of store.allUsers()) {
      const profile = store.getProfile(user.id);
      if (!profile?.prefs || !profile?.resume) continue; // only users who finished setup
      try { await findNewMatches(user); } catch (e) { console.warn(`autosearch ${user.id}: ${e.message}`); }
    }
  } finally {
    running = false;
  }
}

export function startAutoSearchSchedule() {
  if (!config.autoSearchEnabled) return;
  const timer = setInterval(
    () => runAutoSearchOnce().catch((e) => console.warn(`autosearch failed: ${e.message}`)),
    config.autoSearchIntervalHours * 3600 * 1000,
  );
  timer.unref?.();
}
