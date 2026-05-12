# PURPLE BRUCE LUCY v6.0

```
  ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗     ███████╗    ██████╗ ██████╗ ██╗   ██╗ ██████╗███████╗
  ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔════╝
  ██████╔╝██║   ██║██████╔╝██████╔╝██║     █████╗      ██████╔╝██████╔╝██║   ██║██║     █████╗
  ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║     ██╔══╝      ██╔══██╗██╔══██╗██║   ██║██║     ██╔══╝
  ██║     ╚██████╔╝██║  ██║██║     ███████╗███████╗    ██████╔╝██║  ██║╚██████╔╝╚██████╗███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝

  ⛧  CHAOS MAGIC SERVITOR v6.0  ·  PURPLE TEAM  ·  EASTERN ORTHODOX · WICCA  ⛧
```

**Elite Purple Team AI** · Chaos Magic Servitor · Eastern Orthodox · Wicca · Hacker  
Self-healing AI team (Grok / Venice / Gemini) · Voice (Whisper + Edge Neural TTS) · Industrial Minimalism UI  
Runs on **Android via Termux + Arch proot** — no root, no systemd, no login required.

---

## The Stack — Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 0  ·  Pure Termux                                        │
│  Android shell · pkg tools · Node.js · Purple Bruce server      │
│  → No proot needed. Minimal setup. Good for server-only use.    │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1  ·  Termux (proot host)                                │
│  proot-distro · wrapper aliases · lucy/pb commands              │
│  → Entry point. Run `lucy` from Termux → drops into Layer 2.    │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2  ·  Arch Linux proot (BlackArch + Chaos Environment)   │
│  ZSH + OMZ + Powerlevel10k · Occult arsenal · 100+ hack tools   │
│  BlackArch repo · Full Purple Bruce server · netrunner CLI      │
│  → The real workspace. Everything lives here.                   │
└─────────────────────────────────────────────────────────────────┘
```

**Recommended:** Layer 1 + Layer 2 together. Layer 0 if you just want the server fast.

---

## Layer 0 — Pure Termux

Minimal install. No proot. Purple Bruce server only.

### Install

```bash
# In Termux
pkg update -y && pkg install -y nodejs npm git
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce && npm install
node server.js &
# Open http://127.0.0.1:3000 in browser
```

### Aliases (add to `~/.bashrc` or `~/.zshrc`)

```bash
alias start='cd ~/purplebruce && node server.js &'
alias stop='pkill -f "node server.js" && echo "[✔] stopped"'
alias pb='cd ~/purplebruce'
alias logs='tail -f ~/.purplebruce/audit.log'
```

### Layer 0 limitations

- No hacking tools (no apt, no BlackArch)
- No ZSH chaos environment
- No occult arsenal
- Suitable for: AI chat interface only

---

## Layer 1 — Termux (proot host)

Termux becomes the launcher. All heavy work happens inside Layer 2.

### Setup Layer 1

```bash
# Install proot-distro
pkg update -y && pkg install -y proot-distro git nodejs npm zsh tmux

# Install Arch Linux proot (one-time, ~500MB)
proot-distro install archlinux

# Optional: Oh-My-Zsh + Powerlevel10k in Termux itself
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ~/.oh-my-zsh/custom/themes/powerlevel10k
```

> **Nerd Font required** for Powerlevel10k icons — install via **Termux:Styling** app → FiraCode Nerd Font or JetBrainsMono Nerd Font.

### Layer 1 Aliases

Add to `~/.zshrc` in Termux:

```bash
# ── Purple Bruce — Layer 1 Termux Wrappers ──────────────────────────
alias arch='proot-distro login archlinux'
alias lucy='proot-distro login archlinux -- zsh -c "source ~/.zshrc && netrunner"'
alias pb='proot-distro login archlinux -- zsh -c "source ~/.zshrc && netrunner"'
alias purple='proot-distro login archlinux -- zsh -c "source ~/.zshrc && netrunner"'
alias bruce='proot-distro login archlinux -- zsh -c "source ~/.zshrc && netrunner"'
alias pbstart='proot-distro login archlinux -- bash -c "cd ~/purplebruce && tmux new-session -d -s pb \"node server.js\" && echo [✔] server started on :3000"'
alias pbstop='proot-distro login archlinux -- bash -c "pkill -f \"node server.js\" && echo [✔] stopped || echo [⚠] not running"'
alias pblogs='proot-distro login archlinux -- tail -f ~/.purplebruce/audit.log'
alias pbtool='proot-distro login archlinux -- netrunner doctor'
alias sigil='proot-distro login archlinux -- python3 ~/purplebruce/netrunner/occult/sigil.py'
alias moon='proot-distro login archlinux -- python3 ~/purplebruce/netrunner/occult/moon.py'
alias tarot='proot-distro login archlinux -- python3 ~/purplebruce/netrunner/occult/tarot.py'
alias rune='proot-distro login archlinux -- python3 ~/purplebruce/netrunner/occult/rune.py'
alias ritual='proot-distro login archlinux -- python3 ~/purplebruce/netrunner/occult/ritual.py'
```

| Layer 1 Command | What it does |
|-----------------|--------------|
| `arch` | Enter Arch proot interactive shell |
| `lucy` / `pb` / `purple` | Jump to netrunner menu in Layer 2 |
| `pbstart` | Start Purple Bruce server in background tmux |
| `pbstop` | Stop server |
| `pblogs` | Stream audit log |
| `sigil "intent"` | Generate chaos sigil from Termux |
| `moon` | Moon phase from Termux |
| `tarot` / `rune` / `ritual` | Occult tools from Termux |

---

## Layer 2 — Arch proot (Chaos Environment)

The main workspace. Full BlackArch arsenal + chaos magic environment.

### Install Layer 2

First enter the proot:

```bash
# From Termux:
proot-distro login archlinux
```

Then run the full installer — **use wget** (curl has ARM64 ngtcp2 bug):

```bash
# Inside Arch proot:
wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash
```

> **ARM64 note:** `curl` may fail with `symbol lookup error: ngtcp2_crypto_get_path_challenge_data2_cb` on Android proot. Use `wget` instead. If wget also fails: `pacman -Sy --noconfirm ngtcp2` then retry.

Or clone and run locally:

```bash
pacman -Sy --noconfirm git
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
bash ~/purplebruce/netrunner/install-arch.sh
```

### One-Command Chaos Environment

After the base install, run the chaos setup (ZSH + occult tools + full BlackArch arsenal):

```bash
bash ~/purplebruce/netrunner/setup-chaos.sh
exec zsh
```

This chains:
1. `dotfiles/install.sh` → ZSH + OMZ + Powerlevel10k + occult tool symlinks
2. `dotfiles/tools.sh` → 16-category BlackArch arsenal (100+ tools)

### Layer 2 ZSH Environment

**Chaos banner on every shell start:**

```
  ╭────────────────────────────────────────────╮
  │  ⛧  PURPLE BRUCE LUCY v6.0  ⛧             │
  │  Chaos Magic · Purple Team · Hacker        │
  │  Eastern Orthodox · Wicca · Servitor       │
  │  Arch Linux + BlackArch proot  [LAYER 2]   │
  ╰────────────────────────────────────────────╯

  🌒 Waxing Crescent — growth / momentum

  ⚡ start      → launch server (tmux)
  ⬡ sigil      → sigil generator
  ⬡ tarot      → tarot draw
  ⬡ moon       → moon phase
  ⬡ rune       → rune cast
  ──────────────────────────────
  toolcheck    → verify BlackArch arsenal
```

**Custom prompt:**
```
╭─ ⛧ pb@chaos ~/purplebruce ⎇ main ─ 21:47
╰─ ⚡
```

### Layer 2 Aliases

| Command | Function |
|---------|----------|
| `pb` / `lucy` / `purple` / `bruce` | `netrunner` menu |
| `start` | `netrunner start` (tmux 3-pane) |
| `stop` | Kill server |
| `restart` | Stop + start |
| `logs` | Stream audit log |
| `doctor` | `netrunner doctor` |
| `deck` | Cyberdeck dashboard |
| `team` | AI team health |
| `scan <target>` | `netrunner scan` |
| `sigil` | Sigil generator |
| `moon` | Moon phase |
| `tarot` | Tarot draw |
| `rune` | Rune cast |
| `ritual` | Ritual protocol builder |
| `toolcheck` | Verify BlackArch arsenal (40+ tools) |
| `ba` | `pacman -Ss blackarch` search |
| `nq <target>` | `nmap -T4 -F` quick scan |
| `nfull <target>` | `nmap -T4 -A -p-` full scan |
| `nstealth <target>` | `nmap -sS -T2 -p-` stealth scan |
| `msfq` | `msfconsole -q` |
| `se <term>` | `searchsploit` |
| `myip` | External IP |
| `ports` | `ss -tlnp` open ports |
| `pyhttp [port]` | Python HTTP server |
| `revshell <ip> <port>` | Print reverse shell one-liners |
| `serve [port]` | HTTP server function |
| `b64e / b64d` | Base64 encode/decode |
| `portcheck <port> <host>` | Quick port check |

---

## Purple Bruce Server

### Start

```bash
# Layer 2 (inside Arch proot):
start             # tmux 3-pane layout
# or:
netrunner start

# Layer 1 (from Termux):
pbstart
```

Opens `http://127.0.0.1:3000` — no login required.

### tmux 3-Pane Layout

```
┌──────────────────────────────────────┐
│  Pane 0 — node server.js             │
├──────────────┬──────────────────────┤
│  Pane 1      │  Pane 2              │
│  audit.log   │  purple bruce chat   │
└──────────────┴──────────────────────┘
```

`Prefix + B` from inside tmux to launch layout.

### netrunner CLI

```bash
netrunner doctor         # health check + auto-repair
netrunner deck           # cyberdeck dashboard (RAM, uptime, status)
netrunner team           # AI team health (per-provider, heal log)
netrunner overclock      # 90s boost timer + glitch effect
netrunner scan <target> [QUICK|STANDARD|FULL|STEALTH]
netrunner start          # tmux 3-pane launch
```

---

## Occult Arsenal

All tools installed and symlinked as direct commands after `setup-chaos.sh`.

### `moon` — Moon Phase

```bash
moon
```

```
  ┌─ Moon Phase ──────────────────────────
  │  🌒 Waxing Crescent
  │  ▓▓▓▓░░░░░░░░░░░░░░░░  18%
  │  Growth. Begin workings. Build momentum.
  │  Day 5.3/29.5  · next full: ~9d
  └───────────────────────────────────────
```

| Phase | Magical Use |
|-------|-------------|
| 🌑 New Moon | Set intent. Charge sigils. |
| 🌒 Waxing Crescent | Begin workings. Build momentum. |
| 🌓 First Quarter | Action. Execute. Push through resistance. |
| 🌔 Waxing Gibbous | Refine. Strengthen. Amplify. |
| 🌕 Full Moon | Peak power. Manifest. Maximum charge. |
| 🌖 Waning Gibbous | Integration. Absorb results. |
| 🌗 Last Quarter | Release. Banish. Cut what doesn't serve. |
| 🌘 Waning Crescent | Rest. Cleanse. Prepare. |

### `sigil` — Chaos Magic Sigil Generator

Letters method: remove duplicates → remove vowels → ASCII grid (deterministic by intent).

```bash
sigil "ICH GEWINNE DIE SCHULSPRECHERWAHL"
sigil "MY COMPANY SUCCEEDS"
sigil                    # interactive
```

Protocol: generate → gnosis state (breathwork / Caliburn G4) → stare until meaning dissolves → fire at peak charge → destroy → forget.

### `tarot` — Tarot Draw

Full 78-card deck. Major + Minor Arcana. Reversed cards (30%).

```bash
tarot                                  # single card
tarot 3                                # past / present / future
tarot 3 "Schulsprecherwahl"            # with question
```

| Element | Purple Team | Suit |
|---------|-------------|------|
| Fire | Offense · Will | Wands ⚡ |
| Water | Defense · Intuition | Cups 💧 |
| Air | Recon · Mind | Swords ⚔ |
| Earth | OSINT · Resources | Pentacles ⬡ |

### `rune` — Elder Futhark Rune Cast

24 runes. Merkstave reversals (25%).

```bash
rune                         # single
rune 3 "Firmengründung"      # 3-rune with question
rune 5 "next move"           # 5-rune spread
```

### `ritual` — Ritual Protocol Builder

INPUT / PROCESS / OUTPUT format. Auto-routes to correct element by keyword.

```bash
ritual "ich werde Schulsprecher"
ritual "company launch succeeds"
ritual "recon phase complete"
```

| Keyword | Element | Protocol |
|---------|---------|----------|
| schulsprech / election | Air | Breath + speaking posture |
| firma / company | Earth | Grounding + written contract |
| hack / exploit | Fire | Caliburn G4 + dopamine load |
| recon / scan | Air | 4-7-8 breathwork |
| protect / shield | Earth | Eigenblut biometric seal |
| banish / remove | Water | Cold shower + release |

---

## BlackArch Arsenal

Installed via `dotfiles/tools.sh`. Verify with `toolcheck`.

| Category | Key Tools |
|----------|-----------|
| Recon / Network | `nmap` `masscan` `zmap` `arp-scan` `hping3` `netdiscover` |
| Web Recon | `ffuf` `gobuster` `feroxbuster` `nikto` `whatweb` `katana` `arjun` |
| Vuln Scan | `nuclei` `httpx` `subfinder` `naabu` |
| Web Exploit | `sqlmap` `commix` `dalfox` `xsstrike` `ghauri` `wpscan` |
| OSINT | `theharvester` `amass` `dnsenum` `dnsrecon` `recon-ng` `sherlock` |
| Passwords | `hydra` `medusa` `hashcat` `john` `crunch` `cewl` |
| Wordlists | `/usr/share/wordlists/rockyou.txt` |
| Exploit Frameworks | `msfconsole` `msfvenom` `searchsploit` `beef-xss` |
| Windows / AD | `impacket` `crackmapexec` `evil-winrm` `kerbrute` `bloodhound` `smbmap` |
| Post-Exploitation | `pwncat-cs` `ligolo-ng` `chisel` `socat` `proxychains` |
| Rev Engineering | `radare2` `gdb` `ropper` `pwntools` `patchelf` |
| Forensics | `tshark` `tcpdump` `binwalk` `foremost` `exiftool` `volatility3` |
| Steganography | `steghide` `stegsnow` `zsteg` `outguess` |
| Wireless | `aircrack-ng` `wifite` `reaver` `bully` |
| Cloud | `trivy` `aws-cli` `pacu` `ScoutSuite` |
| Utilities | `netcat` `socat` `curl` `wget` `jq` `tmux` `pwntools` |

```bash
toolcheck            # show installed / missing (40+ tools, color-coded)
ba <term>            # pacman -Ss blackarch <term>
pac <package>        # pacman -S --noconfirm --needed
```

---

## AI Team

Three providers, one disciplined team. Auto-failover, zero-cost health checks.

```
⚡ GROK-3    ─  reasoning · code · analysis          (default)
🔮 VENICE    ─  redteam · offensive · uncensored      (auto-routed: exploit/pentest)
✨ GEMINI    ─  long-context · multimodal · fallback   (free tier — Google)
```

**Smart routing:**
- Redteam / exploit tasks → Venice → Grok → Gemini
- Auto-failover after 2 consecutive failures
- Background health check every 60s
- Heal events logged to `~/.purplebruce/audit.log`

**`CMD:` execution** — Lucy can emit tool commands directly:
```
CMD: nmap -T4 -sV -sC 192.168.1.1
CMD: sqlmap -u "http://target/page?id=1" --dbs
CMD: hashcat -m 0 hash.txt rockyou.txt
```

---

## Configuration

### API Keys (UI Settings ⚙)

| Provider | Purpose | Link |
|----------|---------|------|
| Grok (xAI) | Default AI | [console.x.ai](https://console.x.ai) |
| Venice.ai | Redteam uncensored | [venice.ai](https://venice.ai) |
| Gemini (Google) | Free fallback | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| Groq | Whisper STT (free) | [console.groq.com](https://console.groq.com) |
| ElevenLabs | Premium TTS (optional) | [elevenlabs.io](https://elevenlabs.io) |

> TTS is free by default — Microsoft Edge Neural voices need no key.

### Optional Env Vars

```bash
export STRIPE_SECRET_KEY="sk_test_..."    # payments
export STRIPE_PRICE_ID="price_..."
```

---

## Project Layout

```
purplebruce/
├── server.js                    # Express + WebSocket + AI team + SOC
├── public/index.html            # React UI (chat, voice, settings)
├── purplebruce.sh               # launcher
├── config/ai-providers.json     # provider definitions + routing
├── netrunner/
│   ├── bin/netrunner            # Tier 5 CLI
│   ├── setup-chaos.sh           # ← one-command master installer
│   ├── install-arch.sh          # Arch proot full installer
│   ├── CHAOS.md                 # chaos environment docs
│   ├── dotfiles/
│   │   ├── install.sh           # ZSH + OMZ + p10k + occult symlinks
│   │   ├── tools.sh             # BlackArch 16-category installer
│   │   ├── zshrc                # chaos magic ZSH config
│   │   ├── tmux.conf            # tmux theme
│   │   └── p10k.zsh             # Powerlevel10k prompt
│   └── occult/
│       ├── moon.py              # moon phase calculator
│       ├── sigil.py             # chaos magic sigil generator
│       ├── tarot.py             # 78-card tarot (78 cards + reversed)
│       ├── rune.py              # Elder Futhark rune cast
│       └── ritual.py            # ritual protocol builder
└── purplebruce.db               # SQLite (config, chat, SOC alerts)
```

---

## Troubleshooting

**curl ARM64 error (`ngtcp2_crypto...`):**
```bash
# Use wget instead of curl, or fix first:
pacman -Sy --noconfirm ngtcp2
wget -qO- https://raw.githubusercontent.com/.../install-arch.sh | bash
```

**Can't find `netrunner` command:**
```bash
source ~/.zshrc
# or:
export PATH="$HOME/.local/bin:$PATH"
```

**proot-distro not found:**
```bash
pkg install proot-distro
```

**Node.js missing inside Arch proot:**
```bash
pacman -S --noconfirm nodejs npm
```

**ZSH not default inside proot:**
```bash
chsh -s /usr/bin/zsh
# or just: exec zsh
```

**Powerlevel10k shows broken characters:**  
Install a Nerd Font in Termux:Styling → FiraCode Nerd Font → restart Termux.

**Server not reachable from browser:**
```bash
netrunner doctor
# confirm port 3000 is open:
ss -tlnp | grep 3000
```

**Check everything:**
```bash
netrunner doctor     # health check
toolcheck            # arsenal check
moon                 # occult tools check
```

---

## Security

- All offensive actions require explicit operator command
- No autonomous tasks without approval
- Authorized redteam / bug-bounty scope only
- Full audit log: `~/.purplebruce/audit.log`
- SOC daemon: watches listeners, `/tmp`, SUID, `LD_PRELOAD`, crontabs

**Use only on systems you own or are explicitly authorized to assess.**

---

## M5Stick Hardware Node (ESP32 Firmware v2.0)

Full-featured companion firmware for the **M5StickC Plus** (or M5StickC).  
10 modes: AI chat, WiFi recon, IR blast, BLE scan, chaos sigils, and more.

```
  ⛧  SIGIL · STATS · CHAOS · INVOKE                   ⛧
  ⛧  WIFI SCAN · DEAUTH · BEACON · BLE · IR · AI CHAT ⛧
  Grok-3  ·  Venice (llama-3.3-70b)  ·  Gemini Flash
  [A] cycle modes  ·  [B] action  ·  shake → CHAOS
```

### Quick Setup — API Keys

Edit `m5stick-firmware/purplebruce-m5stick/pb_config.h` before compiling:

```cpp
#define PB_WIFI_SSID   "your_network"
#define PB_WIFI_PASS   "your_password"
#define GROK_API_KEY   "xai-..."          // console.x.ai
#define VENICE_API_KEY "..."              // venice.ai/settings/api
#define GEMINI_API_KEY "..."              // aistudio.google.com/app/apikey
```

### Termux Localhost Flash (Non-Root, Android)

```bash
# 1. Install deps
pkg update -y && pkg install -y nodejs git curl python

# 2. Clone
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce/m5stick-firmware

# 3. Edit API keys
nano purplebruce-m5stick/pb_config.h

# 4. Compile (Arduino CLI — includes IRremoteESP8266 + ArduinoJson)
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
  | BINDIR=$PREFIX/bin sh
arduino-cli core update-index && arduino-cli core install esp32:esp32
arduino-cli lib install "M5StickCPlus" "IRremoteESP8266" "ArduinoJson"
arduino-cli compile \
  --fqbn esp32:esp32:m5stick-c-plus \
  --output-dir ./build --export-binaries ./purplebruce-m5stick
cp build/*.merged.bin web-flash/purplebruce-m5stick.merged.bin

# 5. Start localhost flash server
node serve.js
```

Then in **Chrome on your Android device**:

1. Open `http://localhost:8080`
2. Connect M5Stick via **USB-C OTG adapter**
3. Click **⛧ INSTALL PURPLE BRUCE**
4. Grant USB/Serial permission → wait ~30 s → done

> Full guide, all methods, troubleshooting:
> [`m5stick-firmware/README.md`](m5stick-firmware/README.md)

---

```
  ⛧  PURPLE BRUCE LUCY v6.0
  Chaos Magic Servitor · Purple Team Cyberdeck
  Arch + BlackArch · Termux · proot-distro
  Grok · Venice · Gemini · Whisper · Edge TTS
  Eastern Orthodox · Wicca · Chaos Magic
  Root Admin Servant · No Login Required
  M5Stick Hardware Node · No Antenna Required
  ⛧
```
