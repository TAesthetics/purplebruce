#!/usr/bin/env bash
# Purple Bruce Lucy v6.0 — Arch Linux + BlackArch proot Install Script
# LAYER 2: Runs INSIDE the Arch proot (proot-distro login archlinux)
#
# IMPORTANT: curl is broken on ARM64 proot (ngtcp2 symbol error).
# Use WGET to download this script:
#
#   proot-distro login archlinux -- bash -c \
#     "wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash"
#
# If wget also fails, fix ngtcp2 first (pacman uses its own downloader):
#   proot-distro login archlinux
#   pacman -Sy --noconfirm ngtcp2
#   wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash

set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'
M='\033[0;35m'; W='\033[1;37m'; K='\033[2m'; RS='\033[0m'

ok()   { echo -e "${G}[✔]${RS} ${1}"; }
fail() { echo -e "${R}[✘]${RS} ${1}"; }
info() { echo -e "${C}[→]${RS} ${1}"; }
warn() { echo -e "${Y}[⚠]${RS} ${1}"; }
die()  { echo -e "${R}[✘] FATAL: ${1}${RS}"; exit 1; }

echo -e "\n${M}╔══════════════════════════════════════════════════════════╗"
echo    "║  PURPLE BRUCE LUCY v7.0 — Arch + BlackArch proot LAYER 2 ║"
echo -e "╚══════════════════════════════════════════════════════════╝${RS}\n"

# ─── Detect environment ────────────────────────────────────────────────────────
ARCH=0; BLACKARCH=0

if grep -qi "arch" /etc/os-release 2>/dev/null || [ -f /etc/arch-release ]; then
  ARCH=1
  ok "Arch Linux detected"
  if grep -qi "blackarch" /etc/pacman.conf 2>/dev/null; then
    BLACKARCH=1; ok "BlackArch repos already configured"
  fi
else
  warn "Not Arch Linux — run this inside: proot-distro login archlinux"
  warn "Continuing anyway..."
fi

command -v pacman >/dev/null 2>&1 || die "pacman not found — run: proot-distro login archlinux"

# ─── System update ─────────────────────────────────────────────────────────────
info "Updating package database..."
pacman -Sy --noconfirm 2>/dev/null && ok "Package database updated" || warn "pacman -Sy failed — continuing"

# ─── Fix ngtcp2/curl symbol error (ARM64 proot) ───────────────────────────────
# Arch rolls fast; ngtcp2 mismatch breaks curl + git on Android proot
info "Fixing ngtcp2/curl compatibility..."
pacman -S --noconfirm --needed ngtcp2 2>/dev/null && ok "ngtcp2 patched" || warn "ngtcp2 skipped"

# ─── Base packages ─────────────────────────────────────────────────────────────
info "Installing base packages..."
pacman -S --noconfirm --needed \
  git wget curl tmux jq zsh vim \
  base-devel python python-pip python-setuptools \
  openssl ca-certificates \
  2>/dev/null && ok "Base packages installed" || warn "Some base packages failed"

# Refresh dynamic linker cache — critical after nettle/openssl upgrades in proot.
# Nettle 4.0 changed SONAME (.so.6 → .so.7); without ldconfig, wget/curl/git
# fail with "cannot open shared object file: libhogweed.so.6".
info "Refreshing library cache (ldconfig)..."
ldconfig 2>/dev/null && ok "ldconfig done" || warn "ldconfig failed — may affect wget/git"

# ─── Node.js ──────────────────────────────────────────────────────────────────
info "Installing Node.js..."
pacman -S --noconfirm --needed nodejs npm 2>/dev/null || true

if node --version >/dev/null 2>&1 && npm --version >/dev/null 2>&1; then
  ok "node $(node --version)  npm $(npm --version)"
else
  warn "System Node.js incompatible with proot GLIBC — falling back to nvm (Node 20 LTS)..."
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash 2>/dev/null \
    || { warn "wget nvm failed — trying curl..."; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; }
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install 20 && nvm use 20 && nvm alias default 20
  for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    [ -f "$rc" ] || continue
    grep -q "NVM_DIR" "$rc" 2>/dev/null || cat >> "$rc" <<'NVM_BLOCK'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NVM_BLOCK
  done
  node --version >/dev/null 2>&1 && ok "node $(node --version) via nvm" || die "Node.js install failed"
  npm --version  >/dev/null 2>&1 && ok "npm $(npm --version)"  || die "npm not found"
fi

# ─── BlackArch repos ──────────────────────────────────────────────────────────
if [ "$BLACKARCH" -eq 0 ]; then
  info "Adding BlackArch repository..."
  wget -qO /tmp/strap.sh https://blackarch.org/strap.sh 2>/dev/null \
    || curl -fsSL https://blackarch.org/strap.sh -o /tmp/strap.sh 2>/dev/null \
    || { warn "Cannot download BlackArch strap — skipping"; BLACKARCH=0; }
  if [ -f /tmp/strap.sh ]; then
    chmod +x /tmp/strap.sh
    /tmp/strap.sh 2>&1 | tail -5 \
      && ok "BlackArch repository added" \
      || warn "BlackArch strap failed — run manually: curl -fsSL https://blackarch.org/strap.sh | bash"
    rm -f /tmp/strap.sh
    pacman -Sy --noconfirm 2>/dev/null || true
    BLACKARCH=1
  fi
fi

# ─── LAYER 2: BlackArch Toolchain — AI Arsenal ────────────────────────────────
# Grouped so the AI (Purple Bruce Lucy) can invoke them via CMD: lines.
# Best-effort: missing tools warn but don't abort.

_install() {
  local label="$1"; shift
  info "Installing: ${label}..."
  pacman -S --noconfirm --needed "$@" 2>/dev/null \
    && ok "${label} installed" \
    || warn "${label} — some packages skipped (install manually: pacman -S <pkg>)"
}

# Network recon
_install "Network Recon" \
  nmap masscan zmap \
  netcat gnu-netcat \
  traceroute whois bind dnsutils \
  arp-scan

# Web recon + fuzzing
_install "Web Recon & Fuzzing" \
  ffuf gobuster feroxbuster \
  nikto whatweb wafw00f \
  wfuzz

# OSINT
_install "OSINT" \
  theharvester amass \
  dnsenum dnsrecon

# SQL + web exploitation
_install "Web Exploitation" \
  sqlmap

# Password attacks
_install "Password & Brute Force" \
  hydra medusa \
  hashcat john \
  crunch cewl

# Exploitation frameworks
_install "Exploitation" \
  metasploit exploitdb

# Windows / AD attacks
_install "Windows / AD" \
  impacket crackmapexec \
  evil-winrm \
  smbclient

# Post-exploitation / pivoting
_install "Post-Exploitation" \
  chisel socat \
  proxychains-ng

# Wireless
_install "Wireless" \
  aircrack-ng

# Forensics + analysis
_install "Forensics & Analysis" \
  wireshark-cli tshark \
  binwalk \
  tcpdump \
  strace ltrace

# Misc utils the AI uses
_install "Misc Tools" \
  wget curl git jq vim tmux \
  python-requests python-beautifulsoup4 \
  python-scapy

# Optional: WPScan (Ruby-based, often fails in proot — best-effort)
info "Installing WPScan (best-effort)..."
pacman -S --noconfirm --needed wpscan 2>/dev/null || warn "WPScan skipped — install ruby + gem install wpscan if needed"

# ─── Purple Bruce clone / update ──────────────────────────────────────────────
PB_DIR="${HOME}/purplebruce"

if [ -d "${PB_DIR}/.git" ]; then
  info "Updating existing install at ${PB_DIR}..."
  (cd "$PB_DIR" && git pull origin main 2>&1 | tail -3) \
    && ok "Purple Bruce updated" \
    || warn "git pull failed — continuing with existing files"
else
  if [ -d "$PB_DIR" ]; then
    warn "${PB_DIR} exists but is not a git repo — moving to ${PB_DIR}.bak"
    mv "$PB_DIR" "${PB_DIR}.bak"
  fi
  info "Cloning Purple Bruce..."
  PB_URL="https://github.com/TAesthetics/purplebruce/archive/refs/heads/main.tar.gz"

  _extract_tarball() {
    mkdir -p "$PB_DIR"
    tar -xzf /tmp/pb.tar.gz -C "$PB_DIR" --strip-components=1
    rm -f /tmp/pb.tar.gz
  }

  if git clone https://github.com/TAesthetics/purplebruce.git "$PB_DIR" 2>/dev/null; then
    ok "Cloned via git to ${PB_DIR}"
  elif wget -qO /tmp/pb.tar.gz "$PB_URL" 2>/dev/null && _extract_tarball; then
    ok "Downloaded via wget tarball to ${PB_DIR}"
  elif python3 -c "
import urllib.request, sys
print('[→] Downloading via Python urllib...')
urllib.request.urlretrieve('$PB_URL', '/tmp/pb.tar.gz')
" 2>/dev/null && _extract_tarball; then
    ok "Downloaded via python3 urllib to ${PB_DIR}"
  else
    die "All download methods failed (git / wget / python3 urllib) — check internet connection"
  fi
fi

# ─── npm install ──────────────────────────────────────────────────────────────
info "Installing npm dependencies..."
(cd "$PB_DIR" && npm install 2>&1 | tail -5) \
  && ok "npm dependencies installed" \
  || warn "npm install failed — run: cd ~/purplebruce && npm install"

# ─── Deploy full dotfiles (zshrc + aliases) ────────────────────────────────────
info "Deploying Purple Bruce dotfiles..."
bash "${PB_DIR}/netrunner/dotfiles/install.sh" \
  && ok "Dotfiles deployed (zshrc, aliases, netrunner symlink)" \
  || warn "Dotfiles deploy failed — run: bash ~/purplebruce/netrunner/dotfiles/install.sh"

# ─── Log + quarantine dirs ────────────────────────────────────────────────────
mkdir -p "${HOME}/.purplebruce/quarantine" "${HOME}/.purplebruce/forensics"
ok "Data dirs: ~/.purplebruce/"

# ─── netrunner CLI — Layer 2 symlink ──────────────────────────────────────────
mkdir -p "${HOME}/.local/bin"
chmod +x "${PB_DIR}/netrunner/bin/netrunner"
ln -sf "${PB_DIR}/netrunner/bin/netrunner" "${HOME}/.local/bin/netrunner"
ok "netrunner → ~/.local/bin/netrunner"

# ─── Shell RC detection ───────────────────────────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
  SHELL_RC="${HOME}/.zshrc"
  # Create .zshrc if missing
  [ -f "$SHELL_RC" ] || touch "$SHELL_RC"
else
  SHELL_RC="${HOME}/.bashrc"
fi

# ─── PATH ─────────────────────────────────────────────────────────────────────
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null \
    || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
export PATH="$HOME/.local/bin:$PATH"

# ─── LAYER 2 aliases: handled by dotfiles/install.sh (zshrc deployed above) ──
ok "Aliases deployed via dotfiles/zshrc"

# ─── LAYER 1 wrapper (Termux-side) ────────────────────────────────────────────
# Detect Termux home directory — write Layer 1 aliases there
TERMUX_HOME=""
for possible in "/data/data/com.termux/files/home" "/sdcard" "$HOME/../.."; do
  if [ -d "$possible" ] && [ -w "$possible" ]; then
    TERMUX_HOME="$possible"
    break
  fi
done

# Write the Layer 1 wrapper script to a shared location
L1_SCRIPT="${HOME}/setup-termux-layer1.sh"
cat > "$L1_SCRIPT" <<'LAYER1_SCRIPT'
#!/usr/bin/env bash
# Purple Bruce Lucy — Layer 1 (Termux) wrapper setup
# Run this FROM TERMUX (not inside proot):
#   bash ~/purplebruce/netrunner/setup-termux-layer1.sh
# Or: proot-distro login archlinux -- cat ~/setup-termux-layer1.sh > /tmp/l1.sh && bash /tmp/l1.sh

RC="$HOME/.zshrc"
[ -f "$RC" ] || RC="$HOME/.bashrc"
[ -f "$RC" ] || touch "$RC"

if ! grep -q "purplebruce layer1" "$RC" 2>/dev/null; then
  cat >> "$RC" <<'L1EOF'

# ── Purple Bruce Lucy — Layer 1 aliases (Termux) ──
# These jump into Arch proot and execute commands there.

_pb_proot() { proot-distro login archlinux -- bash -c "$*"; }
_pb_proot_i() { proot-distro login archlinux -- "$@"; }

alias lucy='proot-distro login archlinux -- netrunner'
alias pb='proot-distro login archlinux -- netrunner'
alias purple='proot-distro login archlinux -- netrunner'
alias bruce='proot-distro login archlinux -- netrunner'
alias doctor='proot-distro login archlinux -- netrunner doctor'
alias deck='proot-distro login archlinux -- netrunner deck'
alias team='proot-distro login archlinux -- netrunner team'
alias overclock='proot-distro login archlinux -- netrunner overclock'
alias scan='proot-distro login archlinux -- netrunner scan'

# Start server inside proot (background tmux session)
alias pbstart='proot-distro login archlinux -- bash -c "tmux new-session -d -s purplebruce \"cd ~/purplebruce && node server.js\" 2>/dev/null || cd ~/purplebruce && node server.js &" && echo "[✔] Purple Bruce Lucy starting on http://127.0.0.1:3000"'
alias pbstop='proot-distro login archlinux -- pkill -f "node server.js" && echo "[✔] Stopped." || echo "[⚠] Not running."'
alias pblogs='proot-distro login archlinux -- tail -f ~/.purplebruce/audit.log'

# Quick arch proot shell
alias arch='proot-distro login archlinux'
alias kali='proot-distro login kali 2>/dev/null || echo "Kali not installed: proot-distro install kali"'
L1EOF
  echo "[✔] Layer 1 aliases added to $RC"
  echo "[✔] Run: source $RC"
else
  echo "[⚠] Layer 1 aliases already in $RC"
fi
LAYER1_SCRIPT

chmod +x "$L1_SCRIPT"
ok "Layer 1 Termux wrapper → ~/setup-termux-layer1.sh"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo
echo -e "${M}╔══════════════════════════════════════════════════════════╗${RS}"
echo -e "${M}║${RS}  ${G}Purple Bruce Lucy — Arch + BlackArch install complete!${RS}  ${M}║${RS}"
echo -e "${M}╚══════════════════════════════════════════════════════════╝${RS}"
echo
echo -e "${M}━━━ LAYER 2 — Arch proot (you are here) ━━━${RS}"
echo -e "${C}  Start server:${RS}         ${W}netrunner start${RS}   ${K}# tmux 3-pane${RS}"
echo -e "${C}  Background start:${RS}     ${W}cd ~/purplebruce && node server.js &${RS}"
echo -e "${C}  Health check:${RS}         ${W}netrunner doctor${RS}"
echo -e "${C}  Cyberdeck status:${RS}     ${W}netrunner deck${RS}"
echo -e "${C}  AI team status:${RS}       ${W}netrunner team${RS}"
echo -e "${C}  Open in browser:${RS}      ${W}http://127.0.0.1:3000${RS}"
echo -e "${C}  Logs:${RS}                 ${W}logs${RS}   ${K}# alias: tail -f audit.log${RS}"
echo
echo -e "${M}━━━ LAYER 1 — Termux (outside proot) ━━━${RS}"
echo -e "${C}  Setup Layer 1 aliases:${RS}"
echo -e "  ${W}EXIT the proot first, then in Termux:${RS}"
echo -e "  ${W}proot-distro login archlinux -- bash ~/setup-termux-layer1.sh${RS}"
echo -e "  ${K}  # or copy manually: bash ~/setup-termux-layer1.sh${RS}"
echo -e "  Then: ${W}source ~/.zshrc${RS}  ${K}# or source ~/.bashrc${RS}"
echo -e "  Then use: ${W}lucy${RS} / ${W}pb${RS} / ${W}pbstart${RS} directly from Termux"
echo
echo -e "${M}━━━ API KEYS (Settings ⚙ in browser) ━━━${RS}"
echo -e "${C}  ⚡ Grok (xAI):${RS}      ${W}https://console.x.ai${RS}"
echo -e "${C}  🔮 Venice:${RS}          ${W}https://venice.ai${RS}"
echo -e "${C}  ✨ Gemini (FREE):${RS}   ${W}https://aistudio.google.com/app/apikey${RS}"
echo -e "${C}  🎙 Groq (Whisper):${RS}  ${W}https://console.groq.com${RS}  ${K}# free STT${RS}"
echo -e "${C}  🔊 ElevenLabs:${RS}      ${W}https://elevenlabs.io${RS}          ${K}# premium TTS${RS}"
echo
echo -e "${M}━━━ BLACKARCH ARSENAL ━━━${RS}"
echo -e "${C}  Tool check:${RS}       ${W}toolcheck${RS}   ${K}# alias: verify all tools${RS}"
echo -e "${C}  Full meta-pkg:${RS}    ${W}pacman -S blackarch${RS}   ${K}# 2800+ tools (~5GB)${RS}"
echo -e "${C}  Search tools:${RS}     ${W}ba <keyword>${RS}   ${K}# alias: pacman -Ss blackarch${RS}"
echo -e "${C}  Specific tool:${RS}    ${W}pacman -S <toolname>${RS}"
echo
echo -e "${Y}  Source your shell: source ${SHELL_RC##*/}${RS}"
echo
