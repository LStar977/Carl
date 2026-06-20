// One-shot ingestion run: crawls every seeded ATS board and prints what it found
// (count + per-source breakdown + a sample). Use it to validate a token list —
//   npm run ingest
// With an in-memory store this populates the index only for this process, so it's
// mainly for verifying coverage; the long-lived server runs the scheduled worker.
import { runIngest } from './services/ingest.js';
import { store } from './store.js';

const meta = await runIngest();
const jobs = store.getJobIndex();
console.log(`\nIndexed ${meta.count} jobs from ${meta.boards} boards in ${meta.ms}ms`);
for (const s of meta.sources || []) console.log(`  ${s.name}: ${s.found}`);
console.log('\nSample:');
for (const j of jobs.slice(0, 8)) {
  console.log(`  [${j.applyTier}] ${j.title} · ${j.company} · ${j.location || 'n/a'}`);
}
process.exit(0);
