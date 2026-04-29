# 🟣 Purple Bruce v6.0 — Netrunner Edition

Purple-Team platform with a chat-first AI agent (**Lucy**), live SOC daemon,
and a mobile-friendly web UI. Designed to run **on your Android phone** in a
Termux + proot-distro sandbox — and equally well on native Linux.

> v6.0 reduces the install dance from a 12-line ritual to **one command** on
> a fresh phone. Everything else is just `netrunner`.

---

## 🚀 Quickstart (Android / Termux)

Two commands. Fresh Termux, no setup.

```bash
pkg install -y git curl && git clone https://github.com/TAesthetics/purplebruce.git \
  && bash purplebruce/netrunner/install.sh
```

```bash
netrunner
```

That's it. The first `netrunner` call:

1. drops you into the Ubuntu proot
2. clones Purple Bruce inside it (if missing)
3. installs Node, zsh, fastfetch, the cyberpunk terminal
4. starts Lucy on `http://127.0.0.1:3000`

Open that URL in Android Chrome / Firefox. Done.

> **Native Linux / WSL?** Skip the first command, just clone, then run
> `bash netrunner/install.sh` and `netrunner`. Same flow, no proot.

---

## 🎯 The `netrunner` command

One command, layer-aware:

| Where | `netrunner …`        | What it does |
|---|---|---|
| **Termux**     | (no arg)        | enters proot + bootstraps + starts Purple Bruce |
| **Termux**     | `status`        | shows distro state |
| **Proot/Linux**| `start` (default)| starts Purple Bruce on `127.0.0.1:3000` |
| **Proot/Linux**| `stop`          | stops the server |
| **Proot/Linux**| `status`        | what's running, what's missing |
| **Proot/Linux**| `logs`          | tail -f the server log |
| **Proot/Linux**| `chat`          | open Lucy's interactive CLI |
| **Proot/Linux**| `bash`          | drop to a shell |
| **Proot/Linux**| `exit`          | leave the proot |

Env: `PORT=3000  BIND=127.0.0.1  NETRUNNER_DISTRO=ubuntu  PURPLEBRUCE_DIR=~/purplebruce`

---

## ✨ What's inside

- **Lucy** — playful purple-team AI operator. Auto-detects DE/EN. Voice mode
  with Web Speech (browser) or Whisper (Groq/OpenAI) push-to-talk fallback.
- **TTS** — ElevenLabs anime voice; falls back to browser TTS.
- **Chain-of-Thought trace** — `🧠 THINK → 📋 PLAN → ⚡ CMD → 📊 ANALYSIS → ✅ DONE`
  rendered live in the call modal, with round numbers.
- **Blue-team SOC daemon** — watches listeners, outbound connections,
  `LD_PRELOAD`, crontabs; auto-quarantines anomalies.
- **Multi-LLM** — Grok (xAI) and Venice.ai out of the box.
- **Cyberpunk terminal** — zsh + Powerlevel10k + fastfetch image-logo banner,
  Edgerunners palette, custom MOTD. See `netrunner/README.md`.

---

## 🔑 API key setup

Open the web UI → ⚙ Settings, **or** use the CLI inside the proot:

```bash
netrunner chat
purple> setkey grok        xai-xxxxxxxxxxxx
purple> setkey elevenlabs  el_xxxxxxxxxxxx
purple> setvoice           <elevenlabs_voice_id>
purple> setkey groq        gsk_xxxxxxxxxxxx     # enables PTT Whisper STT
```

| Purpose | Provider | Where to get |
|---|---|---|
| Chat LLM (default) | Grok (xAI)        | <https://console.x.ai> |
| Chat LLM (alt)     | Venice.ai         | <https://venice.ai> |
| TTS                | ElevenLabs        | <https://elevenlabs.io> |
| STT (PTT)          | Groq Whisper      | <https://console.groq.com> |
| STT (alt)          | OpenAI Whisper    | <https://platform.openai.com> |

---

## 🛠 Optional: pentest toolkit

```bash
./tools-install.sh           # core + extras (apt or pacman, auto-detect)
./tools-install.sh --core    # only essentials
./tools-install.sh --kali    # also Kali bundles (needs Kali repos)
```

Installs nmap, masscan, sqlmap, hydra, john, hashcat, ffuf, gobuster,
aircrack-ng, tshark, impacket, etc. Missing packages are skipped, not fatal.

---

## 🔁 24/7 service

```bash
./install-service.sh install        # termux-services if available, else nohup watchdog
./install-service.sh status
./install-service.sh logs
./install-service.sh enable-cron    # nightly 03:30 harden + hunt + report
```

Reports land in `~/.purplebruce/reports/YYYY-MM-DD.txt`. All outbound calls
target `127.0.0.1` only.

---

## 📁 Project layout

```
purplebruce/
├── server.js              # Express + WebSocket + agent loop + SOC daemon
├── public/index.html      # React UI (single file, Babel standalone)
├── purplebruce.sh         # Server launcher + Lucy CLI
├── tools-install.sh       # Optional pentest toolkit installer
├── install-service.sh     # 24/7 supervisor + cron
├── netrunner/             # Cyberpunk terminal + the `netrunner` command
│   ├── bin/netrunner      # The universal launcher
│   ├── install.sh         # Layer-aware installer
│   ├── assets/            # cross.png, snake.png, motd.sh, fastfetch.jsonc
│   └── dotfiles/          # zshrc, p10k.zsh, tmux.conf
├── agi/                   # Multi-provider AGI CLI with safe execution
└── purplebruce.db         # SQLite (chat, config, audit, SOC alerts)
```

---

## ⚠ Security note

Lucy's `Unrestricted Access` mode lets the agent execute shell commands on the
host it runs on. Inside a Termux proot-distro that's the proot rootfs (not
your Android system), but it's still **your data**. Use responsibly — only on
systems you own or are authorized to assess.

---

## 🗺 Migrating from v5.0

If you already have v5.0 running:

```bash
cd ~/purplebruce
git pull
bash netrunner/install.sh        # re-run, idempotent
exec zsh
netrunner status
```

Old `proot-distro login ubuntu && cd purplebruce && ./purplebruce.sh` flows
still work — they just got shorter.

---

**Built by TAesthetics — Lucy v6.0 Netrunner Edition.** New here? See
[`QUICKSTART.md`](./QUICKSTART.md).
