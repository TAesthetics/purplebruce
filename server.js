// ═══════════════════════════════════════════════════════════════
//  PURPLE BRUCE CYBERDECK v4.2 — HYBRID SERVER
//  Grok + Venice.ai dual provider. Real command execution.
//  Black Ice with preview/confirm. Persistent autonomous agent.
// ═══════════════════════════════════════════════════════════════

const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, 'purplebruce.db');

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS config (key TEXT PRIMARY KEY, value TEXT);
  CREATE TABLE IF NOT EXISTS chat_history (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT NOT NULL, content TEXT NOT NULL, timestamp TEXT DEFAULT (datetime('now')));
  CREATE TABLE IF NOT EXISTS agent_log (id INTEGER PRIMARY KEY AUTOINCREMENT, round INTEGER, session_id TEXT, type TEXT, content TEXT, timestamp TEXT DEFAULT (datetime('now')));
  CREATE TABLE IF NOT EXISTS scan_results (id INTEGER PRIMARY KEY AUTOINCREMENT, target TEXT, mode TEXT, output TEXT, timestamp TEXT DEFAULT (datetime('now')));
  CREATE TABLE IF NOT EXISTS tasks (id TEXT PRIMARY KEY, type TEXT NOT NULL, label TEXT, pid INTEGER, status TEXT DEFAULT 'running', started TEXT DEFAULT (datetime('now')), ended TEXT);
`);
db.prepare("UPDATE tasks SET status = 'crashed' WHERE status = 'running'").run();

function getConfig(k) { const r = db.prepare('SELECT value FROM config WHERE key = ?').get(k); return r ? r.value : null; }
function setConfig(k, v) { db.prepare('INSERT OR REPLACE INTO config (key, value) VALUES (?, ?)').run(k, v); }

// ═══ TASK MANAGER ═══
const liveTasks = {};
function registerTask(type, label, proc, abortFn) {
  const id = uuidv4().slice(0, 8);
  const pid = proc?.pid || null;
  const started = new Date().toISOString();
  liveTasks[id] = { proc, type, label, started, abortFn, pid };
  db.prepare('INSERT INTO tasks (id, type, label, pid, status, started) VALUES (?,?,?,?,?,?)').run(id, type, label, pid, 'running', started);
  broadcast('task_registered', { id, type, label, pid, status: 'running', started });
  return id;
}
function completeTask(id) {
  delete liveTasks[id];
  db.prepare("UPDATE tasks SET status='completed', ended=datetime('now') WHERE id=?").run(id);
  broadcast('task_completed', { id });
}
function killTask(id) {
  const t = liveTasks[id];
  if (t) { if (t.abortFn) t.abortFn(); if (t.proc?.pid) try { process.kill(t.proc.pid, 'SIGTERM'); } catch {} delete liveTasks[id]; }
  else { const r = db.prepare("SELECT pid FROM tasks WHERE id=? AND status='running'").get(id); if (r?.pid) try { process.kill(r.pid, 'SIGTERM'); } catch {} }
  db.prepare("UPDATE tasks SET status='killed', ended=datetime('now') WHERE id=?").run(id);
  broadcast('task_killed', { id });
  return true;
}
function listTasks() {
  return db.prepare("SELECT * FROM tasks ORDER BY started DESC LIMIT 50").all().map(t => ({ ...t, alive: !!liveTasks[t.id] }));
}

// ═══ WEBSOCKET ═══
const clients = new Set();
wss.on('connection', (ws) => {
  clients.add(ws);
  ws.on('close', () => clients.delete(ws));
  ws.on('message', (raw) => { try { handleWsMessage(ws, JSON.parse(raw)); } catch {} });
  ws.send(JSON.stringify({ type: 'agent_status', data: { running: agent.running, round: agent.round, maxRounds: agent.maxRounds, autonomous: agent.autonomousExec, pendingCmd: agent.pendingCmd ? { round: agent.pendingCmd.round, cmd: agent.pendingCmd.cmd } : null } }));
  // send provider info
  ws.send(JSON.stringify({ type: 'provider_status', data: getProviderStatus() }));
});
function broadcast(type, data, channel) { const m = JSON.stringify({ type, data, channel }); for (const ws of clients) if (ws.readyState === 1) ws.send(m); }

// ═══ SHELL EXEC ═══
function runCommand(cmd, args, channel) {
  return new Promise((resolve) => {
    const output = [];
    const proc = spawn(cmd, args, { shell: true, env: { ...process.env, TERM: 'xterm-256color' }, timeout: 300000 });
    const sendLine = (text, type = 'stdout') => { const line = { type, text: text.toString(), channel }; output.push(line); broadcast('terminal', line, channel); };
    proc.stdout.on('data', d => d.toString().split('\n').filter(l => l).forEach(l => sendLine(l, 'stdout')));
    proc.stderr.on('data', d => d.toString().split('\n').filter(l => l).forEach(l => sendLine(l, 'stderr')));
    proc.on('close', c => { sendLine(`[EXIT ${c}]`, c === 0 ? 'info' : 'error'); resolve({ code: c, output, proc }); });
    proc.on('error', e => { sendLine(`[ERROR] ${e.message}`, 'error'); resolve({ code: 1, output, proc }); });
  });
}
function execCollect(cmd) { try { return execSync(cmd, { timeout: 30000, encoding: 'utf8' }).trim(); } catch (e) { return e.stdout?.trim() || ''; } }

// ═══ INTEL ═══
function collectIntel() {
  return {
    hostname: execCollect('hostname'), user: execCollect('whoami'), kernel: execCollect('uname -a'),
    shell: process.env.SHELL || '/bin/sh',
    ip: execCollect("hostname -I 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || echo unknown"),
    uptime: execCollect('uptime -p 2>/dev/null || uptime'),
    distro: execCollect('cat /etc/os-release 2>/dev/null | head -2 || sw_vers 2>/dev/null'),
    ports: execCollect('ss -tlnp 2>/dev/null | head -20 || lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | head -20'),
    suid: execCollect('find / -perm -4000 -type f 2>/dev/null | head -10'),
    cron: execCollect('crontab -l 2>/dev/null'),
    historyExposed: ['.bash_history', '.ash_history', '.zsh_history'].filter(f => fs.existsSync(path.join(process.env.HOME || '/root', f))),
    pathDot: (process.env.PATH || '').includes('.:'),
  };
}
function intelStr(i) {
  let s = `Host:${i.hostname} User:${i.user} Kernel:${i.kernel} Shell:${i.shell} IP:${i.ip} Up:${i.uptime} `;
  if (i.historyExposed.length) s += `History:${i.historyExposed.join(',')} `;
  if (i.pathDot) s += 'WARN:dot-in-PATH ';
  return s;
}

// ═══ AI PROVIDER — GROK + VENICE ═══
function getProviderStatus() {
  const provider = getConfig('ai_provider') || 'grok';
  const grokKey = getConfig('grok_api_key');
  const veniceKey = getConfig('venice_api_key');
  return {
    provider,
    grokHasKey: !!grokKey, grokMask: grokKey ? grokKey.slice(0, 8) + '...' : null,
    veniceHasKey: !!veniceKey, veniceMask: veniceKey ? veniceKey.slice(0, 8) + '...' : null,
  };
}

async function callAI(messages) {
  const provider = getConfig('ai_provider') || 'grok';

  if (provider === 'venice') {
    return callVenice(messages);
  }
  return callGrok(messages);
}

async function callGrok(messages) {
  const key = getConfig('grok_api_key');
  if (!key) return null;
  try {
    const r = await fetch('https://api.x.ai/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` },
      body: JSON.stringify({ model: 'grok-3-mini', messages, temperature: 0.7, max_tokens: 2048 })
    });
    const d = await r.json();
    return d?.choices?.[0]?.message?.content || null;
  } catch { return null; }
}

async function callVenice(messages) {
  const key = getConfig('venice_api_key');
  if (!key) return null;
  try {
    const r = await fetch('https://api.venice.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${key}` },
      body: JSON.stringify({ model: 'llama-3.3-70b', messages, temperature: 0.7, max_tokens: 2048 })
    });
    const d = await r.json();
    return d?.choices?.[0]?.message?.content || null;
  } catch { return null; }
}

// ═══ SECURITY TOOLS ═══

async function doScan(target, mode) {
  const ch = 'scan', tid = registerTask('scan', `Scan ${target} [${mode}]`, null, null);
  const output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };

  send(`[RECON] Scanning ${target} | Mode: ${mode}`);
  const ping = await runCommand('ping', ['-c', '1', '-W', '2', target], ch); output.push(...ping.output);

  const hasNmap = execCollect('which nmap 2>/dev/null');
  if (hasNmap) {
    const flags = { QUICK: '-T4 -F --open', FULL: '-T4 -p- --open', STEALTH: '-sS -T2 -F --open', STANDARD: '-T4 --top-ports 100 --open' }[mode] || '-T4 -F --open';
    send(`[RECON] nmap ${flags} ${target}`);
    const r = await runCommand('nmap', [flags, target], ch); output.push(...r.output);
  } else {
    send('[RECON] nmap not found, using nc fallback');
    const ports = mode === 'QUICK' ? [22, 80, 443, 8080] : [21, 22, 25, 53, 80, 443, 3306, 5432, 6379, 8080, 8443, 9200, 27017];
    for (const p of ports) { const r = await runCommand('sh', ['-c', `echo ""|nc -w 2 ${target} ${p} && echo "OPEN:${p}" || echo "CLOSED:${p}"`], ch); output.push(...r.output); }
  }

  send('[RECON] HTTP Headers');
  const h = await runCommand('sh', ['-c', `curl -sI -m 5 http://${target} 2>/dev/null || printf "HEAD / HTTP/1.0\\r\\nHost: ${target}\\r\\n\\r\\n"|nc -w 3 ${target} 80 2>/dev/null|head -15`], ch);
  output.push(...h.output);

  if (execCollect('which openssl 2>/dev/null')) {
    send('[RECON] SSL Check');
    const s = await runCommand('sh', ['-c', `echo|openssl s_client -connect ${target}:443 -servername ${target} 2>/dev/null|openssl x509 -noout -subject -dates -issuer 2>/dev/null`], ch);
    output.push(...s.output);
  }
  send('[RECON] Scan complete.'); completeTask(tid); return output;
}

async function doHarden() {
  const ch = 'harden', home = process.env.HOME || '/root', tid = registerTask('harden', 'Fortress Protocol', null, null);
  const output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  send('[FORTRESS] Security audit starting...');
  const r = await runCommand('sh', ['-c', `
echo "=== SSH ===" && [ -d "${home}/.ssh" ] && { [ -f "${home}/.ssh/authorized_keys" ] && echo "[PASS] auth_keys: $(wc -l<${home}/.ssh/authorized_keys) keys"||echo "[WARN] No auth_keys"; } || echo "[INFO] No .ssh"
echo "=== World-writable ===" && WW=$(find ${home} -maxdepth 2 -perm -002 -type f 2>/dev/null|head -10) && { [ -n "$WW" ]&&{ echo "[FAIL] World-writable:";echo "$WW"; }||echo "[PASS] Clean"; }
echo "=== PATH ===" && case "$PATH" in *.:*|.:*|*:.) echo "[FAIL] Dot in PATH";;*) echo "[PASS] PATH clean";;esac
echo "=== History ===" && for f in .bash_history .ash_history .zsh_history;do [ -f "${home}/$f" ]&&echo "[WARN] $f exposed";done
echo "=== SUID ===" && echo "[INFO] SUID: $(find / -perm -4000 -type f 2>/dev/null|wc -l)" && find / -perm -4000 -type f 2>/dev/null|head -10
echo "=== Ports ===" && ss -tlnp 2>/dev/null||lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -20
  `], ch);
  output.push(...r.output); send('[FORTRESS] Audit complete.'); completeTask(tid); return output;
}

async function doHunt() {
  const ch = 'hunt', tid = registerTask('hunt', 'Ghost Protocol', null, null);
  const output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  send('[GHOST] Threat hunting...');
  const r = await runCommand('sh', ['-c', `
echo "== PROCESSES ==" && ps aux 2>/dev/null|head -20
echo "== PORTS ==" && ss -tlnp 2>/dev/null||lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -20
echo "== CONNECTIONS ==" && ss -tnp 2>/dev/null|grep ESTAB|head -15
echo "== CRON ==" && crontab -l 2>/dev/null||echo "None"
echo "== HIDDEN /tmp ==" && H=$(find /tmp -name ".*" -type f 2>/dev/null) && { [ -n "$H" ]&&echo "[ALERT] $H"||echo "[CLEAN]"; }
echo "== ENV SECRETS ==" && env|grep -iE "key|token|pass|secret|api" 2>/dev/null|head -5||echo "[PASS] Clean"
echo "== PERSISTENCE ==" && [ -z "$LD_PRELOAD" ]&&echo "[PASS] LD_PRELOAD clean"||echo "[ALERT] LD_PRELOAD:$LD_PRELOAD"
  `], ch);
  output.push(...r.output); send('[GHOST] Hunt complete.'); completeTask(tid); return output;
}

// ═══ BLACK ICE — REAL COMMANDS WITH PREVIEW ═══
const RED_TACTICS = {
  'cred-dump': {
    mitre: 'T1003.001', name: 'CREDENTIAL DUMPING', detect: 87,
    description: 'Check if /etc/shadow is readable, find SSH keys, check for leaked creds in env/history.',
    commands: [
      { label: 'Check shadow readability', cmd: 'cat /etc/shadow > /dev/null 2>&1 && echo "[VULN] shadow READABLE" || echo "[SAFE] shadow protected"' },
      { label: 'Find SSH private keys', cmd: 'find / -name "id_rsa" -o -name "*.pem" -o -name "id_ed25519" 2>/dev/null | head -10' },
      { label: 'Check env for secrets', cmd: 'env | grep -iE "password|secret|token|api_key" 2>/dev/null | head -5 || echo "clean"' },
      { label: 'Check bash history for creds', cmd: 'grep -iE "pass|mysql.*-p|curl.*-u|wget.*--password" ~/.bash_history 2>/dev/null | tail -5 || echo "clean"' },
    ]
  },
  'lateral': {
    mitre: 'T1021.002', name: 'LATERAL MOVEMENT', detect: 74,
    description: 'Check for SSH access, known hosts, ARP table, and network neighbors.',
    commands: [
      { label: 'SSH banner on localhost', cmd: 'echo QUIT | nc -w 2 127.0.0.1 22 2>/dev/null | head -1 || echo "No SSH on localhost"' },
      { label: 'Known SSH hosts', cmd: 'cat ~/.ssh/known_hosts 2>/dev/null | awk "{print $1}" | head -10 || echo "none"' },
      { label: 'ARP / network neighbors', cmd: 'arp -a 2>/dev/null || ip neigh 2>/dev/null | head -10' },
      { label: 'Check for other users', cmd: 'who 2>/dev/null; last -5 2>/dev/null' },
    ]
  },
  'c2-https': {
    mitre: 'T1071.001', name: 'C2 OVER HTTPS', detect: 38,
    description: 'Test outbound HTTPS connectivity and DNS-over-HTTPS capability.',
    commands: [
      { label: 'HTTPS egress test', cmd: 'curl -s -o /dev/null -w "HTTP %{http_code} %{time_total}s" https://example.com 2>/dev/null || echo "Blocked"' },
      { label: 'DNS-over-HTTPS test', cmd: 'curl -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=example.com&type=A" 2>/dev/null | head -1 || echo "N/A"' },
      { label: 'Check proxy settings', cmd: 'echo "HTTP_PROXY=$HTTP_PROXY HTTPS_PROXY=$HTTPS_PROXY"' },
    ]
  },
  'ransomware': {
    mitre: 'T1486', name: 'RANSOMWARE CHAIN', detect: 95,
    description: 'Check backup directories for write access and look for encrypted files.',
    commands: [
      { label: 'Check backup dirs', cmd: 'for d in /backup /var/backups $HOME/backups; do [ -d "$d" ] && { [ -w "$d" ] && echo "[RISK] $d writable" || echo "[SAFE] $d read-only"; }; done' },
      { label: 'Find encrypted/locked files', cmd: 'find / -name "*.encrypted" -o -name "*.locked" -o -name "*.ransom" 2>/dev/null | head -5 || echo "None found"' },
      { label: 'Check volume shadow copies', cmd: 'vssadmin list shadows 2>/dev/null || echo "Not available"' },
    ]
  },
  'fileless': {
    mitre: 'T1546.015', name: 'FILELESS PERSISTENCE', detect: 29,
    description: 'Check LD_PRELOAD, shared memory, and alias hijacking.',
    commands: [
      { label: 'LD_PRELOAD check', cmd: '[ -z "$LD_PRELOAD" ] && echo "[SAFE] LD_PRELOAD empty" || echo "[ALERT] LD_PRELOAD=$LD_PRELOAD"' },
      { label: 'ld.so.preload', cmd: 'cat /etc/ld.so.preload 2>/dev/null && echo "[ALERT] ld.so.preload exists" || echo "[SAFE] No ld.so.preload"' },
      { label: 'Suspicious aliases', cmd: 'alias 2>/dev/null | grep -iE "sudo|ssh|curl|wget" || echo "[SAFE] No suspicious aliases"' },
      { label: 'Shared memory check', cmd: 'ls -la /dev/shm/ 2>/dev/null || echo "N/A"' },
    ]
  },
  'sched-task': {
    mitre: 'T1053.005', name: 'SCHEDULED TASK', detect: 81,
    description: 'Check crontabs, system cron directories, and systemd timers.',
    commands: [
      { label: 'User crontab', cmd: 'crontab -l 2>/dev/null || echo "No user crontab"' },
      { label: 'System cron dirs', cmd: 'ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ 2>/dev/null' },
      { label: 'Systemd timers', cmd: 'systemctl list-timers 2>/dev/null | head -15 || echo "N/A"' },
    ]
  },
  'dns-exfil': {
    mitre: 'T1048.003', name: 'DNS EXFILTRATION', detect: 44,
    description: 'Check DNS configuration and test DNS resolution capabilities.',
    commands: [
      { label: 'DNS config', cmd: 'cat /etc/resolv.conf 2>/dev/null' },
      { label: 'DNS resolution test', cmd: 'dig +short example.com 2>/dev/null || nslookup example.com 2>/dev/null | tail -3 || echo "No DNS tools"' },
      { label: 'Check for dig/nslookup', cmd: 'which dig nslookup host 2>/dev/null || echo "Limited DNS tools"' },
    ]
  },
  'persistence': {
    mitre: 'T1053', name: 'PERSISTENCE CHECK', detect: 70,
    description: 'Check for persistence mechanisms: cron, rc.local, profile scripts.',
    commands: [
      { label: 'Cron persistence', cmd: 'crontab -l 2>/dev/null; ls /etc/cron.d/ 2>/dev/null' },
      { label: 'rc.local', cmd: 'cat /etc/rc.local 2>/dev/null || echo "No rc.local"' },
      { label: 'Profile scripts', cmd: 'ls -la ~/.bashrc ~/.profile ~/.bash_profile /etc/profile.d/ 2>/dev/null | head -10' },
    ]
  },
  'recon': {
    mitre: 'T1082', name: 'SYSTEM RECON', detect: 90,
    description: 'Full system reconnaissance: host, user, kernel, network, processes.',
    commands: [
      { label: 'System info', cmd: 'echo "Host: $(hostname) | User: $(whoami) | Kernel: $(uname -r) | Shell: $SHELL"' },
      { label: 'Network info', cmd: 'hostname -I 2>/dev/null || ipconfig getifaddr en0 2>/dev/null; ip route 2>/dev/null | head -5' },
      { label: 'Running services', cmd: 'ss -tlnp 2>/dev/null || lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | head -15' },
    ]
  },
  'discovery': {
    mitre: 'T1046', name: 'NETWORK DISCOVERY', detect: 60,
    description: 'Discover local network services and hosts.',
    commands: [
      { label: 'Localhost scan', cmd: 'for p in 22 80 443 3000 5000 8080 8443 9090; do (echo ""|nc -w 1 127.0.0.1 "$p") >/dev/null 2>&1 && echo "OPEN: 127.0.0.1:$p"; done' },
      { label: 'ARP table', cmd: 'arp -a 2>/dev/null || ip neigh 2>/dev/null | head -15' },
      { label: 'Network interfaces', cmd: 'ip addr 2>/dev/null || ifconfig 2>/dev/null' },
    ]
  },
  'exfiltration': {
    mitre: 'T1048', name: 'EXFILTRATION TEST', detect: 50,
    description: 'Test exfiltration channels: DNS, HTTP, ICMP.',
    commands: [
      { label: 'DNS exfil simulation', cmd: 'dig +short example.com 2>/dev/null || nslookup example.com 2>/dev/null | tail -3 || echo "No DNS tools"' },
      { label: 'HTTP egress', cmd: 'curl -s -o /dev/null -w "%{http_code}" https://example.com 2>/dev/null || echo "Blocked"' },
      { label: 'ICMP egress', cmd: 'ping -c 1 -W 2 8.8.8.8 2>/dev/null && echo "[OPEN] ICMP allowed" || echo "[BLOCKED] ICMP blocked"' },
    ]
  },
};

async function doRedPreview(tactic) {
  const t = RED_TACTICS[tactic];
  if (!t) return { error: `Unknown tactic: ${tactic}` };
  return {
    tactic, mitre: t.mitre, name: t.name, detect: t.detect,
    description: t.description,
    commands: t.commands.map((c, i) => ({ index: i, label: c.label, cmd: c.cmd }))
  };
}

async function doRedExecute(tactic, commandIndices) {
  const t = RED_TACTICS[tactic];
  if (!t) return [];
  const ch = 'red', tid = registerTask('red', `Red:${tactic}`, null, null);
  const output = [];
  const send = (text, tp = 'info') => { const l = { type: tp, text, channel: ch }; output.push(l); broadcast('terminal', l, ch); };

  send(`[BLACK ICE] ${t.mitre} — ${t.name}`);

  const indices = commandIndices && commandIndices.length > 0 ? commandIndices : t.commands.map((_, i) => i);
  for (const idx of indices) {
    const c = t.commands[idx];
    if (!c) continue;
    send(`\n[EXEC] ${c.label}`, 'cmd');
    const r = await runCommand('sh', ['-c', c.cmd], ch);
    output.push(...r.output);
  }

  send(`\n[BLACK ICE] ${tactic} emulation complete.`);
  completeTask(tid);
  broadcast('red_done', { tactic });
  return output;
}

// ═══ AUTONOMOUS AGENT — REAL COMMANDS ═══
const agent = { running: false, round: 0, maxRounds: 0, sessionId: null, pendingCmd: null, aborted: false, autonomousExec: false, output: [], taskId: null };

async function startAgent(maxRounds, autonomousExec) {
  if (agent.running) return { message: 'Agent already running.' };
  const unlimited = maxRounds === 0;
  Object.assign(agent, { running: true, round: 0, maxRounds: unlimited ? 999999 : maxRounds, sessionId: uuidv4(), aborted: false, autonomousExec, output: [], pendingCmd: null });
  agent.taskId = registerTask('agent', `Agent ${autonomousExec ? 'AUTO' : 'NORMAL'} ${unlimited ? '∞' : 'x' + maxRounds}`, null, () => { agent.aborted = true; });

  const send = (text, type = 'info') => { const l = { type, text }; agent.output.push(l); broadcast('agent_line', l, 'auto'); db.prepare('INSERT INTO agent_log (round,session_id,type,content) VALUES (?,?,?,?)').run(agent.round, agent.sessionId, type, text); };
  broadcast('agent_status', { running: true, round: 0, maxRounds: agent.maxRounds, autonomous: autonomousExec, unlimited });

  send('╔══════════════════════════════════════════════╗');
  send(`║  AGENT — ${autonomousExec ? 'FULL AUTONOMOUS' : 'APPROVAL MODE'}${' '.repeat(autonomousExec ? 11 : 7)}║`);
  send(`║  ${unlimited ? 'UNLIMITED — runs until stopped' : maxRounds + ' rounds'}${' '.repeat(unlimited ? 12 : 30)}║`);
  send('╚══════════════════════════════════════════════╝');

  send('\n[AUTO] Collecting intel...');
  const intel = collectIntel(), is = intelStr(intel);
  send('[AUTO] Running baseline...');
  const auditOut = execCollect(`ls -la $HOME/.ssh/ 2>/dev/null;find $HOME -maxdepth 2 -perm -002 -type f 2>/dev/null|head -5;ss -tlnp 2>/dev/null|head -10 || lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -10`);
  const huntOut = execCollect(`ps aux 2>/dev/null|head -10;ss -tnp 2>/dev/null|grep ESTAB|head -5;crontab -l 2>/dev/null`);

  const provider = getConfig('ai_provider') || 'grok';
  const sysPrompt = `You are NETGHOST AI, an autonomous cybersecurity agent on Purple Bruce v4.2 Cyberdeck (provider: ${provider}). Cyberpunk 2077 corpo netrunner. REAL system access. Data: ${is}\nAUDIT: ${auditOut}\nHUNT: ${huntOut}\n\nEach round: 1) Critical issue 2) CMD: <real shell command> 3) Explanation 4) Severity 5) NEXT: next check. The commands WILL BE EXECUTED on the real system. Plain text only.`;
  let prev = '';
  const max = unlimited ? 999999 : maxRounds;

  for (let r = 1; r <= max; r++) {
    if (agent.aborted) { send('\n[ABORT] Stopped.'); break; }
    agent.round = r;
    broadcast('agent_status', { running: true, round: r, maxRounds: agent.maxRounds, autonomous: autonomousExec, unlimited });
    send(`\n┌─ ROUND ${r}${unlimited ? '' : '/' + maxRounds} ──────────────────────┐`);

    const prompt = r === 1 ? sysPrompt : `Continue. Previous: ${prev}. System: ${is}. Round ${r}. Next issue. Same format. Plain text.`;
    send('[AUTO] NetGhost analyzing...');
    const answer = await callAI([{ role: 'user', content: prompt }]);
    if (!answer) { send('[ERROR] No AI response.', 'error'); await new Promise(r => setTimeout(r, 5000)); continue; }

    answer.split('\n').forEach(l => {
      if (l.includes('CRITICAL')) send(l, 'error');
      else if (l.includes('HIGH')) send(l, 'warn');
      else if (l.includes('CMD:')) send(l, 'cmd');
      else if (l.includes('NEXT:')) send(l, 'next');
      else send(l, 'info');
    });

    // REAL command execution
    const cm = answer.match(/CMD:\s*(.+)/);
    if (cm) {
      const cmd = cm[1].trim();
      if (autonomousExec) {
        send(`\n[AUTO-EXEC] ${cmd}`, 'cmd');
        const res = execCollect(cmd);
        (res || '(no output)').split('\n').forEach(l => send(`  ${l}`, 'stdout'));
        send('[AUTO-EXEC] Done.');
      } else {
        agent.pendingCmd = { round: r, cmd, approved: undefined };
        broadcast('agent_pending_cmd', { round: r, cmd });
        send(`\n[WAITING] Approve? -> ${cmd}`, 'cmd');
        const start = Date.now();
        while (agent.pendingCmd?.approved === undefined && Date.now() - start < 120000 && !agent.aborted) await new Promise(r => setTimeout(r, 500));
        const ap = agent.pendingCmd?.approved;
        if (ap === true) { send(`[EXEC] ${cmd}`, 'cmd'); const res = execCollect(cmd); (res || '(no output)').split('\n').forEach(l => send(`  ${l}`, 'stdout')); send('[EXEC] Done.'); }
        else if (ap === false) send('[SKIP] Rejected.', 'warn');
        else send('[TIMEOUT] Skipped.', 'warn');
        agent.pendingCmd = null;
      }
    }
    prev = answer.slice(0, 500);
    if (!agent.aborted) { const w = unlimited ? 15 : (autonomousExec ? 3 : 5); send(`[AUTO] Next in ${w}s...`); await new Promise(r => setTimeout(r, w * 1000)); }
  }

  if (!agent.aborted) {
    send('\n══ AGENT COMPLETE ══');
    const summary = await callAI([{ role: 'user', content: `Summary of ${agent.round} rounds. Critical findings, actions, risks, priorities. Plain text.` }]);
    if (summary) { send('\n── SUMMARY ──'); summary.split('\n').forEach(l => send(l)); }
  }
  agent.running = false; agent.pendingCmd = null; completeTask(agent.taskId);
  broadcast('agent_status', { running: false, round: agent.round, maxRounds: agent.maxRounds, autonomous: false });
  return { message: `Agent finished after ${agent.round} rounds.` };
}

// ═══ CHAT ═══
async function doChat(message) {
  if (!message) return { role: 'assistant', content: 'Empty message.' };
  const provider = getConfig('ai_provider') || 'grok';
  const key = provider === 'venice' ? getConfig('venice_api_key') : getConfig('grok_api_key');
  if (!key) return { role: 'assistant', content: `No ${provider} API key configured. Open settings.` };

  db.prepare('INSERT INTO chat_history (role,content) VALUES (?,?)').run('user', message);
  const hist = db.prepare('SELECT role,content FROM chat_history ORDER BY id DESC LIMIT 20').all().reverse();
  const sys = { role: 'system', content: `You are NETGHOST AI on Purple Bruce v4.2 (${provider}). Cyberpunk netrunner pentester. System: ${intelStr(collectIntel())}. Use CMD: prefix for commands that CAN be executed on the real system. Be concise.` };
  const answer = await callAI([sys, ...hist.map(h => ({ role: h.role, content: h.content }))]);
  const resp = answer || 'Neural link down. Check API key.';
  db.prepare('INSERT INTO chat_history (role,content) VALUES (?,?)').run('assistant', resp);
  broadcast('chat_response', { role: 'assistant', content: resp });
  return { role: 'assistant', content: resp };
}

// ═══ REPORT ═══
async function doReport() {
  const intel = collectIntel();
  const tc = db.prepare("SELECT COUNT(*) as c FROM tasks").get().c;
  const lines = [
    { type: 'info', text: '══════════════════════════════════════' },
    { type: 'info', text: '  PURPLE BRUCE v4.2 — INTEL REPORT' },
    { type: 'info', text: '══════════════════════════════════════' },
    { type: 'stdout', text: `  Host: ${intel.hostname}` },
    { type: 'stdout', text: `  User: ${intel.user}` },
    { type: 'stdout', text: `  Kernel: ${intel.kernel}` },
    { type: 'stdout', text: `  IP: ${intel.ip}` },
    { type: 'stdout', text: `  Provider: ${getConfig('ai_provider') || 'grok'}` },
    { type: 'stdout', text: `  Agent: ${agent.running ? 'RUNNING R' + agent.round : 'STANDBY'}` },
    { type: 'stdout', text: `  Tasks: ${tc}` },
    { type: 'info', text: '══════════════════════════════════════' },
  ];
  if (intel.historyExposed.length) lines.push({ type: 'warn', text: `  [WARN] Exposed: ${intel.historyExposed.join(', ')}` });
  return lines;
}

// ═══ WS HANDLER ═══
async function handleWsMessage(ws, msg) {
  switch (msg.action) {
    case 'scan': doScan(msg.target, msg.mode || 'STANDARD'); break;
    case 'harden': doHarden(); break;
    case 'hunt': doHunt(); break;
    case 'red_preview': {
      const preview = await doRedPreview(msg.tactic);
      ws.send(JSON.stringify({ type: 'red_preview', data: preview }));
      break;
    }
    case 'red_execute': {
      try {
        await doRedExecute(msg.tactic, msg.commandIndices);
      } catch (e) {
        broadcast('terminal', { type: 'error', text: `[BLACK ICE] ${e.message}`, channel: 'red' }, 'red');
        broadcast('red_done', { tactic: msg.tactic, error: e.message });
      }
      break;
    }
    case 'chat': {
      if (!msg.message) return;
      const resp = await doChat(msg.message);
      ws.send(JSON.stringify({ type: 'chat_response', data: resp }));
      break;
    }
    case 'agent_start': startAgent(msg.rounds || 0, msg.autonomous ?? agent.autonomousExec); break;
    case 'agent_stop': agent.aborted = true; broadcast('agent_status', { running: false, round: agent.round, maxRounds: agent.maxRounds, autonomous: agent.autonomousExec }); break;
    case 'agent_approve': if (agent.pendingCmd?.round === msg.round) agent.pendingCmd.approved = msg.approve; break;
    case 'autonomous_toggle': agent.autonomousExec = msg.enabled; broadcast('agent_status', { running: agent.running, round: agent.round, maxRounds: agent.maxRounds, autonomous: agent.autonomousExec }); break;
    case 'exec_cmd': if (msg.cmd) { const tid = registerTask('exec', `CMD:${msg.cmd.slice(0, 40)}`, null, null); await runCommand('sh', ['-c', msg.cmd], msg.channel || 'chat'); completeTask(tid); } break;
    case 'task_list': ws.send(JSON.stringify({ type: 'task_list', data: listTasks() })); break;
    case 'task_kill': killTask(msg.id); ws.send(JSON.stringify({ type: 'task_list', data: listTasks() })); break;
    case 'set_key': {
      if (msg.key && msg.provider) {
        const configKey = msg.provider === 'venice' ? 'venice_api_key' : 'grok_api_key';
        setConfig(configKey, msg.key);
        ws.send(JSON.stringify({ type: 'key_saved', data: { provider: msg.provider, masked: msg.key.slice(0, 8) + '...' } }));
        broadcast('provider_status', getProviderStatus());
      }
      break;
    }
    case 'set_provider': {
      setConfig('ai_provider', msg.provider);
      broadcast('provider_status', getProviderStatus());
      break;
    }
    case 'get_provider': ws.send(JSON.stringify({ type: 'provider_status', data: getProviderStatus() })); break;
    case 'get_key': { const s = getProviderStatus(); ws.send(JSON.stringify({ type: 'key_status', data: { hasKey: s.provider === 'venice' ? s.veniceHasKey : s.grokHasKey, masked: s.provider === 'venice' ? s.veniceMask : s.grokMask } })); break; }
    case 'get_chat_history': ws.send(JSON.stringify({ type: 'chat_history', data: db.prepare('SELECT role,content,timestamp FROM chat_history ORDER BY id').all() })); break;
    case 'clear_chat': db.prepare('DELETE FROM chat_history').run(); ws.send(JSON.stringify({ type: 'chat_cleared' })); break;
    case 'get_status': { const i = collectIntel(); ws.send(JSON.stringify({ type: 'status', data: { ...i, agentRunning: agent.running, agentRound: agent.round, agentAutonomous: agent.autonomousExec, provider: getConfig('ai_provider') || 'grok' } })); break; }
    case 'get_red_tactics': ws.send(JSON.stringify({ type: 'red_tactics', data: Object.entries(RED_TACTICS).map(([id, t]) => ({ id, mitre: t.mitre, name: t.name, detect: t.detect, description: t.description, commandCount: t.commands.length })) })); break;
  }
}

// ═══ CLI BRIDGE ═══
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.post('/api/cli', async (req, res) => {
  const { cmd, target, mode, tactic, message, id, key, provider, rounds } = req.body;
  const autonomousMode = req.body.mode;
  try {
    switch (cmd) {
      case 'scan': res.json({ lines: await doScan(target, mode || 'STANDARD') }); break;
      case 'harden': res.json({ lines: await doHarden() }); break;
      case 'hunt': res.json({ lines: await doHunt() }); break;
      case 'red': res.json({ lines: await doRedExecute(tactic, []) }); break;
      case 'chat': { const r = await doChat(message); res.json({ lines: [{ type: 'info', text: r.content }] }); break; }
      case 'report': res.json({ lines: await doReport() }); break;
      case 'tasks': res.json(listTasks()); break;
      case 'kill': killTask(id); res.json({ message: `Task ${id} killed.` }); break;
      case 'set_key': { const ck = provider === 'venice' ? 'venice_api_key' : 'grok_api_key'; setConfig(ck, key); broadcast('provider_status', getProviderStatus()); res.json({ message: `${provider} key saved: ${key.slice(0, 8)}...` }); break; }
      case 'set_provider': setConfig('ai_provider', provider); broadcast('provider_status', getProviderStatus()); res.json({ message: `Provider: ${provider}` }); break;
      case 'autonomous': { agent.autonomousExec = autonomousMode === 'on'; broadcast('agent_status', { running: agent.running, round: agent.round, maxRounds: agent.maxRounds, autonomous: agent.autonomousExec }); res.json({ message: `Autonomous: ${agent.autonomousExec ? 'ON' : 'OFF'}` }); break; }
      case 'agent_start': { if (agent.running) { res.json({ message: 'Agent already running.' }); } else { startAgent(rounds || 0, agent.autonomousExec); res.json({ message: `Agent started.` }); } break; }
      case 'agent_stop': agent.aborted = true; res.json({ message: 'Agent stopping...' }); break;
      default: res.json({ error: `Unknown: ${cmd}` });
    }
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/status', (req, res) => res.json({ version: '4.2.0', ...collectIntel(), agentRunning: agent.running, provider: getConfig('ai_provider') || 'grok' }));
app.get('/api/tasks', (req, res) => res.json(listTasks()));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n╔══════════════════════════════════════════════╗\n║  PURPLE BRUCE v4.2 | Port ${PORT} | HYBRID MODE   ║\n╚══════════════════════════════════════════════╝\n`);
});
