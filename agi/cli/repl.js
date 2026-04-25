// agi/cli/repl.js — minimal interactive loop for the `ai` CLI.

'use strict';

const readline = require('readline');
const { callRole, runPipeline } = require('../core/pipeline');

const C = {
  reset: '\x1b[0m', dim: '\x1b[2m',
  pink: '\x1b[38;5;201m', purple: '\x1b[38;5;129m',
  cyan: '\x1b[38;5;51m',  yellow: '\x1b[38;5;226m',
  green: '\x1b[38;5;46m', red: '\x1b[38;5;196m',
};

function header(label) {
  process.stdout.write(`${C.purple}┌─ ${C.cyan}${label}${C.reset}\n`);
}
function body(text) {
  for (const line of String(text).split('\n')) {
    process.stdout.write(`${C.purple}│${C.reset} ${line}\n`);
  }
  process.stdout.write(`${C.purple}└────${C.reset}\n`);
}

async function start({ defaultMode = 'pipeline', defaultRole = 'strategist' } = {}) {
  let mode = defaultMode; // 'pipeline' | 'role'
  let role = defaultRole;

  process.stdout.write(`${C.pink}AGI · CLI · ${mode}${C.reset}  (commands: /role <name>, /mode pipeline|role, /quit)\n`);

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const ask = () => rl.question(`${C.pink}master>${C.reset} `, async (line) => {
    const msg = (line || '').trim();
    if (!msg) return ask();
    if (msg === '/quit' || msg === 'exit') { rl.close(); return; }
    if (msg.startsWith('/role ')) { role = msg.slice(6).trim(); mode = 'role'; process.stdout.write(`${C.dim}role → ${role}${C.reset}\n`); return ask(); }
    if (msg.startsWith('/mode ')) { mode = msg.slice(6).trim(); process.stdout.write(`${C.dim}mode → ${mode}${C.reset}\n`); return ask(); }

    try {
      if (mode === 'role') {
        const { text } = await callRole(role, msg);
        header(`${role}`);
        body(text);
      } else {
        await runPipeline(msg, {
          onStep: (s) => { header(s.role + ' · ' + s.providerName); body(s.text); }
        });
      }
    } catch (e) {
      process.stdout.write(`${C.red}error:${C.reset} ${e.message || e}\n`);
    }
    ask();
  });
  ask();
}

module.exports = { start };
