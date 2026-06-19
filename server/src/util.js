import { randomUUID } from 'node:crypto';

export const uid = (prefix = 'id') => `${prefix}_${randomUUID().slice(0, 8)}`;
export const nowISO = () => new Date().toISOString();
export const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));

export function sendJSON(res, status, body) {
  const s = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type, x-carl-token',
    'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
  });
  res.end(s);
}

export function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (c) => {
      data += c;
      if (data.length > 8e6) req.destroy();
    });
    req.on('end', () => {
      if (!data) return resolve({});
      try { resolve(JSON.parse(data)); }
      catch { reject(new Error('invalid_json')); }
    });
    req.on('error', reject);
  });
}

/** fetch + JSON parse with a timeout; never throws on network errors. */
export async function fetchJSON(url, opts = {}, timeoutMs = 12000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const r = await fetch(url, { ...opts, signal: ctrl.signal });
    const text = await r.text();
    let json = null;
    try { json = text ? JSON.parse(text) : null; } catch { /* non-JSON */ }
    return { ok: r.ok, status: r.status, json, text };
  } catch (err) {
    return { ok: false, status: 0, json: null, text: '', error: String(err) };
  } finally {
    clearTimeout(t);
  }
}

export const pick = (arr, i) => arr[i % arr.length];
