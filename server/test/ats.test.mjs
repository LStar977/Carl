// Unit tests for the free public-ATS adapter (no network): verify each provider
// payload normalises into Carl's job shape, that Tier-A jobs carry their apply
// ids, and that title + US/Canada market filtering behave.
import assert from 'node:assert/strict';
import { mapGreenhouse, mapLever, mapAshby, filterJobs, titleMatches, marketOk, titleKeywords } from '../src/adapters/ats.js';

let n = 0;
const ok = (cond, msg) => { assert.ok(cond, msg); console.log(`  ok ${++n} - ${msg}`); };

// --- Greenhouse (Tier A) -----------------------------------------------------
const gh = mapGreenhouse('figma', {
  jobs: [{
    id: 12345, title: 'Senior Product Designer',
    location: { name: 'San Francisco, CA' },
    content: '&lt;p&gt;Design systems &amp; prototyping.&lt;/p&gt;',
    absolute_url: 'https://boards.greenhouse.io/figma/jobs/12345',
  }],
});
ok(gh.length === 1, 'greenhouse maps one job');
ok(gh[0].source === 'greenhouse' && gh[0].applyTier === 'A', 'greenhouse is Tier A');
ok(gh[0].company === 'Figma', 'company derived from token');
ok(gh[0].greenhouse?.boardToken === 'figma' && gh[0].greenhouse.jobId === '12345', 'carries greenhouse apply ids');
ok(!/[<>]|&lt;|&gt;/.test(gh[0].descriptionSnippet) && /Design systems & prototyping/.test(gh[0].descriptionSnippet), 'html stripped + entities decoded');

// --- Lever (Tier A) ----------------------------------------------------------
const lv = mapLever('netflix', [{
  id: 'abc-123', text: 'Staff Product Designer',
  categories: { location: 'Remote - US', commitment: 'Full-time' },
  descriptionPlain: 'Own design end to end.',
  hostedUrl: 'https://jobs.lever.co/netflix/abc-123',
  salaryRange: { min: 170000, max: 200000, currency: 'USD' },
  country: 'US',
}]);
ok(lv.length === 1 && lv[0].applyTier === 'A', 'lever is Tier A');
ok(lv[0].lever?.site === 'netflix' && lv[0].lever.postingId === 'abc-123', 'carries lever apply ids');
ok(lv[0].payFloor === 170 && lv[0].payText === '$170–200k', 'lever salary parsed to k');
ok(lv[0].remoteType === 'remote', 'lever remote detected from location');

// --- Ashby (Tier B) ----------------------------------------------------------
const ab = mapAshby('ramp', {
  jobs: [{
    id: 'job_9', title: 'Product Designer', location: 'New York',
    isRemote: false, descriptionPlain: 'Craft-focused team.',
    jobUrl: 'https://jobs.ashbyhq.com/ramp/job_9',
    compensation: { compensationTierSummary: '$150K – $185K' },
  }],
});
ok(ab.length === 1 && ab[0].applyTier === 'B', 'ashby is Tier B (assisted)');
ok(ab[0].payFloor === 150, 'ashby compensation summary parsed');
ok(ab[0].greenhouse === undefined && ab[0].lever === undefined, 'ashby carries no auto-apply ids');

// --- Title filtering ---------------------------------------------------------
const kw = titleKeywords({ titles: ['Product Designer'] });
ok(kw.primary === 'designer', 'primary keyword is the role noun');
ok(titleMatches('Senior Product Designer', kw) === true, 'matching title kept');
ok(titleMatches('Backend Engineer', kw) === false, 'off-target title dropped');
ok(titleMatches('anything', { primary: '' }) === true, 'no target title keeps everything');

// "Product Manager" should match PRODUCT roles, not every "Manager"
const kwPM = titleKeywords({ titles: ['Product Manager'] });
ok(kwPM.primary === 'product', 'generic "manager" suffix dropped; primary is "product"');
ok(titleMatches('Senior Product Manager', kwPM) === true, 'product manager kept');
ok(titleMatches('Group Product Lead', kwPM) === true, 'product lead kept');
ok(titleMatches('Engineering Manager', kwPM) === false, 'unrelated manager dropped');
ok(titleMatches('Account Manager', kwPM) === false, 'account manager dropped');
// Multi-word roles cast a wider, relevant net (OR over domain words)
const kwGM = titleKeywords({ titles: ['Growth Marketing'] });
ok(titleMatches('Head of Growth', kwGM) === true, 'growth role kept via "growth"');
ok(titleMatches('Content Marketing Manager', kwGM) === true, 'marketing role kept via "marketing"');
ok(titleMatches('Backend Engineer', kwGM) === false, 'unrelated role dropped');
// Multiple chosen role fields aggregate across all of them
const kwMulti = titleKeywords({ titles: ['Product Manager', 'Marketing', 'Sales'] });
ok(kwMulti.all.includes('product') && kwMulti.all.includes('marketing') && kwMulti.all.includes('sales'),
   'keywords aggregate across all chosen roles');
ok(titleMatches('Senior Product Manager', kwMulti) === true, 'multi: product role kept');
ok(titleMatches('Field Marketing Lead', kwMulti) === true, 'multi: marketing role kept');
ok(titleMatches('Account Executive (Sales)', kwMulti) === true, 'multi: sales role kept');
ok(titleMatches('Backend Engineer', kwMulti) === false, 'multi: unrelated role dropped');

// --- Market filtering (US/Canada) -------------------------------------------
ok(marketOk({ location: 'Toronto, Canada' }) === true, 'canada kept');
ok(marketOk({ location: 'Austin, TX' }) === true, 'us kept');
ok(marketOk({ location: '' }) === true, 'unknown location kept (often remote)');
ok(marketOk({ location: 'London, United Kingdom' }) === false, 'uk dropped');
ok(marketOk({ location: 'Remote', country: 'IN' }) === false, 'foreign country signal dropped');

// --- End-to-end filter pass --------------------------------------------------
const mixed = [...gh, ...lv, ...ab,
  ...mapGreenhouse('acme', { jobs: [{ id: 1, title: 'Sales Manager', location: { name: 'Berlin, Germany' }, content: '', absolute_url: '' }] }),
];
const filtered = filterJobs(mixed, { titles: ['Product Designer'] });
ok(filtered.length === 3, 'filter keeps the 3 designer roles, drops off-target + foreign');

// --- City filtering (via match.scoreMatches) --------------------------------
const { scoreMatches } = await import('../src/services/match.js');
const cityJobs = [
  { id: 'j1', title: 'Product Designer', location: 'Toronto, ON', remoteType: 'onsite', payFloor: 0 },
  { id: 'j2', title: 'Product Designer', location: 'GTA', remoteType: 'onsite', payFloor: 0 },
  { id: 'j3', title: 'Product Designer', location: 'Austin, TX', remoteType: 'onsite', payFloor: 0 },
  { id: 'j4', title: 'Product Designer', location: 'Remote - Canada', remoteType: 'remote', payFloor: 0 },
];
const torontoOnsite = scoreMatches({}, { titles: ['Product Designer'], location: 'Toronto', locationType: 'onsite' }, cityJobs);
ok(torontoOnsite.some((j) => j.id === 'j1'), 'onsite Toronto kept');
ok(torontoOnsite.some((j) => j.id === 'j2'), 'GTA alias matches Toronto');
ok(!torontoOnsite.some((j) => j.id === 'j3'), 'Austin onsite dropped for Toronto seeker');
ok(torontoOnsite.some((j) => j.id === 'j4'), 'remote-Canada always eligible');

const torontoRemote = scoreMatches({}, { location: 'Toronto', locationType: 'remote' }, cityJobs);
ok(torontoRemote.length === 1 && torontoRemote[0].id === 'j4', 'remote-only seeker gets only remote');

// --- Work-authorization steering (Canada-only seeker) -----------------------
const authJobs = [
  { id: 'a_ca', title: 'Product Designer', location: 'Toronto, ON', country: 'CA', remoteType: 'onsite', payFloor: 0 },
  { id: 'a_us', title: 'Product Designer', location: 'Austin, TX', country: 'US', remoteType: 'onsite', payFloor: 0 },
  { id: 'a_usr', title: 'Product Designer', location: 'Remote - US', country: 'US', remoteType: 'remote', payFloor: 0 },
  { id: 'a_ww', title: 'Product Designer', location: 'Remote', remoteType: 'remote', payFloor: 0 },
];
const caOnly = { eligibility: { authorizedCA: true, authorizedUS: false } };
const caRes = scoreMatches(caOnly, { titles: ['Product Designer'], locationType: 'any' }, authJobs).map((j) => j.id);
ok(caRes.includes('a_ca'), 'Canada-only: Canadian role kept');
ok(!caRes.includes('a_us') && !caRes.includes('a_usr'), 'Canada-only: US roles (incl US-remote) dropped');
ok(caRes.includes('a_ww'), 'Canada-only: worldwide remote kept');
const bothAuth = { eligibility: { authorizedCA: true, authorizedUS: true } };
ok(scoreMatches(bothAuth, { titles: ['Product Designer'], locationType: 'any' }, authJobs).length === 4,
   'authorized in both: nothing filtered');

// --- Multi-city: open to several cities + remote ----------------------------
const multiJobs = [
  { id: 'm_yyc', title: 'Product Designer', location: 'Calgary, AB', remoteType: 'onsite', payFloor: 0 },
  { id: 'm_van', title: 'Product Designer', location: 'Vancouver, BC', remoteType: 'onsite', payFloor: 0 },
  { id: 'm_tor', title: 'Product Designer', location: 'Toronto, ON', remoteType: 'onsite', payFloor: 0 },
  { id: 'm_aus', title: 'Product Designer', location: 'Austin, TX', remoteType: 'onsite', payFloor: 0 },
  { id: 'm_rus', title: 'Product Designer', location: 'Remote - US', remoteType: 'remote', country: 'US', payFloor: 0 },
  { id: 'm_rca', title: 'Product Designer', location: 'Remote - Canada', remoteType: 'remote', country: 'CA', payFloor: 0 },
];
const openTo = scoreMatches(
  {},
  { titles: ['Product Designer'], locations: ['Calgary', 'Vancouver', 'Toronto'], locationType: 'any' },
  multiJobs,
).map((j) => j.id);
ok(openTo.includes('m_yyc') && openTo.includes('m_van') && openTo.includes('m_tor'), 'all three wanted cities kept');
ok(!openTo.includes('m_aus'), 'a city not on the list (Austin) is dropped');
ok(openTo.includes('m_rus') && openTo.includes('m_rca'), 'remote roles eligible when not onsite-only');

// remote scoping: "remote in the US only"
const usRemoteOnly = scoreMatches(
  {},
  { titles: ['Product Designer'], locations: ['Calgary'], locationType: 'any', remoteCountries: ['US'] },
  multiJobs,
).map((j) => j.id);
ok(usRemoteOnly.includes('m_rus'), 'US remote kept under US remote scope');
ok(!usRemoteOnly.includes('m_rca'), 'Canada remote dropped under US-only remote scope');
ok(usRemoteOnly.includes('m_yyc'), 'home city (Calgary) still kept alongside remote scope');

// --- Expanded metro matching (top ~50 metros) -------------------------------
const metroJobs = [
  { id: 'sf1', title: 'Product Designer', location: 'San Francisco, CA', remoteType: 'onsite', payFloor: 0 },
  { id: 'ba1', title: 'Product Designer', location: 'Bay Area', remoteType: 'onsite', payFloor: 0 },
  { id: 'dc1', title: 'Product Designer', location: 'Washington, DC', remoteType: 'onsite', payFloor: 0 },
  { id: 'atl', title: 'Product Designer', location: 'Atlanta, GA', remoteType: 'onsite', payFloor: 0 },
];
const pick = (loc) => scoreMatches({}, { titles: ['Product Designer'], location: loc, locationType: 'onsite' }, metroJobs).map((j) => j.id);
ok(pick('San Francisco').includes('sf1') && pick('San Francisco').includes('ba1'), 'San Francisco matches city + "Bay Area"');
ok(pick('sf').includes('sf1'), 'nickname "sf" reverse-maps to San Francisco');
ok(pick('gta')?.length === 0, 'unrelated metro (gta) matches none of these');
ok(pick('Washington').includes('dc1'), 'Washington matches "Washington, DC"');
ok(!pick('la').includes('atl'), 'token-safe: "la" does NOT false-match inside "Atlanta"');

// --- Ingestion index: searchJobs prefers the index when populated -----------
const { store } = await import('../src/store.js');
const { searchJobs } = await import('../src/services/jobs.js');

const indexJobs = [
  { id: 'i1', title: 'Senior Product Designer', company: 'Acme', location: 'Toronto, ON', remoteType: 'onsite', payFloor: 0, sourceName: 'Greenhouse' },
  { id: 'i2', title: 'Backend Engineer', company: 'Acme', location: 'Toronto, ON', remoteType: 'onsite', payFloor: 0, sourceName: 'Greenhouse' },
  { id: 'i3', title: 'Product Designer', company: 'Beta', location: 'Remote - Canada', remoteType: 'remote', payFloor: 0, sourceName: 'Lever' },
];
store.setJobIndex(indexJobs, { at: 'now', count: 3, sources: [{ name: 'Greenhouse', found: 2 }, { name: 'Lever', found: 1 }] });

const res = await searchJobs({ titles: ['Product Designer'] });
ok(res.jobs.length === 2, 'index serves only title-matching jobs (designer roles)');
ok(res.jobs.every((j) => /designer/i.test(j.title)), 'backend engineer pre-filtered out of index results');
ok(res.sources.some((s) => s.name === 'Greenhouse'), 'index reports its source breakdown');
store.setJobIndex([], { at: null, count: 0, sources: [] }); // reset so we hit live/mock path
const fallback = await searchJobs({ titles: ['Product Designer'] });
ok(fallback.jobs.length > 0, 'empty index falls back to live/mock discovery');

// --- Board import extraction (shared by CLI + auto-refresh) -----------------
const { extractTokens } = await import('../src/data/board-import.js');
const fromUrls = extractTokens(
  'see https://boards.greenhouse.io/airbnb and https://jobs.lever.co/spotify and https://jobs.ashbyhq.com/openai',
);
ok(fromUrls.greenhouse.includes('airbnb'), 'extract greenhouse token from URL');
ok(fromUrls.lever.includes('spotify'), 'extract lever token from URL');
ok(fromUrls.ashby.includes('openai'), 'extract ashby token from URL');

const fromObjs = extractTokens(JSON.stringify([
  { ats: 'Greenhouse', slug: 'stripe' }, { platform: 'lever', token: 'palantir' },
  { provider: 'workday', slug: 'skipme' },
]));
ok(fromObjs.greenhouse.includes('stripe') && fromObjs.lever.includes('palantir'), 'extract tokens from {ats,token} objects');
ok(!Object.values(fromObjs).flat().includes('skipme'), 'unsupported ATS (workday) skipped');

const bare = extractTokens('shopify\nwealthsimple\n!notatoken', 'greenhouse');
ok(bare.greenhouse.length === 2, 'bare list + provider hint; junk line dropped');

// --- Runtime roster growth (mergeBoards) ------------------------------------
const { getBoards, mergeBoards } = await import('../src/data/boards.js');
const start = getBoards().greenhouse.length;
const r1 = mergeBoards({ greenhouse: ['airbnb', 'a-brand-new-co'] }); // airbnb already seeded
ok(r1.after === r1.before + 1, 'mergeBoards adds only the new token (dedupes existing)');
ok(getBoards().greenhouse.includes('a-brand-new-co'), 'roster reflects the added company live');
ok(getBoards().greenhouse.length === start + 1, 'roster grew by exactly one');

console.log(`\nats.test: ${n} checks passed`);
