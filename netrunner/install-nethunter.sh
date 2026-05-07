#!/usr/bin/env bash
# Purple Bruce — Kali NetHunter Full Rootless Install Script
# Supports: NetHunter Full Rootless, Kali on Termux proot, native Kali Linux
# No root required. No systemd.

set -uo pipefail
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'; RS='\033[0m'

ok()   { echo -e "${G}[✔]${RS} ${1}"; }
fail() { echo -e "${R}[✘]${RS} ${1}"; }
info() { echo -e "${C}[→]${RS} ${1}"; }
warn() { echo -e "${Y}[⚠]${RS} ${1}"; }
die()  { echo -e "${R}[✘] FATAL: ${1}${RS}"; exit 1; }

echo -e "\n${M}╔═══════════════════════════════════════════════════╗"
echo    "║  PURPLE BRUCE — NetHunter Full Rootless Install   ║"
echo -e "╚═══════════════════════════════════════════════════╝${RS}\n"

# ─── Detect environment ───────────────────────────────────────────────────────
KALI=0; NETHUNTER=0; TERMUX_MODE=0
if grep -qi "kali" /etc/os-release 2>/dev/null; then
  KALI=1
  ok "Kali Linux detected"
  if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
    TERMUX_MODE=1; ok "Running via Termux proot"
  fi
elif [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
  warn "Termux (non-Kali) detected — consider: proot-distro install kali && proot-distro login kali"
  warn "Continuing anyway..."
fi

# ─── Node.js ─────────────────────────────────────────────────────────────────
info "Checking Node.js ≥18..."
if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1)
  if [ "${NODE_VER:-0}" -ge 18 ]; then
    ok "node $(node --version)"
  else
    warn "Node.js $(node --version) too old — needs ≥18"
    info "Installing via nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install 20 && nvm use 20 && ok "node $(node --version) via nvm"
  fi
else
  info "Installing Node.js..."
  if [ "$KALI" -eq 1 ] || command -v apt >/dev/null 2>&1; then
    apt-get update -qq 2>/dev/null
    apt-get install -y nodejs npm 2>/dev/null || {
      info "apt failed — trying nvm..."
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
      export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
      nvm install 20 && nvm use 20
    }
  fi
  command -v node >/dev/null 2>&1 && ok "node $(node --version)" || die "Node.js install failed"
fi

# ─── Kali tools (optional, best-effort) ──────────────────────────────────────
if [ "$KALI" -eq 1 ] && command -v apt >/dev/null 2>&1; then
  info "Installing recommended Kali tools..."
  apt-get install -y --no-install-recommends \
    nmap nikto sqlmap ffuf gobuster \
    curl wget git tmux jq zsh \
    netcat-openbsd dnsutils whois \
    build-essential 2>/dev/null && ok "Kali tools installed" || warn "Some tools skipped — run manually if needed"
fi

# ─── Purple Bruce ─────────────────────────────────────────────────────────────
PB_DIR="${HOME}/purplebruce"
if [ -d "$PB_DIR" ]; then
  info "Updating existing install..."
  (cd "$PB_DIR" && git pull origin main 2>&1 | tail -3) && ok "Updated" || warn "git pull failed — check manually"
else
  info "Cloning Purple Bruce..."
  git clone https://github.com/TAesthetics/purplebruce.git "$PB_DIR" && ok "Cloned to ${PB_DIR}"
fi

info "Installing npm dependencies..."
(cd "$PB_DIR" && npm install 2>&1 | tail -4) && ok "Dependencies installed" || die "npm install failed"

# ─── Netrunner CLI ────────────────────────────────────────────────────────────
mkdir -p "${HOME}/.local/bin"
ln -sf "${PB_DIR}/netrunner/bin/netrunner" "${HOME}/.local/bin/netrunner" 2>/dev/null
chmod +x "${PB_DIR}/netrunner/bin/netrunner"

if ! echo "$PATH" | grep -q "${HOME}/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc" 2>/dev/null || true
  info "Added ~/.local/bin to PATH (restart shell or: export PATH=\$HOME/.local/bin:\$PATH)"
fi
ok "netrunner CLI installed"

# ─── Zsh / aliases ───────────────────────────────────────────────────────────
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

# ─── env hint ────────────────────────────────────────────────────────────────
echo
echo -e "${M}╔═══════════════════════════════════════════════════╗${RS}"
echo -e "${M}║${RS}  ${G}Purple Bruce — NetHunter install complete!${RS}         ${M}║${RS}"
echo -e "${M}╚═══════════════════════════════════════════════════╝${RS}"
echo
echo -e "${C}  1. Set your JWT secret (required):${RS}"
echo -e "     ${W}export JWT_SECRET=\"$(head -c 24 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)\"${RS}"
echo -e "${C}  2. Start the cyberdeck:${RS}"
echo -e "     ${W}cd ~/purplebruce && node server.js &${RS}"
echo -e "     ${W}# or: netrunner start   (tmux layout)${RS}"
echo -e "${C}  3. Open in browser:${RS}"
echo -e "     ${W}http://127.0.0.1:3000${RS}"
echo -e "${C}  4. Run health check:${RS}"
echo -e "     ${W}netrunner doctor${RS}"
echo
echo -e "${Y}  NetHunter tip: use 'source ~/.bashrc' or restart terminal first${RS}"
echo
