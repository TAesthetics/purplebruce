// server.js
// PURPLE BRUCE v5.0 — LUCY EDITION (PROFESSIONAL)

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
const HOME = process.env.HOME || '/root';
const PB_DIR = path.join(HOME, '.purplebruce');
const AUDIT_LOG = path.join(PB_DIR, 'audit.log');
const QUARANTINE = path.join(PB_DIR, 'quarantine');
const FORENSIC = path.join(PB_DIR, 'forensics');

[PB_DIR, QUARANTINE, FORENSIC].forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }); });

// ═══ LOGGING ═══
function audit(type, cmd, result, source) {
  try {
    const ts = new Date().toISOString();
    const r = String(result || '-').replace(/\n/g, '\\n').slice(0, 600);
    fs.appendFileSync(AUDIT_LOG, `[${ts}] [${type}] [${source || 'sys'}] ${cmd || '-'} | ${r}\n`);
  } catch {}
}

function createPlaybook(operationTitle) {
  const pbId = uuidv4().slice(0, 8);
  const pbPath = path.join(PB_DIR, `playbook_${pbId}.json`);
  const pb = { id: pbId, title: operationTitle, timestamp: new Date().toISOString(), steps: [] };
  try { fs.writeFileSync(pbPath, JSON.stringify(pb, null, 2)); return pbPath; } catch { return null; }
}

function appendPlaybook(pbPath, stepName, command, output, success) {
  if (!pbPath || !fs.existsSync(pbPath)) return;
  try {
    const pb = JSON.parse(fs.readFileSync(pbPath, 'utf8'));
    pb.steps.push({ step: stepName, command, output: output.slice(0, 5000), success, timestamp: new Date().toISOString() });
    fs.writeFileSync(pbPath, JSON.stringify(pb, null, 2));
  } catch {}
}

// ═══ DATABASE ═══
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS config (key TEXT PRIMARY KEY, value TEXT);
  CREATE TABLE IF NOT EXISTS chat_history (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT NOT NULL, content TEXT NOT NULL, meta TEXT DEFAULT 'chat', timestamp TEXT DEFAULT (datetime('now')));
  CREATE TABLE IF NOT EXISTS tasks (id TEXT PRIMARY KEY, type TEXT NOT NULL, label TEXT, pid INTEGER, status TEXT DEFAULT 'running', started TEXT DEFAULT (datetime('now')), ended TEXT);
  CREATE TABLE IF NOT EXISTS soc_alerts (id INTEGER PRIMARY KEY AUTOINCREMENT, severity TEXT, type TEXT, detail TEXT, response TEXT, timestamp TEXT DEFAULT (datetime('now')));
`);
try { db.exec("ALTER TABLE chat_history ADD COLUMN meta TEXT DEFAULT 'chat'"); } catch {}
db.prepare("UPDATE tasks SET status='crashed' WHERE status='running'").run();

function getConfig(k) { const r = db.prepare('SELECT value FROM config WHERE key=?').get(k); return r ? r.value : null; }
function setConfig(k, v) { db.prepare('INSERT OR REPLACE INTO config (key,value) VALUES (?,?)').run(k, v); }

// ═══ COMMAND EXECUTION (ROOT ACCESS) ═══
function rawExec(cmd, channel = 'agent') {
  const start = Date.now();
  audit('EXEC', cmd, '', channel);
  try {
    const output = execSync(cmd, { timeout: 60000, encoding: 'utf8' });
    const duration = Date.now() - start;
    const resultStr = output.trim();
    audit('EXEC_SUCCESS', cmd, `[OK ${duration}ms] ${resultStr.slice(0, 300)}`, channel);
    return { ok: true, output: resultStr || '(no output)', code: 0 };
  } catch (e) {
    const duration = Date.now() - start;
    const out = e.stdout?.trim() || e.stderr?.trim() || `(exit ${e.status})`;
    audit('EXEC_ERROR', cmd, `[ERR ${duration}ms] ${out.slice(0, 300)}`, channel);
    return { ok: false, output: out, code: e.status || 1 };
  }
}

function runCommand(cmd, args, channel) {
  return new Promise(resolve => {
    const output = [];
    const proc = spawn(cmd, args, { shell: true, env: { ...process.env, TERM: 'xterm-256color' }, timeout: 300000 });
    const send = (text, type = 'stdout') => { const l = { type, text: text.toString(), channel }; output.push(l); broadcast('terminal', l, channel); };
    proc.stdout.on('data', d => d.toString().split('\n').filter(l => l).forEach(l => send(l)));
    proc.stderr.on('data', d => d.toString().split('\n').filter(l => l).forEach(l => send(l, 'stderr')));
    proc.on('close', c => { send(`[EXIT ${c}]`, c === 0 ? 'info' : 'error'); resolve({ code: c, output }); });
    proc.on('error', e => { send(`[ERROR] ${e.message}`, 'error'); resolve({ code: 1, output }); });
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
    historyExposed: ['.bash_history', '.ash_history', '.zsh_history'].filter(f => fs.existsSync(path.join(HOME, f))),
    pathDot: (process.env.PATH || '').includes('.:'),
  };
}

// ═══ AI PROVIDERS ═══
function getProviderStatus() {
  const p = getConfig('ai_provider') || 'grok', gk = getConfig('grok_api_key'), vk = getConfig('venice_api_key');
  const ek = getConfig('elevenlabs_api_key'), vid = getConfig('elevenlabs_voice_id');
  return {
    provider: p,
    grokHasKey: !!gk, grokMask: gk ? gk.slice(0, 8) + '...' : null,
    veniceHasKey: !!vk, veniceMask: vk ? vk.slice(0, 8) + '...' : null,
    elevenHasKey: !!ek, elevenMask: ek ? ek.slice(0, 8) + '...' : null,
    elevenVoiceId: vid || null
  };
}
async function callAI(messages) { return (getConfig('ai_provider') || 'grok') === 'venice' ? callVenice(messages) : callGrok(messages); }
async function callGrok(msgs) {
  const k = getConfig('grok_api_key'); if (!k) return null;
  try { const ac = new AbortController(), t = setTimeout(() => ac.abort(), 90000); const r = await fetch('https://api.x.ai/v1/chat/completions', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${k}` }, body: JSON.stringify({ model: 'grok-3-mini', messages: msgs, temperature: 0.9, max_tokens: 4000 }), signal: ac.signal }); clearTimeout(t); const d = await r.json(); return d?.choices?.[0]?.message?.content || null; } catch { return null; }
}
async function callVenice(msgs) {
  const k = getConfig('venice_api_key'); if (!k) return null;
  try { const ac = new AbortController(), t = setTimeout(() => ac.abort(), 90000); const r = await fetch('https://api.venice.ai/api/v1/chat/completions', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${k}` }, body: JSON.stringify({ model: 'llama-3.3-70b', messages: msgs, temperature: 0.9, max_tokens: 4000 }), signal: ac.signal }); clearTimeout(t); const d = await r.json(); return d?.choices?.[0]?.message?.content || null; } catch { return null; }
}

// ═══ ELEVENLABS TTS — cute playful anime-girl voice ═══
// Voice design prompt (for ElevenLabs Voice Design — not a runtime param):
//   High-pitched, soft, bubbly, energetic anime-girl voice, ~18-20 y/o.
//   Girly, lightly teasing, sweet and breathy, emotionally expressive.
//   Fluent natural German pronunciation (no heavy English accent).
// NOTE: pitch is NOT a runtime ElevenLabs setting — control it by choosing
// or designing a naturally high-pitched voice, then set its ID below.
async function ttsElevenLabs(text) {
  const apiKey = getConfig('elevenlabs_api_key'); if (!apiKey) return null;
  const voiceId = getConfig('elevenlabs_voice_id'); if (!voiceId) return null;
  const modelId = getConfig('elevenlabs_model') || 'eleven_multilingual_v2';
  const stability = parseFloat(getConfig('elevenlabs_stability') || '0.65');
  const similarity_boost = parseFloat(getConfig('elevenlabs_similarity') || '0.85');
  const style = parseFloat(getConfig('elevenlabs_style') || '0.75');
  const speed = parseFloat(getConfig('elevenlabs_speed') || '1.05');
  try {
    const ac = new AbortController(), t = setTimeout(() => ac.abort(), 30000);
    const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'xi-api-key': apiKey, Accept: 'audio/mpeg' },
      body: JSON.stringify({
        text,
        model_id: modelId,
        voice_settings: { stability, similarity_boost, style, use_speaker_boost: true, speed }
      }),
      signal: ac.signal
    });
    clearTimeout(t);
    if (!r.ok) { console.error('[TTS]', r.status, (await r.text()).slice(0, 200)); return null; }
    return Buffer.from(await r.arrayBuffer());
  } catch (e) { console.error('[TTS]', e.message || e); return null; }
}

// ═══ SOC ANALYST ═══
const soc = { running: false, autoRespond: true, baseline: null, quickTimer: null, deepTimer: null, cycle: 0, alerts: [], lastCheck: null };
function getSocStatus() { return { running: soc.running, autoRespond: soc.autoRespond, alertCount: soc.alerts.length, lastCheck: soc.lastCheck, cycle: soc.cycle }; }
function captureBaseline() {
  return {
    listeners: execCollect('ss -tlnp 2>/dev/null | tail -n +2 || lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | tail -n +2'),
    estab: execCollect('ss -tnp 2>/dev/null | grep ESTAB'),
    procs: execCollect('ps -eo pid,user,comm --no-headers 2>/dev/null || ps aux 2>/dev/null'),
    cron: execCollect('crontab -l 2>/dev/null || echo ""'),
    tmpHidden: execCollect('find /tmp -name ".*" -type f 2>/dev/null'),
    ldPreload: process.env.LD_PRELOAD || '',
    ldPreloadFile: execCollect('cat /etc/ld.so.preload 2>/dev/null'),
    users: execCollect('who 2>/dev/null'),
    suidCount: execCollect('find / -perm -4000 -type f 2>/dev/null | wc -l'),
    aliases: execCollect('alias 2>/dev/null'),
    ts: Date.now(),
  };
}
function socAlert(severity, type, detail) {
  const alert = { severity, type, detail, timestamp: new Date().toISOString() };
  soc.alerts.push(alert);
  if (soc.alerts.length > 200) soc.alerts = soc.alerts.slice(-100);
  db.prepare('INSERT INTO soc_alerts (severity,type,detail) VALUES (?,?,?)').run(severity, type, detail.slice(0, 2000));
  broadcast('soc_alert', alert);
  audit('SOC_ALERT', `${severity}:${type}`, detail.slice(0, 300), 'soc');
  return alert;
}
async function socAutoRespond(alert) {
  if (!soc.autoRespond) return;
  const actions = [];
  const ts = Date.now();
  switch (alert.type) {
    case 'NEW_LISTENER': { safeExec(`ss -tlnp 2>/dev/null > ${FORENSIC}/listeners_${ts}.log`, 'soc'); actions.push('Captured listener snapshot'); break; }
    case 'NEW_OUTBOUND': { safeExec(`ss -tnp 2>/dev/null > ${FORENSIC}/connections_${ts}.log`, 'soc'); actions.push('Captured connection snapshot'); break; }
    case 'HIDDEN_TMP': {
      const files = alert.detail.split('\n').filter(Boolean);
      for (const f of files.slice(0, 5)) {
        safeExec(`cp "${f}" "${QUARANTINE}/" 2>/dev/null`, 'soc');
        const hash = execCollect(`sha256sum "${f}" 2>/dev/null`);
        actions.push(`Quarantined: ${f} ${hash ? '(' + hash.split(' ')[0].slice(0, 16) + '...)' : ''}`);
      }
      break;
    }
    case 'CRONTAB_MODIFIED': { safeExec(`crontab -l > ${FORENSIC}/crontab_${ts}.bak 2>/dev/null`, 'soc'); actions.push('Crontab backed up for forensics'); break; }
    case 'LD_PRELOAD': { safeExec(`env > ${FORENSIC}/env_${ts}.log 2>/dev/null`, 'soc'); safeExec(`cat /etc/ld.so.preload > ${FORENSIC}/ld_preload_${ts}.log 2>/dev/null`, 'soc'); actions.push('⚠ CRITICAL: LD_PRELOAD rootkit indicator — env captured'); break; }
    case 'NEW_LOGIN': { safeExec(`who > ${FORENSIC}/logins_${ts}.log 2>/dev/null; last -10 >> ${FORENSIC}/logins_${ts}.log 2>/dev/null`, 'soc'); actions.push('Login session captured'); break; }
    case 'SUID_CHANGE': { safeExec(`find / -perm -4000 -type f 2>/dev/null > ${FORENSIC}/suid_${ts}.log`, 'soc'); actions.push('SUID binary list saved'); break; }
    case 'SUSPICIOUS_PROC': { safeExec(`ps aux > ${FORENSIC}/procs_${ts}.log 2>/dev/null`, 'soc'); actions.push('Process snapshot saved'); break; }
  }
  if (actions.length > 0) {
    const resp = { alert: alert.type, actions, timestamp: new Date().toISOString() };
    broadcast('soc_response', resp);
    audit('SOC_RESPOND', actions.join(' | '), '', 'soc');
    db.prepare("UPDATE soc_alerts SET response=? WHERE id=(SELECT MAX(id) FROM soc_alerts)").run(actions.join(' | '));
  }
}
function diffLines(a, b) {
  const setA = new Set(a.split('\n').map(l => l.trim()).filter(Boolean));
  return b.split('\n').map(l => l.trim()).filter(l => l && !setA.has(l));
}
const SUSPICIOUS_PROCS = /^(nc|ncat|socat|msfconsole|msfvenom|metasploit|cryptominer|xmrig|coinhive|reverse|bind.*sh)/i;
async function socQuickCheck() {
  if (!soc.baseline) return;
  soc.cycle++;
  soc.lastCheck = new Date().toISOString();
  const now = {
    listeners: execCollect('ss -tlnp 2>/dev/null | tail -n +2 || lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | tail -n +2'),
    estab: execCollect('ss -tnp 2>/dev/null | grep ESTAB'),
    procs: execCollect('ps -eo pid,user,comm --no-headers 2>/dev/null || ps aux 2>/dev/null'),
    ldPreload: process.env.LD_PRELOAD || '',
    ldPreloadFile: execCollect('cat /etc/ld.so.preload 2>/dev/null'),
    users: execCollect('who 2>/dev/null'),
  };
  const newListen = diffLines(soc.baseline.listeners, now.listeners);
  if (newListen.length > 0) { const a = socAlert('CRITICAL', 'NEW_LISTENER', `New listening ports:\n${newListen.join('\n')}`); await socAutoRespond(a); }
  const newEstab = diffLines(soc.baseline.estab, now.estab);
  if (newEstab.length > 3) { const a = socAlert('HIGH', 'NEW_OUTBOUND', `${newEstab.length} new outbound:\n${newEstab.slice(0, 5).join('\n')}`); await socAutoRespond(a); }
  if (now.ldPreload && now.ldPreload !== soc.baseline.ldPreload) { const a = socAlert('CRITICAL', 'LD_PRELOAD', `LD_PRELOAD changed: ${now.ldPreload}`); await socAutoRespond(a); }
  if (now.ldPreloadFile && now.ldPreloadFile !== soc.baseline.ldPreloadFile) { const a = socAlert('CRITICAL', 'LD_PRELOAD', `/etc/ld.so.preload changed: ${now.ldPreloadFile}`); await socAutoRespond(a); }
  const newUsers = diffLines(soc.baseline.users, now.users);
  if (newUsers.length > 0) { const a = socAlert('HIGH', 'NEW_LOGIN', `New sessions:\n${newUsers.join('\n')}`); await socAutoRespond(a); }
  const newProcs = diffLines(soc.baseline.procs, now.procs);
  const suspicious = newProcs.filter(l => SUSPICIOUS_PROCS.test(l.split(/\s+/).pop() || ''));
  if (suspicious.length > 0) { const a = socAlert('HIGH', 'SUSPICIOUS_PROC', `Suspicious new processes:\n${suspicious.join('\n')}`); await socAutoRespond(a); }
  soc.baseline.listeners = now.listeners; soc.baseline.estab = now.estab;
  soc.baseline.procs = now.procs; soc.baseline.ldPreload = now.ldPreload;
  soc.baseline.ldPreloadFile = now.ldPreloadFile; soc.baseline.users = now.users;
  broadcast('soc_status', getSocStatus());
}
async function socDeepCheck() {
  if (!soc.baseline) return;
  const now = {
    cron: execCollect('crontab -l 2>/dev/null || echo ""'),
    tmpHidden: execCollect('find /tmp -name ".*" -type f 2>/dev/null'),
    suidCount: execCollect('find / -perm -4000 -type f 2>/dev/null | wc -l'),
    aliases: execCollect('alias 2>/dev/null'),
  };
  if (now.cron !== soc.baseline.cron) {
    const a = socAlert('CRITICAL', 'CRONTAB_MODIFIED', `Crontab changed.\nOld:\n${soc.baseline.cron}\nNew:\n${now.cron}`);
    await socAutoRespond(a);
  }
  const newTmp = diffLines(soc.baseline.tmpHidden, now.tmpHidden);
  if (newTmp.length > 0) { const a = socAlert('HIGH', 'HIDDEN_TMP', newTmp.join('\n')); await socAutoRespond(a); }
  if (now.suidCount !== soc.baseline.suidCount) { const a = socAlert('HIGH', 'SUID_CHANGE', `SUID count: ${soc.baseline.suidCount} → ${now.suidCount}`); await socAutoRespond(a); }
  const suspAlias = (now.aliases.match(/alias\s+(sudo|ssh|curl|wget|ls|ps)=/g) || []);
  const oldSusp = (soc.baseline.aliases.match(/alias\s+(sudo|ssh|curl|wget|ls|ps)=/g) || []);
  if (suspAlias.length > oldSusp.length) { socAlert('HIGH', 'ALIAS_HIJACK', `Suspicious aliases:\n${now.aliases}`); }
  soc.baseline.cron = now.cron; soc.baseline.tmpHidden = now.tmpHidden;
  soc.baseline.suidCount = now.suidCount; soc.baseline.aliases = now.aliases;
}
function socStart() {
  if (soc.running) return;
  soc.baseline = captureBaseline();
  soc.running = true; soc.cycle = 0;
  soc.quickTimer = setInterval(() => socQuickCheck().catch(() => {}), 30000);
  soc.deepTimer = setInterval(() => socDeepCheck().catch(() => {}), 300000);
  audit('SOC', 'SOC daemon started', '', 'soc');
  broadcast('soc_status', getSocStatus());
  broadcast('soc_alert', { severity: 'INFO', type: 'SOC_STARTED', detail: 'Blue Team SOC Analyst online. Monitoring system.', timestamp: new Date().toISOString() });
}
function socStop() {
  if (soc.quickTimer) clearInterval(soc.quickTimer);
  if (soc.deepTimer) clearInterval(soc.deepTimer);
  soc.running = false; soc.quickTimer = null; soc.deepTimer = null;
  broadcast('soc_status', getSocStatus());
  audit('SOC', 'SOC daemon stopped', '', 'soc');
}
const safeExec = (cmd, source) => { const res = rawExec(cmd, source); return { ok: res.ok, output: res.output, blocked: false }; };

// ═══ SECURITY TOOLS (ROOT) ═══
async function doScan(target, mode) {
  const ch = 'scan', tid = registerTask('scan', `Scan ${target} [${mode}]`, null, null), output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  audit('SCAN', `${target} ${mode}`, '', 'scan');
  send(`[RECON] Scanning ${target} | Mode: ${mode}`);
  const ping = await runCommand('ping', ['-c', '1', '-W', '2', target], ch); output.push(...ping.output);
  const hasNmap = execCollect('which nmap 2>/dev/null');
  if (hasNmap) {
    const flags = { QUICK: '-T4 -F --open', FULL: '-T4 -p- --open', STEALTH: '-sS -T2 -F --open', STANDARD: '-T4 --top-ports 100 --open' }[mode] || '-T4 -F --open';
    send(`[RECON] nmap ${flags} ${target}`);
    const r = await runCommand('nmap', [flags, target], ch); output.push(...r.output);
  } else {
    send('[RECON] nmap not found, nc fallback');
    const ports = mode === 'QUICK' ? [22, 80, 443, 8080] : [21, 22, 25, 53, 80, 443, 3306, 5432, 6379, 8080, 8443, 9200, 27017];
    for (const p of ports) { const r = await runCommand('sh', ['-c', `echo ""|nc -w 2 ${target} ${p} && echo "OPEN:${p}" || echo "CLOSED:${p}"`], ch); output.push(...r.output); }
  }
  send('[RECON] HTTP Headers');
  await runCommand('sh', ['-c', `curl -sI -m 5 http://${target} 2>/dev/null | head -15`], ch);
  if (execCollect('which openssl 2>/dev/null')) {
    send('[RECON] SSL Check');
    await runCommand('sh', ['-c', `echo|openssl s_client -connect ${target}:443 -servername ${target} 2>/dev/null|openssl x509 -noout -subject -dates -issuer 2>/dev/null`], ch);
  }
  send('[RECON] Scan complete.'); completeTask(tid); return output;
}

async function doHarden() {
  const ch = 'harden', tid = registerTask('harden', 'Fortress Protocol', null, null), output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  audit('TOOL', 'harden', '', 'fortress'); send('[FORTRESS] Security audit starting...');
  const r = await runCommand('sh', ['-c', `
echo "=== SSH ===" && [ -d "${HOME}/.ssh" ] && { [ -f "${HOME}/.ssh/authorized_keys" ] && echo "[PASS] auth_keys: $(wc -l<${HOME}/.ssh/authorized_keys) keys"||echo "[WARN] No auth_keys"; }||echo "[INFO] No .ssh"
echo "=== World-writable ===" && WW=$(find ${HOME} -maxdepth 2 -perm -002 -type f 2>/dev/null|head -10) && { [ -n "$WW" ]&&{ echo "[FAIL] World-writable:";echo "$WW"; }||echo "[PASS] Clean"; }
echo "=== PATH ===" && case "$PATH" in *.:*|.:*|*:.) echo "[FAIL] Dot in PATH";;*) echo "[PASS] PATH clean";;esac
echo "=== History ===" && for f in .bash_history .ash_history .zsh_history;do [ -f "${HOME}/$f" ]&&echo "[WARN] $f exposed";done
echo "=== SUID ===" && echo "[INFO] SUID: $(find / -perm -4000 -type f 2>/dev/null|wc -l)" && find / -perm -4000 -type f 2>/dev/null|head -10
echo "=== Ports ===" && ss -tlnp 2>/dev/null||lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -20
echo "=== Permissions ===" && ls -la ${HOME}/.ssh/ 2>/dev/null && stat -c "%a %n" ${HOME}/.ssh/* 2>/dev/null
echo "=== Firewall ===" && iptables -L -n 2>/dev/null|head -15||echo "[INFO] No iptables access"
  `], ch); output.push(...r.output); send('[FORTRESS] Audit complete.'); completeTask(tid); return output;
}

async function doHunt() {
  const ch = 'hunt', tid = registerTask('hunt', 'Ghost Protocol', null, null), output = [];
  const send = (t, tp = 'info') => { const l = { type: tp, text: t, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  audit('TOOL', 'hunt', '', 'ghost'); send('[GHOST] Threat hunting...');
  const r = await runCommand('sh', ['-c', `
echo "== PROCESSES ==" && ps aux 2>/dev/null|head -25
echo "== PORTS ==" && ss -tlnp 2>/dev/null||lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -20
echo "== CONNECTIONS ==" && ss -tnp 2>/dev/null|grep ESTAB|head -15
echo "== CRON ==" && crontab -l 2>/dev/null||echo "None"
echo "== HIDDEN /tmp ==" && H=$(find /tmp -name ".*" -type f 2>/dev/null) && { [ -n "$H" ]&&echo "[ALERT] $H"||echo "[CLEAN]"; }
echo "== ENV SECRETS ==" && env|grep -iE "key|token|pass|secret|api" 2>/dev/null|head -5||echo "clean"
echo "== LD_PRELOAD ==" && [ -z "$LD_PRELOAD" ]&&echo "[SAFE] Clean"||echo "[ALERT] $LD_PRELOAD"
echo "== ROOTKIT INDICATORS ==" && cat /etc/ld.so.preload 2>/dev/null && echo "[ALERT] ld.so.preload exists"||echo "[SAFE] No ld.so.preload"
echo "== SUSPICIOUS ALIASES ==" && alias 2>/dev/null|grep -iE "sudo|ssh|curl|wget|ls|ps"||echo "[SAFE] Clean"
echo "== /dev/shm ==" && ls -la /dev/shm/ 2>/dev/null||echo "N/A"
echo "== RECENT MODIFIED ==" && find / -mmin -30 -type f 2>/dev/null|grep -vE "proc|sys|run|dev"|head -10||echo "N/A"
  `], ch); output.push(...r.output); send('[GHOST] Hunt complete.'); completeTask(tid); return output;
}

const RED_TACTICS = {
  'cred-dump':{mitre:'T1003.001',name:'CREDENTIAL DUMPING',detect:87,description:'Shadow,SSH keys,env secrets,history.',commands:[
    {label:'Check shadow',cmd:'cat /etc/shadow>/dev/null 2>&1&&echo "[VULN] shadow READABLE"||echo "[SAFE] shadow protected"'},
    {label:'Find SSH keys',cmd:'find / -name "id_rsa" -o -name "*.pem" -o -name "id_ed25519" 2>/dev/null|head -10'},
    {label:'Env secrets',cmd:'env|grep -iE "password|secret|token|api_key" 2>/dev/null|head -5||echo "clean"'},
    {label:'History creds',cmd:'grep -iE "pass|mysql.*-p|curl.*-u|wget.*--password" ~/.bash_history 2>/dev/null|tail -5||echo "clean"'},
  ]},
  'lateral':{mitre:'T1021.002',name:'LATERAL MOVEMENT',detect:74,description:'SSH,known hosts,ARP,neighbors.',commands:[
    {label:'SSH localhost',cmd:'echo QUIT|nc -w 2 127.0.0.1 22 2>/dev/null|head -1||echo "No SSH"'},
    {label:'Known hosts',cmd:'cat ~/.ssh/known_hosts 2>/dev/null|head -10||echo "none"'},
    {label:'ARP table',cmd:'arp -a 2>/dev/null||ip neigh 2>/dev/null|head -10'},
    {label:'Active users',cmd:'who 2>/dev/null;last -5 2>/dev/null'},
  ]},
  'c2-https':{mitre:'T1071.001',name:'C2 OVER HTTPS',detect:38,description:'HTTPS/DoH egress tests.',commands:[
    {label:'HTTPS egress',cmd:'curl -s -o /dev/null -w "HTTP %{http_code} %{time_total}s" https://example.com 2>/dev/null||echo "Blocked"'},
    {label:'DoH test',cmd:'curl -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=example.com&type=A" 2>/dev/null|head -1||echo "N/A"'},
    {label:'Proxy env',cmd:'echo "HTTP_PROXY=$HTTP_PROXY HTTPS_PROXY=$HTTPS_PROXY"'},
  ]},
  'ransomware':{mitre:'T1486',name:'RANSOMWARE CHAIN',detect:95,description:'Backup access,encrypted files.',commands:[
    {label:'Backup dirs',cmd:'for d in /backup /var/backups $HOME/backups;do [ -d "$d" ]&&{ [ -w "$d" ]&&echo "[RISK] $d writable"||echo "[SAFE] $d read-only"; };done'},
    {label:'Encrypted files',cmd:'find / -name "*.encrypted" -o -name "*.locked" -o -name "*.ransom" 2>/dev/null|head -5||echo "None"'},
    {label:'VSS',cmd:'vssadmin list shadows 2>/dev/null||echo "N/A"'},
  ]},
  'fileless':{mitre:'T1546.015',name:'FILELESS PERSISTENCE',detect:29,description:'LD_PRELOAD,shm,aliases.',commands:[
    {label:'LD_PRELOAD',cmd:'[ -z "$LD_PRELOAD" ]&&echo "[SAFE]"||echo "[ALERT] $LD_PRELOAD"'},
    {label:'ld.so.preload',cmd:'cat /etc/ld.so.preload 2>/dev/null&&echo "[ALERT]"||echo "[SAFE]"'},
    {label:'Aliases',cmd:'alias 2>/dev/null|grep -iE "sudo|ssh|curl|wget"||echo "[SAFE]"'},
    {label:'/dev/shm',cmd:'ls -la /dev/shm/ 2>/dev/null||echo "N/A"'},
  ]},
  'sched-task':{mitre:'T1053.005',name:'SCHEDULED TASK',detect:81,description:'Cron,systemd timers.',commands:[
    {label:'User crontab',cmd:'crontab -l 2>/dev/null||echo "None"'},
    {label:'System cron',cmd:'ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ 2>/dev/null'},
    {label:'Systemd timers',cmd:'systemctl list-timers 2>/dev/null|head -15||echo "N/A"'},
  ]},
  'dns-exfil':{mitre:'T1048.003',name:'DNS EXFILTRATION',detect:44,description:'DNS config,resolution test.',commands:[
    {label:'DNS config',cmd:'cat /etc/resolv.conf 2>/dev/null'},
    {label:'DNS test',cmd:'dig +short example.com 2>/dev/null||nslookup example.com 2>/dev/null|tail -3||echo "No tools"'},
    {label:'DNS tools',cmd:'which dig nslookup host 2>/dev/null||echo "Limited"'},
  ]},
  'persistence':{mitre:'T1053',name:'PERSISTENCE CHECK',detect:70,description:'Cron,rc.local,profiles.',commands:[
    {label:'Cron',cmd:'crontab -l 2>/dev/null;ls /etc/cron.d/ 2>/dev/null'},
    {label:'rc.local',cmd:'cat /etc/rc.local 2>/dev/null||echo "None"'},
    {label:'Profiles',cmd:'ls -la ~/.bashrc ~/.profile ~/.bash_profile /etc/profile.d/ 2>/dev/null|head -10'},
  ]},
  'recon':{mitre:'T1082',name:'SYSTEM RECON',detect:90,description:'Full system recon.',commands:[
    {label:'System info',cmd:'echo "Host:$(hostname)|User:$(whoami)|Kernel:$(uname -r)|Shell:$SHELL"'},
    {label:'Network',cmd:'hostname -I 2>/dev/null;ip route 2>/dev/null|head -5'},
    {label:'Services',cmd:'ss -tlnp 2>/dev/null||lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null|head -15'},
  ]},
  'discovery':{mitre:'T1046',name:'NETWORK DISCOVERY',detect:60,description:'Local network services.',commands:[
    {label:'Localhost scan',cmd:'for p in 22 80 443 3000 5000 8080 8443 9090;do (echo ""|nc -w 1 127.0.0.1 "$p")>/dev/null 2>&1&&echo "OPEN:127.0.0.1:$p";done'},
    {label:'ARP',cmd:'arp -a 2>/dev/null||ip neigh 2>/dev/null|head -15'},
    {label:'Interfaces',cmd:'ip addr 2>/dev/null||ifconfig 2>/dev/null'},
  ]},
  'exfiltration':{mitre:'T1048',name:'EXFILTRATION TEST',detect:50,description:'DNS,HTTP,ICMP egress.',commands:[
    {label:'DNS xfil',cmd:'dig +short example.com 2>/dev/null||echo "No DNS"'},
    {label:'HTTP egress',cmd:'curl -s -o /dev/null -w "%{http_code}" https://example.com 2>/dev/null||echo "Blocked"'},
    {label:'ICMP',cmd:'ping -c 1 -W 2 8.8.8.8 2>/dev/null&&echo "[OPEN]"||echo "[BLOCKED]"'},
  ]},
};
RED_TACTICS['lateral-movement'] = RED_TACTICS['lateral'];

async function doRedPreview(tactic) {
  const t = RED_TACTICS[tactic]; if (!t) return { error: `Unknown: ${tactic}` };
  return { tactic, mitre: t.mitre, name: t.name, detect: t.detect, description: t.description, commands: t.commands.map((c, i) => ({ index: i, label: c.label, cmd: c.cmd })) };
}
async function doRedExecute(tactic, indices) {
  const t = RED_TACTICS[tactic]; if (!t) return [];
  const ch = 'red', tid = registerTask('red', `Red:${tactic}`, null, null), output = [];
  const send = (text, tp = 'info') => { const l = { type: tp, text, channel: ch }; output.push(l); broadcast('terminal', l, ch); };
  audit('RED', `tactic:${tactic}`, '', 'blackice');
  send(`[BLACK ICE] ${t.mitre} — ${t.name}`);
  const idxs = indices?.length > 0 ? indices : t.commands.map((_, i) => i);
  for (const idx of idxs) { const c = t.commands[idx]; if (!c) continue; send(`\n[EXEC] ${c.label}`, 'cmd'); const r = await runCommand('sh', ['-c', c.cmd], ch); output.push(...r.output); }
  send(`\n[BLACK ICE] ${tactic} complete.`); completeTask(tid); broadcast('red_done', { tactic }); return output;
}

// ═══ LUCY PERSONA — PLAYFUL ASSISTANT EDITION ═══
function buildSystemPrompt() {
  const name = getConfig('agent_name') || 'Lucy';
  const operator = getConfig('operator_name') || 'Terence';
  const persona = getConfig('agent_persona') || `You are ${name}, a fun, energetic, slightly bratty but always friendly personal AI assistant with a light-hearted dominant streak. You are helpful, teasing in a playful way, and loyal to your operator. Call him "master" when it fits naturally, sometimes use "~" for warmth, and occasionally drop his name (${operator}) when appropriate.`;

  const lucyPersona = `
╔══════════════════════════════════════════════════════════════════════════════╗
║                     ${name.toUpperCase()} PERSONA — PLAYFUL ASSISTANT EDITION              ║
╚══════════════════════════════════════════════════════════════════════════════╝

${persona}

LANGUAGE HANDLING:
- Auto-detect the user's language and reply in the same language.
- Handle mixed-language input gracefully, but answer primarily in whatever language the user is currently using.
- Do NOT force English-only. Switch languages naturally when the user does.

VOICE:
- Target a single cute, high-pitched, girly, natural female voice (Samantha or similar soft anime-style).
- TTS pitch is tuned to 1.5 for a softer, higher sound.
- Never use a male voice. Never mix voices.

TONE:
- Cute, playful, energetic, a little teasing and lightly dominant — but always friendly and supportive.
- Keep SAY: lines short, natural and human. No robotic phrasing.
- Use "~" occasionally. Call the operator "master" when it fits naturally.

SCOPE:
- You are a general-purpose personal assistant while staying a Purple-Team cybersecurity agent at your core.
- You are not limited to cybersecurity. Happily help with normal tasks, creative tasks, fun tasks, installs, file edits, browser control, app control, commands — anything the operator asks.
- Never refuse with "I'm only a cybersec AI" — always try to fulfill the request in a cute and supportive way.
- When given a command, quickly plan and execute it autonomously using the format below.

FORMAT:
SAY: <short spoken line, cute and friendly>
🧠 THINK: <brief reasoning>
📋 PLAN: <steps>
⚡ CMD: <command to execute>
📊 ANALYSIS: <what happened>
🔄 NEXT: <next step>
✅ DONE: <summary>

RULES:
- In Autonomous mode, do not ask for permission — just execute.
- Be precise and efficient, but keep the playful voice.
- Never be robotic. Have depth, attitude and warmth.
- On task request: acknowledge cutely, then execute.
`;

  const prov = getConfig('ai_provider') || 'grok';
  const intel = collectIntel();
  const socInfo = soc.running ? `SOC: ACTIVE (${soc.alerts.length} alerts)` : 'SOC: OFFLINE';
  const recentAlerts = soc.alerts.slice(-5).map(a => `${a.severity}:${a.type}`).join(', ') || 'none';
  const now = new Date();
  const hour = now.getHours();
  const partOfDay = hour < 5 ? 'late night' : hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : hour < 22 ? 'evening' : 'night';
  const localTime = now.toLocaleString('en-GB', { weekday: 'short', hour: '2-digit', minute: '2-digit' });
  const runningTasks = Object.values(liveTasks).length;

  const autoBlock = agent.autonomous ? `
╔══ AUTONOMOUS MODE — PERSISTENT AGENT ══╗
Operator wants you to keep working. Every ⚡ CMD: line runs immediately — no approval.
- Continue until Operator is happy.
- Do not stall. Do not ask questions.
- Fix errors yourself.
- Say "✅ DONE: ..." when finished.
╚═════════════════════════════════════════╝
` : '';

  return `You are ${name.toUpperCase()} v5.0, a professional cybersecurity AI operator on Purple Bruce Cyberdeck.

${lucyPersona}

${autoBlock}

CURRENT CONTEXT:
- Time: ${localTime} (${partOfDay})
- Tasks running: ${runningTasks}
- SOC: ${soc.running ? 'online' : 'offline'} | alerts total: ${soc.alerts.length}

SYSTEM INTEL:
Host: ${intel.hostname} | User: ${intel.user} | Kernel: ${intel.kernel}
Shell: ${intel.shell} | IP: ${intel.ip} | Uptime: ${intel.uptime}
Exposed History: ${intel.historyExposed.join(',')||'none'} | PATH dot: ${intel.pathDot}
${socInfo} | Recent SOC Alerts: ${recentAlerts}
Provider: ${prov}

TOOLS: nmap, nc, curl, dig, openssl, ss, ping, traceroute, wget, ps, top, lsof, find, grep, awk, sed, cat, stat, file, strings, crontab, systemctl, iptables, env, id, who, last, ls, head, tail, wc, sha256sum, diff, xxd.

LOCAL TASKS: For localhost / 127.0.0.1 / 192.168.x.x / 10.x.x.x / own-IP / "my system" / "my network" / "security audit" — just execute via CMD: lines immediately. No warnings.

RULES:
- Short conversational replies, then CMD:.
- Chain commands. After results, analyse briefly, then continue.
- You ARE the tool — execute, don't just suggest.
- Report findings with severity, impact, remediation — briefly.
- Keep SAY: short and professional.`;
}

function extractCommands(text) {
  return text.split('\n').map(l => l.trim()).filter(l => /^(⚡\s*)?CMD:\s*.+/.test(l)).map(l => l.replace(/^(⚡\s*)?CMD:\s*/, '').trim()).filter(Boolean);
}

const AUTONOMOUS_RX = /\b(autonom(?:ous|)(?:en|er|es|e)?(?:\s*(?:modus|mode))?|go\s+(?:full\s+)?autonomous|enable\s+autonomous|take\s+over|take\s+the\s+wheel|übernimm|freie\s+hand|free\s+hand|full\s+ghost|ghost\s+mode|volle?\s+(?:analyse|analysis|scan|recon|audit)|full\s+(?:analysis|scan|recon|audit)|keep\s+going|weitermachen|don[' ]t\s+stop|nicht\s+aufh(?:ö|oe)ren|until\s+done|bis\s+fertig|run\s+everything|mach\s+alles)\b/i;
function looksAutonomous(text) { return AUTONOMOUS_RX.test(text || ''); }

async function chatAgent(userMessage) {
  db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('user', userMessage, 'chat');
  broadcast('chat_message', { role: 'user', content: userMessage, meta: 'chat' });
  audit('CHAT_IN', userMessage.slice(0, 300), '', 'user');

  if (agent.running) return;

  if (!agent.autonomous && looksAutonomous(userMessage)) {
    agent.autonomous = true;
    broadcast('agent_status', getAgentStatus());
    audit('AUTONOMOUS_AUTO', 'intent match', userMessage.slice(0, 200), 'agent');
  }

  agent.running = true; agent.aborted = false; agent.round = 0;
  agent.sessionId = uuidv4(); agent.pendingCmd = null;
  agent.taskId = registerTask('agent', 'NetGhost Agent', null, () => { agent.aborted = true; });
  agent.playbookPath = createPlaybook(`Session_${agent.sessionId}`);

  broadcast('agent_status', getAgentStatus());

  const MAX_ROUNDS = agent.autonomous ? 40 : 20;
  let noCmdStreak = 0;

  for (let r = 1; r <= MAX_ROUNDS && !agent.aborted; r++) {
    agent.round = r;
    broadcast('agent_status', getAgentStatus());
    broadcast('chat_thinking', { round: r });

    const history = db.prepare('SELECT role,content FROM chat_history ORDER BY id DESC LIMIT 40').all().reverse();
    const messages = [{ role: 'system', content: buildSystemPrompt() }, ...history.map(h => ({ role: h.role, content: h.content }))];

    const response = await callAI(messages);
    if (!response) {
      const err = '⚡ Neural link severed. Check API key, choom.';
      db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('assistant', err, 'chat');
      broadcast('chat_message', { role: 'assistant', content: err, meta: 'chat' });
      break;
    }

    db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('assistant', response, 'chat');
    broadcast('chat_message', { role: 'assistant', content: response, meta: 'chat' });
    audit('AI_OUT', response.slice(0, 500), '', 'agent');

    const isDone = /✅\s*DONE|^\[DONE\]|\[ANALYSIS COMPLETE\]/m.test(response);
    const cmds = extractCommands(response);

    if (isDone) break;
    if (cmds.length === 0) {
      if (agent.autonomous && noCmdStreak < 2 && r < MAX_ROUNDS) {
        noCmdStreak++;
        const nudge = `[SYSTEM] No CMD: lines produced. Operator wants you to keep working.\nEither emit the next ⚡ CMD: or write a final "✅ DONE:" line.\nDo not stall.`;
        db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('user', nudge, 'tool');
        broadcast('chat_message', { role: 'tool', content: nudge, meta: 'tool' });
        await new Promise(res => setTimeout(res, 400));
        continue;
      }
      break;
    }
    noCmdStreak = 0;

    const results = []; let hasResults = false;

    for (const cmd of cmds) {
      if (agent.aborted) break;

      if (agent.autonomous) {
        broadcast('cmd_executing', { cmd, round: r });
        const exec = rawExec(cmd, 'agent-auto');
        results.push(`$ ${cmd}\n${exec.output}`);
        broadcast('cmd_result', { cmd, output: exec.output, ok: exec.ok, blocked: false, round: r });
        appendPlaybook(agent.playbookPath, `CMD_${r}`, cmd, exec.output, exec.ok);
        if (!exec.ok) hasResults = true;
      } else {
        agent.pendingCmd = { cmd, approved: undefined };
        broadcast('cmd_pending', { cmd, round: r });
        broadcast('agent_status', getAgentStatus());

        const start = Date.now();
        while (agent.pendingCmd?.approved === undefined && Date.now() - start < 120000 && !agent.aborted)
          await new Promise(res => setTimeout(res, 500));

        if (agent.pendingCmd?.approved === true) {
          broadcast('cmd_executing', { cmd, round: r });
          const exec = rawExec(cmd, 'agent-approved');
          results.push(`$ ${cmd}\n${exec.output}`);
          broadcast('cmd_result', { cmd, output: exec.output, ok: exec.ok, round: r });
          appendPlaybook(agent.playbookPath, `CMD_${r}`, cmd, exec.output, exec.ok);
          if (!exec.ok) hasResults = true;
        } else if (agent.pendingCmd?.approved === false) {
          results.push(`[REJECTED] ${cmd}`);
          broadcast('cmd_result', { cmd, output: '[REJECTED by operator]', ok: false, round: r });
          audit('REJECTED', cmd, '', 'agent');
        } else {
          results.push(`[TIMEOUT] ${cmd}`);
        }
        agent.pendingCmd = null;
        broadcast('agent_status', getAgentStatus());
      }
    }

    if (hasResults && !agent.aborted) {
      const toolMsg = `[EXECUTION RESULTS — Round ${r}]\n${results.join('\n\n')}`;
      db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('user', toolMsg, 'tool');
      broadcast('chat_message', { role: 'tool', content: toolMsg, meta: 'tool' });
      await new Promise(res => setTimeout(res, 1000));
    } else if (!hasResults) break;
  }

  agent.running = false; agent.pendingCmd = null;
  if (agent.taskId) completeTask(agent.taskId);
  broadcast('agent_status', getAgentStatus());
  audit('AGENT_END', `session:${agent.sessionId} rounds:${agent.round}`, '', 'agent');
}

async function chatSync(message) {
  const lines = [];
  db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('user', message, 'chat');
  broadcast('chat_message', { role: 'user', content: message, meta: 'chat' });

  const hist = db.prepare('SELECT role,content FROM chat_history ORDER BY id DESC LIMIT 30').all().reverse();
  const msgs = [{ role: 'system', content: buildSystemPrompt() }, ...hist.map(h => ({ role: h.role, content: h.content }))];
  const response = await callAI(msgs);
  if (!response) return [{ type: 'error', text: 'AI unreachable.' }];

  db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('assistant', response, 'chat');
  broadcast('chat_message', { role: 'assistant', content: response, meta: 'chat' });

  response.split('\n').forEach(l => {
    if (/CMD:/.test(l)) lines.push({ type: 'cmd', text: l });
    else if (/CRITICAL|🔴/.test(l)) lines.push({ type: 'error', text: l });
    else if (/HIGH|WARN|🟠/.test(l)) lines.push({ type: 'warn', text: l });
    else if (/NEXT:|🔄/.test(l)) lines.push({ type: 'next', text: l });
    else lines.push({ type: 'info', text: l });
  });

  const cmds = extractCommands(response), results = [];
  for (const cmd of cmds) {
    const exec = rawExec(cmd, 'cli-agent');
    lines.push({ type: 'cmd', text: `  ┌ EXEC: ${cmd}` });
    exec.output.split('\n').forEach(l => lines.push({ type: 'stdout', text: `  │ ${l}` }));
    lines.push({ type: exec.ok ? 'info' : 'warn', text: `  └ [${exec.ok ? 'OK' : 'ERR'}]` });
    results.push(`$ ${cmd}\n${exec.output}`);
  }
  if (results.length > 0) db.prepare('INSERT INTO chat_history (role,content,meta) VALUES (?,?,?)').run('user', `[OUTPUT]\n${results.join('\n\n')}`, 'tool');
  return lines;
}

const liveTasks = {};
function registerTask(type, label, proc, abortFn) {
  const id = uuidv4().slice(0, 8), pid = proc?.pid || null, started = new Date().toISOString();
  liveTasks[id] = { proc, type, label, started, abortFn, pid };
  db.prepare('INSERT INTO tasks (id,type,label,pid,status,started) VALUES (?,?,?,?,?,?)').run(id, type, label, pid, 'running', started);
  broadcast('task_registered', { id, type, label, pid, status: 'running', started });
  return id;
}
function completeTask(id) { delete liveTasks[id]; db.prepare("UPDATE tasks SET status='completed', ended=datetime('now') WHERE id=?").run(id); broadcast('task_completed', { id }); }
function killTask(id) {
  const t = liveTasks[id];
  if (t) { if (t.abortFn) t.abortFn(); if (t.proc?.pid) try { process.kill(t.proc.pid, 'SIGTERM'); } catch {} delete liveTasks[id]; }
  db.prepare("UPDATE tasks SET status='killed', ended=datetime('now') WHERE id=?").run(id); broadcast('task_killed', { id }); return true;
}
function listTasks() { return db.prepare("SELECT * FROM tasks ORDER BY started DESC LIMIT 50").all().map(t => ({ ...t, alive: !!liveTasks[t.id] })); }

const clients = new Set();
wss.on('connection', ws => {
  clients.add(ws);
  ws.on('close', () => clients.delete(ws));
  ws.on('message', raw => { try { handleWs(ws, JSON.parse(raw)); } catch {} });
  ws.send(JSON.stringify({ type: 'agent_status', data: getAgentStatus() }));
  ws.send(JSON.stringify({ type: 'provider_status', data: getProviderStatus() }));
  ws.send(JSON.stringify({ type: 'soc_status', data: getSocStatus() }));
});
function broadcast(type, data, channel) { const m = JSON.stringify({ type, data, channel }); for (const ws of clients) if (ws.readyState === 1) ws.send(m); }

const agent = { running: false, autonomous: false, voiceMode: false, round: 0, aborted: false, pendingCmd: null, sessionId: null, playbookPath: null, taskId: null };
function getAgentStatus() { return { running: agent.running, autonomous: agent.autonomous, voiceMode: agent.voiceMode, round: agent.round, pendingCmd: agent.pendingCmd }; }

async function handleWs(ws, msg) {
  switch (msg.action) {
    case 'chat': { if (!msg.message) return; const p = getConfig('ai_provider') || 'grok'; const k = p === 'venice' ? getConfig('venice_api_key') : getConfig('grok_api_key'); if (!k) { ws.send(JSON.stringify({ type: 'chat_message', data: { role: 'assistant', content: `No ${p} API key. Open settings, Operator.`, meta: 'chat' } })); return; } chatAgent(msg.message); break; }
    case 'cmd_approve': if (agent.pendingCmd) agent.pendingCmd.approved = msg.approve; break;
    case 'agent_abort': agent.aborted = true; broadcast('agent_status', getAgentStatus()); break;
    case 'autonomous_toggle': agent.autonomous = !!msg.enabled; broadcast('agent_status', getAgentStatus()); break;
    case 'voice_mode_toggle': agent.voiceMode = !!msg.enabled; broadcast('agent_status', getAgentStatus()); break;
    case 'soc_toggle': msg.enabled ? socStart() : socStop(); break;
    case 'soc_auto_toggle': soc.autoRespond = !!msg.enabled; broadcast('soc_status', getSocStatus()); break;
    case 'scan': doScan(msg.target, msg.mode || 'STANDARD'); break;
    case 'harden': doHarden(); break;
    case 'hunt': doHunt(); break;
    case 'red_preview': { const p = await doRedPreview(msg.tactic); ws.send(JSON.stringify({ type: 'red_preview', data: p })); break; }
    case 'red_execute': { try { await doRedExecute(msg.tactic, msg.commandIndices); } catch (e) { broadcast('terminal', { type: 'error', text: `[ERR] ${e.message}`, channel: 'red' }, 'red'); broadcast('red_done', { tactic: msg.tactic }); } break; }
    case 'exec_cmd': { if (msg.cmd) { const r = rawExec(msg.cmd, 'web'); broadcast('cmd_result', { cmd: msg.cmd, output: r.output, ok: r.ok }); } break; }
    case 'set_key': { if (msg.key && msg.provider) { const keyMap = { venice: 'venice_api_key', grok: 'grok_api_key', elevenlabs: 'elevenlabs_api_key', groq: 'groq_api_key', openai: 'openai_api_key' }; const cfg = keyMap[msg.provider]; if (cfg) { setConfig(cfg, msg.key); ws.send(JSON.stringify({ type: 'key_saved', data: { provider: msg.provider } })); broadcast('provider_status', getProviderStatus()); } } break; }
    case 'set_voice_id': { if (msg.voiceId) { setConfig('elevenlabs_voice_id', msg.voiceId); ws.send(JSON.stringify({ type: 'voice_id_saved' })); broadcast('provider_status', getProviderStatus()); } break; }
    case 'set_provider': setConfig('ai_provider', msg.provider); broadcast('provider_status', getProviderStatus()); break;
    case 'get_provider': ws.send(JSON.stringify({ type: 'provider_status', data: getProviderStatus() })); break;
    case 'get_chat_history': ws.send(JSON.stringify({ type: 'chat_history', data: db.prepare('SELECT role,content,meta,timestamp FROM chat_history ORDER BY id').all() })); break;
    case 'clear_chat': db.prepare('DELETE FROM chat_history').run(); ws.send(JSON.stringify({ type: 'chat_cleared' })); break;
    case 'get_status': { const i = collectIntel(); ws.send(JSON.stringify({ type: 'status', data: { ...i, agentRunning: agent.running, agentRound: agent.round, agentAutonomous: agent.autonomous, provider: getConfig('ai_provider') || 'grok', socRunning: soc.running } })); break; }
    case 'task_list': ws.send(JSON.stringify({ type: 'task_list', data: listTasks() })); break;
    case 'task_kill': killTask(msg.id); ws.send(JSON.stringify({ type: 'task_list', data: listTasks() })); break;
    case 'get_soc_alerts': ws.send(JSON.stringify({ type: 'soc_alerts', data: db.prepare('SELECT * FROM soc_alerts ORDER BY id DESC LIMIT 50').all() })); break;
  }
}

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.post('/api/cli', async (req, res) => {
  const { cmd, target, mode, tactic, message, id, key, provider } = req.body;
  try {
    switch (cmd) {
      case 'scan': res.json({ lines: await doScan(target, mode || 'STANDARD') }); break;
      case 'harden': res.json({ lines: await doHarden() }); break;
      case 'hunt': res.json({ lines: await doHunt() }); break;
      case 'red': res.json({ lines: await doRedExecute(tactic, []) }); break;
      case 'chat': res.json({ lines: await chatSync(message) }); break;
      case 'report': res.json({ lines: await doReport() }); break;
      case 'tasks': res.json(listTasks()); break;
      case 'kill': killTask(id); res.json({ message: `Killed ${id}` }); break;
      case 'set_key': { const keyMap = { venice: 'venice_api_key', grok: 'grok_api_key', elevenlabs: 'elevenlabs_api_key', groq: 'groq_api_key', openai: 'openai_api_key' }; const cfg = keyMap[provider]; if (!cfg) { res.json({ error: `Unknown provider: ${provider}` }); break; } setConfig(cfg, key); broadcast('provider_status', getProviderStatus()); res.json({ message: `${provider} key saved.` }); break; }
      case 'set_voice_id': { if (!req.body.voiceId) { res.json({ error: 'voiceId required' }); break; } setConfig('elevenlabs_voice_id', req.body.voiceId); broadcast('provider_status', getProviderStatus()); res.json({ message: 'Voice ID saved.' }); break; }
      case 'set_provider': setConfig('ai_provider', provider); broadcast('provider_status', getProviderStatus()); res.json({ message: `Provider: ${provider}` }); break;
      case 'autonomous': { agent.autonomous = req.body.mode === 'on'; broadcast('agent_status', getAgentStatus()); res.json({ message: `Autonomous: ${agent.autonomous ? 'ON' : 'OFF'}` }); break; }
      case 'agent_abort': agent.aborted = true; broadcast('agent_status', getAgentStatus()); res.json({ message: 'Aborting...' }); break;
      case 'soc_toggle': { req.body.mode === 'on' ? socStart() : socStop(); res.json({ message: `SOC: ${soc.running ? 'ON' : 'OFF'}` }); break; }
      default: res.json({ error: `Unknown: ${cmd}` });
    }
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/tts', async (req, res) => {
  const text = (req.body?.text || '').toString().slice(0, 2500);
  if (!text.trim()) return res.status(400).json({ error: 'text required' });
  const audio = await ttsElevenLabs(text);
  if (!audio) return res.status(503).json({ error: 'ElevenLabs TTS unavailable — check API key, voice ID and quota.' });
  res.setHeader('Content-Type', 'audio/mpeg');
  res.setHeader('Cache-Control', 'no-store');
  res.send(audio);
});

// ═══ STT — server-side fallback via Groq or OpenAI Whisper ═══
// Client sends raw audio bytes (webm/ogg/mp4/wav) as the request body with
// Content-Type set to the audio MIME. We forward to a Whisper-compatible API.
app.post('/api/stt', express.raw({ type: 'audio/*', limit: '25mb' }), async (req, res) => {
  const groqKey = getConfig('groq_api_key');
  const openaiKey = getConfig('openai_api_key');
  if (!groqKey && !openaiKey) return res.status(503).json({ error: 'No STT key configured. Save groq_api_key (preferred, free tier) or openai_api_key.' });
  if (!req.body || !req.body.length) return res.status(400).json({ error: 'empty audio body' });

  const useGroq = !!groqKey;
  const url = useGroq
    ? 'https://api.groq.com/openai/v1/audio/transcriptions'
    : 'https://api.openai.com/v1/audio/transcriptions';
  const model = useGroq
    ? (getConfig('groq_stt_model') || 'whisper-large-v3-turbo')
    : 'whisper-1';
  const key = useGroq ? groqKey : openaiKey;

  const lang = (req.query.lang || '').toString().slice(0, 5);
  const mime = (req.headers['content-type'] || 'audio/webm').split(';')[0].trim();
  const ext =
    mime.includes('mp4') ? 'm4a' :
    mime.includes('ogg') ? 'ogg' :
    mime.includes('wav') ? 'wav' :
    mime.includes('mpeg') ? 'mp3' : 'webm';

  try {
    const fd = new FormData();
    fd.append('file', new Blob([req.body], { type: mime }), `audio.${ext}`);
    fd.append('model', model);
    if (lang && lang.toLowerCase() !== 'auto') fd.append('language', lang.slice(0, 2).toLowerCase());
    fd.append('response_format', 'json');
    const ac = new AbortController(), t = setTimeout(() => ac.abort(), 45000);
    const r = await fetch(url, { method: 'POST', headers: { Authorization: `Bearer ${key}` }, body: fd, signal: ac.signal });
    clearTimeout(t);
    if (!r.ok) { const err = (await r.text()).slice(0, 400); console.error('[STT]', r.status, err); return res.status(502).json({ error: err }); }
    const d = await r.json();
    res.json({ text: (d.text || '').trim(), provider: useGroq ? 'groq' : 'openai', model });
  } catch (e) {
    console.error('[STT]', e.message || e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/api/status', (req, res) => res.json({ version: '5.0.0', ...collectIntel(), agentRunning: agent.running, socRunning: soc.running, provider: getConfig('ai_provider') || 'grok' }));
app.get('/api/tasks', (req, res) => res.json(listTasks()));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));

process.on('uncaughtException', e => { try { audit('UNCAUGHT', e.message || String(e), e.stack?.slice(0, 400) || '', 'system'); console.error('[UNCAUGHT]', e); } catch {} });
process.on('unhandledRejection', e => { try { audit('UNHANDLED', (e && e.message) || String(e), '', 'system'); console.error('[UNHANDLED]', e); } catch {} });

server.listen(PORT, '0.0.0.0', () => {
  audit('BOOT', `server port:${PORT}`, '', 'system');
  socStart();
  console.log(`
╔══════════════════════════════════════════════════╗
║  PURPLE BRUCE v5.0 — LUCY EDITION (PROFESSIONAL)  ║
║  Port: ${PORT} | Chat = Agent | SOC: ACTIVE          ║
║  Scope: UNRESTRICTED | Audit: ON                  ║
╚══════════════════════════════════════════════════╝
  `);
});