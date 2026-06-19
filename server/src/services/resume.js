// Résumé parsing: Claude when available, deterministic heuristics otherwise.
import { llmJSON } from '../llm.js';

const KNOWN_SKILLS = [
  'Figma', 'Design Systems', 'Prototyping', 'UX Research', 'Sketch', 'Swift',
  'React', 'TypeScript', 'Python', 'Node', 'SQL', 'Product Strategy',
  'Roadmapping', 'A/B Testing', 'Accessibility', 'Data Analysis', 'Leadership',
];

export async function parseResume(rawText) {
  const text = (rawText || '').trim();
  const parsed = await llmJSON({
    system: 'You extract a structured candidate profile from a résumé. Respond with JSON only.',
    prompt:
      `Résumé:\n"""${text.slice(0, 8000)}"""\n\n` +
      'Return JSON: {"targetRole": string, "years": number, "seniority": ' +
      '"Junior"|"Mid"|"Senior"|"Staff"|"Lead", "skills": string[] (max 8), "summary": string}',
    maxTokens: 600,
  });
  return normalize(parsed || heuristic(text));
}

function heuristic(text) {
  const lower = text.toLowerCase();
  const skills = KNOWN_SKILLS.filter((s) => lower.includes(s.toLowerCase())).slice(0, 8);
  const yearsMatch = lower.match(/(\d{1,2})\+?\s*(?:years|yrs)/);
  const years = yearsMatch ? Number(yearsMatch[1]) : 6;
  const roleMatch = text.match(/(senior|staff|lead|principal|junior)?\s*(product designer|software engineer|designer|engineer|product manager|data scientist)/i);
  const targetRole = roleMatch ? roleMatch[0].trim().replace(/\s+/g, ' ') : 'Senior Product Designer';
  return {
    targetRole: titleCase(targetRole),
    years,
    seniority: years >= 8 ? 'Staff' : years >= 4 ? 'Senior' : years >= 2 ? 'Mid' : 'Junior',
    skills: skills.length ? skills : ['Figma', 'Design Systems', 'Prototyping', 'UX Research'],
    summary: 'Experienced candidate with a strong track record of shipping impactful work.',
  };
}

function normalize(p) {
  return {
    targetRole: titleCase(String(p.targetRole || 'Senior Product Designer')),
    years: Number(p.years) || 6,
    seniority: p.seniority || 'Senior',
    skills: Array.isArray(p.skills) ? p.skills.slice(0, 8) : [],
    summary: String(p.summary || ''),
  };
}

const titleCase = (s) => s.replace(/\w\S*/g, (w) => w[0].toUpperCase() + w.slice(1).toLowerCase());
