// USAJOBS search adapter (US federal listings, discovery only).
// Docs: https://developer.usajobs.gov
import { config } from '../config.js';
import { fetchJSON, uid } from '../util.js';

export async function searchUSAJobs(prefs) {
  if (!config.usajobsKey) return [];
  const keyword = encodeURIComponent(prefs?.titles?.[0] || prefs?.targetRole || 'designer');
  const url = `https://data.usajobs.gov/api/search?Keyword=${keyword}&ResultsPerPage=25`;

  const { ok, json } = await fetchJSON(url, {
    headers: {
      'Authorization-Key': config.usajobsKey,
      'User-Agent': config.usajobsEmail || 'carl-app',
      Host: 'data.usajobs.gov',
    },
  });
  const items = json?.SearchResult?.SearchResultItems || [];
  if (!ok || !items.length) return [];

  return items.map((it) => {
    const d = it.MatchedObjectDescriptor || {};
    const pay = d.PositionRemuneration?.[0];
    return {
      id: uid('job'),
      source: 'usajobs',
      sourceName: 'USAJOBS',
      externalId: String(d.PositionID || it.MatchedObjectId),
      title: d.PositionTitle || 'Federal role',
      company: d.OrganizationName || 'US Government',
      avatarColor: 'navy',
      location: d.PositionLocationDisplay || 'United States',
      remoteType: 'onsite',
      payText: pay ? `$${Math.round(Number(pay.MinimumRange) / 1000)}–${Math.round(Number(pay.MaximumRange) / 1000)}k` : '',
      payFloor: pay ? Math.round(Number(pay.MinimumRange) / 1000) : 0,
      descriptionSnippet: (d.UserArea?.Details?.JobSummary || d.QualificationSummary || '').slice(0, 240),
      applyTier: 'B', // application completes on USAJOBS.gov
      applyUrl: d.ApplyURI?.[0] || d.PositionURI,
      dedupeKey: `${d.OrganizationName || ''}|${d.PositionTitle || ''}`.toLowerCase(),
    };
  });
}
