// Contact capture: résumé extraction pre-fills it, and a live application is
// blocked without a real email (so employers can always reach the user).
import assert from 'node:assert/strict';

process.env.APPLY_MODE = 'live'; // must be set before importing config/apply
const { parseResume } = await import('../src/services/resume.js');
const { submitApplication } = await import('../src/services/apply.js');

let n = 0;
const ok = (cond, msg) => { assert.ok(cond, msg); console.log(`  ok ${++n} - ${msg}`); };

// --- résumé contact extraction (heuristic path; no LLM key in tests) ---------
const r = await parseResume(
  'Jane Smith\nSenior Product Designer\njane.smith@example.com | (415) 555-0199\n6 years experience. Figma.',
);
ok(r.contact.email === 'jane.smith@example.com', 'extracts email from résumé');
ok(/555-0199/.test(r.contact.phone), 'extracts phone from résumé');
ok(r.contact.name === 'Jane Smith', 'extracts name from résumé');

// --- live apply requires a real email ---------------------------------------
const job = { applyTier: 'B', externalId: 'x1', source: 'lever', company: 'Acme', title: 'Product Designer' };
const draft = { coverNote: 'hi', answers: [] };

const blocked = await submitApplication({ user: { name: '', email: '' }, profile: {}, job, draft });
ok(blocked.submitted === false && blocked.error === 'missing_contact_email', 'live apply blocked without email');

const sent = await submitApplication({ user: { name: 'Jane Smith', email: 'jane@example.com' }, profile: {}, job, draft });
ok(sent.submitted === true && sent.mode === 'assisted', 'live tier-B proceeds once an email is present');

console.log(`\ncontact.test: ${n} checks passed`);
