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

  console.log('\nRésumé builder ($14.99 unlock)');
  const gated = await api('POST', '/v1/resume/build', { input: { role: 'Designer', experience: 'x' } });
  check('build blocked without the unlock (402)', gated.status === 402, `status=${gated.status}`);
  const ent = await api('POST', '/v1/entitlements/purchase', { productId: 'com.carlapp.resumebuilder' });
  check('resume-builder unlock granted', ent.json.ok === true && ent.json.entitlements?.includes('resumeBuilder'), JSON.stringify(ent.json));
  const built = await api('POST', '/v1/resume/build', { input: { name: 'Jane', role: 'Product Designer', years: '6', skills: 'Figma', experience: 'Led design systems at Acme for 4 years.' } });
  check('build returns a résumé after unlock', built.status === 200 && typeof built.json.resume === 'string' && built.json.resume.length > 0, JSON.stringify(built.json).slice(0, 120));

  console.log('\nSearch & reveal');
  const search = await api('POST', '/v1/search', {});
  check('search returns a job count', search.json.count > 0, `count=${search.json.count}`);

  // Blocklist: block a company that appears in results, re-search, expect it gone.
  const blockCo = search.json.topMatches?.[0]?.company;
  if (blockCo) {
    await api('POST', '/v1/blocklist', { company: blockCo });
    const reSearch = await api('POST', '/v1/search', {});
    const stillThere = reSearch.json.topMatches?.some((m) => m.company === blockCo);
    check('blocked company removed from search', !stillThere, `blocked=${blockCo}`);
    await api('POST', '/v1/blocklist', { company: blockCo, remove: true }); // unblock for rest of flow
  }
  check('search returns avgFit', search.json.avgFit > 0, `avgFit=${search.json.avgFit}`);
  check('search returns 3 top matches', search.json.topMatches?.length === 3);
  check('top match has fit + company', !!search.json.topMatches?.[0]?.fit && !!search.json.topMatches?.[0]?.company);
  check('sources listed', search.json.sources?.length > 0);

  console.log('\nQueue & drafts');
  const queue = await api('GET', '/v1/queue');
  check('queue has prepared items', queue.json.items?.length > 0, `items=${queue.json.items?.length}`);
  check('queue item has a drafted cover note', !!queue.json.items?.[0]?.draft?.coverNote);

  console.log('\nTailored résumé (+1 credit)');
  const m1 = queue.json.items[0].matchId;
  const m2 = queue.json.items[1].matchId;
  const m3 = queue.json.items[2].matchId;
  await api('POST', `/v1/applications/${m2}/tailor-resume`);
  const qT = await api('GET', '/v1/queue');
  check('tailored résumé flagged on the queue item', qT.json.items.find((i) => i.matchId === m2)?.tailored === true);

  console.log('\nConfirm & credits');
  const confirm = await api('POST', `/v1/applications/${m1}/confirm`, { coverNote: 'My edited cover note.' });
  check('standard apply submits + consumes 1 credit (3 → 2)', confirm.json.submitted === true && confirm.json.credits === 2, JSON.stringify(confirm.json));
  check('confirm returns the employer apply URL (assisted send)', typeof confirm.json.applyUrl === 'string' && confirm.json.applyUrl.length > 0, JSON.stringify(confirm.json.applyUrl));
  const appDetail = await api('GET', `/v1/applications/${m1}`);
  check('edited cover note was saved on the application', appDetail.json.application?.draft?.coverNote === 'My edited cover note.', JSON.stringify(appDetail.json.application?.draft));

  const confirmTailored = await api('POST', `/v1/applications/${m2}/confirm`);
  check('tailored apply consumes 2 credits (2 → 0)', confirmTailored.json.submitted === true && confirmTailored.json.credits === 0, JSON.stringify(confirmTailored.json));

  const broke = await api('POST', `/v1/applications/${m3}/confirm`);
  check('paywall at 0 credits (402)', broke.status === 402, `status=${broke.status}`);

  console.log('\nPurchase & dashboard');
  const buy = await api('POST', '/v1/credits/purchase', { packId: 'popular' });
  check('purchase grants 110 credits', buy.json.granted === 110, JSON.stringify(buy.json));
  const dash = await api('GET', '/v1/dashboard');
  check('dashboard counts applied', dash.json.totalApplied === 2, `applied=${dash.json.totalApplied}`);
  check('dashboard has activity feed', dash.json.activity?.length >= 2);
  check('dashboard shows credits', dash.json.credits === 110, `credits=${dash.json.credits}`);

  console.log('\nFind more jobs');
  const more = await api('POST', '/v1/search/more');
  check('search/more returns a found count', more.status === 200 && typeof more.json.found === 'number', JSON.stringify(more.json));

  console.log('\nApplication detail');
  const detail = await api('GET', `/v1/applications/${m1}`);
  check('detail returns submitted application', detail.json.application?.status === 'applied');

  console.log('\nAccount deletion');
  const del = await api('POST', '/v1/account/delete');
  check('account delete returns deleted:true', del.json.deleted === true, JSON.stringify(del.json));
  const afterDel = await api('GET', '/v1/dashboard');
  check('data is gone after deletion (token no longer valid)', afterDel.status === 401, `status=${afterDel.status}`);

  console.log(`\n${failed === 0 ? '✅' : '❌'} ${passed} passed, ${failed} failed\n`);
} catch (err) {
  console.error('Smoke test crashed:', err);
  failed++;
} finally {
  srv.kill('SIGTERM');
  process.exit(failed === 0 ? 0 : 1);
}
