// Adzuna job-search adapter (discovery only — Adzuna has no apply endpoint).
// Docs: https://developer.adzuna.com
import { config } from '../config.js';
import { fetchJSON, uid } from '../util.js';

const COUNTRY = { us: 'us', ca: 'ca', uk: 'gb', au: 'au' };

export async function searchAdzuna(prefs) {
  const country = COUNTRY[(prefs?.country || 'us').toLowerCase()] || 'us';
  const what = encodeURIComponent(prefs?.titles?.[0] || prefs?.targetRole || 'product designer');
  const where = encodeURIComponent(prefs?.location || '');
  const url = `https://api.adzuna.com/v1/api/jobs/${country}/search/1`
    + `?app_id=${config.adzunaAppId}&app_key=${config.adzunaAppKey}`
    + `&results_per_page=50&what=${what}${where ? `&where=${where}` : ''}&content-type=application/json`;

  const { ok, json } = await fetchJSON(url);
  if (!ok || !json?.results) return [];

  return json.results.map((r) => ({
    id: uid('job'),
    source: 'adzuna',
    sourceName: 'Adzuna',
    externalId: String(r.id),
    title: r.title?.replace(/<\/?[^>]+>/g, '') || 'Role',
    company: r.company?.display_name || 'Company',
    avatarColor: 'navy',
    location: r.location?.display_name || '',
    remoteType: /remote/i.test(r.title || '') ? 'remote' : 'onsite',
    payText: r.salary_min ? `$${Math.round(r.salary_min / 1000)}–${Math.round((r.salary_max || r.salary_min) / 1000)}k` : '',
    payFloor: r.salary_min ? Math.round(r.salary_min / 1000) : 0,
    descriptionSnippet: (r.description || '').slice(0, 240),
    // Adzuna only links out; the underlying ATS determines the real apply tier.
    applyTier: 'B',
    applyUrl: r.redirect_url,
    dedupeKey: `${r.company?.display_name || ''}|${r.title || ''}`.toLowerCase(),
  }));
}
