// The apply engine: draft a tailored application (Claude or templated), then
// submit it. Tier A submits via official ATS APIs; everything else is Tier B
// (assisted — the user confirms). APPLY_MODE=dry-run never hits a real employer.
import { config } from '../config.js';
import { llmJSON } from '../llm.js';
import { submitGreenhouse } from '../adapters/greenhouse.js';
import { submitLever } from '../adapters/lever.js';

export function classifyTier(job) {
  return job.applyTier === 'A' ? 'A' : 'B';
}

/** Produce a cover note + screening answers tailored to the job. */
export async function draftApplication(profile, job) {
  const parsed = profile?.resume?.parsed || {};
  const elig = profile?.eligibility || {};
  const drafted = await llmJSON({
    system: 'You are Carl, drafting a concise, genuine job application. Respond with JSON only.',
    prompt:
      `Candidate: ${parsed.targetRole}, ${parsed.years} yrs, skills: ${(parsed.skills || []).join(', ')}.\n` +
      `Job: ${job.title} at ${job.company} (${job.location}).\n` +
      `${job.descriptionSnippet}\n` +
      `Facts to use truthfully in answers: ${eligibilityFacts(elig)}\n\n` +
      'Return JSON {"coverNote": string (2-3 sentences, first person), ' +
      '"answers": [{"question": string, "answer": string}] (1-2 items)}',
    maxTokens: 500,
  });
  return drafted || templateDraft(parsed, job);
}

/** Rewrite the user's résumé to emphasise what's relevant to a specific job.
 *  Premium feature (+1 credit). Stays truthful; falls back to the base résumé. */
export async function tailorResume(profile, job) {
  const base = profile?.resume?.rawText || '';
  const parsed = profile?.resume?.parsed || {};
  const out = await llmJSON({
    system: 'You tailor a résumé to a specific job while staying strictly truthful. Respond with JSON only.',
    prompt:
      `Base résumé:\n"""${base.slice(0, 6000)}"""\n\n` +
      `Target job: ${job.title} at ${job.company}. ${job.descriptionSnippet}\n\n` +
      'Rewrite the résumé to surface the most relevant experience, skills and keywords ' +
      'for this job. Do NOT invent experience, employers, or dates. Keep it realistic and concise. ' +
      'Return JSON {"resume": string}.',
    maxTokens: 1200,
  });
  return out?.resume || base || `${parsed.targetRole || 'Candidate'} — ${(parsed.skills || []).join(', ')}`;
}

/** Summarise the screening answers Carl actually knows, for the draft prompt. */
function eligibilityFacts(e) {
  const f = [];
  if (e.authorized != null) f.push(`work-authorized: ${e.authorized ? 'yes' : 'no'}`);
  if (e.needsSponsorship != null) f.push(`needs visa sponsorship: ${e.needsSponsorship ? 'yes' : 'no'}`);
  if (e.willingToRelocate != null) f.push(`willing to relocate: ${e.willingToRelocate ? 'yes' : 'no'}`);
  if (e.salaryExpectation) f.push(`salary expectation: ${e.salaryExpectation}`);
  if (e.noticePeriod) f.push(`notice period: ${e.noticePeriod}`);
  return f.length ? f.join(', ') : 'none provided';
}

function templateDraft(parsed, job) {
  return {
    coverNote:
      `${job.company}'s work is exactly where I do my best. Over ${parsed.years || 6} years as a ` +
      `${parsed.targetRole || 'designer'} I've shipped ${(parsed.skills || ['design systems'])[1] || 'impactful'} ` +
      'work end-to-end, and I\'d bring that ownership here.',
    answers: [
      {
        question: 'Why do you want this role?',
        answer: `I want to own ${(parsed.skills || ['the craft'])[0]} with a team that values quality, and ${job.company} fits that.`,
      },
    ],
  };
}

/**
 * Submit an application. In dry-run mode (default) it records the submission
 * without contacting an employer. In live mode, Tier-A jobs are submitted via
 * their ATS API; Tier-B remains assisted (recorded as submitted by the user).
 */
export async function submitApplication({ user, profile, job, draft, resumeText }) {
  const tier = classifyTier(job);
  const applicant = applicantFrom(user, profile);
  const resume = resumeText || profile?.resume?.rawText;

  if (config.applyMode !== 'live') {
    return { submitted: true, mode: 'dry-run', tier, reference: `dry_${job.externalId}` };
  }

  // Never submit a real application without a real email — the employer replies
  // there. The app captures this during onboarding; this is the final backstop.
  if (!applicant.email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(applicant.email)) {
    return { submitted: false, mode: 'blocked', tier, error: 'missing_contact_email' };
  }

  if (tier === 'A' && job.source === 'greenhouse' && job.greenhouse) {
    const r = await submitGreenhouse({
      boardToken: job.greenhouse.boardToken,
      jobId: job.greenhouse.jobId,
      apiKey: job.greenhouse.apiKey,
      applicant,
      coverNote: draft.coverNote,
      resumeText: resume,
    });
    return { submitted: r.ok, mode: 'live', tier, reference: r.reference, error: r.error };
  }

  if (tier === 'A' && job.source === 'lever' && job.lever) {
    const r = await submitLever({ site: job.lever.site, postingId: job.lever.postingId, applicant, coverNote: draft.coverNote });
    return { submitted: r.ok, mode: 'live', tier, reference: r.reference, error: r.error };
  }

  // Tier B in live mode: the application is prepared; the user submits via the
  // employer's site. We record it as submitted-by-user.
  return { submitted: true, mode: 'assisted', tier, reference: `assisted_${job.externalId}` };
}

function applicantFrom(user, profile) {
  const name = (user?.name || '').trim().split(/\s+/).filter(Boolean);
  return {
    firstName: name[0] || '',
    lastName: name.slice(1).join(' ') || '',
    email: (user?.email || '').trim(),
    phone: user?.phone || '',
  };
}
