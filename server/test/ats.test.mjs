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

console.log(`\nats.test: ${n} checks passed`);
