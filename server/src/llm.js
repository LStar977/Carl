// Thin Claude (Anthropic Messages API) wrapper. Returns null when no key is
// configured or the call fails, so callers can fall back to deterministic logic.
import { config, hasLLM } from './config.js';
import { fetchJSON } from './util.js';

export async function llmText({ system, prompt, model, maxTokens = 1024 }) {
  if (!hasLLM) return null;
  const { ok, json } = await fetchJSON('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': config.anthropicKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: model || config.model,
      max_tokens: maxTokens,
      system,
      messages: [{ role: 'user', content: prompt }],
    }),
  }, 20000);
  if (!ok || !json) return null;
  return (json.content || []).map((b) => b.text || '').join('').trim();
}

export async function llmJSON(args) {
  const text = await llmText(args);
  return parseJSONLoose(text);
}

export function parseJSONLoose(text) {
  if (!text) return null;
  const m = text.match(/\{[\s\S]*\}|\[[\s\S]*\]/);
  if (!m) return null;
  try { return JSON.parse(m[0]); } catch { return null; }
}
