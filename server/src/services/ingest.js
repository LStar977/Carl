// Background ingestion worker: crawls every seeded ATS board on a schedule into
// the global job index, so user searches hit the index instantly instead of
// fan-out fetching thousands of boards per request. This is the path to a large
// (1M+), city-accurate, fully-appliable job universe without per-search latency.
//
// In-memory today (single long-lived process); when the store moves to Postgres
// this writes to a `jobs` table and `searchJobs` queries it with a WHERE clause.
import { config } from '../config.js';
import { crawlAllBoards } from '../adapters/ats.js';
import { store } from '../store.js';
import { nowISO } from '../util.js';

let running = false;

/** Run one full crawl and replace the index. Safe to call manually or on a timer. */
export async function runIngest({ concurrency } = {}) {
  if (running) return store.getJobIndexMeta();
  running = true;
  const started = Date.now();
  try {
    const { jobs, sources, boards } = await crawlAllBoards({
      concurrency: concurrency || config.ingestConcurrency,
    });
    const ms = Date.now() - started;
    store.setJobIndex(jobs, { at: nowISO(), count: jobs.length, sources, ms, boards });
    console.log(`ingest: indexed ${jobs.length} jobs from ${boards} boards in ${ms}ms`);
    return store.getJobIndexMeta();
  } finally {
    running = false;
  }
}

/** Kick off the initial crawl + periodic refresh, if enabled. */
export function startIngestSchedule() {
  if (!config.atsEnabled || !config.ingestEnabled) return;
  runIngest().catch((e) => console.warn(`ingest failed: ${e.message}`));
  const timer = setInterval(
    () => runIngest().catch((e) => console.warn(`ingest failed: ${e.message}`)),
    config.ingestIntervalMin * 60 * 1000,
  );
  timer.unref?.(); // don't keep the process alive just for the timer
}
