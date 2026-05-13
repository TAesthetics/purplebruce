# PURPLE BRUCE LUCY v7.0

```
  ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗     ███████╗    ██████╗ ██████╗ ██╗   ██╗ ██████╗███████╗
  ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔════╝
  ██████╔╝██║   ██║██████╔╝██████╔╝██║     █████╗      ██████╔╝██████╔╝██║   ██║██║     █████╗
  ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║     ██╔══╝      ██╔══██╗██╔══██╗██║   ██║██║     ██╔══╝
  ██║     ╚██████╔╝██║  ██║██║     ███████╗███████╗    ██████╔╝██║  ██║╚██████╔╝╚██████╗███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝

  ⚡  PURPLE TEAM · AI AGENT · BLACKARCH  ·  v7.0  ⚡
```

**Elite Purple Team AI** · Hacker · AI Agent  
Self-healing AI team (Grok / Venice / Gemini / Claude / OpenRouter / OpenClaw) · Voice (Whisper + Edge Neural TTS) · Industrial Minimalism UI  
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
│  LAYER 2  ·  Arch Linux proot (BlackArch Environment)           │
│  ZSH + OMZ + Powerlevel10k · 100+ hack tools · BlackArch repo  │
│  Full Purple Bruce server · netrunner CLI · OpenClaw agent      │
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
alias pbstart='cd ~/purplebruce && node server.js &'
alias pbstop='pkill -f "node server.js" && echo "[✔] stopped"'
alias pb='cd ~/purplebruce'
alias logs='tail -f ~/.purplebruce/audit.log'
```

### Layer 0 limitations

- No hacking tools (no apt, no BlackArch)
- No ZSH environment
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
```

| Layer 1 Command | What it does |
|-----------------|--------------|
| `arch` | Enter Arch proot interactive shell |
| `lucy` / `pb` / `purple` | Jump to netrunner menu in Layer 2 |
| `pbstart` | Start Purple Bruce server in background tmux |
| `pbstop` | Stop server |
| `pblogs` | Stream audit log |
| `pbtool` | Run netrunner doctor |

---

## Layer 2 — Arch proot (BlackArch Environment)

The main workspace. Full BlackArch arsenal + AI agent environment.

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

### Deploy ZSH Environment

After the base install, run the dotfiles setup (ZSH + OMZ + Powerlevel10k + BlackArch tools):

```bash
bash ~/purplebruce/netrunner/dotfiles/install.sh
exec zsh
```

### Layer 2 ZSH Environment

**Banner on every shell start:**

```
  ╭────────────────────────────────────────────╮
  │  ⚡  PURPLE BRUCE LUCY  v7.0              │
  │  Purple Team · AI Agent · BlackArch        │
  │  Arch Linux proot  [LAYER 2]               │
  ╰────────────────────────────────────────────╯

  ⚡ pbstart    → launch server
  ⚡ go         → same (short)
  ⬡ oc         → openclaw CLI
  ⬡ ocstart    → start openclaw gateway
  ──────────────────────────────
  toolcheck    → verify BlackArch arsenal
  pbupdate     → update + redeploy
```

### Layer 2 Aliases

| Command | Function |
|---------|----------|
| `pb` / `lucy` / `purple` / `bruce` | `netrunner` menu |
| `pbstart` / `go` | Launch server (tmux) |
| `pbstop` / `stop` | Kill server |
| `pbrestart` | Stop + start |
| `logs` | Stream audit log |
| `pbupdate` / `update` | `git pull` + `npm install` + redeploy dotfiles |
| `doctor` | `netrunner doctor` |
| `deck` | Cyberdeck dashboard |
| `team` | AI team health |
| `scan <target>` | `netrunner scan` |
| `oc` | OpenClaw CLI |
| `ocstart` | Start OpenClaw gateway |
| `ocstop` | Stop OpenClaw |
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
pbstart           # tmux 3-pane layout
# or:
go
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

## AI Providers

Purple Bruce supports multiple AI providers. Configure via the Settings modal in the web UI.

| Provider | Type | Notes |
|----------|------|-------|
| **Grok** (xAI) | Cloud | `xai_api_key` |
| **Venice** | Cloud | `venice_api_key` — privacy-first |
| **Gemini** (Google) | Cloud | `gemini_api_key` |
| **Claude** (Anthropic) | Cloud | `claude_api_key` — used for reasoning |
| **OpenRouter** | Cloud | `openrouter_api_key` — access 100+ models |
| **OpenClaw** | Local | No API key — runs at `127.0.0.1:18789` |

### OpenClaw (Local Agent)

```bash
# Install
npm install -g openclaw@latest

# Start gateway
openclaw onboard --install-daemon

# Enable in Purple Bruce settings
# → Settings → OpenClaw → toggle ON
```

OpenClaw runs locally — no data leaves your device.

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

## Update

```bash
# Inside Arch proot (Layer 2):
pbupdate        # git pull + npm install + redeploy dotfiles
# or:
update
```

This safely pulls the latest code without overwriting local changes.

---

## Troubleshooting

**Server won't start:**
```bash
doctor          # auto-repair
pbstop && pbstart   # restart
```

**ZSH config broken:**
```bash
pbupdate        # redeploy from repo
exec zsh
```

**Missing tools:**
```bash
toolcheck       # see what's installed/missing
pac <toolname>  # install via pacman
ba <category>   # search blackarch
```

**OpenClaw not connecting:**
```bash
ocstart         # start the openclaw daemon
oc status       # check status
```
