# PURPLE BRUCE LUCY — Claude Code Project Context

**Purple Team AI Agent · v7.0 · Runs on Android (Termux + Arch proot)**

## What This Is

Purple Bruce Lucy is a self-healing, multi-provider AI agent platform built for purple team security operations. It runs entirely on a consumer Android device via Termux + Arch Linux proot — no root required, no expensive hardware, no cloud dependency beyond AI APIs.

The name: **Purple** (purple team) + **Bruce** (hardened) + **Lucy** (the AI persona).

## Architecture — Three Layers

```
LAYER 0  Pure Termux          Node.js server only, no hacking tools
LAYER 1  Termux (proot host)  Launcher + wrapper aliases (lucy, pbstart)
LAYER 2  Arch Linux proot     Full BlackArch arsenal + ZSH + AI agent  ← main workspace
```

## Key Files

| File | Purpose |
|------|---------|
| `server.js` | Main server — Express + WebSocket + AI routing + SOC + Red team (1350 lines) |
| `public/index.html` | Main web UI — React-like SPA via vanilla JS |
| `public/hud.html` | Smart glasses HUD — minimal OLED-optimized display |
| `public/drone.html` | DJI Mini 4K control panel — telemetry + flight controls |
| `netrunner/bin/netrunner` | CLI tool — `netrunner doctor/deck/team/scan/start` |
| `netrunner/dotfiles/zshrc` | ZSH environment v7.0 — all aliases |
| `netrunner/dotfiles/install.sh` | Deploy dotfiles (run inside Arch proot) |
| `netrunner/install-arch.sh` | Full Arch proot setup + npm install + dotfiles |
| `netrunner/drone/mini4k.py` | DJI Mini 4K drone bridge (Python WebSocket server, port 7778) |
| `netrunner/firmware/flash-bruce.sh` | Flash Bruce firmware to M5StickC Plus2 |
| `purplebruce.db` | SQLite — config (API keys, operator token), chat history, tasks, alerts |

## Running the Server

```bash
# Inside Arch proot (Layer 2):
cd ~/purplebruce && npm install    # first time only
node server.js                      # or: pbstart / go

# Health check:
curl http://127.0.0.1:3000/api/health

# Operator token (shown at startup, also in file):
cat ~/.purplebruce/operator.txt
```

## AI Providers

Six providers with automatic failover. Configured via Settings modal in web UI.

| Provider | Config Key | Notes |
|----------|-----------|-------|
| Grok (xAI) | `grok_api_key` | Default reasoning |
| Venice | `venice_api_key` | Red team / privacy-first |
| Gemini | `gemini_api_key` | Voice + fallback |
| Claude (Anthropic) | `claude_api_key` | Deep reasoning preferred |
| OpenRouter | `openrouter_api_key` | 100+ model access |
| OpenClaw | `openclaw_enabled=1` | Local agent, no API key |

Provider routing: Claude → reasoning, Venice+Claude → redteam, Gemini → voice, OpenClaw → local fallback.

## WebSocket Protocol

All real-time communication is via WebSocket. Sensitive actions require `token` field.

```javascript
// Get operator token from ~/.purplebruce/operator.txt
ws.send(JSON.stringify({ action: 'exec_cmd', cmd: 'id', token: 'YOUR_TOKEN' }))
ws.send(JSON.stringify({ action: 'chat', message: 'run a quick scan of localhost' }))
ws.send(JSON.stringify({ action: 'scan', target: '192.168.1.1', mode: 'QUICK', token: 'YOUR_TOKEN' }))
ws.send(JSON.stringify({ action: 'drone_connect', ip: '192.168.2.1', token: 'YOUR_TOKEN' }))
```

Actions requiring token: `exec_cmd scan harden hunt red_preview red_execute drone_scan drone_connect drone_command autonomous_toggle set_key set_provider`

## API Endpoints

```
GET  /api/health    Safe health check (no system info)
GET  /api/status    Full system intel (hostname, ports, etc.)
GET  /api/providers AI provider status
GET  /api/team      Team health + failover state
GET  /api/tasks     Running tasks
GET  /api/drone     Drone status
GET  /hud           Smart glasses HUD
GET  /drone         Drone control panel
POST /api/cli       HTTP equivalent of WS actions
POST /api/stt       Speech-to-text (Groq Whisper)
POST /api/tts       Text-to-speech (ElevenLabs / Edge TTS)
```

## Security Model

- **Operator token**: Generated at first boot, stored in `~/.purplebruce/operator.txt` and SQLite
- **Sensitive actions**: Require `token` field in WS message
- **Rate limiting**: 120 messages/min global
- **Scan target validation**: Blocks shell metacharacters in scan targets
- **Autonomous mode**: Requires explicit toggle — never auto-enabled from chat
- **Audit log**: Every command logged to `~/.purplebruce/audit.log`
- **Design note**: This is a local personal tool. Bind to 127.0.0.1 if exposing beyond localhost.

## Drone Integration

```bash
# Start drone bridge (in Arch proot or Termux):
drone-bridge   # alias: pip install websockets + run mini4k.py

# Open drone panel:
# http://127.0.0.1:3000/drone

# DJI Mini 4K setup:
# 1. Hold power button 3s → drone creates WiFi hotspot
# 2. Connect to DJI_MINI_XXXXXX from Termux
# 3. drone-bridge → Scan → Connect in web panel
```

## ZSH Aliases (Layer 2)

```bash
pbstart / go        # start server (tmux)
pbstop / stop       # stop server
pbupdate / update   # git pull + npm install + redeploy dotfiles
doctor              # netrunner doctor (health check)
team                # AI team status
toolcheck           # verify BlackArch arsenal
bruce-flash         # flash Bruce firmware to M5StickC Plus2
drone-bridge        # start DJI Mini 4K bridge
oc / ocstart        # OpenClaw local AI
```

## Common Development Commands

```bash
# Install deps:
cd ~/purplebruce && npm install

# Deploy dotfiles (run inside Arch proot):
bash netrunner/dotfiles/install.sh && exec zsh

# Full fresh install (from empty Arch proot):
bash netrunner/install-arch.sh

# Run with custom port:
PORT=8080 node server.js

# Check health:
curl http://127.0.0.1:3000/api/health | jq

# Watch logs:
logs    # alias: tail -f ~/.purplebruce/audit.log

# Git workflow:
pbupdate    # pull + install + deploy
```

## SQLite Schema

```sql
config       (key TEXT PRIMARY KEY, value TEXT)           -- all settings + API keys
chat_history (id, role, content, meta, timestamp)
tasks        (id, type, label, pid, status, started, ended)
soc_alerts   (id, severity, type, detail, response, timestamp)
```

## Known Issues / Gotchas

1. **ARM64 + nettle 4.0**: After `pacman` upgrade, run `ldconfig` before git/wget
2. **`start` alias conflict**: Android proot intercepts `start` command — use `pbstart` or `go`
3. **DJI Mini 4K**: Full autonomous waypoint missions require DJI Mobile SDK (Android app); manual control works via UDP bridge
4. **ngtcp2/curl**: On Android ARM64 proot, `curl` may fail with ngtcp2 symbol error — use `wget` or `python3 -c "import urllib.request; ..."`
5. **npm install**: Must run inside Arch proot with correct Node.js (v18+)
6. **Edge TTS**: No API key needed — uses Microsoft's public token

## Environment Variables

```bash
PORT=3000                      # server port (default: 3000)
OPERATOR_TOKEN=<hex>           # override generated token
EDGE_TTS_TOKEN=<token>         # Microsoft Edge TTS token (optional)
STRIPE_SECRET_KEY=<key>        # Stripe integration (optional)
STRIPE_PRICE_ID=<price_id>     # Stripe price ID (optional)
```

## Value Proposition

- **Runs on a $50 Android phone** — no expensive hardware
- **6 AI providers** with automatic failover — enterprise-grade reliability
- **Purple Team in one tool** — offensive + defensive + SOC analyst
- **Voice-native** — Whisper STT + ElevenLabs/Edge TTS, hands-free operation
- **Hardware control** — DJI drone + M5StickC Plus2 (Bruce firmware) + smart glasses HUD
- **Air-gap capable** — OpenClaw provides local AI when offline
- **Zero root** — runs entirely in Termux proot container
