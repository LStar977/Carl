// Data store. In-memory working set with optional durable persistence to
// Postgres (a periodic + on-demand JSON snapshot). When DATABASE_URL is unset
// (dev/tests) it's pure in-memory — no dependency on `pg` is loaded. When set
// (production), state is loaded on boot and saved on a tick / on demand, so it
// survives restarts and deploys.
//
// This suits a single always-on instance (e.g. a Replit Reserved VM). It is NOT
// multi-instance safe — if you ever run more than one process, move to a real
// relational schema (the method interface below is the seam to do that).

const db = {
  users: new Map(),        // id -> user
  profiles: new Map(),     // userId -> profile
  jobs: new Map(),         // userId -> Job[]
  matches: new Map(),      // userId -> Match[]
  applications: new Map(), // userId -> Application[]
  activity: new Map(),     // userId -> Activity[] (newest first)
  tx: new Map(),           // userId -> Transaction[]
  usedTx: new Set(),       // consumed App Store transactionIds (replay guard)
  jobIndex: [],            // global crawled job universe (ingestion worker)
  jobIndexMeta: { at: null, count: 0, sources: [], ms: 0 },
};

let dirty = false;
const markDirty = () => { dirty = true; };

export const store = {
  createUser(u) { db.users.set(u.id, u); db.activity.set(u.id, []); markDirty(); return u; },
  getUser(id) { return db.users.get(id); },
  allUsers() { return [...db.users.values()]; },
  getUserByToken(tok) {
    for (const u of db.users.values()) if (u.token === tok) return u;
    return undefined;
  },
  updateUser(u) { db.users.set(u.id, u); markDirty(); return u; },

  /** Permanently delete a user and ALL their data (account deletion). */
  deleteUser(userId) {
    db.users.delete(userId);
    db.profiles.delete(userId);
    db.jobs.delete(userId);
    db.matches.delete(userId);
    db.applications.delete(userId);
    db.activity.delete(userId);
    db.tx.delete(userId);
    markDirty();
    // usedTx holds App Store transaction ids for replay protection (not PII).
  },

  saveProfile(p) { db.profiles.set(p.userId, p); markDirty(); return p; },
  getProfile(userId) { return db.profiles.get(userId); },

  setJobs(userId, jobs) { db.jobs.set(userId, jobs); markDirty(); },
  getJobs(userId) { return db.jobs.get(userId) || []; },
  getJob(userId, jobId) { return (db.jobs.get(userId) || []).find((j) => j.id === jobId); },

  setMatches(userId, matches) { db.matches.set(userId, matches); markDirty(); },
  getMatches(userId) { return db.matches.get(userId) || []; },
  getMatch(userId, id) { return (db.matches.get(userId) || []).find((m) => m.id === id); },
  updateMatch(userId, match) {
    const list = db.matches.get(userId) || [];
    const i = list.findIndex((m) => m.id === match.id);
    if (i >= 0) list[i] = match;
    db.matches.set(userId, list);
    markDirty();
    return match;
  },

  upsertApplication(a) {
    const list = db.applications.get(a.userId) || [];
    const i = list.findIndex((x) => x.id === a.id);
    if (i >= 0) list[i] = a; else list.push(a);
    db.applications.set(a.userId, list);
    markDirty();
    return a;
  },
  getApplications(userId) { return db.applications.get(userId) || []; },
  getApplication(userId, id) { return (db.applications.get(userId) || []).find((a) => a.id === id); },

  addActivity(userId, ev) {
    const list = db.activity.get(userId) || [];
    list.unshift(ev);
    db.activity.set(userId, list);
    markDirty();
    return ev;
  },
  getActivity(userId) { return db.activity.get(userId) || []; },

  addTx(userId, t) {
    const list = db.tx.get(userId) || [];
    list.push(t);
    db.tx.set(userId, list);
    markDirty();
    return t;
  },
  getTx(userId) { return db.tx.get(userId) || []; },

  /** Reserve a transactionId; returns false if it was already consumed. */
  useTransaction(txId) {
    if (db.usedTx.has(txId)) return false;
    db.usedTx.add(txId);
    markDirty();
    return true;
  },

  // Global job index, populated by the ingestion worker.
  setJobIndex(jobs, meta) { db.jobIndex = jobs; db.jobIndexMeta = meta; markDirty(); },
  getJobIndex() { return db.jobIndex; },
  getJobIndexMeta() { return db.jobIndexMeta; },
};

// ----- Durable snapshot persistence (Postgres, optional) -----------------

function serialize() {
  return JSON.stringify({
    users: [...db.users], profiles: [...db.profiles], jobs: [...db.jobs],
    matches: [...db.matches], applications: [...db.applications],
    activity: [...db.activity], tx: [...db.tx], usedTx: [...db.usedTx],
    jobIndex: db.jobIndex, jobIndexMeta: db.jobIndexMeta,
  });
}

function restore(json) {
  const d = JSON.parse(json);
  db.users = new Map(d.users || []);
  db.profiles = new Map(d.profiles || []);
  db.jobs = new Map(d.jobs || []);
  db.matches = new Map(d.matches || []);
  db.applications = new Map(d.applications || []);
  db.activity = new Map(d.activity || []);
  db.tx = new Map(d.tx || []);
  db.usedTx = new Set(d.usedTx || []);
  db.jobIndex = d.jobIndex || [];
  db.jobIndexMeta = d.jobIndexMeta || { at: null, count: 0, sources: [], ms: 0 };
}

let pool = null;
let saving = false;

/** Connect to Postgres (if DATABASE_URL is set), load the snapshot, and start
 *  periodic saving. No-op (pure in-memory) when DATABASE_URL is unset. */
export async function initStore() {
  const url = process.env.DATABASE_URL;
  if (!url) return; // dev / tests: in-memory only, `pg` never loaded
  try {
    const { default: pg } = await import('pg');
    const local = /localhost|127\.0\.0\.1/.test(url);
    pool = new pg.Pool({ connectionString: url, ssl: local ? false : { rejectUnauthorized: false } });
    await pool.query('CREATE TABLE IF NOT EXISTS carl_state (id text PRIMARY KEY, data text, updated_at timestamptz DEFAULT now())');
    const r = await pool.query("SELECT data FROM carl_state WHERE id = 'main'");
    if (r.rows[0]?.data) { restore(r.rows[0].data); console.log('store: snapshot loaded from Postgres'); }
    else { console.log('store: connected to Postgres (fresh)'); }
    const t = setInterval(() => { if (dirty) flush(); }, 5000);
    t.unref?.();
  } catch (e) {
    console.warn(`store: Postgres init failed (${e.message}); running in-memory (data will NOT persist)`);
    pool = null;
  }
}

/** Persist the current state immediately (used on a tick, after purchases, and
 *  on shutdown). Safe to call when persistence is off. */
export async function flush() {
  if (!pool || saving) return;
  saving = true;
  dirty = false;
  try {
    await pool.query(
      "INSERT INTO carl_state (id, data, updated_at) VALUES ('main', $1, now()) " +
      'ON CONFLICT (id) DO UPDATE SET data = $1, updated_at = now()',
      [serialize()],
    );
  } catch (e) {
    console.warn(`store: snapshot save failed (${e.message})`);
    dirty = true; // retry on the next tick
  } finally {
    saving = false;
  }
}
