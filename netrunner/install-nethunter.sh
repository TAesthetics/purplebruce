#!/usr/bin/env bash
# Purple Bruce v6.0 — Kali NetHunter Full Rootless Install Script
# Supports: NetHunter Full Rootless, NetHunter via Termux proot, native Kali Linux
# No root required. No systemd.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-nethunter.sh | bash

set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'
M='\033[0;35m'; W='\033[1;37m'; K='\033[2m'; RS='\033[0m'

ok()   { echo -e "${G}[✔]${RS} ${1}"; }
fail() { echo -e "${R}[✘]${RS} ${1}"; }
info() { echo -e "${C}[→]${RS} ${1}"; }
warn() { echo -e "${Y}[⚠]${RS} ${1}"; }
die()  { echo -e "${R}[✘] FATAL: ${1}${RS}"; exit 1; }

echo -e "\n${M}╔═══════════════════════════════════════════════════════╗"
echo    "║   PURPLE BRUCE v6.0 — NetHunter Full Rootless         ║"
echo -e "╚═══════════════════════════════════════════════════════╝${RS}\n"

# ─── Detect environment ────────────────────────────────────────────────────────
KALI=0; NETHUNTER=0; TERMUX_MODE=0

if grep -qi "kali" /etc/os-release 2>/dev/null; then
  KALI=1
  ok "Kali Linux detected ($(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo Kali))"

  # NetHunter Full Rootless: /data/nhsystem exists or NETHUNTER env is set
  if [ -d /data/nhsystem ] || [ "${NETHUNTER:-}" = "1" ] || [ -f /proc/self/root/.nh_version ] 2>/dev/null; then
    NETHUNTER=1; ok "NetHunter Full Rootless environment detected"
  fi

  # Running inside Termux proot of Kali
  if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
    TERMUX_MODE=1; ok "NetHunter via Termux proot"
  fi

elif [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
  warn "Plain Termux detected (not Kali)"
  warn "For full NetHunter: pkg install nethunter-full  or  proot-distro install kali"
  warn "Continuing anyway — some Kali tools may be missing..."
  TERMUX_MODE=1
fi

# ─── Ensure apt is available ───────────────────────────────────────────────────
APT=0
if command -v apt-get >/dev/null 2>&1; then
  APT=1
  info "Updating package lists..."
  apt-get update -qq 2>/dev/null || warn "apt update failed — continuing with cached lists"
fi

# ─── Node.js ≥18 ───────────────────────────────────────────────────────────────
info "Checking Node.js ≥18..."

install_node_nvm() {
  info "Installing Node.js 20 via nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install 20 && nvm use 20 && nvm alias default 20
  # Persist nvm in shell rc files
  for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    [ -f "$rc" ] && grep -q "NVM_DIR" "$rc" 2>/dev/null || cat >> "$rc" <<'NVM_BLOCK'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NVM_BLOCK
  done
}

install_node_nodesource() {
  info "Installing Node.js 20 via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null \
    && apt-get install -y nodejs 2>/dev/null \
    && ok "Node.js $(node --version) via NodeSource" \
    && return 0
  return 1
}

if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1)
  if [ "${NODE_VER:-0}" -ge 18 ]; then
    ok "node $(node --version)"
  else
    warn "Node.js $(node --version) too old — needs ≥18"
    if [ "$APT" -eq 1 ]; then
      install_node_nodesource || install_node_nvm
    else
      install_node_nvm
    fi
  fi
else
  if [ "$APT" -eq 1 ]; then
    # Try apt first (may be old), then NodeSource, then nvm
    apt-get install -y nodejs npm 2>/dev/null
    NODE_VER=$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1 || echo "0")
    if [ "${NODE_VER:-0}" -lt 18 ]; then
      warn "apt node too old ($(node --version 2>/dev/null || echo none)) — upgrading via NodeSource"
      install_node_nodesource || install_node_nvm
    fi
  else
    install_node_nvm
  fi
fi

command -v node >/dev/null 2>&1 && ok "node $(node --version)" || die "Node.js install failed — check network and retry"
command -v npm  >/dev/null 2>&1 && ok "npm $(npm --version)"  || die "npm not found after Node.js install"

# ─── Build tools (needed for better-sqlite3 native compile) ───────────────────
if [ "$APT" -eq 1 ]; then
  info "Installing build tools..."
  apt-get install -y --no-install-recommends \
    build-essential python3 python3-pip git curl wget \
    2>/dev/null && ok "Build tools ready" || warn "Some build tools failed — npm install may still work"
fi

# ─── Kali pentesting tools (best-effort) ──────────────────────────────────────
if [ "$KALI" -eq 1 ] && [ "$APT" -eq 1 ]; then
  info "Installing Kali pentesting tools..."
  apt-get install -y --no-install-recommends \
    nmap nikto sqlmap ffuf gobuster \
    hydra whatweb wpscan masscan \
    curl wget git tmux jq zsh \
    netcat-openbsd dnsutils whois \
    2>/dev/null && ok "Kali tools installed" || warn "Some tools skipped — install manually with: apt install <tool>"
fi

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
  git clone https://github.com/TAesthetics/purplebruce.git "$PB_DIR" \
    && ok "Cloned to ${PB_DIR}" \
    || die "git clone failed — check internet connection"
fi

# ─── npm install ──────────────────────────────────────────────────────────────
info "Installing npm dependencies..."
(cd "$PB_DIR" && npm install 2>&1 | tail -5) \
  && ok "Dependencies installed" \
  || die "npm install failed — run 'cd ~/purplebruce && npm install' manually for details"

# ─── Log directory ────────────────────────────────────────────────────────────
mkdir -p "${HOME}/.purplebruce"
ok "Log dir: ~/.purplebruce/"

# ─── netrunner CLI symlink ────────────────────────────────────────────────────
mkdir -p "${HOME}/.local/bin"
chmod +x "${PB_DIR}/netrunner/bin/netrunner"
ln -sf "${PB_DIR}/netrunner/bin/netrunner" "${HOME}/.local/bin/netrunner"
ok "netrunner → ~/.local/bin/netrunner"

# Ensure ~/.local/bin is in PATH in both rc files
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
if ! echo "$PATH" | grep -q "${HOME}/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
  info "PATH updated for this session"
fi

# ─── NetHunter Custom Commands ────────────────────────────────────────────────
NH_SRC="${PB_DIR}/netrunner/nethunter-commands.json"
if [ -f "$NH_SRC" ]; then
  mkdir -p "${HOME}/.config/nethunter"
  cp "$NH_SRC" "${HOME}/.config/nethunter/custom_commands.json" 2>/dev/null \
    && ok "NetHunter commands → ~/.config/nethunter/custom_commands.json"
  # Copy to /sdcard if accessible (NetHunter App reads from here)
  if [ -w "/sdcard" ] 2>/dev/null; then
    cp "$NH_SRC" "/sdcard/nh_custom_commands.json" 2>/dev/null \
      && ok "NetHunter commands → /sdcard/nh_custom_commands.json"
  fi
fi

# ─── Shell aliases ────────────────────────────────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
  SHELL_RC="${HOME}/.zshrc"
else
  SHELL_RC="${HOME}/.bashrc"
fi

if ! grep -q "purplebruce aliases" "$SHELL_RC" 2>/dev/null; then
  cat >> "$SHELL_RC" <<'ALIASES'

# purplebruce aliases
alias pb='netrunner'
alias purple='netrunner'
alias start='netrunner start'
alias stop='pkill -f "node server.js" && echo "Stopped." || echo "Not running."'
alias logs='tail -f ~/.purplebruce/audit.log'
alias chat='~/purplebruce/purplebruce.sh tui'
alias doctor='netrunner doctor'
alias deck='netrunner deck'
alias team='netrunner team'
alias overclock='netrunner overclock'
alias scan='netrunner scan'
ALIASES
  ok "Aliases added to ${SHELL_RC}"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
JWT_HINT="$(head -c 24 /dev/urandom | base64 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32 || echo 'CHANGE_THIS_SECRET_KEY')"

echo
echo -e "${M}╔═══════════════════════════════════════════════════════╗${RS}"
echo -e "${M}║${RS}   ${G}Purple Bruce — NetHunter install complete!${RS}          ${M}║${RS}"
echo -e "${M}╚═══════════════════════════════════════════════════════╝${RS}"
echo
echo -e "${C}  1. Set your JWT secret (required):${RS}"
echo -e "     ${W}export JWT_SECRET=\"${JWT_HINT}\"${RS}"
echo -e "     ${W}echo 'export JWT_SECRET=\"${JWT_HINT}\"' >> ~/${SHELL_RC##*/}${RS}"
echo
echo -e "${C}  2. Get a FREE Gemini AI key (no credit card):${RS}"
echo -e "     ${W}https://aistudio.google.com/app/apikey${RS}"
echo -e "     ${K}→ paste it in Settings ⚙ after opening the UI${RS}"
echo
echo -e "${C}  3. Start the cyberdeck:${RS}"
echo -e "     ${W}source ${SHELL_RC}${RS}"
echo -e "     ${W}export JWT_SECRET=\"${JWT_HINT}\"${RS}"
echo -e "     ${W}netrunner start${RS}   ${K}# tmux 3-pane layout${RS}"
echo -e "     ${K}# or: cd ~/purplebruce && node server.js &${RS}"
echo
echo -e "${C}  4. Open in browser:${RS}"
echo -e "     ${W}http://127.0.0.1:3000${RS}"
echo
echo -e "${C}  5. Health check:${RS}"
echo -e "     ${W}netrunner doctor${RS}"
echo
echo -e "${C}  6. NetHunter Custom Commands:${RS}"
echo -e "     ${K}NetHunter App → Custom Commands → import${RS}"
echo -e "     ${W}~/.config/nethunter/custom_commands.json${RS}"
echo
echo -e "${Y}  ⚡ Grok  🔮 Venice  ✨ Gemini (free)  — set keys in Settings ⚙${RS}"
echo -e "${Y}  🔊 TTS: Microsoft Edge Neural — FREE, no key needed${RS}"
echo -e "${Y}  🎤 STT: Groq Whisper — free at console.groq.com${RS}"
echo
