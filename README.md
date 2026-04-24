# 🟣 Purple Bruce v5.0 — Lucy Edition

Purple-Team platform with a chat-first AI agent (Lucy), live SOC daemon, and a mobile-friendly web UI. Built to run **natively on Linux** and **inside a Termux `proot-distro` sandbox** (Ubuntu / Kali / BlackArch) on Android, without systemd or sudo assumptions.

---

## ✨ Features

- **Lucy — playful AI operator**: cute, energetic, lightly-teasing personal assistant that stays a purple-team agent at her core. Auto-detects the user's language (DE / EN) and mirrors it.
- **Voice call**: full-duplex voice mode with two STT paths:
  - Browser-native `Web Speech API` (free, offline-ish, works on desktop Chrome)
  - Server-side **Whisper** via Groq (free tier) or OpenAI, used as a Push-to-Talk fallback everywhere else — including Android Chrome in a proot-distro setup
- **TTS**: ElevenLabs for a natural, high-pitched anime-style female voice (pitch controlled by Voice Design, not runtime). Falls back to the browser's Web Speech synthesizer if ElevenLabs isn't configured.
- **Chain-of-Thought trace** rendered live in the call modal: `🧠 THINK → 📋 PLAN → ⚡ CMD → 📊 ANALYSIS → ✅ DONE`, with round numbers.
- **Blue-team SOC daemon**: continuously watches listeners, outbound connections, `LD_PRELOAD` injections, and crontabs; auto-quarantines and alerts on anomalies.
- **Multi-LLM**: Grok (xAI) and Venice.ai supported out of the box.
- **Mobile-friendly**: runs inside Termux proot-distro, single SQLite database, no system services required.

---

## 📦 Install

### A. Termux + Ubuntu proot-distro (Android)

```bash
# 1) In Termux (as the regular termux user)
pkg update -y
pkg install -y proot-distro git
proot-distro install ubuntu          # one-time
proot-distro login ubuntu            # drop into the Ubuntu rootfs

# 2) Inside the proot (you're root here — no sudo needed)
apt update
apt install -y nodejs npm git curl ca-certificates
cd /root
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
chmod +x purplebruce.sh tools-install.sh
./tools-install.sh --core            # optional: base pentest tools
./purplebruce.sh                     # starts the web UI on 127.0.0.1:3000
```

Open `http://127.0.0.1:3000` in Android Chrome / Firefox to talk to Lucy. Localhost counts as a "secure context", so mic + Web Speech work without HTTPS.

### B. Termux + Kali proot-distro (Android)

```bash
pkg install -y proot-distro
proot-distro install kali            # heavier install, ~1–2 GB
proot-distro login kali

apt update
apt install -y nodejs npm git curl
cd /root
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
chmod +x purplebruce.sh tools-install.sh
./tools-install.sh --kali            # adds metasploit, crackmapexec, wpscan, ...
./purplebruce.sh
```

### C. Termux + Arch / BlackArch proot-distro

```bash
proot-distro install archlinux
proot-distro login archlinux

pacman -Syu --noconfirm
pacman -S --needed --noconfirm nodejs npm git curl
# Optional — add the BlackArch repo (see blackarch.org for the official bootstrap)
cd /root
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
chmod +x purplebruce.sh tools-install.sh
./tools-install.sh                   # auto-detects pacman + BlackArch repo
./purplebruce.sh
```

### D. Native Linux / macOS / WSL

```bash
# Requires Node.js ≥ 18 (for native fetch/Blob/FormData)
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
chmod +x purplebruce.sh tools-install.sh
./tools-install.sh                    # optional
./purplebruce.sh
```

---

## 🔑 API key setup

Open the web UI → ⚙ Settings, or use the CLI.

| Purpose | Provider | Config key | Where to get |
|---|---|---|---|
| Chat LLM (default) | Grok (xAI) | `grok_api_key` | <https://console.x.ai> |
| Chat LLM (alt)     | Venice.ai  | `venice_api_key` | <https://venice.ai> |
| TTS (anime voice)  | ElevenLabs | `elevenlabs_api_key` + `elevenlabs_voice_id` | <https://elevenlabs.io> |
| STT (fallback, free tier) | Groq Whisper | `groq_api_key` | <https://console.groq.com> |
| STT (fallback)     | OpenAI Whisper | `openai_api_key` | <https://platform.openai.com> |

CLI:

```bash
purple> setkey grok        xai-xxxxxxxxxxxx
purple> setkey elevenlabs  el_xxxxxxxxxxxx
purple> setvoice           <elevenlabs_voice_id>
purple> setkey groq        gsk_xxxxxxxxxxxx      # enables push-to-talk STT
```

---

## 🎙 Voice call — how it works

1. Click the 🎙 button on the chat page to enter **voice call mode**.
2. Default: **continuous Web Speech** — the browser listens, and any final transcript is sent to Lucy automatically. A live interim pill (`… your words…`) shows STT is actually picking up audio.
3. Hit **PTT ON** in the call modal's language bar to switch to **Push-to-Talk / Whisper mode**:
   - Press-and-hold the big mic button, speak, release.
   - The audio blob is POSTed to `/api/stt` → Groq/OpenAI Whisper → transcript → sent as a chat message.
   - Useful on Android WebView / in-proot browsers where Web Speech is flaky or unavailable.
4. Lucy's replies come back as chat messages AND are spoken via ElevenLabs (or Web Speech TTS as fallback).
5. **Thinking trace**: `chat_thinking` events surface round numbers live (`🧠 Lucy is thinking... (round 2)`), and the assistant's THINK/PLAN/CMD/ANALYSIS lines are CoT-styled inside the call modal.

### Debug logs

Open the browser console — every critical event is tagged:

- `[WS]` — WebSocket connect / send / close
- `[MIC]` — SpeechRecognition start / interim / final / error
- `[STT]` — PTT recording, blob size, Whisper result
- `[TTS]` — ElevenLabs request

If voice seems dead, the log tells you exactly which step broke.

---

## 🛠 Tools installer

`./tools-install.sh` is a best-effort installer for a pragmatic pentest toolkit. It detects `apt` / `pacman` and installs what's available:

| Group | Tools |
|---|---|
| Core recon / exploit | nmap, masscan, sqlmap, hydra, john, ncrack |
| Web | ffuf, gobuster, wfuzz, nikto, wpscan |
| Crypto / forensics | hashcat, binwalk, exiftool |
| Wireless / network | aircrack-ng, tshark, tcpdump |
| Python stacks (via pipx) | impacket, updog |
| Kali-only (with `--kali` or on Kali) | metasploit-framework, crackmapexec, theharvester, enum4linux-ng, sslscan, amass |

Modes:

```bash
./tools-install.sh           # core + extras
./tools-install.sh --core    # only essentials
./tools-install.sh --kali    # also Kali bundles (needs Kali repos)
```

Missing packages are skipped, not fatal. Re-run safely.

---

## 🔁 24/7 service (Termux / proot)

Run Purple Bruce as a supervised background service with auto-restart and log rotation:

```bash
./install-service.sh install        # termux-services if available, else nohup watchdog
./install-service.sh status         # node + watchdog + cron + HTTP liveness probe
./install-service.sh logs           # tail ~/.purplebruce/service.log
./install-service.sh restart
./install-service.sh uninstall

./install-service.sh enable-cron    # nightly 03:30 harden + hunt + report (localhost only)
./install-service.sh disable-cron
```

All outbound calls target `127.0.0.1` only — nightly reports land in `~/.purplebruce/reports/YYYY-MM-DD.txt`.

---

## 🟣 Netrunner cyberpunk terminal (`netrunner/`)

Optional zsh/tmux overlay with Edgerunners palette, Powerlevel10k two-line prompt, pink blinking cursor, custom ASCII logo + neofetch-style MOTD, and a shared `netrunner` command:

- **Termux (Android)** → `netrunner` jumps into the Ubuntu proot (manual setup: `netrunner/TERMUX.md`)
- **Ubuntu proot-distro** → `netrunner` launches Purple Bruce

Install inside the proot:

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
```

See `netrunner/README.md` for the full breakdown, subcommands (`install / uninstall / status`), dotfile layout and customisation hooks.

---

## 📁 Project layout

```
purplebruce/
├── server.js              # Express + WebSocket + agent loop + SOC daemon
├── public/index.html      # React UI (single file, Babel standalone)
├── purplebruce.sh         # Launcher (Termux/Proot aware, no hard sudo)
├── tools-install.sh       # Pentest toolkit installer
├── purplebruce.db         # SQLite (chat, config, audit, SOC alerts)
└── .purplebruce/          # Runtime data (reports, quarantine, logs)
```

---

## 🧪 Smoke test after a fresh clone

```bash
./purplebruce.sh &           # background the server
sleep 2
curl -s http://127.0.0.1:3000/api/status | head -c 200 ; echo
# Expect: {"version":"5.0.0",...}
```

In the browser, open DevTools → Console, hit 🎙, speak, and watch for:

```
[WS] open
[MIC] starting recognition — lang= de-DE
[MIC] onstart
[MIC] interim: hallo lucy
[MIC] FINAL: hallo lucy wie geht's
[WS] send chat {message: "hallo lucy wie geht's"}
```

If you see `[MIC] FINAL` but no reply, check your LLM API key. If you see no `[MIC] interim` at all while speaking, switch to **PTT ON** (Whisper) — works when Web Speech doesn't.

---

## ⚠ Security note

`Unrestricted Access` mode lets the agent execute shell commands on the host it runs on. Inside a Termux proot-distro that's the proot rootfs (not your Android system), but it's still **your data**. Use responsibly, only on systems you own or are authorized to assess.

---

**Built by TAesthetics — Lucy v5.0**
