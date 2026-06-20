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
  return normalize(parsed || heuristic(text), text);
}

// Pull the candidate's contact details straight from the résumé text (works with
// or without the LLM). Used to pre-fill the in-app contact step so employers can
// actually reach the user — the application carries these.
function extractContact(text) {
  const email = (text.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/) || [''])[0].toLowerCase();
  const phoneRaw = (text.match(/(\+?\d[\d\s().-]{7,}\d)/) || [''])[0];
  const phone = phoneRaw.replace(/\s+/g, ' ').trim();
  let name = '';
  for (const line of text.split(/\r?\n/).slice(0, 6)) {
    const t = line.trim();
    if (/^[A-Z][a-zA-Z'.-]+(?:\s+[A-Z][a-zA-Z'.-]+){1,3}$/.test(t)) { name = t; break; }
  }
  return { name, email, phone };
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

function normalize(p, rawText = '') {
  return {
    targetRole: titleCase(String(p.targetRole || 'Senior Product Designer')),
    years: Number(p.years) || 6,
    seniority: p.seniority || 'Senior',
    skills: Array.isArray(p.skills) ? p.skills.slice(0, 8) : [],
    summary: String(p.summary || ''),
    contact: extractContact(rawText),
  };
}

const titleCase = (s) => s.replace(/\w\S*/g, (w) => w[0].toUpperCase() + w.slice(1).toLowerCase());

/** Build a full résumé from the user's notes (premium one-time feature). */
export async function buildResume(input = {}) {
  const { name = '', role = '', years = '', skills = '', experience = '' } = input;
  const out = await llmJSON({
    system: 'You write a clean, professional, strictly truthful résumé from the candidate\'s notes. Respond with JSON only.',
    prompt:
      `Name: ${name}\nTarget role: ${role}\nYears: ${years}\nSkills: ${skills}\n` +
      `Experience notes:\n"""${String(experience).slice(0, 5000)}"""\n\n` +
      'Write a complete one-page résumé: a short summary, a skills line, experience with concise ' +
      'bullet points, and education if mentioned. Use ONLY what the notes support — do not invent ' +
      'employers, titles, or dates. Return JSON {"resume": string}.',
    maxTokens: 1500,
  });
  return out?.resume || templateResume(input);
}

function templateResume({ name, role, years, skills, experience }) {
  return [
    name || 'Candidate',
    [role, years ? `${years} years` : ''].filter(Boolean).join(' · '),
    skills ? `\nSkills: ${skills}` : '',
    experience ? `\nExperience:\n${experience}` : '',
  ].filter(Boolean).join('\n');
}
