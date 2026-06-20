// Scheduled company-list refresher: periodically pulls public ATS crawl
// source(s), extracts board tokens, and merges them into the live roster so the
// company list grows on its own — no manual `import-boards` runs. After it adds
// companies, it re-runs ingestion so the new boards show up promptly.
//
// Configure with BOARD_SOURCES (comma-separated URLs) + BOARD_REFRESH_HOURS.
// Sources are re-fetched on startup and on the interval, so the expanded list
// rebuilds itself after a restart — no persistence needed.
import { config } from '../config.js';
import { mergeBoards } from '../data/boards.js';
import { extractTokens, unionBoards, totalTokens, PROVIDERS } from '../data/board-import.js';
import { runIngest } from './ingest.js';

let running = false;

export async function refreshBoardSources() {
  if (running || config.boardSources.length === 0) return;
  running = true;
  try {
    const sets = [];
    for (const src of config.boardSources) {
      try {
        const r = await fetch(src, { headers: { 'user-agent': 'carl-board-refresh' } });
        if (!r.ok) { console.warn(`board-refresh: ${src} -> HTTP ${r.status}`); continue; }
        sets.push(extractTokens(await r.text()));
      } catch (e) {
        console.warn(`board-refresh: ${src} failed: ${e.message}`);
      }
    }
    const found = unionBoards(...sets);
    if (totalTokens(found) === 0) return;

    const { before, after } = mergeBoards(found);
    if (after > before) {
      console.log(`board-refresh: company roster ${before} -> ${after} (+${after - before})`);
      if (config.ingestEnabled) await runIngest(); // index the newly-added boards
    }
  } finally {
    running = false;
  }
}

export function startBoardRefreshSchedule() {
  if (config.boardSources.length === 0) return;
  if (!config.ingestEnabled) {
    // A large auto-grown roster without ingestion would make per-search live
    // fetching explode, so we require the worker to be on.
    console.warn('board-refresh: BOARD_SOURCES set but INGEST_ENABLED is off — skipping (turn on ingestion to auto-grow the roster).');
    return;
  }
  refreshBoardSources().catch((e) => console.warn(`board-refresh failed: ${e.message}`));
  const timer = setInterval(
    () => refreshBoardSources().catch((e) => console.warn(`board-refresh failed: ${e.message}`)),
    config.boardRefreshHours * 3600 * 1000,
  );
  timer.unref?.();
}
