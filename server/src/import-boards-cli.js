// Import ATS board tokens from a public dataset and merge them into a board
// list (default data/boards.json), de-duplicated. This is how you scale from the
// ~250-company starter list to thousands / 20k+ companies in one command.
//
// Usage:
//   npm run import-boards -- <source> [provider] [--out <path>] [--dry-run]
//
//   <source>    URL or local file: a token list / company crawl / page of links.
//   [provider]  greenhouse | lever | ashby — only needed when the source is a
//               flat list of bare tokens (no provider info in the data).
//   --out PATH  output file to merge into (default: data/boards.json)
//   --dry-run   show what would be added without writing
import { readFileSync, writeFileSync } from 'node:fs';
import { extractTokens, normProvider, clean, PROVIDERS, totalTokens } from './data/board-import.js';

async function readSource(src) {
  if (/^https?:/i.test(src)) {
    const r = await fetch(src, { headers: { 'user-agent': 'carl-board-importer' } });
    if (!r.ok) throw new Error(`fetch ${src} -> HTTP ${r.status}`);
    return r.text();
  }
  return readFileSync(src, 'utf8');
}

function parseArgs(argv) {
  let outPath = 'data/boards.json';
  let dryRun = false;
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') dryRun = true;
    else if (a === '--out') outPath = argv[++i];
    else positional.push(a);
  }
  return { source: positional[0], providerHint: normProvider(positional[1]), outPath, dryRun };
}

const USAGE = 'Usage: npm run import-boards -- <source-url-or-file> [greenhouse|lever|ashby] [--out data/boards.json] [--dry-run]';

async function main() {
  const { source, providerHint, outPath, dryRun } = parseArgs(process.argv.slice(2));
  if (!source) { console.error(USAGE); process.exit(1); }

  const content = await readSource(source);
  const found = extractTokens(content, providerHint);
  if (totalTokens(found) === 0) {
    console.error('No tokens recognised in the source.');
    console.error('If it is a bare list of tokens, pass a provider, e.g.:');
    console.error('  npm run import-boards -- list.txt greenhouse');
    process.exit(2);
  }

  let preserved = {};
  const existing = {};
  try {
    preserved = JSON.parse(readFileSync(outPath, 'utf8'));
    for (const p of PROVIDERS) existing[p] = clean(preserved[p] || []);
  } catch { for (const p of PROVIDERS) existing[p] = []; }

  const merged = { ...preserved };
  let totalAfter = 0;
  console.log(`Imported from ${source}`);
  for (const p of PROVIDERS) {
    const before = existing[p].length;
    const union = clean([...existing[p], ...found[p]]).sort();
    merged[p] = union;
    totalAfter += union.length;
    console.log(`  ${p.padEnd(11)} +${union.length - before}  (${before} -> ${union.length}, ${found[p].length} found)`);
  }
  console.log(`Total boards: ${totalAfter}`);

  if (dryRun) { console.log('\n(dry run — nothing written)'); return; }
  writeFileSync(outPath, `${JSON.stringify(merged, null, 2)}\n`);
  console.log(`\nWrote ${outPath}. Validate live coverage with: npm run ingest`);
}

main().catch((e) => { console.error(`import failed: ${e.message}`); process.exit(1); });
