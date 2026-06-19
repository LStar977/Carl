// Greenhouse Job Board API — Tier-A apply (real submission endpoint).
// Docs: https://developers.greenhouse.io/job-board.html
import { fetchJSON } from '../util.js';

/**
 * Submit an application to a Greenhouse-hosted job.
 * Requires the board's Job Board API key (Basic auth, base64) — held server-side.
 * @returns {{ ok: boolean, status: number, reference?: string, error?: string }}
 */
export async function submitGreenhouse({ boardToken, jobId, apiKey, applicant, coverNote, resumeText }) {
  if (!boardToken || !jobId || !apiKey) {
    return { ok: false, status: 0, error: 'missing_greenhouse_config' };
  }
  const url = `https://boards-api.greenhouse.io/v1/boards/${boardToken}/jobs/${jobId}`;
  const auth = Buffer.from(`${apiKey}:`).toString('base64');
  const body = new URLSearchParams({
    first_name: applicant.firstName,
    last_name: applicant.lastName,
    email: applicant.email,
    phone: applicant.phone || '',
    cover_letter_text: coverNote || '',
    resume_text: resumeText || '',
  });
  const { ok, status, json, text } = await fetchJSON(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });
  return { ok, status, reference: json?.success ? String(json.success) : undefined, error: ok ? undefined : (text || 'submit_failed') };
}
