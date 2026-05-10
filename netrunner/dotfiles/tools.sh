#!/usr/bin/env bash
# Purple Bruce Lucy — BlackArch Hacking Tools Installer
# Run INSIDE Arch proot: bash ~/purplebruce/netrunner/dotfiles/tools.sh
# Organized by category — all best-effort, failures warn but don't abort.

set -uo pipefail

V='\033[38;5;135m'; C='\033[38;5;51m'; Y='\033[38;5;220m'
M='\033[38;5;201m'; G='\033[38;5;46m'; D='\033[38;5;240m'; RS='\033[0m'

ok()   { printf "  ${G}✔${RS}  %-28s ${D}installed${RS}\n" "$1"; }
skip() { printf "  ${Y}–${RS}  %-28s ${D}skipped${RS}\n"   "$1"; }
info() { echo -e "\n  ${V}━━ ${1} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RS}"; }
die()  { echo -e "  \033[31m✘${RS} $1"; exit 1; }

echo -e "\n${M}  ╔═══════════════════════════════════════════════════╗"
echo    "  ║  PURPLE BRUCE LUCY — BlackArch Arsenal v6.0       ║"
echo -e "  ╚═══════════════════════════════════════════════════╝${RS}"

command -v pacman >/dev/null 2>&1 || die "pacman not found — run inside Arch proot"

pac() {
  pacman -S --noconfirm --needed "$@" 2>/dev/null \
    && ok "$1" || skip "$1"
}

pip3() {
  command python3 -m pip install --quiet --break-system-packages "$@" 2>/dev/null \
    && ok "$1" || skip "$1"
}

go_install() {
  local name="$1"; local pkg="$2"
  command -v go >/dev/null 2>&1 || { skip "$name (go not installed)"; return; }
  go install "$pkg" 2>/dev/null \
    && ok "$name" || skip "$name"
}

# ─── Sync DB ─────────────────────────────────────────────────────
pacman -Sy --noconfirm 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
info "01 · RECON / NETWORK SCANNING"
# ═══════════════════════════════════════════════════════════════════
pac nmap
pac masscan
pac zmap
pac arp-scan
pac netdiscover
pac hping3
pac nbtscan
pac unicornscan
pac dnsx                  # fast DNS toolkit

# ═══════════════════════════════════════════════════════════════════
info "02 · WEB RECON & FUZZING"
# ═══════════════════════════════════════════════════════════════════
pac ffuf
pac gobuster
pac feroxbuster
pac wfuzz
pac nikto
pac whatweb
pac wafw00f
pac arjun                 # HTTP parameter discovery
pac gau                   # get all URLs (wayback + others)
pac hakrawler             # web crawler
pac katana                # next-gen web crawler (ProjectDiscovery)

# ═══════════════════════════════════════════════════════════════════
info "03 · VULNERABILITY SCANNING"
# ═══════════════════════════════════════════════════════════════════
pac nuclei                # template-based fast vulnscanner
pac naabu                 # port scanner (ProjectDiscovery)
pac httpx                 # HTTP toolkit (probing)
pac subfinder             # subdomain discovery

# ═══════════════════════════════════════════════════════════════════
info "04 · WEB EXPLOITATION"
# ═══════════════════════════════════════════════════════════════════
pac sqlmap
pac commix                # command injection
pac dalfox                # XSS scanner
pac xsstrike              # advanced XSS
pac ghauri                # advanced SQLi
pac wpscan                # WordPress scanner

# ═══════════════════════════════════════════════════════════════════
info "05 · OSINT"
# ═══════════════════════════════════════════════════════════════════
pac theharvester
pac amass
pac dnsenum
pac dnsrecon
pac recon-ng              # OSINT framework
pac maltego               # visual OSINT (best-effort)
pip3 sherlock-project     # username OSINT across 300+ sites

# ═══════════════════════════════════════════════════════════════════
info "06 · PASSWORD ATTACKS"
# ═══════════════════════════════════════════════════════════════════
pac hydra
pac medusa
pac hashcat
pac john
pac crunch
pac cewl
pac haiti                 # hash identifier
pac name-that-hash
pip3 hashid

# Wordlists
pac wordlists             # rockyou + common lists
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
  gunzip -f /usr/share/wordlists/rockyou.txt.gz 2>/dev/null && ok "rockyou.txt unpacked"
fi

# ═══════════════════════════════════════════════════════════════════
info "07 · EXPLOITATION FRAMEWORKS"
# ═══════════════════════════════════════════════════════════════════
pac metasploit
pac exploitdb             # searchsploit
pac beef-xss              # browser exploitation framework (best-effort)

# ═══════════════════════════════════════════════════════════════════
info "08 · WINDOWS / ACTIVE DIRECTORY"
# ═══════════════════════════════════════════════════════════════════
pac impacket
pac crackmapexec
pac evil-winrm
pac smbclient
pac smbmap
pac enum4linux
pac enum4linux-ng
pac kerbrute              # Kerberos brute-forcing
pac bloodhound            # AD attack paths
pac neo4j                 # bloodhound backend

# ═══════════════════════════════════════════════════════════════════
info "09 · POST-EXPLOITATION & C2"
# ═══════════════════════════════════════════════════════════════════
pac pwncat-cs             # interactive post-ex shell
pac ligolo-ng             # tunneling / pivoting
pac chisel                # TCP tunneling
pac socat
pac proxychains-ng
pip3 pwntools             # CTF + exploit development

# ═══════════════════════════════════════════════════════════════════
info "10 · REVERSE ENGINEERING & DEBUGGING"
# ═══════════════════════════════════════════════════════════════════
pac radare2
pac gdb
pac gdbserver
pac pwndbg                # gdb enhanced for pwn
pac ropper                # ROP gadget finder
pac patchelf
pac ltrace
pac strace
pip3 pwntools

# ═══════════════════════════════════════════════════════════════════
info "11 · FORENSICS & ANALYSIS"
# ═══════════════════════════════════════════════════════════════════
pac wireshark-cli
pac tshark
pac tcpdump
pac binwalk
pac foremost
pac testdisk
pac perl-image-exiftool   # exiftool
pac scalpel
pip3 volatility3          # memory forensics

# ═══════════════════════════════════════════════════════════════════
info "12 · STEGANOGRAPHY"
# ═══════════════════════════════════════════════════════════════════
pac steghide
pac stegsnow
pac zsteg                 # PNG/BMP stego
pac outguess

# ═══════════════════════════════════════════════════════════════════
info "13 · CRYPTOGRAPHY & ENCODING"
# ═══════════════════════════════════════════════════════════════════
pac openssl
pac python-pycryptodome
pac gpg
pip3 pyOpenSSL
pip3 cryptography

# ═══════════════════════════════════════════════════════════════════
info "14 · WIRELESS"
# ═══════════════════════════════════════════════════════════════════
pac aircrack-ng
pac wifite
pac reaver
pac bully
pac cowpatty

# ═══════════════════════════════════════════════════════════════════
info "15 · UTILITIES & SHELLS"
# ═══════════════════════════════════════════════════════════════════
pac netcat
pac gnu-netcat
pac ncat                  # nmap's netcat
pac curl
pac wget
pac jq
pac tmux
pac vim
pac python-requests
pac python-beautifulsoup4
pac python-scapy
pip3 updog                # better python http server
pip3 uro                  # URL deduplication

# ═══════════════════════════════════════════════════════════════════
info "16 · CLOUD & CONTAINER (best-effort)"
# ═══════════════════════════════════════════════════════════════════
pac trivy                 # container/IaC scanner
pac aws-cli               # AWS CLI
pip3 pacu                 # AWS exploitation framework
pip3 ScoutSuite           # cloud security audit

# ═══════════════════════════════════════════════════════════════════
echo
echo -e "  ${M}╔══════════════════════════════════════════════════╗${RS}"
echo -e "  ${M}║${RS}  ${G}BlackArch Arsenal installation complete!${RS}      ${M}║${RS}"
echo -e "  ${M}╚══════════════════════════════════════════════════╝${RS}"
echo
echo -e "  ${V}Quick tool check:${RS}   ${Y}toolcheck${RS}"
echo -e "  ${V}Search BlackArch:${RS}   ${Y}pacman -Ss blackarch <tool>${RS}"
echo -e "  ${V}Full meta-pkg:${RS}      ${Y}pacman -S blackarch${RS}  ${D}(2800+ tools, ~5GB)${RS}"
echo -e "  ${V}Wordlists:${RS}          ${D}/usr/share/wordlists/${RS}"
echo -e "  ${V}NSE scripts:${RS}        ${D}/usr/share/nmap/scripts/${RS}"
echo -e "  ${V}Exploitdb:${RS}          ${D}searchsploit <term>${RS}"
echo
