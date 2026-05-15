```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          N E U R A L   I N T E R F A C E   v 7 . 1
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿

 ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗     ███████╗
 ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝
 ██████╔╝██║   ██║██████╔╝██████╔╝██║     █████╗
 ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║     ██╔══╝
 ██║     ╚██████╔╝██║  ██║██║     ███████╗███████╗
 ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

          B R U C E  ⚡  L U C Y
    Purple Team · BlackArch · Neural Mesh
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```

**Purple Bruce Lucy** is a purple team AI agent that runs on your Android phone.  
No root. No laptop. No cloud required. Just Termux and one command.

---

## ◈ Install — 4 Commands, Done

Open **Termux** (from F-Droid, not Play Store) and paste this:

```bash
# 1 — Install Termux packages
pkg update -y && pkg install -y proot-distro

# 2 — Download and enter Arch Linux
proot-distro install archlinux && proot-distro login archlinux

# 3 — Run the Purple Bruce installer (inside Arch)
wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash

# 4 — Activate
exec zsh
```

After step 3 finishes (10-20 min, do it on WiFi), you'll see the Purple Bruce banner.  
Type `go` to start. Open **http://127.0.0.1:3000** in your browser.

> **WiFi tip:** If `wget` fails with a crypto error, run `pacman -Sy --noconfirm ngtcp2` first.

---

## ⚡ From Now On — One Command

After the first install, the installer writes a `pb` alias into your Termux shell.

**From Termux, just type:**

```
pb
```

That's it. One command. Enters Arch Linux, starts the server, drops you into the cyberpunk terminal.

---

## ◈ What Is This

A self-healing AI agent platform for security professionals, built for Android.

```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  You       →  Android phone  (any, $50+)
  Shell     →  Termux + Arch Linux proot
  Arsenal   →  100+ BlackArch hacking tools
  Brain     →  6 AI providers, auto-failover
  Ears      →  Whisper speech-to-text (Groq)
  Voice     →  Edge TTS / ElevenLabs
  Eyes      →  DJI Mini 4K drone camera
  Wrist     →  M5StickC Plus2 wearable remote
  Headset   →  HOCO EQ3 via Bluetooth audio
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```

---

## ◈ Commands — The Full Arsenal

Once you're inside (after typing `pb` from Termux):

### Server

| Command | What it does |
|---------|--------------|
| `go` | Start Purple Bruce server |
| `stop` | Stop server |
| `pbrestart` | Restart |
| `logs` | Watch live logs |
| `pbupdate` | Download latest + redeploy everything |

### AI Agent

| Command | What it does |
|---------|--------------|
| `nc` | NemoClaw — interactive AI REPL (like Claude CLI) |
| `nc "question"` | One-shot query |
| `nct "task"` | NemoClaw with tool use (can run bash commands) |
| `ncg` | Force Gemini provider |
| `ncc` | Force Claude provider |
| `nc /setkey gemini KEY` | Save your API key |

### Scanning & Hacking

| Command | What it does |
|---------|--------------|
| `scan <target>` | Recon scan via AI-powered scanner |
| `nq <target>` | Quick nmap scan |
| `nfull <target>` | Full nmap scan (all ports) |
| `nstealth <target>` | Stealth scan |
| `se <term>` | Search Exploit-DB |
| `msfq` | Metasploit |
| `toolcheck` | Show all installed/missing tools |

### Audio & Bluetooth

| Command | What it does |
|---------|--------------|
| `bt` | Interactive Bluetooth menu |
| `bt-connect` | Connect HOCO EQ3 headphones |
| `bt-scan` | Scan for BT devices |
| `bt-status` | Show BT + audio status |
| `bt-vol 80` | Set volume to 80% |

### Drone

| Command | What it does |
|---------|--------------|
| `drone` | Start DJI Mini 4K bridge |
| `drone-track` | Autonomous follow-me tracker (click to select target) |
| `drone-track-auto` | Auto-detect and follow first person |

### Dashboard

| Command | What it does |
|---------|--------------|
| `tui` | Interactive TUI dashboard |
| `deck` | Cyberdeck status |
| `team` | AI provider health |
| `doctor` | Auto-diagnose + fix problems |

---

## ◈ AI Providers — Add Your Keys

Open **http://127.0.0.1:3000** → Settings ⚙ → enter your keys.

Or from the terminal with NemoClaw:

```bash
nc /setkey gemini YOUR_KEY
nc /setkey grok   YOUR_KEY
nc /setkey claude YOUR_KEY
```

| Provider | Free? | Key URL |
|----------|-------|---------|
| **Gemini** (Google) | ✅ Free tier | aistudio.google.com/app/apikey |
| **Groq** (voice STT) | ✅ Free tier | console.groq.com |
| **Grok** (xAI) | Partial free | console.x.ai |
| **Claude** (Anthropic) | Paid | console.anthropic.com |
| **Venice** | Paid | venice.ai |
| **OpenRouter** | Pay per use | openrouter.ai |

**Start with Gemini** — free, no credit card, works immediately.

---

## ◈ Bluetooth Audio — HOCO EQ3

```bash
bt            # opens interactive menu
bt-connect    # auto-detect + connect HOCO EQ3
bt-status     # verify connection + audio sink
bt-vol 80     # set volume
```

> Purple Bruce tries to use BlueZ (Linux Bluetooth stack) inside the proot.
> If your Android kernel doesn't expose Bluetooth to the proot (most do not without root),
> pair via **Android Settings → Bluetooth**, then the audio will route automatically.
>
> For audio inside proot to work, install PulseAudio in Termux:
> ```bash
> # In a SECOND Termux window (not inside proot):
> pkg install pulseaudio
> pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1"
> ```

---

## ◈ Drone — DJI Mini 4K Autonomous Tracker

```bash
# 1. Turn on drone (hold power 3s) → creates WiFi hotspot
# 2. Connect phone to DJI_MINI_XXXXXX WiFi
# 3. Start bridge:
drone

# 4. For autonomous follow-me mode:
drone-track              # click on target in video window
drone-track-auto         # auto-detect first person

# 5. Or open the web panel:
# http://127.0.0.1:3000/drone
```

The tracker uses OpenCV CSRT — locks target in ~15ms, follows at up to 30 km/h with PID velocity control.

---

## ◈ M5Stick Drone Remote — Wearable Controller

The M5StickC Plus2 (ESP32) becomes a wearable IMU drone controller:

- **Tilt wrist** → drone moves in that direction (30Hz IMU)
- **Button B** (2s hold) → emergency land
- **Shake** → emergency stop
- **Screen** → shows battery, altitude, target lock, tilt angles
- **4 modes** → HOVER / IMU\_CTRL / STATUS / WIFI\_SCAN

Flash firmware:
```bash
cd netrunner/hardware/drone-remote
pio run -t upload
```

---

## ◈ NemoClaw — CLI AI Agent

```bash
nc                              # interactive REPL
nc "explain SQL injection"      # one-shot
nc -t "scan this network"       # tool use — runs commands with your approval
echo "what is nmap?" | nc       # piped
nc -p gemini "question"         # force specific provider
```

NemoClaw reads API keys from Purple Bruce's database automatically.
No setup needed if you've already configured keys in the web UI.

---

## ◈ Smart Glasses HUD

Connect AR glasses (Xreal, Vuzix, etc.) and open:
```
http://127.0.0.1:3000/hud
```

Minimal OLED-optimized UI — shows AI status, alerts, scan results.

---

## ◈ Fix Common Errors

**`pb` command not found in Termux**
```bash
# Add manually to ~/.bashrc in Termux:
echo "alias pb='proot-distro login archlinux -- bash ~/purplebruce/netrunner/launch.sh'" >> ~/.bashrc
source ~/.bashrc
```

**`npm install` fails (Python / prebuilt binary error)**
```bash
pacman -S --noconfirm python make gcc
cd ~/purplebruce && npm install
```

**`wget` fails with crypto / ngtcp2 error**
```bash
pacman -Sy --noconfirm ngtcp2 && ldconfig
```

**`pbupdate` fails: "not a git repository"**  
Fixed in v7.1 — `pbupdate` auto-downloads via tarball if `.git` is missing.

**Server starts but browser can't connect**
```bash
doctor        # auto-fix
curl http://127.0.0.1:3000/api/health
```

**Bluetooth: "adapter not found" in proot**  
Normal on most Android kernels. Pair HOCO EQ3 via Android Bluetooth settings,
then start PulseAudio in Termux (see Bluetooth section above).

---

## ◈ Update

```bash
pbupdate
```

Downloads latest, reinstalls deps, redeploys dotfiles. Run `exec zsh` after.

---

## ◈ File Map

```
purplebruce/
├── server.js                      AI server — Express + WebSocket + SOC
├── purplebruce.sh                 Launcher script (plain Linux / Layer 0)
├── public/
│   ├── index.html                 Web UI
│   ├── hud.html                   Smart glasses HUD
│   └── drone.html                 Drone control panel
├── netrunner/
│   ├── launch.sh                  ← single 'pb' launch target
│   ├── bin/netrunner              CLI: doctor/deck/team/scan/nc/track/tui
│   ├── tui.sh                     Bash TUI dashboard
│   ├── install-arch.sh            Full Arch + BlackArch installer
│   ├── dotfiles/
│   │   ├── zshrc                  ZSH v7.1 — all aliases + cyberpunk boot
│   │   └── install.sh             Deploy dotfiles + write 'pb' Termux alias
│   ├── nemoclaw/
│   │   └── nemoclaw.py            CLI AI agent (nc command)
│   ├── audio/
│   │   └── bt-setup.sh            Bluetooth audio — HOCO EQ3
│   ├── drone/
│   │   ├── mini4k.py              DJI Mini 4K bridge (port 7778)
│   │   └── tracker.py             Autonomous target tracker
│   └── hardware/
│       └── drone-remote/          M5StickC Plus2 wearable remote
│           ├── drone-remote.ino   IMU drone controller firmware
│           └── platformio.ini
└── purplebruce.db                 SQLite: config, keys, history, alerts
```

---

## ◈ Security

- **Operator token** — generated at first boot, in `~/.purplebruce/operator.txt`
- **Localhost only** — server binds to `127.0.0.1` by default
- **Audit log** — every command logged to `~/.purplebruce/audit.log`
- **Rate limiting** — 120 requests/min
- Drone tracking, scan, exec: all require operator token

---

## ◈ Links

- GitHub: https://github.com/TAesthetics/purplebruce
- Issues: https://github.com/TAesthetics/purplebruce/issues
- Free Gemini key: aistudio.google.com/app/apikey
- Free Groq key (voice): console.groq.com

```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  PURPLE BRUCE LUCY v7.1 — NEURAL MESH ACTIVE
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```
