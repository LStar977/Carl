// Deterministic mock job universe, used when no real job-source keys are set.
// Generates a believable set of postings so the whole app works end-to-end.
import { uid, pick } from '../util.js';

const COMPANIES = [
  ['Northwind', 'navy'], ['Lumen Health', 'greenhouse'], ['Vela Robotics', 'lever'],
  ['Cardinal Bank', 'navy'], ['Brightwave', 'greenhouse'], ['Atlas Foundry', 'lever'],
  ['Meridian', 'navy'], ['Cedar & Co', 'greenhouse'], ['Quanta Labs', 'lever'],
  ['Harbor Health', 'navy'], ['Pinewood', 'greenhouse'], ['Solstice', 'lever'],
  ['Riverstone', 'navy'], ['Beacon AI', 'greenhouse'], ['Orchard', 'lever'],
];

const SENIORITY = ['', 'Junior ', 'Mid ', 'Senior ', 'Staff ', 'Lead ', 'Principal '];
const SOURCES = [
  { name: 'LinkedIn Jobs', source: 'linkedin', tier: 'B' },
  { name: 'Greenhouse', source: 'greenhouse', tier: 'A' },
  { name: 'Lever', source: 'lever', tier: 'A' },
  { name: 'Ashby', source: 'ashby', tier: 'B' },
];

const LOCATIONS = [
  ['Remote', 'remote'], ['SF Hybrid', 'hybrid'], ['Austin', 'onsite'],
  ['New York', 'onsite'], ['Toronto', 'onsite'], ['Remote (US/CA)', 'remote'],
  ['Seattle Hybrid', 'hybrid'], ['Chicago', 'onsite'],
];

function payBand(seed) {
  const base = 90 + (seed % 8) * 15; // 90k..195k
  return `$${base}–${base + 25}k`;
}

/** Generate `n` normalized jobs derived from the user's preferences. */
export function generateMockJobs(prefs, n = 312) {
  const role = prefs?.titles?.[0] || prefs?.targetRole || 'Product Designer';
  const jobs = [];
  for (let i = 0; i < n; i++) {
    const [company, color] = pick(COMPANIES, i);
    const src = pick(SOURCES, i);
    const [loc, remoteType] = pick(LOCATIONS, i);
    const title = `${pick(SENIORITY, i)}${role}`.trim();
    jobs.push({
      id: uid('job'),
      source: src.source,
      sourceName: src.name,
      externalId: `${src.source}-${1000 + i}`,
      title,
      company,
      avatarColor: color,
      location: loc,
      remoteType,
      payText: payBand(i),
      payFloor: 90 + (i % 8) * 15,
      descriptionSnippet: `${company} is hiring a ${title}. Own end-to-end work with a team that values craft, ship measurable impact, and grow fast.`,
      applyTier: src.tier,
      applyUrl: `https://example.com/${src.source}/${company.toLowerCase().replace(/\W+/g, '-')}/${1000 + i}`,
      dedupeKey: `${company}|${title}`.toLowerCase(),
    });
  }
  return jobs;
}

/** Source breakdown shown on the searching screen. */
export function mockSourceCounts() {
  return [
    { name: 'LinkedIn Jobs', found: 142 },
    { name: 'Greenhouse', found: 86 },
    { name: 'Lever', found: 54 },
    { name: 'Ashby', found: 30 },
  ];
}
