// agi/providers/openai-compat.js — One fetch for any OpenAI-compatible chat-completions API.
// Used for OpenAI, Grok (x.ai), Venice (OpenRouter etc.). Node 18+ (native fetch).

'use strict';

/** @typedef {{role:'system'|'user'|'assistant', content:string}} Msg */
/** @typedef {{baseURL:string, apiKey:string, model:string, temperature?:number, maxTokens?:number, timeoutMs?:number}} Cfg */

/**
 * @param {Cfg} cfg
 * @param {Msg[]} messages
 * @returns {Promise<{text:string, raw:any}>}
 */
async function chat(cfg, messages) {
  if (!cfg.apiKey) throw new Error(`missing apiKey for ${cfg.baseURL}`);
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), cfg.timeoutMs ?? 60_000);
  let r;
  try {
    r = await fetch(`${cfg.baseURL.replace(/\/+$/, '')}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${cfg.apiKey}`,
      },
      body: JSON.stringify({
        model: cfg.model,
        messages,
        temperature: cfg.temperature ?? 0.7,
        max_tokens: cfg.maxTokens ?? 2048,
      }),
      signal: ac.signal,
    });
  } finally {
    clearTimeout(t);
  }
  const raw = await r.json().catch(() => ({}));
  if (!r.ok) {
    const msg = raw?.error?.message || raw?.message || `${r.status} ${r.statusText}`;
    throw new Error(`provider error: ${msg}`);
  }
  const text = raw?.choices?.[0]?.message?.content ?? '';
  return { text, raw };
}

module.exports = { chat };
