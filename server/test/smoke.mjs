// End-to-end smoke test: walks the full Carl flow against a running server.
// Usage: node test/smoke.mjs   (starts its own server on a test port)
import { spawn } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';

const PORT = 8799;
const BASE = `http://127.0.0.1:${PORT}`;
let token = '';

const srv = spawn(process.execPath, ['src/index.js'], {
  env: { ...process.env, PORT: String(PORT), APPLY_MODE: 'dry-run' },
  stdio: ['ignore', 'inherit', 'inherit'],
});

async function api(method, path, body) {
  const r = await fetch(BASE + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { 'x-carl-token': token } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await r.json().catch(() => ({}));
  return { status: r.status, json };
}

let passed = 0, failed = 0;
function check(name, cond, extra = '') {
  if (cond) { passed++; console.log(`  ✓ ${name}`); }
  else { failed++; console.log(`  ✗ ${name} ${extra}`); }
}

try {
  // wait for boot
  for (let i = 0; i < 40; i++) {
    try { const r = await fetch(BASE + '/health'); if (r.ok) break; } catch {}
    await sleep(100);
  }

  console.log('\nHealth & auth');
  const health = await api('GET', '/health');
  check('health ok', health.status === 200 && health.json.ok);

  const auth = await api('POST', '/v1/auth/anon');
  token = auth.json.token;
  check('anon auth returns token', !!token);
  check('starts with free credits', auth.json.user.credits === 3, JSON.stringify(auth.json.user));

  console.log('\nIntake & résumé');
  await api('PUT', '/v1/profile', { prefs: { titles: ['Product Designer'], locationType: 'remote', payFloor: 120, country: 'us' } });
  const resume = await api('POST', '/v1/resume', { text: 'Senior Product Designer with 6 years experience. Skills: Figma, Design Systems, Prototyping, UX Research.' });
  check('résumé parsed targetRole', !!resume.json.parsed?.targetRole, JSON.stringify(resume.json));
  check('résumé parsed skills', Array.isArray(resume.json.parsed?.skills) && resume.json.parsed.skills.length > 0);

  await api('PUT', '/v1/profile', { eligibility: { authorized: true, needsSponsorship: false, willingToRelocate: true, salaryExpectation: '$140k+' } });
  const prof = await api('GET', '/v1/profile');
  check('eligibility saved + returned', prof.json.eligibility?.salaryExpectation === '$140k+', JSON.stringify(prof.json.eligibility));

  console.log('\nSearch & reveal');
  const search = await api('POST', '/v1/search', {});
  check('search returns a job count', search.json.count > 0, `count=${search.json.count}`);
  check('search returns avgFit', search.json.avgFit > 0, `avgFit=${search.json.avgFit}`);
  check('search returns 3 top matches', search.json.topMatches?.length === 3);
  check('top match has fit + company', !!search.json.topMatches?.[0]?.fit && !!search.json.topMatches?.[0]?.company);
  check('sources listed', search.json.sources?.length > 0);

  console.log('\nQueue & drafts');
  const queue = await api('GET', '/v1/queue');
  check('queue has prepared items', queue.json.items?.length > 0, `items=${queue.json.items?.length}`);
  check('queue item has a drafted cover note', !!queue.json.items?.[0]?.draft?.coverNote);

  console.log('\nConfirm & credits');
  const firstMatch = queue.json.items[0].matchId;
  const confirm = await api('POST', `/v1/applications/${firstMatch}/confirm`, { coverNote: 'My edited cover note.' });
  check('confirm submits', confirm.json.submitted === true, JSON.stringify(confirm.json));
  check('credit consumed (3 → 2)', confirm.json.credits === 2, `credits=${confirm.json.credits}`);
  const appDetail = await api('GET', `/v1/applications/${firstMatch}`);
  check('edited cover note was saved on the application', appDetail.json.application?.draft?.coverNote === 'My edited cover note.', JSON.stringify(appDetail.json.application?.draft));

  // exhaust remaining credits, then hit the paywall
  const q2 = await api('GET', '/v1/queue');
  await api('POST', `/v1/applications/${q2.json.items[0].matchId}/confirm`);
  await api('POST', `/v1/applications/${q2.json.items[1].matchId}/confirm`);
  const q3 = await api('GET', '/v1/queue');
  const broke = await api('POST', `/v1/applications/${q3.json.items[0].matchId}/confirm`);
  check('paywall at 0 credits (402)', broke.status === 402, `status=${broke.status}`);

  console.log('\nPurchase & dashboard');
  const buy = await api('POST', '/v1/credits/purchase', { packId: 'popular' });
  check('purchase grants 110 credits', buy.json.granted === 110, JSON.stringify(buy.json));
  const dash = await api('GET', '/v1/dashboard');
  check('dashboard counts applied', dash.json.totalApplied === 3, `applied=${dash.json.totalApplied}`);
  check('dashboard has activity feed', dash.json.activity?.length >= 3);
  check('dashboard shows credits', dash.json.credits === 110, `credits=${dash.json.credits}`);

  console.log('\nApplication detail');
  const detail = await api('GET', `/v1/applications/${firstMatch}`);
  check('detail returns submitted application', detail.json.application?.status === 'applied');

  console.log(`\n${failed === 0 ? '✅' : '❌'} ${passed} passed, ${failed} failed\n`);
} catch (err) {
  console.error('Smoke test crashed:', err);
  failed++;
} finally {
  srv.kill('SIGTERM');
  process.exit(failed === 0 ? 0 : 1);
}
