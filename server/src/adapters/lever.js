// Lever Postings API — Tier-A apply (real "Apply to a Posting" endpoint).
// Docs: https://github.com/lever/postings-api
import { fetchJSON } from '../util.js';

/**
 * Submit an application to a Lever posting.
 * @returns {{ ok: boolean, status: number, reference?: string, error?: string }}
 */
export async function submitLever({ site, postingId, applicant, coverNote }) {
  if (!site || !postingId) {
    return { ok: false, status: 0, error: 'missing_lever_config' };
  }
  const url = `https://api.lever.co/v0/postings/${site}/${postingId}?key=`;
  const body = {
    name: `${applicant.firstName} ${applicant.lastName}`.trim(),
    email: applicant.email,
    phone: applicant.phone || '',
    comments: coverNote || '',
  };
  const { ok, status, json, text } = await fetchJSON(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ok, status, reference: json?.applicationId || undefined, error: ok ? undefined : (text || 'submit_failed') };
}
