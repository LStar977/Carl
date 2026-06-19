// Import ATS board tokens from a public dataset and merge them into a board
// list (default data/boards.json), de-duplicated. This is how you scale from the
// ~250-company starter list to thousands / 20k+ companies.
//
// Usage:
//   npm run import-boards -- <source> [provider] [--out <path>] [--dry-run]
//
//   <source>    URL or local file: a token list / company crawl / page of links.
//   [provider]  greenhouse | lever | ashby — only needed when the source is a
//               flat list of bare tokens (no provider info in the data).
//   --out PATH  output file to merge into (default: data/boards.json)
//   --dry-run   show what would be added without writing
//
// It accepts almost any shape:
//   • { "greenhouse": [...], "lever": [...], "ashby": [...] }   (our shape)
//   • [ {ats|platform|provider|source, token|slug|board|name}, ... ]
//   • [ "stripe", "figma", ... ]            (needs a [provider] arg)
//   • newline/CSV list of tokens            (needs a [provider] arg)
//   • raw text/HTML with career-page URLs   (greenhouse.io/lever.co/ashbyhq.com)
import { readFileSync, writeFileSync } from 'node:fs';

const PROVIDERS = ['greenhouse', 'lever', 'ashby'];
const empty = () => ({ greenhouse: [], lever: [], ashby: [] });

function normProvider(s) {
  s = String(s || '').toLowerCase();
  if (s.includes('greenhouse')) return 'greenhouse';
  if (s.includes('lever')) return 'lever';
  if (s.includes('ashby')) return 'ashby';
  return null;
}

// Pull tokens out of any career-page / ATS API URLs in free text or HTML.
function fromUrls(text) {
  const out = empty();
  const patterns = [
    [/boards(?:-api)?\.greenhouse\.io\/(?:embed\/job_board\?for=|v1\/boards\/)?([a-z0-9_-]+)/gi, 'greenhouse'],
    [/job-boards\.greenhouse\.io\/([a-z0-9_-]+)/gi, 'greenhouse'],
    [/(?:jobs|api)\.lever\.co\/(?:v0\/postings\/)?([a-z0-9_-]+)/gi, 'lever'],
    [/jobs\.ashbyhq\.com\/([a-z0-9_-]+)/gi, 'ashby'],
    [/api\.ashbyhq\.com\/posting-api\/job-board\/([a-z0-9_-]+)/gi, 'ashby'],
  ];
  for (const [re, prov] of patterns) {
    let m;
    while ((m = re.exec(text))) out[prov].push(m[1]);
  }
  return out;
}

function fromJson(data, providerHint) {
  const out = empty();
  if (Array.isArray(data)) {
    for (const item of data) {
      if (typeof item === 'string') {
        if (providerHint) out[providerHint].push(item);
      } else if (item && typeof item === 'object') {
        const prov = normProvider(item.ats || item.platform || item.provider || item.source || item.board_type);
        const tok = item.token || item.board || item.slug || item.board_token || item.company_token || item.id || item.name;
        if (prov && tok) out[prov].push(tok);
        else if (providerHint && tok) out[providerHint].push(tok);
      }
    }
  } else if (data && typeof data === 'object') {
    for (const p of PROVIDERS) if (Array.isArray(data[p])) out[p].push(...data[p]);
  }
  return out;
}

function fromLines(text, providerHint) {
  const out = empty();
  if (!providerHint) return out;
  for (const line of text.split(/\r?\n/)) {
    const tok = line.trim().split(/[,\t;]/)[0].trim();
    if (tok) out[providerHint].push(tok);
  }
  return out;
}

function merge(...sets) {
  const out = empty();
  for (const s of sets) for (const p of PROVIDERS) out[p].push(...s[p]);
  return out;
}

function clean(arr) {
  return [...new Set((arr || []).map((t) => String(t).trim().toLowerCase()))]
    .filter((t) => /^[a-z0-9][a-z0-9_-]*$/.test(t));
}

function extract(content, providerHint) {
  const urls = fromUrls(content);
  let json = null;
  try { json = JSON.parse(content); } catch { /* not JSON */ }
  const structured = json ? fromJson(json, providerHint) : empty();
  const total = (b) => PROVIDERS.reduce((n, p) => n + b[p].length, 0);
  // Only treat the source as a bare token list if URL + JSON parsing found nothing.
  const lines = (!json && total(urls) === 0) ? fromLines(content, providerHint) : empty();
  const found = merge(urls, structured, lines);
  for (const p of PROVIDERS) found[p] = clean(found[p]);
  return found;
}

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
  const found = extract(content, providerHint);
  const foundTotal = PROVIDERS.reduce((n, p) => n + found[p].length, 0);
  if (foundTotal === 0) {
    console.error('No tokens recognised in the source.');
    console.error('If it is a bare list of tokens, pass a provider, e.g.:');
    console.error('  npm run import-boards -- list.txt greenhouse');
    process.exit(2);
  }

  let preserved = {};
  const existing = empty();
  try {
    preserved = JSON.parse(readFileSync(outPath, 'utf8'));
    for (const p of PROVIDERS) existing[p] = clean(preserved[p] || []);
  } catch { /* new file */ }

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
