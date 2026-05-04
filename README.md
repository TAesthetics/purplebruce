# PURPLE BRUCE v6.0 — TERTRATRONIC RIPPLER TIER 5

```
  ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗
  ████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗
  ██╔██╗ ██║█████╗     ██║   ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
  ██║╚██╗██║██╔══╝     ██║   ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
  ██║ ╚████║███████╗   ██║   ██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║
  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
  
  TERTRATRONIC RIPPLER v6.0  ·  TIER 5  ·  STUFE 2  ·  AUTHENTICATION + PAYMENTS
```

**Professional Purple-Team Cyberdeck** — AI security agent + voice interface + team coordination + Stripe payments.  
Runs on Android (Termux/proot), Linux, WSL. No systemd required.

---

## What's New in v6.0 Stufe 2

| Feature | Stufe 1 | Stufe 2 |
|---------|---------|---------|
| **AI Providers** | OpenAI only | Grok / Venice / **Gemini** (free tier) |
| **Voice TTS** | ElevenLabs only | **Microsoft Edge Neural** (free) + ElevenLabs fallback |
| **Voice STT** | Web Speech API | **Groq Whisper-large-v3-turbo** + vocab prompt |
| **Auth** | None | **Registration + JWT** (Supabase-ready) |
| **Payments** | None | **Stripe** integration (settings modal) |
| **Chat Layout** | Misaligned on mobile | **Fixed 42px uniform buttons** + dvh |
| **CLI** | Basic netrunner | **Full Tier 5** (doctor, deck, team, overclock, scan) |

---

## Features

### Self-Healing AI Team

Three AIs work as ONE disciplined security team — automatic failover, no API costs for health checks.

```
⚡ GROK-3    ──  reasoning · code · analysis          (default)
🔮 VENICE    ──  redteam · offensive · uncensored      (auto-routed on exploit/pentest)
✨ GEMINI    ──  long-context · multimodal · fallback   (free tier — Google)
```

**Smart Routing:**
- `redteam` tasks → Venice (uncensored) → Grok → Gemini
- `reasoning` tasks → configured provider → Gemini
- Auto-failover after 2 consecutive failures
- Zero-cost background health monitoring every 60s
- Heal events logged to audit trail + broadcast to UI

### Voice v2 — Full Neural Stack

- **8-bar animated frequency visualizer** — bars pulse to audio state
- **Provider badge** in call modal — live provider indicator
- **Latency pill** — response time in ms
- **Whisper STT** (Groq, free) — cyberdeck vocabulary prompt + temperature 0
- **Microsoft Edge Neural TTS** (free, no key) — de-DE-KatjaNeural / en-US-AriaNeural
- **ElevenLabs premium fallback** — only if configured
- **Push-to-Talk (PTT)** — hold mic button for Whisper, release to transcribe
- **Language switcher** — DE/EN auto-detect + manual override

### Authentication + Payments

- **Registration & Login** — JWT tokens, email + password
- **Stripe integration** — Settings modal → "UPGRADE TO PRO" button
- **Persistent sessions** — localStorage token recall
- **Protected endpoints** — `/api/*` requires valid JWT

### netrunner CLI (Tier 5)

```bash
netrunner doctor       # health check + auto-repair
netrunner deck         # cyberdeck dashboard (RAM, uptime, status)
netrunner team         # AI team health (per-provider dots, heal log)
netrunner overclock    # 90s boost timer + glitch effect
netrunner scan <target> [mode]   # recon (QUICK/STANDARD/FULL/STEALTH)
netrunner start        # tmux 3-pane layout (server + logs + chat)
```

### tmux 3-Pane Auto-Layout

```
┌──────────────────────────────────────┐
│  Pane 0 — npm start (server)         │
├──────────────┬──────────────────────┤
│  Pane 1      │  Pane 2              │
│  audit.log   │  Lucy chat CLI       │
└──────────────┴──────────────────────┘
```

Launch with `netrunner start` or `Prefix + B` in tmux.

### SOC Daemon — Blue Team Monitor

- Watches listeners, outbound connections, `LD_PRELOAD`, crontabs, SUID changes
- Auto-quarantines hidden `/tmp` files
- Captures forensic snapshots
- Alerts appear as `🛡 SOC [CRITICAL]` in chat

### Black Ice — MITRE ATT&CK Modules

11 live execution modules (selective execution):
`cred-dump` · `lateral` · `c2-https` · `ransomware` · `fileless` · `sched-task` · `dns-exfil` · `persistence` · `recon` · `discovery` · `exfiltration`

---

## Quick Start

### A. Termux + Ubuntu proot (Android)

```bash
pkg install -y proot-distro git nodejs npm
proot-distro install ubuntu
proot-distro login ubuntu

apt update && apt install -y build-essential ca-certificates
cd /root
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
npm install
export JWT_SECRET="your-secret-here"
node server.js &
# Open http://127.0.0.1:3000 in Chrome
```

### B. Linux / WSL / macOS

```bash
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
npm install
export JWT_SECRET="your-secret-here"
node server.js
# http://localhost:3000
```

### C. Shell Setup (optional)

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
# Now available: pb, start, stop, logs, chat, doctor, deck, team, scan
```

---

## Configuration

### Environment Variables

```bash
export JWT_SECRET="your-jwt-secret-key-change-this"
export STRIPE_SECRET_KEY="sk_test_your_key_here"
export STRIPE_PRICE_ID="price_1ABC123xyz"
export SUPABASE_URL="https://your-project.supabase.co"  # optional
export SUPABASE_KEY="your-anon-key"                     # optional
```

### API Keys (in UI Settings ⚙)

| Provider | Purpose | Get it at |
|----------|---------|-----------|
| **Grok** (xAI) | Default reasoning | [console.x.ai](https://console.x.ai) |
| **Venice.ai** | Redteam (auto-routed) | [venice.ai](https://venice.ai) |
| **Gemini** (Google) | Free fallback chain | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| **Groq** | Whisper STT (free) | [console.groq.com](https://console.groq.com) |
| **ElevenLabs** (optional) | Premium TTS voice | [elevenlabs.io](https://elevenlabs.io) |

> **TTS is FREE by default** — Microsoft Edge Neural voices need no API key.

### netrunner Shell Aliases

```bash
pb / purple        → netrunner (short form)
start              → netrunner start (tmux)
stop               → pkill node
logs               → tail -f ~/.purplebruce/audit.log
chat               → ./purplebruce.sh tui
doctor / deck / team / overclock / scan  → netrunner subcommands
```

---

## API Reference

### Authentication

```bash
POST /api/auth/register
{ "email": "user@example.com", "password": "secret" }
→ { "user": {...}, "token": "eyJ..." }

POST /api/auth/login
{ "email": "user@example.com", "password": "secret" }
→ { "user": {...}, "token": "eyJ..." }

GET /api/auth/me (requires Authorization: Bearer <token>)
→ { "user": { "id": "...", "email": "..." } }
```

### Stripe Checkout

```bash
POST /api/stripe/checkout (requires Authorization: Bearer <token>)
→ { "url": "https://checkout.stripe.com/...", "sessionId": "cs_..." }
```

### AI Team Status

```bash
GET /api/team
→ { "providers": {...}, "healLog": [...], "primary": "grok" }

GET /api/providers
→ { "provider": "grok", "grokHasKey": true, ..., "routing": {...} }
```

### Chat + Commands

```bash
POST /api/chat { "message": "scan 192.168.1.1" }
POST /api/exec { "cmd": "nmap -sV localhost" }
POST /api/stt (raw audio binary, lang query param)
POST /api/tts { "text": "Hello world" }
```

---

## Project Layout

```
purplebruce/
├── server.js              # Express + WebSocket + AI team + auth + payments
├── public/index.html      # React UI (chat, voice, settings, login)
├── purplebruce.sh         # Launcher script
├── config/
│   └── ai-providers.json  # Provider definitions + routing
├── netrunner/
│   ├── bin/netrunner      # Tier 5 CLI
│   ├── dotfiles/          # zshrc, tmux.conf, etc.
│   └── install.sh         # Shell setup
├── package.json           # Dependencies
└── purplebruce.db         # SQLite (users, chat, config, tasks, SOC alerts)
```

---

## Security & Discipline

**Strict Discipline Model:**
- Every offensive action requires explicit operator command
- No autonomous security tasks
- Only within authorized redteam / bug-bounty scope
- Full audit log + SOC monitoring
- Healing events + failover events logged

**Use only on systems you own or are explicitly authorized to assess.**

---

## Troubleshooting

**Syntax check:**
```bash
node -c server.js
npm run build  # if applicable
```

**Smoke Test:**
```bash
./purplebruce.sh &
sleep 2
curl -s http://127.0.0.1:3000/api/status | jq .
```

**Register + Login:**
```bash
# In UI: click login modal, register first, then login
# Token stored in localStorage, persists across sessions
```

**No audio on voice call?**
- Check microphone permissions in browser
- Ensure Groq API key is set (for Whisper STT)
- Edge TTS requires network — should work offline after first call (cached)

---

## Built by TAesthetics

**TERTRATRONIC RIPPLER TIER 5**  
Lucy v6.0 · Self-Healing AI Team · Gemini-Powered Fallback  
Authentication · Stripe Payments · Discipline-First Design

---

*Updated: 2025 · Stufe 2 · Professional Purple Team Platform*
