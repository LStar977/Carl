// Shared logic for turning an arbitrary public dataset into ATS board tokens.
// Used by the import CLI (one-off) and the scheduled board refresher.
//
// Accepts almost any shape:
//   • { "greenhouse": [...], "lever": [...], "ashby": [...] }   (our shape)
//   • [ {ats|platform|provider|source, token|slug|board|name}, ... ]
//   • [ "stripe", "figma", ... ]            (needs a providerHint)
//   • newline/CSV list of tokens            (needs a providerHint)
//   • raw text/HTML with career-page URLs   (greenhouse.io/lever.co/ashbyhq.com)
export const PROVIDERS = ['greenhouse', 'lever', 'ashby'];
export const emptyBoards = () => ({ greenhouse: [], lever: [], ashby: [] });

export function normProvider(s) {
  s = String(s || '').toLowerCase();
  if (s.includes('greenhouse')) return 'greenhouse';
  if (s.includes('lever')) return 'lever';
  if (s.includes('ashby')) return 'ashby';
  return null;
}

export function clean(arr) {
  return [...new Set((arr || []).map((t) => String(t).trim().toLowerCase()))]
    .filter((t) => /^[a-z0-9][a-z0-9_-]*$/.test(t));
}

export function totalTokens(boards) {
  return PROVIDERS.reduce((n, p) => n + (boards[p]?.length || 0), 0);
}

export function unionBoards(...sets) {
  const out = emptyBoards();
  for (const s of sets) for (const p of PROVIDERS) out[p].push(...(s[p] || []));
  for (const p of PROVIDERS) out[p] = clean(out[p]);
  return out;
}

// Pull tokens out of any career-page / ATS API URLs in free text or HTML.
function fromUrls(text) {
  const out = emptyBoards();
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
  const out = emptyBoards();
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
  const out = emptyBoards();
  if (!providerHint) return out;
  for (const line of text.split(/\r?\n/)) {
    const tok = line.trim().split(/[,\t;]/)[0].trim();
    if (tok) out[providerHint].push(tok);
  }
  return out;
}

/** Extract { greenhouse, lever, ashby } token arrays from arbitrary content. */
export function extractTokens(content, providerHint = null) {
  const urls = fromUrls(content);
  let json = null;
  try { json = JSON.parse(content); } catch { /* not JSON */ }
  const structured = json ? fromJson(json, providerHint) : emptyBoards();
  // Treat the source as a bare token list only if URL + JSON parsing found nothing.
  const lines = (!json && totalTokens(urls) === 0) ? fromLines(content, providerHint) : emptyBoards();
  return unionBoards(urls, structured, lines);
}
