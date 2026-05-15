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

**Purple Bruce Lucy** is a hacker AI agent that runs on **your Android phone** using Termux.  
It gives you a full security lab — AI chat, hacking tools, voice control, drone support — no laptop needed, no root required, free.

---

## Quick Start — Which path is right for you?

| I want... | Use this |
|-----------|----------|
| Just the AI chat fast, no hacking tools | [Layer 0](#layer-0--just-the-ai-chat-termux-only) |
| Full hacking lab + AI agent + beautiful terminal | [Layer 2](#layer-2--full-setup-recommended) ← **recommended** |
| Control from Termux but tools in Arch | [Layer 1](#layer-1--termux-launcher-optional) |

**Not sure?** → Go to [Layer 2](#layer-2--full-setup-recommended). It does everything.

---

## Layer 0 — Just the AI Chat (Termux only)

This is the **fastest path**. You get the AI chat web interface but none of the hacking tools.  
Good if: you just want to test it, or your phone is low on storage.

### What you need
- Termux installed from [F-Droid](https://f-droid.org/packages/com.termux/) (NOT the Play Store version — that one is broken)
- Internet connection

### Step 1 — Install Termux packages

```bash
pkg update -y
pkg install -y nodejs npm git
```

> This takes 1–3 minutes. Say `Y` if it asks anything.

### Step 2 — Download Purple Bruce

```bash
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
```

### Step 3 — Install dependencies

```bash
cd ~/purplebruce
npm install
```

> If this fails with a Python error, run: `pkg install python make clang` then try again.  
> If it fails with "Node version too new", run: `pkg install nodejs-lts` then try again.

### Step 4 — Start the server

```bash
node server.js &
```

### Step 5 — Open in browser

Open your Android browser and go to: **http://127.0.0.1:3000**

You should see the Purple Bruce dashboard.

### Stop the server

```bash
pkill -f "node server.js"
```

---

## Layer 2 — Full Setup (Recommended)

This gives you everything: hacking tools, beautiful ZSH terminal, AI agent, voice control.  
It sets up a full **Arch Linux** environment inside Termux using `proot-distro`.

> Think of proot as a tiny virtual machine running inside Termux. You get full Linux without rooting your phone.

### What you need
- Termux from F-Droid (see above)
- ~3GB free storage
- 15–30 minutes the first time

---

### STEP 1 — Install Termux packages

Copy and paste this entire block:

```bash
pkg update -y && pkg install -y proot-distro git nodejs npm zsh tmux wget curl
```

---

### STEP 2 — Install Arch Linux inside Termux

```bash
proot-distro install archlinux
```

> This downloads ~500MB. Do it on WiFi.  
> If it pauses for a long time, just wait — it's downloading.

---

### STEP 3 — Enter the Arch Linux shell

```bash
proot-distro login archlinux
```

Your prompt changes to `root@localhost` — you are now inside Arch Linux.

---

### STEP 4 — Run the Purple Bruce installer

```bash
wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash
```

> This installs: Node.js, hacking tools, ZSH environment, everything.  
> It takes 10–20 minutes. Errors that say `[⚠]` are warnings — they are OK, keep going.  
> Only a `[✘] FATAL` line stops everything.

If `wget` fails with a crypto error, run this first then retry:
```bash
pacman -Sy --noconfirm ngtcp2
```

---

### STEP 5 — Start the shell

After the installer finishes:

```bash
exec zsh
```

You will see the Purple Bruce banner:
```
  ╭────────────────────────────────────────────╮
  │  ⚡  PURPLE BRUCE LUCY  v7.0              │
  │  Purple Team · AI Agent · BlackArch        │
  │  Arch Linux proot  [LAYER 2]               │
  ╰────────────────────────────────────────────╯
```

---

### STEP 6 — Start the server

```bash
pbstart
```

or just type:

```bash
go
```

Then open **http://127.0.0.1:3000** in your browser.

---

### Every time you come back

When you open Termux again, do this:

```bash
proot-distro login archlinux
# prompt changes to root@localhost
go
# server starts
```

That's it. Two commands.

---

## Layer 1 — Termux Launcher (Optional)

This makes it so you can type `lucy` or `pbstart` directly from Termux without entering the proot manually.

### Setup

After completing Layer 2 setup, the installer creates a script at `~/setup-termux-layer1.sh` **inside the proot**. Run it from Termux like this:

```bash
# Exit the proot first (type: exit)
# Then in Termux:
proot-distro login archlinux -- bash ~/setup-termux-layer1.sh
source ~/.zshrc
```

Now you can use these commands directly from Termux:

| Command | What it does |
|---------|--------------|
| `arch` | Enter Arch proot shell |
| `lucy` | Open netrunner menu |
| `pbstart` | Start server in background |
| `pbstop` | Stop server |
| `pblogs` | Watch server logs |

---

## Commands — Once You're Inside Layer 2

These all work after you run `exec zsh` inside the Arch proot:

### Server control

| Command | What it does |
|---------|--------------|
| `pbstart` or `go` | Start Purple Bruce server |
| `pbstop` or `stop` | Stop the server |
| `pbrestart` | Restart server |
| `logs` | Watch live server logs |
| `pbupdate` or `update` | Download latest version + redeploy |
| `doctor` | Auto-diagnose and fix problems |

### AI + hacking tools

| Command | What it does |
|---------|--------------|
| `scan <target>` | Port scan a target |
| `team` | Show AI provider health |
| `deck` | Cyberdeck dashboard |
| `tui` | Interactive TUI dashboard |
| `toolcheck` | Show which hacking tools are installed |
| `ba <keyword>` | Search BlackArch for a tool |
| `pac <toolname>` | Install a tool via pacman |

### Hacking shortcuts

| Command | What it does |
|---------|--------------|
| `nq <target>` | Quick nmap scan |
| `nfull <target>` | Full nmap scan (all ports) |
| `nstealth <target>` | Stealth scan (slow, quiet) |
| `msfq` | Open Metasploit (quiet mode) |
| `se <term>` | Search Exploit-DB |
| `myip` | Show your external IP |
| `ports` | Show open ports on this machine |
| `pyhttp [port]` | Start a quick HTTP server |
| `revshell <ip> <port>` | Print reverse shell one-liners |

### Terminal shortcuts

| Command | What it does |
|---------|--------------|
| `ll` | List files (detailed) |
| `..` | Go up one folder |
| `t` | Open tmux |
| `ta <name>` | Attach to tmux session |
| `gs` | Git status |
| `c` or `cls` | Clear screen |
| `b64e <text>` | Base64 encode |
| `b64d <text>` | Base64 decode |

---

## Add Your AI API Keys

The AI works without any keys (it has fallbacks) but for best results add at least one key.

1. Open **http://127.0.0.1:3000** in your browser
2. Click the **⚙ Settings** button
3. Add your API key(s)
4. Click Save

### Free options to get started

| Provider | Free? | Get Key At |
|----------|-------|------------|
| **Gemini** (Google) | ✅ Free tier | https://aistudio.google.com/app/apikey |
| **Groq** (voice/STT) | ✅ Free tier | https://console.groq.com |
| **Grok** (xAI) | Limited free | https://console.x.ai |
| **Venice** | Paid | https://venice.ai |
| **Claude** (Anthropic) | Paid | https://console.anthropic.com |
| **OpenRouter** | Pay per use | https://openrouter.ai |

---

## Install Hacking Tools

After Layer 2 is set up, tools are installed automatically. Check what's there:

```bash
toolcheck
```

Install more tools:

```bash
pac nmap masscan gobuster    # install specific tools
pac blackarch                # install ALL 2800+ BlackArch tools (~5GB)
ba web                       # search for web hacking tools
```

### What's included out of the box

| Category | Tools |
|----------|-------|
| Network Recon | `nmap` `masscan` `zmap` `arp-scan` `netcat` `traceroute` |
| Web | `ffuf` `gobuster` `feroxbuster` `nikto` `whatweb` `sqlmap` |
| OSINT | `theharvester` `amass` `dnsenum` `dnsrecon` |
| Passwords | `hydra` `medusa` `hashcat` `john` `crunch` |
| Exploits | `metasploit` `searchsploit` |
| Windows/AD | `impacket` `crackmapexec` `evil-winrm` `smbclient` |
| Pivot/Tunnel | `chisel` `socat` `proxychains` |
| Forensics | `wireshark-cli` `tshark` `binwalk` `tcpdump` |
| Wireless | `aircrack-ng` |
| Utilities | `tmux` `vim` `jq` `wget` `curl` `python` |

---

## Fix Common Errors

### "npm install fails — Python not found" or "no prebuilt binary"

```bash
# Inside Arch proot:
pacman -S --noconfirm python make gcc
cd ~/purplebruce && npm install
```

### "Cannot find module 'express'" when starting server

```bash
cd ~/purplebruce && npm install
```

### "pbupdate fails: not a git repository"

This is fixed in v7.0. Run `pbupdate` — it now downloads the latest version automatically even without git.

### "fatal: not a git repository" on pbupdate (old version)

```bash
cd ~/purplebruce
wget -qO /tmp/pb.tar.gz https://github.com/TAesthetics/purplebruce/archive/refs/heads/main.tar.gz
mv ~/purplebruce ~/purplebruce.bak
mkdir ~/purplebruce
tar -xzf /tmp/pb.tar.gz -C ~/purplebruce --strip-components=1
cd ~/purplebruce && npm install
bash netrunner/dotfiles/install.sh && exec zsh
```

### "wget fails — symbol lookup error" (ARM64 curl/ngtcp2 bug)

```bash
pacman -Sy --noconfirm ngtcp2
ldconfig
```

Then try your command again.

### "zsh: command not found: openclaw" or "oc"

OpenClaw was removed. It was listed as a feature but never worked. Use the web UI AI chat at http://127.0.0.1:3000 instead — it's better.

### "Oh-My-Zsh already installed" error

This is not an error, it's just telling you it's already there. Type `exec zsh` to reload.

### "The $ZSH folder already exists" when running setup again

```bash
# If you really want to reinstall Oh-My-Zsh:
rm -rf ~/.oh-my-zsh
# Then run the install again
```

Or just ignore it and type `exec zsh` — everything still works.

### Server won't start

```bash
doctor          # auto-fix attempt
pbstop          # make sure old instance is stopped
pbstart         # start fresh
```

### "not a git repository" on pbupdate inside proot

This happens if Purple Bruce was installed via the tarball method (not git clone).  
The v7.0 `pbupdate` fixes this automatically — it downloads the latest tarball instead.  
If you're on an old version, run this one-time fix:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh)
```

---

## Update Purple Bruce

```bash
pbupdate
```

This command:
1. Downloads the latest version from GitHub (via git or tarball — works either way)
2. Runs `npm install` to update dependencies
3. Redeploys all dotfiles (zshrc, aliases, netrunner)
4. Tells you to run `exec zsh` to reload

---

## The netrunner CLI

The `netrunner` command is Purple Bruce's CLI tool. Type `netrunner` to see the menu, or use subcommands:

```bash
netrunner doctor          # health check + auto-repair
netrunner deck            # show system info (RAM, uptime, tools)
netrunner team            # AI provider status
netrunner scan <target>   # run a scan
netrunner start           # start server in tmux 3-pane layout
netrunner tui             # open interactive TUI dashboard
```

---

## Voice Control

Purple Bruce supports voice input (speech-to-text) and voice responses (text-to-speech).

**Speech-to-text (STT):** Uses Groq Whisper — free tier available at https://console.groq.com  
**Text-to-speech (TTS):** Uses ElevenLabs (paid) or Microsoft Edge TTS (free, no key needed)

Enable in the web UI: Settings → Voice section.

---

## Drone Control (DJI Mini 4K)

Purple Bruce can control a DJI Mini 4K drone over WiFi.

```bash
# 1. Turn on your drone (hold power 3 seconds)
# 2. Connect your phone to the drone's WiFi (named DJI_MINI_XXXXXX)
# 3. Start the drone bridge:
drone-bridge

# 4. Open the drone panel:
# http://127.0.0.1:3000/drone
```

---

## Smart Glasses HUD

A minimal OLED-optimized display for smart glasses (Vuzix, Xreal, etc.):

```
http://127.0.0.1:3000/hud
```

---

## Architecture — How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 0  ·  Pure Termux                                        │
│  Android shell · Node.js only · Purple Bruce server             │
│  → Fastest setup. No hacking tools.                             │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1  ·  Termux (proot host)                                │
│  proot-distro launcher · wrapper aliases in Termux              │
│  → Run lucy/pbstart from Termux, work runs in Layer 2           │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2  ·  Arch Linux proot (recommended)                     │
│  ZSH + OMZ + Powerlevel10k · 100+ hacking tools                 │
│  Full AI agent + server + BlackArch repository                  │
│  → Everything lives here. This is the main workspace.           │
└─────────────────────────────────────────────────────────────────┘
```

The three layers run on a single Android phone — no cloud, no root, no laptop.

---

## File Structure

```
purplebruce/
├── server.js                        Main server (AI routing, WebSocket, SOC)
├── purplebruce.sh                   Launcher script (Layer 0 / plain Linux)
├── public/
│   ├── index.html                   Main web UI
│   ├── hud.html                     Smart glasses HUD
│   └── drone.html                   Drone control panel
├── netrunner/
│   ├── bin/netrunner                CLI tool
│   ├── tui.sh                       Bash TUI dashboard
│   ├── install-arch.sh              Full Arch + BlackArch installer
│   ├── dotfiles/
│   │   ├── zshrc                    ZSH config + all aliases
│   │   ├── install.sh               Deploys dotfiles
│   │   └── tmux.conf                Tmux config
│   ├── drone/mini4k.py              DJI Mini 4K bridge
│   └── firmware/flash-bruce.sh     M5StickC Plus2 flash script
└── purplebruce.db                   SQLite: config, chat history, alerts
```

---

## Security

- **Operator token** — generated at first boot, stored in `~/.purplebruce/operator.txt`. Required for sensitive actions (scans, exec, settings).
- **Binds to localhost** — the server only accepts connections from `127.0.0.1` by default.
- **Audit log** — every command is logged to `~/.purplebruce/audit.log`.
- **Rate limiting** — max 120 messages per minute.

---

## What Purple Bruce Lucy Can Do

| Feature | Status |
|---------|--------|
| AI Chat (multi-provider with failover) | ✅ |
| Voice input (Whisper STT) | ✅ |
| Voice output (ElevenLabs / Edge TTS) | ✅ |
| Port scanning (nmap integration) | ✅ |
| System hardening advisor | ✅ |
| Blue team threat hunting | ✅ |
| Red team preview + execute | ✅ |
| IT Support Hotline AI | ✅ |
| SOC alerts dashboard | ✅ |
| Drone control (DJI Mini 4K) | ✅ |
| Smart glasses HUD | ✅ |
| BlackArch 100+ hacking tools | ✅ Layer 2 |
| M5StickC Plus2 "Bruce" hardware | ✅ |
| Works offline (no internet needed after setup) | ✅ |
| Runs on a $50 Android phone | ✅ |
| No root required | ✅ |

---

## Support & Links

- GitHub: https://github.com/TAesthetics/purplebruce
- Issues: https://github.com/TAesthetics/purplebruce/issues
- Gemini free key (good starting point): https://aistudio.google.com/app/apikey
- Groq free key (voice): https://console.groq.com
