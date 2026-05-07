# PURPLE BRUCE v6.0 — TERTRATRONIC RIPPLER TIER 5

```
  ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗
  ████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗
  ██╔██╗ ██║█████╗     ██║   ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
  ██║╚██╗██║██╔══╝     ██║   ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
  ██║ ╚████║███████╗   ██║   ██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║
  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝

  TERTRATRONIC RIPPLER v6.0  ·  TIER 5  ·  KALI NETHUNTER FULL ROOTLESS
```

**Professional Purple-Team Cyberdeck** — AI security agent + voice interface + team coordination + Stripe payments.  
Optimized for **Kali NetHunter Full Rootless** on Android. No root. No systemd. No proot.

---

## Kali NetHunter Full Rootless

Purple Bruce runs natively inside **NetHunter Full Rootless** — the official Kali NetHunter environment for non-rooted Android devices. No chroot, no proot-distro, no superuser required.

> **NetHunter Full Rootless** gives you a full Kali environment in Termux with all pentesting tools pre-installed. Purple Bruce lives inside this environment and connects to the tools directly.

### Requirements

- Android device (no root needed)
- **Kali NetHunter Full Rootless** installed ([nethunter.com](https://www.kali.org/get-kali/#kali-mobile))
- NetHunter Terminal app
- Internet connection for first install

---

## Install (NetHunter Terminal)

Open the **NetHunter Terminal** and run:

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-nethunter.sh | bash
```

Then set your JWT secret and start:

```bash
export JWT_SECRET="your-secret-here"
cd ~/purplebruce && node server.js &
# Open http://127.0.0.1:3000 in Chrome/Firefox
```

The installer will:
1. Detect Kali / NetHunter / Termux environment
2. Check Node.js ≥18 (install via apt or nvm if needed)
3. Install recommended Kali tools (nmap, nikto, sqlmap, ffuf, gobuster, etc.)
4. Clone or update Purple Bruce
5. Run `npm install`
6. Symlink `netrunner` CLI to `~/.local/bin/`
7. Add shell aliases to `.zshrc` / `.bashrc`

---

## Manual Install

```bash
# Inside NetHunter Terminal
apt update && apt install -y nodejs npm git

git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce
npm install

export JWT_SECRET="$(head -c 24 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)"
node server.js &

# Open http://127.0.0.1:3000 in your mobile browser
```

---

## Other Platforms

### Linux / WSL / macOS

```bash
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
npm install
export JWT_SECRET="your-secret-here"
node server.js
# http://localhost:3000
```

### Termux + proot (Ubuntu/Debian, non-NetHunter)

```bash
pkg install -y proot-distro git nodejs npm
proot-distro install ubuntu
proot-distro login ubuntu
apt update && apt install -y build-essential
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce && npm install
export JWT_SECRET="your-secret-here"
node server.js &
```

> For full Kali toolset on non-rooted Android, use **Kali NetHunter Full Rootless** (above) instead of Ubuntu proot.

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
- **Local mode (default)** — SQLite + bcrypt, no external services needed
- **Supabase mode** — set `SUPABASE_URL` + `SUPABASE_ANON_KEY` to enable

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

## Configuration

### Environment Variables

```bash
# Required
export JWT_SECRET="your-jwt-secret-key-CHANGE-THIS"

# Stripe payments (optional)
export STRIPE_SECRET_KEY="sk_test_your_key_here"
export STRIPE_PRICE_ID="price_1ABC123xyz"

# Supabase (optional — falls back to local SQLite if not set)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-public-key"
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

### Auth Modes

| Mode | When | Storage | Password Hashing |
|------|------|---------|-----------------|
| **Local** (default) | No Supabase env vars | SQLite `users` table | bcrypt (cost 12) |
| **Supabase** | `SUPABASE_URL` + `SUPABASE_ANON_KEY` set | Supabase `auth.users` | Supabase managed |

### Supabase Setup (optional, recommended for production)

1. Create a project at [supabase.com](https://supabase.com) — free tier works
2. Go to **Project Settings → API** → copy `URL` and `anon public` key
3. Set env vars above
4. Restart server — login/register will use Supabase instead of local SQLite

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

## Kali Tools (Pre-installed in NetHunter)

NetHunter Full Rootless includes Kali's full toolset. Purple Bruce integrates with:

| Tool | Purpose |
|------|---------|
| `nmap` | Network discovery & port scanning |
| `nikto` | Web server vulnerability scan |
| `sqlmap` | SQL injection testing |
| `ffuf` | Web fuzzing (directories, params) |
| `gobuster` | Directory / DNS brute force |
| `hydra` | Password / credential brute force |
| `whatweb` | Web fingerprinting |
| `netcat` | Raw TCP/UDP connections |
| `masscan` | Fast port scanner |
| `metasploit` | Exploitation framework |

Run `netrunner doctor` to verify tools availability in your environment.

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

GET /api/auth/me   # Authorization: Bearer <token>
→ { "user": { "id": "...", "email": "..." } }
```

### Stripe Checkout

```bash
POST /api/stripe/checkout   # Authorization: Bearer <token>
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
POST /api/stt   # raw audio binary, lang query param
POST /api/tts { "text": "Hello world" }
```

---

## Project Layout

```
purplebruce/
├── server.js                  # Express + WebSocket + AI team + auth + payments
├── public/index.html          # React UI (chat, voice, settings, login)
├── purplebruce.sh             # Launcher script
├── config/
│   └── ai-providers.json      # Provider definitions + routing
├── netrunner/
│   ├── bin/netrunner          # Tier 5 CLI
│   ├── install-nethunter.sh   # NetHunter Full Rootless installer
│   ├── dotfiles/              # zshrc, tmux.conf, etc.
│   └── install.sh             # Generic shell setup
├── package.json               # Dependencies
└── purplebruce.db             # SQLite (users, chat, config, tasks, SOC alerts)
```

---

## Troubleshooting

**Syntax check:**
```bash
node -c server.js
```

**Smoke test:**
```bash
node server.js &
sleep 2
curl -s http://127.0.0.1:3000/api/status | python3 -m json.tool
```

**Check netrunner health:**
```bash
netrunner doctor
```

**PATH not set after install:**
```bash
source ~/.bashrc   # or source ~/.zshrc
# then: netrunner doctor
```

**Node.js missing on NetHunter:**
```bash
apt update && apt install -y nodejs npm
# or via nvm:
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc && nvm install 20 && nvm use 20
```

**No audio on voice call:**
- Check microphone permissions in browser
- Ensure Groq API key is set (Settings ⚙ → Groq key)
- Edge TTS requires network for first call

**Register / Login:**
- Click the login modal on first load
- Register first, then login
- Token stored in localStorage — persists across sessions

---

## Security & Discipline

**Strict Discipline Model:**
- Every offensive action requires explicit operator command
- No autonomous security tasks without approval
- Only within authorized redteam / bug-bounty scope
- Full audit log + SOC monitoring
- Healing events + failover events logged to `~/.purplebruce/audit.log`

**Use only on systems you own or are explicitly authorized to assess.**

---

## Built by TAesthetics

**TERTRATRONIC RIPPLER TIER 5**  
Lucy v6.0 · Self-Healing AI Team · Gemini-Powered Fallback  
Authentication · Stripe Payments · Kali NetHunter Full Rootless

---

*Updated: 2025 · Stufe 2 · Kali NetHunter Full Rootless · Professional Purple Team Platform*
