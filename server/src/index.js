import { createServer } from 'node:http';
import { config, hasLLM, hasATS, hasAdzuna, hasUSAJobs } from './config.js';
import { store } from './store.js';
import { sendJSON, readBody, uid, nowISO } from './util.js';
import { parseResume } from './services/resume.js';
import { searchJobs } from './services/jobs.js';
import { scoreMatches } from './services/match.js';
import { classifyTier, draftApplication, submitApplication } from './services/apply.js';
import { PACKS, balance, consume, purchase } from './services/credits.js';
import { startIngestSchedule } from './services/ingest.js';
import { startBoardRefreshSchedule } from './services/board-refresh.js';

// ----- DTO helpers -------------------------------------------------------

const jobDTO = (job) => ({
  id: job.id,
  title: job.title,
  company: job.company,
  detail: [job.location, job.payText].filter(Boolean).join(' · '),
  location: job.location,
  pay: job.payText,
  letter: (job.company || '?')[0].toUpperCase(),
  avatarColor: job.avatarColor || 'navy',
  tier: classifyTier(job),
  source: job.sourceName || job.source,
});

const matchDTO = (m) => ({ matchId: m.id, fit: m.fit, reasons: m.reasons, status: m.status, ...jobDTO(m.job) });

// ----- Route handlers ----------------------------------------------------

const routes = [];
const route = (method, pattern, handler) => routes.push({ method, pattern, handler });

route('GET', '/health', async () => ({
  status: 200,
  body: {
    ok: true,
    integrations: { llm: hasLLM, ats: hasATS, adzuna: hasAdzuna, usajobs: hasUSAJobs },
    applyMode: config.applyMode,
    index: { enabled: config.ingestEnabled, ...store.getJobIndexMeta() },
  },
}));

route('POST', '/v1/auth/anon', async () => {
  const user = store.createUser({
    id: uid('user'), token: uid('tok'), name: '', email: '', phone: '',
    credits: config.freeCredits, createdAt: nowISO(),
  });
  store.saveProfile({ userId: user.id, prefs: {}, resume: null });
  return { status: 200, body: { token: user.token, user: publicUser(user) } };
});

route('GET', '/v1/profile', async (ctx) => {
  const p = store.getProfile(ctx.user.id) || { prefs: {}, resume: null };
  return { status: 200, body: { prefs: p.prefs, resume: p.resume?.parsed || null, contact: contactOf(ctx.user), eligibility: p.eligibility || null } };
});

route('PUT', '/v1/profile', async (ctx) => {
  const p = store.getProfile(ctx.user.id) || { userId: ctx.user.id, prefs: {}, resume: null };
  p.prefs = { ...p.prefs, ...(ctx.body.prefs || {}) };
  // Standard application screening answers (work authorization, sponsorship,
  // relocation, salary expectation, EEO, links) — used to fill out applications.
  if (ctx.body.eligibility && typeof ctx.body.eligibility === 'object') {
    p.eligibility = { ...(p.eligibility || {}), ...ctx.body.eligibility };
  }
  store.saveProfile(p);
  // The user can confirm/edit the contact details employers will reach them on.
  const c = ctx.body.contact;
  if (c && typeof c === 'object') {
    if (typeof c.name === 'string' && c.name.trim()) ctx.user.name = c.name.trim();
    if (typeof c.email === 'string') ctx.user.email = c.email.trim().toLowerCase();
    if (typeof c.phone === 'string') ctx.user.phone = c.phone.trim();
    store.updateUser(ctx.user);
  }
  return { status: 200, body: { prefs: p.prefs, contact: contactOf(ctx.user), eligibility: p.eligibility || null } };
});

route('POST', '/v1/resume', async (ctx) => {
  const parsed = await parseResume(ctx.body.text || '');
  const p = store.getProfile(ctx.user.id) || { userId: ctx.user.id, prefs: {}, resume: null };
  p.resume = { rawText: ctx.body.text || '', parsed };
  store.saveProfile(p);
  // Pre-fill the user's contact from the résumé, unless they've already set it.
  const c = parsed.contact || {};
  let changed = false;
  if (c.email && !ctx.user.email) { ctx.user.email = c.email; changed = true; }
  if (c.phone && !ctx.user.phone) { ctx.user.phone = c.phone; changed = true; }
  if (c.name && !ctx.user.name) { ctx.user.name = c.name; changed = true; }
  if (changed) store.updateUser(ctx.user);
  return { status: 200, body: { parsed } };
});

route('POST', '/v1/search', async (ctx) => {
  const profile = store.getProfile(ctx.user.id) || { prefs: {} };
  const prefs = { ...profile.prefs, ...(ctx.body.prefs || {}), targetRole: profile.resume?.parsed?.targetRole };
  const { jobs, sources } = await searchJobs(prefs);
  const scored = scoreMatches(profile, prefs, jobs);
  const matches = scored.map((j) => ({ id: uid('match'), status: 'suggested', fit: j.fit, reasons: j.reasons, job: j }));
  store.setJobs(ctx.user.id, jobs);
  store.setMatches(ctx.user.id, matches);

  const avg = matches.slice(0, 50);
  const avgFit = avg.length ? Math.round(avg.reduce((s, m) => s + m.fit, 0) / avg.length) : 0;
  return {
    status: 200,
    body: {
      count: matches.length,
      avgFit,
      sources,
      topMatches: matches.slice(0, 3).map(matchDTO),
    },
  };
});

route('GET', '/v1/queue', async (ctx) => {
  const matches = store.getMatches(ctx.user.id);
  const ready = matches.filter((m) => m.status === 'suggested' || m.status === 'ready').slice(0, 14);
  const items = [];
  for (const m of ready) {
    let app = store.getApplications(ctx.user.id).find((a) => a.matchId === m.id);
    if (!app) {
      const draft = await draftApplication(store.getProfile(ctx.user.id), m.job);
      app = store.upsertApplication({
        id: uid('app'), userId: ctx.user.id, matchId: m.id, jobId: m.job.id,
        tier: classifyTier(m.job), draft, status: 'ready', createdAt: nowISO(), history: [],
      });
      m.status = 'ready'; m.applicationId = app.id; store.updateMatch(ctx.user.id, m);
    }
    items.push({ ...matchDTO(m), applicationId: app.id, draft: app.draft });
  }
  return { status: 200, body: { credits: balance(ctx.user), items } };
});

route('POST', '/v1/applications/:matchId/confirm', async (ctx) => {
  return confirmOne(ctx, ctx.params.matchId);
});

route('POST', '/v1/applications/confirm-all', async (ctx) => {
  const matches = store.getMatches(ctx.user.id).filter((m) => m.status === 'ready' || m.status === 'suggested');
  const results = [];
  for (const m of matches) {
    if (balance(ctx.user) <= 0) break;
    const r = await confirmOne(ctx, m.id);
    results.push(r.body);
  }
  return { status: 200, body: { submitted: results.filter((r) => r.submitted).length, credits: balance(ctx.user) } };
});

route('GET', '/v1/applications/:id', async (ctx) => {
  const app = store.getApplication(ctx.user.id, ctx.params.id)
    || store.getApplications(ctx.user.id).find((a) => a.matchId === ctx.params.id);
  if (!app) return { status: 404, body: { error: 'not_found' } };
  const m = store.getMatch(ctx.user.id, app.matchId);
  return { status: 200, body: { application: { id: app.id, status: app.status, submittedAt: app.submittedAt, draft: app.draft, tier: app.tier, history: app.history }, job: m ? jobDTO(m.job) : null } };
});

route('GET', '/v1/dashboard', async (ctx) => {
  const apps = store.getApplications(ctx.user.id);
  const submitted = apps.filter((a) => a.status === 'submitted' || a.status === 'applied');
  const today = new Date().toISOString().slice(0, 10);
  return {
    status: 200,
    body: {
      appliedToday: submitted.filter((a) => (a.submittedAt || '').slice(0, 10) === today).length,
      totalApplied: submitted.length,
      responses: apps.filter((a) => ['responded', 'interview'].includes(a.status)).length,
      interviews: apps.filter((a) => a.status === 'interview').length,
      credits: balance(ctx.user),
      activity: store.getActivity(ctx.user.id).slice(0, 12),
    },
  };
});

route('GET', '/v1/credits', async (ctx) => ({
  status: 200, body: { balance: balance(ctx.user), packs: PACKS },
}));

route('POST', '/v1/credits/purchase', async (ctx) => {
  const r = await purchase(ctx.user, ctx.body.packId, ctx.body.receipt);
  return r.ok ? { status: 200, body: r } : { status: 400, body: r };
});

// ----- Confirm helper ----------------------------------------------------

async function confirmOne(ctx, matchId) {
  const m = store.getMatch(ctx.user.id, matchId);
  if (!m) return { status: 404, body: { error: 'match_not_found' } };
  if (balance(ctx.user) <= 0) return { status: 402, body: { error: 'no_credits', credits: 0 } };

  let app = store.getApplications(ctx.user.id).find((a) => a.matchId === matchId);
  if (!app) {
    const draft = await draftApplication(store.getProfile(ctx.user.id), m.job);
    app = store.upsertApplication({ id: uid('app'), userId: ctx.user.id, matchId, jobId: m.job.id, tier: classifyTier(m.job), draft, status: 'ready', createdAt: nowISO(), history: [] });
  }
  if (app.status === 'submitted' || app.status === 'applied') {
    return { status: 200, body: { submitted: true, already: true, credits: balance(ctx.user) } };
  }

  // Apply any edits the user made to the cover note before it's sent.
  const edit = ctx.body || {};
  if (typeof edit.coverNote === 'string' && edit.coverNote.trim()) {
    app.draft = { ...app.draft, coverNote: edit.coverNote.trim() };
    store.upsertApplication(app);
  }

  const result = await submitApplication({ user: ctx.user, profile: store.getProfile(ctx.user.id), job: m.job, draft: app.draft });
  if (!result.submitted) return { status: 502, body: { error: 'submit_failed', detail: result.error } };

  consume(ctx.user, 1);
  app.status = 'applied';
  app.submittedAt = nowISO();
  app.history = [{ at: app.submittedAt, status: 'applied', mode: result.mode }];
  store.upsertApplication(app);
  m.status = 'submitted'; store.updateMatch(ctx.user.id, m);
  store.addActivity(ctx.user.id, { id: uid('act'), type: 'applied', dot: 'royal', text: `Applied to ${m.job.title} · ${m.job.company}`, ts: app.submittedAt });

  return { status: 200, body: { submitted: true, mode: result.mode, credits: balance(ctx.user) } };
}

// ----- Server / router ---------------------------------------------------

function matchRoute(method, path) {
  for (const r of routes) {
    if (r.method !== method) continue;
    const pp = r.pattern.split('/');
    const sp = path.split('/');
    if (pp.length !== sp.length) continue;
    const params = {};
    let ok = true;
    for (let i = 0; i < pp.length; i++) {
      if (pp[i].startsWith(':')) params[pp[i].slice(1)] = decodeURIComponent(sp[i]);
      else if (pp[i] !== sp[i]) { ok = false; break; }
    }
    if (ok) return { handler: r.handler, params };
  }
  return null;
}

const OPEN = new Set(['/health', '/v1/auth/anon']);

const server = createServer(async (req, res) => {
  const path = (req.url || '/').split('?')[0];
  if (req.method === 'OPTIONS') { res.writeHead(204, corsHeaders()); return res.end(); }

  const found = matchRoute(req.method, path);
  if (!found) return sendJSON(res, 404, { error: 'not_found' });

  try {
    const ctx = { params: found.params, body: {}, user: null };
    if (req.method === 'POST' || req.method === 'PUT') ctx.body = await readBody(req);

    if (!OPEN.has(path)) {
      const user = store.getUserByToken(req.headers['x-carl-token']);
      if (!user) return sendJSON(res, 401, { error: 'unauthorized' });
      ctx.user = user;
    }
    const out = await found.handler(ctx);
    return sendJSON(res, out.status, out.body);
  } catch (err) {
    if (String(err.message) === 'invalid_json') return sendJSON(res, 400, { error: 'invalid_json' });
    console.error(err);
    return sendJSON(res, 500, { error: 'server_error' });
  }
});

function corsHeaders() {
  return {
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type, x-carl-token',
    'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
  };
}

function publicUser(u) { return { id: u.id, name: u.name, email: u.email, phone: u.phone || '', credits: u.credits }; }
function contactOf(u) { return { name: u.name || '', email: u.email || '', phone: u.phone || '' }; }

server.listen(config.port, () => {
  console.log(`Carl server on :${config.port}  ·  llm=${hasLLM} ats=${hasATS} adzuna=${hasAdzuna} usajobs=${hasUSAJobs} apply=${config.applyMode} ingest=${config.ingestEnabled}`);
  startIngestSchedule();
  startBoardRefreshSchedule();
});
