// agi/core/pipeline.js — Lucy → Bruce → Strategist → Operator chain.
// Output stays user-visible at every step; nothing is auto-executed.

'use strict';

const { chat } = require('../providers/openai-compat');
const { PERSONAS } = require('./personas');
const { resolveProvider } = require('./router');

async function callRole(role, userText, extraSystem = '') {
  const provider = resolveProvider(role);
  const persona = PERSONAS[role];
  if (!persona) throw new Error(`unknown role: ${role}`);
  const system = extraSystem ? `${persona.system}\n\n${extraSystem}` : persona.system;
  const { text } = await chat(provider, [
    { role: 'system', content: system },
    { role: 'user',   content: userText },
  ]);
  return { role, providerName: provider.name, text };
}

function safeJson(s) {
  try { return JSON.parse(s); } catch {}
  // try to extract first {...} block
  const m = s.match(/\{[\s\S]*\}/);
  if (m) { try { return JSON.parse(m[0]); } catch {} }
  return null;
}

async function runPipeline(rawInput, { onStep } = {}) {
  const steps = [];

  // 1) Lucy — classify
  const lucy = await callRole('lucy', rawInput);
  const lucyJson = safeJson(lucy.text);
  steps.push({ ...lucy, parsed: lucyJson });
  onStep?.(steps[steps.length - 1]);

  // 2) Bruce — security audit (if execution likely)
  const needsExec = !!lucyJson?.needs_command_execution
    || ['task', 'command'].includes(lucyJson?.intent);
  let bruce = null;
  if (needsExec) {
    bruce = await callRole(
      'bruce',
      `Original input:\n${rawInput}\n\nLucy's classification:\n${lucy.text}`
    );
    const bruceJson = safeJson(bruce.text);
    steps.push({ ...bruce, parsed: bruceJson });
    onStep?.(steps[steps.length - 1]);
    if (bruceJson?.verdict === 'block') {
      return { steps, blocked: true, reason: bruceJson.reasons?.join('; ') || 'auditor blocked' };
    }
  }

  // 3) Strategist — produce a plan
  const strategist = await callRole(
    'strategist',
    `User input:\n${rawInput}\n\nClassification:\n${lucy.text}\n` +
    (bruce ? `\nAuditor verdict:\n${bruce.text}\n` : '')
  );
  steps.push(strategist);
  onStep?.(steps[steps.length - 1]);

  // 4) Operator — translate plan into safe_exec.sh lines
  const operator = await callRole(
    'operator',
    `Plan from Strategist:\n${strategist.text}`
  );
  steps.push(operator);
  onStep?.(steps[steps.length - 1]);

  return { steps, blocked: false };
}

module.exports = { callRole, runPipeline };
