# PURPLE BRUCE v6.0 — TERTRATRONIC RIPPLER TIER 5

```
  ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗
  ████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗
  ██╔██╗ ██║█████╗     ██║   ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
  ██║╚██╗██║██╔══╝     ██║   ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
  ██║ ╚████║███████╗   ██║   ██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║
  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
  TERTRATRONIC RIPPLER v6.0  ·  TIER 5  ·  STUFE 2  ·  PURPLEBRUCE GRID
```

**Purple-Team Cyberdeck** — one AI agent, three providers, zero downtime.  
Runs on Android (Termux proot), native Linux, or WSL. No systemd. No sudo.

---

## What's New in v6.0 — Stufe 2

| Stufe 1 (v5.0) | Stufe 2 (v6.0) |
|---|---|
| Single AI provider | **Self-healing 3-AI team** (Grok / Venice / GPT-4o) |
| Manual provider switch | **Smart auto-routing** by task type |
| No failover | **Automatic failover** + heal log |
| Basic netrunner CLI | **Full Tier 5 CLI** (doctor, deck, team, overclock, scan) |
| Pulsing circle voice UI | **Voice v2** — 8-bar visualizer + latency + provider badge |
| No tmux layout | **3-pane auto-layout** (`netrunner start`) |
| Basic aliases | **Drop-in alias set** (pb, purple, start, stop, team, …) |

---

## Features

### Self-Healing AI Team

Three AIs operate as one disciplined security team. They cover for each other automatically — but **never act autonomously on security tasks**. Every offensive action requires an explicit operator command.

```
⚡ GROK-3    ──  reasoning · code · analysis          (default)
🔮 VENICE    ──  redteam · offensive · uncensored      (auto-routed on exploit/pentest keywords)
🤖 GPT-4o   ──  voice · long-context · fallback       (STT/TTS + chain end)
```

**Routing rules (`config/ai-providers.json`)**

| Task type | Primary | Fallback chain |
|---|---|---|
| `redteam` (exploit, pentest, C2, …) | Venice | Grok → GPT-4o |
| `reasoning` (code, analysis, chat) | configured | GPT-4o |
| `voice` (STT, TTS) | GPT-4o | Grok |

**Self-healing mechanics (no API cost):**
- Each call updates per-provider health (latency, error count)
- After 2 consecutive failures → provider marked `offline`, next in chain takes over
- When a call succeeds again → provider auto-recovers, heal event logged
- 60-second background key-presence check (zero API calls)
- All heal events broadcast to UI and audit log

### Lucy — AI Operator

Playful, disciplined, language-aware (DE/EN auto-detect). Works as a **purple-team agent** at her core:

- Chain-of-Thought rendered live: `🧠 THINK → 📋 PLAN → ⚡ CMD → 📊 ANALYSIS → ✅ DONE`
- Autonomous mode: runs until done, self-corrects errors
- Approval mode: every shell command needs operator confirmation
- Context-aware: knows current team health, SOC alerts, active tasks

### Voice v2

- **8-bar animated frequency visualizer** — bars pulse to match voice activity state
- **Provider badge** in call modal — shows which AI is responding live
- **Latency pill** — response time in ms after each reply
- **Continuous Web Speech** (free, works on desktop Chrome)
- **Push-to-Talk / Whisper** — hold big mic button → Groq or OpenAI Whisper → transcript sent. Works on Android Chrome, proot browsers, everything
- **ElevenLabs TTS** with Web Speech fallback
- Language switcher (DE / EN), mute toggle, PTT mode toggle

### netrunner CLI (Tier 5)

```bash
netrunner doctor       # full health check + auto-repair
                       # checks: proot, Node.js, port 3000, DB, AI keys,
                       #         server process, log dir, required tools
netrunner deck         # cyberdeck dashboard — RAM bar, uptime, server
                       # status, provider routing, active sessions, features
netrunner team         # AI team health — per-provider dot + latency +
                       # heal log + routing rules + discipline note
netrunner overclock    # 90s boost countdown + glitch cooldown effect
netrunner scan <target> [mode]   # recon via /api/cli (QUICK/STANDARD/FULL/STEALTH)
netrunner quickhack              # interactive protocol menu
netrunner quickhack <target>     # direct injection sequence
netrunner start                  # launch tmux 3-pane layout
```

### tmux 3-Pane Layout

`netrunner start` creates a named `purplebruce` session:

```
┌─────────────────────────────────────────────────┐
│  Pane 0 — npm start (Purple Bruce server)        │
├──────────────────────┬──────────────────────────┤
│  Pane 1 — audit.log  │  Pane 2 — Lucy chat CLI  │
└──────────────────────┴──────────────────────────┘
```

`Prefix + B` from any tmux session also triggers the layout.

### SOC Daemon — Blue Team

- Watches listeners, outbound connections, `LD_PRELOAD`, crontabs, SUID changes, suspicious processes
- Auto-quarantines hidden `/tmp` files, captures forensic snapshots
- Alerts appear as `🛡 SOC [CRITICAL]` messages in chat
- Toggle per-session via settings or `soc_toggle` WebSocket action

### Black Ice — MITRE ATT&CK

11 live execution modules mapped to the ATT&CK framework:

`cred-dump` · `lateral` · `c2-https` · `ransomware` · `fileless` · `sched-task` · `dns-exfil` · `persistence` · `recon` · `discovery` · `exfiltration`

Each module shows detection difficulty, preview commands, and checkbox-based selective execution.

---

## Install

### A. Termux + Ubuntu proot (Android)

```bash
# In Termux
pkg update -y
pkg install -y proot-distro git
proot-distro install ubuntu
proot-distro login ubuntu

# Inside the proot
apt update && apt install -y nodejs npm git curl ca-certificates
cd /root
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
npm install
./purplebruce.sh          # server on 127.0.0.1:3000
```

Open `http://127.0.0.1:3000` in Android Chrome.

### B. Native Linux / macOS / WSL

```bash
# Requires Node.js ≥ 18
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
npm install
./purplebruce.sh
```

### C. Netrunner cyberpunk shell (optional)

Install Powerlevel10k, zsh plugins, tmux theme, and drop-in aliases inside the proot:

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
```

Available after install:

```bash
pb / purple        → netrunner (short form)
start              → netrunner start (tmux 3-pane)
stop               → pkill node server
logs               → tail audit.log
chat               → purplebruce.sh tui
doctor / deck / team / overclock / scan  → netrunner subcommands
```

---

## API Key Setup

Settings → ⚙ in the UI, or via CLI:

| Provider | Purpose | Config key | Get it at |
|---|---|---|---|
| Grok (xAI) | Default reasoning | `grok_api_key` | [console.x.ai](https://console.x.ai) |
| Venice.ai | Redteam (auto-routed) | `venice_api_key` | [venice.ai](https://venice.ai) |
| OpenAI | Voice fallback / GPT-4o | `openai_api_key` | [platform.openai.com](https://platform.openai.com) |
| ElevenLabs | TTS voice | `elevenlabs_api_key` + `elevenlabs_voice_id` | [elevenlabs.io](https://elevenlabs.io) |
| Groq | Whisper STT (free tier) | `groq_api_key` | [console.groq.com](https://console.groq.com) |

```bash
purple> setkey grok     xai-xxxxxxxxxxxx
purple> setkey venice   venice-xxxxxxxxxx
purple> setkey openai   sk-xxxxxxxxxxxxxxx
purple> setkey groq     gsk_xxxxxxxxxxxx
purple> setvoice        <elevenlabs_voice_id>
```

Or save keys in the browser UI → Settings. Keys persist in `purplebruce.db`.

---

## Project Layout

```
purplebruce/
├── server.js              # Express + WebSocket + AI team coordinator
│                          # SOC daemon + agent loop + MITRE red modules
├── public/index.html      # React UI — chat, voice v2, team panel, SOC, Black Ice
├── purplebruce.sh         # Launcher (Termux + proot aware)
├── config/
│   └── ai-providers.json  # Provider definitions + routing rules
├── netrunner/
│   ├── bin/netrunner      # Tier 5 CLI — doctor / deck / team / overclock / scan
│   ├── dotfiles/          # zshrc · p10k.zsh · tmux.conf
│   └── install.sh         # Cyberpunk shell installer
├── tools-install.sh       # Pentest toolkit (nmap, ffuf, sqlmap, …)
├── install-service.sh     # 24/7 watchdog service
└── purplebruce.db         # SQLite (chat, config, audit, SOC alerts, tasks)
```

---

## 24/7 Service

```bash
./install-service.sh install        # supervised background service + auto-restart
./install-service.sh status
./install-service.sh logs
./install-service.sh enable-cron    # nightly 03:30 harden + hunt + report
./install-service.sh restart
./install-service.sh uninstall
```

---

## Security Scope

`Unrestricted Access` means the agent executes real shell commands on the host. Inside a Termux proot-distro that is the proot rootfs (isolated from your Android system). On native Linux it is your actual machine.

**Use only on systems you own or are explicitly authorized to assess.**  
The AI team is a tool of order and discipline — not of arbitrary action.  
No uninvited attacks. No autonomous offensive moves without an explicit operator command.

---

## Smoke Test

```bash
./purplebruce.sh &
sleep 2
curl -s http://127.0.0.1:3000/api/status   | python3 -m json.tool | head -8
curl -s http://127.0.0.1:3000/api/team     | python3 -m json.tool
curl -s http://127.0.0.1:3000/api/providers | python3 -m json.tool
```

Expected: `"version": "6.0.0"` in status, three provider entries in team.

---

**Built by TAesthetics — TERTRATRONIC RIPPLER TIER 5 — Lucy v6.0**
