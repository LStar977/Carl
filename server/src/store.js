// In-memory data store. Intentionally behind a small interface so it can be
// swapped for Postgres/Prisma later without touching the services.

const db = {
  users: new Map(),        // id -> user
  profiles: new Map(),     // userId -> profile
  jobs: new Map(),         // userId -> Job[]
  matches: new Map(),      // userId -> Match[]
  applications: new Map(), // userId -> Application[]
  activity: new Map(),     // userId -> Activity[] (newest first)
  tx: new Map(),           // userId -> Transaction[]
  usedTx: new Set(),       // consumed App Store transactionIds (replay guard)
};

export const store = {
  createUser(u) { db.users.set(u.id, u); db.activity.set(u.id, []); return u; },
  getUser(id) { return db.users.get(id); },
  getUserByToken(tok) {
    for (const u of db.users.values()) if (u.token === tok) return u;
    return undefined;
  },
  updateUser(u) { db.users.set(u.id, u); return u; },

  saveProfile(p) { db.profiles.set(p.userId, p); return p; },
  getProfile(userId) { return db.profiles.get(userId); },

  setJobs(userId, jobs) { db.jobs.set(userId, jobs); },
  getJobs(userId) { return db.jobs.get(userId) || []; },
  getJob(userId, jobId) { return (db.jobs.get(userId) || []).find((j) => j.id === jobId); },

  setMatches(userId, matches) { db.matches.set(userId, matches); },
  getMatches(userId) { return db.matches.get(userId) || []; },
  getMatch(userId, id) { return (db.matches.get(userId) || []).find((m) => m.id === id); },
  updateMatch(userId, match) {
    const list = db.matches.get(userId) || [];
    const i = list.findIndex((m) => m.id === match.id);
    if (i >= 0) list[i] = match;
    db.matches.set(userId, list);
    return match;
  },

  upsertApplication(a) {
    const list = db.applications.get(a.userId) || [];
    const i = list.findIndex((x) => x.id === a.id);
    if (i >= 0) list[i] = a; else list.push(a);
    db.applications.set(a.userId, list);
    return a;
  },
  getApplications(userId) { return db.applications.get(userId) || []; },
  getApplication(userId, id) { return (db.applications.get(userId) || []).find((a) => a.id === id); },

  addActivity(userId, ev) {
    const list = db.activity.get(userId) || [];
    list.unshift(ev);
    db.activity.set(userId, list);
    return ev;
  },
  getActivity(userId) { return db.activity.get(userId) || []; },

  addTx(userId, t) {
    const list = db.tx.get(userId) || [];
    list.push(t);
    db.tx.set(userId, list);
    return t;
  },
  getTx(userId) { return db.tx.get(userId) || []; },

  /** Reserve a transactionId; returns false if it was already consumed. */
  useTransaction(txId) {
    if (db.usedTx.has(txId)) return false;
    db.usedTx.add(txId);
    return true;
  },
};
