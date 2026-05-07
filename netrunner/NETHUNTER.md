# PURPLE BRUCE — NetHunter Full Rootless

```
  ╔══════════════════════════════════════════════════╗
  ║  TERTRATRONIC RIPPLER v6.0  ·  TIER 5            ║
  ║  Kali NetHunter Full Rootless Integration         ║
  ╚══════════════════════════════════════════════════╝
```

Full integration of Purple Bruce into **Kali NetHunter Full Rootless** on Android.  
No root. No systemd. No proot. Runs natively inside the NetHunter Terminal.

---

## Quick Install

Open **NetHunter Terminal** and run:

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-nethunter.sh | bash
```

Then start:

```bash
source ~/.bashrc          # reload shell aliases
export JWT_SECRET="your-secret"
netrunner start           # tmux 3-pane layout
# OR: cd ~/purplebruce && node server.js &
```

Open `http://127.0.0.1:3000` in Chrome or Firefox.

---

## What the Installer Does

| Step | Action |
|------|--------|
| 1 | Detects Kali / NetHunter / Termux environment |
| 2 | Checks Node.js ≥18 — installs via `apt` or `nvm` if needed |
| 3 | Installs Kali tools: `nmap nikto sqlmap ffuf gobuster hydra whatweb netcat masscan` |
| 4 | Clones or updates Purple Bruce to `~/purplebruce` |
| 5 | Runs `npm install` |
| 6 | Symlinks `netrunner` CLI to `~/.local/bin/netrunner` |
| 7 | Adds shell aliases to `.zshrc` / `.bashrc` |
| 8 | Copies `nethunter-commands.json` to `~/.config/nethunter/` |

---

## netrunner CLI

```bash
netrunner doctor              # health check + auto-repair
netrunner deck                # system + cyberdeck status dashboard
netrunner team                # AI team: Grok / Venice / Gemini status
netrunner overclock           # 90s boost timer + glitch effect
netrunner scan <target>       # recon — QUICK / STANDARD / FULL / STEALTH
netrunner start               # tmux 3-pane layout
```

### Shell Aliases (added automatically)

```bash
pb / purple       → netrunner
start             → netrunner start
stop              → pkill node
logs              → tail -f ~/.purplebruce/audit.log
doctor            → netrunner doctor
deck              → netrunner deck
team              → netrunner team
overclock         → netrunner overclock
scan              → netrunner scan
```

---

## NetHunter Custom Commands

The file `nethunter-commands.json` contains 10 ready-made commands for the **NetHunter App → Custom Commands** section.

### Auto-deployed to

```
~/.config/nethunter/custom_commands.json
/sdcard/nh_custom_commands.json          (if /sdcard is writable)
```

### Import manually (if needed)

1. Open **NetHunter App**
2. Tap **Custom Commands** → import icon
3. Select `~/.config/nethunter/custom_commands.json`

### Commands included

| Command | What it does |
|---------|-------------|
| Purple Bruce — Start | `node server.js` on port 3000 |
| Purple Bruce — tmux deck | `netrunner start` — 3-pane tmux layout |
| Purple Bruce — Doctor | Full health check + auto-repair |
| Purple Bruce — Deck | System + cyberdeck status dashboard |
| Purple Bruce — AI Team | Grok / Venice / Gemini provider status |
| Purple Bruce — Overclock | 90s glitch timer |
| Purple Bruce — Scan (QUICK) | Quick recon on `<target>` |
| Purple Bruce — Scan (FULL) | Full recon on `<target>` |
| Purple Bruce — Logs | Follow audit log live |
| Purple Bruce — Stop | Kill server process |

---

## tmux 3-Pane Layout

`netrunner start` launches:

```
┌─────────────────────────────────────────────┐
│  Pane 0 — node server.js (Purple Bruce)     │
├───────────────────┬─────────────────────────┤
│  Pane 1           │  Pane 2                 │
│  audit.log (live) │  Lucy chat CLI          │
└───────────────────┴─────────────────────────┘
```

Detach with `Ctrl+B d`. Reattach: `tmux attach -t purplebruce`.

---

## AI Providers

| Provider | Role | Key |
|----------|------|-----|
| ⚡ Grok (xAI) | Default reasoning + code | [console.x.ai](https://console.x.ai) |
| 🔮 Venice.ai | Redteam (auto-routed for offensive tasks) | [venice.ai](https://venice.ai) |
| ✨ Gemini | Free fallback — long-context, multimodal | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| 🎤 Groq | Whisper STT — free speech-to-text | [console.groq.com](https://console.groq.com) |

**TTS is FREE** — Microsoft Edge Neural voices (`de-DE-KatjaNeural`, `en-US-AriaNeural`), no API key needed.

Set keys in **UI Settings ⚙** after opening `http://127.0.0.1:3000`.

---

## Environment Variables

```bash
# Required
export JWT_SECRET="your-secret-key-min-32-chars"

# Optional — Stripe payments
export STRIPE_SECRET_KEY="sk_test_..."
export STRIPE_PRICE_ID="price_..."

# Optional — Supabase auth (falls back to local SQLite if not set)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
```

Persist in `~/.bashrc` or `~/.zshrc`:

```bash
echo 'export JWT_SECRET="your-secret"' >> ~/.bashrc
source ~/.bashrc
```

---

## Kali Tools

NetHunter Full Rootless ships the full Kali toolset. Purple Bruce integrates with:

```
nmap        gobuster    masscan
nikto       hydra       metasploit
sqlmap      whatweb     netcat
ffuf        wpscan      john
```

Run `netrunner doctor` to audit which tools are available on your device.

---

## Health Check

```bash
netrunner doctor
```

Checks and auto-repairs:
- Platform detection (Kali / NetHunter / Termux)
- Node.js + npm version
- `node_modules` (runs `npm install` if missing)
- Server process + HTTP response
- SQLite database + audit log
- AI provider keys (Grok / Venice / Gemini / Groq)
- Essential tools + Kali pentesting tools

---

## Troubleshooting

**`netrunner: command not found`**
```bash
source ~/.bashrc
# or:
export PATH="$HOME/.local/bin:$PATH"
```

**Node.js missing**
```bash
apt update && apt install -y nodejs npm
# or via nvm:
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc && nvm install 20
```

**Server won't start — port in use**
```bash
pkill -f "node server.js"
netrunner start
```

**No audio / voice not working**
- Browser microphone permission must be allowed
- Groq key needed for Whisper STT (Settings ⚙)
- Edge Neural TTS needs internet on first call

---

## File Layout

```
netrunner/
├── bin/netrunner              # Tier 5 CLI (doctor, deck, team, overclock, scan, start)
├── install-nethunter.sh       # One-liner installer for NetHunter Full Rootless
├── nethunter-commands.json    # NetHunter App Custom Commands (10 commands)
├── NETHUNTER.md               # This file
├── README.md                  # Generic netrunner docs (proot setup)
├── TERMUX.md                  # Termux host layer docs
├── dotfiles/
│   ├── zshrc                  # Cyberpunk .zshrc — aliases + prompt + cursor
│   ├── p10k.zsh               # Powerlevel10k preset (no wizard)
│   └── tmux.conf              # Cyberpunk tmux theme
└── assets/
    ├── logo.ascii             # ASCII banner
    └── motd.sh                # Login greeter: sysinfo + clock
```

---

## Security

- Every offensive action requires **explicit operator command**
- No autonomous attacks — discipline-first design
- Full audit log at `~/.purplebruce/audit.log`
- SOC daemon monitors listeners, crontabs, SUID, LD_PRELOAD

**Use only on systems you own or are explicitly authorized to assess.**

---

*Purple Bruce v6.0 · TERTRATRONIC RIPPLER TIER 5 · Kali NetHunter Full Rootless*
