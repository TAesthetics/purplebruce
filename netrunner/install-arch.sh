#!/usr/bin/env bash
# Purple Bruce v6.0 — Arch Linux + BlackArch proot-distro Install Script
# Run this INSIDE the Arch proot: proot-distro login archlinux
# No root required. No systemd.
#
# Usage (from Termux):
#   proot-distro install archlinux
#   proot-distro login archlinux -- bash -c "curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash"
#
# Or manually:
#   proot-distro login archlinux
#   curl -fsSL .../install-arch.sh | bash

set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'
M='\033[0;35m'; W='\033[1;37m'; K='\033[2m'; RS='\033[0m'

ok()   { echo -e "${G}[✔]${RS} ${1}"; }
fail() { echo -e "${R}[✘]${RS} ${1}"; }
info() { echo -e "${C}[→]${RS} ${1}"; }
warn() { echo -e "${Y}[⚠]${RS} ${1}"; }
die()  { echo -e "${R}[✘] FATAL: ${1}${RS}"; exit 1; }

echo -e "\n${M}╔═══════════════════════════════════════════════════════╗"
echo    "║   PURPLE BRUCE v6.0 — Arch Linux + BlackArch proot   ║"
echo -e "╚═══════════════════════════════════════════════════════╝${RS}\n"

# ─── Detect environment ────────────────────────────────────────────────────────
ARCH=0; BLACKARCH=0

if grep -qi "arch" /etc/os-release 2>/dev/null || [ -f /etc/arch-release ]; then
  ARCH=1
  ok "Arch Linux detected"
  if grep -qi "blackarch" /etc/pacman.conf 2>/dev/null || pacman -Sg blackarch 2>/dev/null | head -1 | grep -q blackarch; then
    BLACKARCH=1; ok "BlackArch repos already configured"
  fi
else
  warn "Not Arch Linux — use install-nethunter.sh for Kali or install-arch.sh only inside Arch proot"
  warn "Continuing anyway..."
fi

command -v pacman >/dev/null 2>&1 || die "pacman not found — are you inside the Arch proot? Run: proot-distro login archlinux"

# ─── System update ────────────────────────────────────────────────────────────
info "Updating package database..."
pacman -Sy --noconfirm 2>/dev/null && ok "Package database updated" || warn "pacman -Sy failed — continuing"

# ─── Fix ngtcp2/curl symbol error (common in ARM64 proot) ─────────────────────
# Arch packages roll fast; ngtcp2 mismatch breaks curl + git on Android proot
info "Fixing ngtcp2/curl compatibility (ARM64 proot fix)..."
pacman -S --noconfirm --needed ngtcp2 2>/dev/null && ok "ngtcp2 updated" || warn "ngtcp2 update skipped"

# ─── Base packages ────────────────────────────────────────────────────────────
info "Installing base packages..."
pacman -S --noconfirm --needed \
  git wget curl tmux jq zsh \
  base-devel python python-pip \
  2>/dev/null && ok "Base packages installed" || warn "Some base packages failed"

# ─── Node.js: pacman installs latest (may need GLIBC 2.43+), use nvm fallback ─
info "Installing Node.js..."
pacman -S --noconfirm --needed nodejs npm 2>/dev/null || true

# Test if pacman nodejs actually works (Arch rolls fast, may need newer GLIBC)
if node --version >/dev/null 2>&1 && npm --version >/dev/null 2>&1; then
  ok "node $(node --version)  npm $(npm --version)"
else
  warn "System Node.js incompatible with proot GLIBC — falling back to nvm (Node 20 LTS)..."
  # Use wget (doesn't depend on libcurl) to install nvm
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash 2>/dev/null \
    || { warn "wget nvm failed — trying curl..."; curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; }
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install 20 && nvm use 20 && nvm alias default 20
  # Persist nvm in shell rc files
  for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    [ -f "$rc" ] || continue
    grep -q "NVM_DIR" "$rc" 2>/dev/null || cat >> "$rc" <<'NVM_BLOCK'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NVM_BLOCK
  done
  node --version >/dev/null 2>&1 && ok "node $(node --version) via nvm" || die "Node.js install failed"
  npm --version  >/dev/null 2>&1 && ok "npm $(npm --version)" || die "npm not found"
fi

# ─── BlackArch repos ──────────────────────────────────────────────────────────
if [ "$BLACKARCH" -eq 0 ]; then
  info "Adding BlackArch repository..."
  # Use wget fallback in case curl still has issues
  wget -qO /tmp/strap.sh https://blackarch.org/strap.sh 2>/dev/null \
    || curl -fsSL https://blackarch.org/strap.sh -o /tmp/strap.sh 2>/dev/null \
    || { warn "Cannot download BlackArch strap — skipping"; BLACKARCH=0; }
  if [ -f /tmp/strap.sh ]; then
    chmod +x /tmp/strap.sh
    /tmp/strap.sh 2>&1 | tail -5 \
      && ok "BlackArch repository added" \
      || warn "BlackArch strap failed — run manually after install"
    rm -f /tmp/strap.sh
    pacman -Sy --noconfirm 2>/dev/null || true
    BLACKARCH=1
  fi
fi

# ─── Pentesting tools (best-effort) ───────────────────────────────────────────
info "Installing pentesting tools (this may take a while)..."
pacman -S --noconfirm --needed \
  nmap nikto sqlmap ffuf gobuster \
  hydra whatweb masscan \
  netcat gnu-netcat dnsutils whois \
  2>/dev/null && ok "Pentesting tools installed" || warn "Some tools skipped — install manually: pacman -S <tool>"

# Optional BlackArch extras (best-effort, don't fail)
info "Installing BlackArch extras (best-effort)..."
pacman -S --noconfirm --needed \
  wpscan impacket crackmapexec \
  2>/dev/null || warn "Some BlackArch extras skipped"

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
  git clone https://github.com/TAesthetics/purplebruce.git "$PB_DIR" 2>/dev/null \
    && ok "Cloned to ${PB_DIR}" \
    || {
      # curl/git may still have ngtcp2 issues — try wget tarball fallback
      warn "git clone failed — trying wget tarball fallback..."
      wget -qO /tmp/pb.tar.gz https://github.com/TAesthetics/purplebruce/archive/refs/heads/main.tar.gz \
        && mkdir -p "$PB_DIR" \
        && tar -xzf /tmp/pb.tar.gz -C "$PB_DIR" --strip-components=1 \
        && rm -f /tmp/pb.tar.gz \
        && ok "Downloaded via tarball to ${PB_DIR}" \
        || die "Both git clone and wget tarball failed — check internet connection"
    }
fi

# ─── npm install ──────────────────────────────────────────────────────────────
info "Installing npm dependencies..."
(cd "$PB_DIR" && npm install 2>&1 | tail -5) \
  && ok "Dependencies installed" \
  || die "npm install failed — run 'cd ~/purplebruce && npm install' manually"

# ─── Log directory ────────────────────────────────────────────────────────────
mkdir -p "${HOME}/.purplebruce"
ok "Log dir: ~/.purplebruce/"

# ─── netrunner CLI symlink ────────────────────────────────────────────────────
mkdir -p "${HOME}/.local/bin"
chmod +x "${PB_DIR}/netrunner/bin/netrunner"
ln -sf "${PB_DIR}/netrunner/bin/netrunner" "${HOME}/.local/bin/netrunner"
ok "netrunner → ~/.local/bin/netrunner"

for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
export PATH="$HOME/.local/bin:$PATH"

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
echo -e "${M}║${RS}   ${G}Purple Bruce — Arch + BlackArch install complete!${RS}   ${M}║${RS}"
echo -e "${M}╚═══════════════════════════════════════════════════════╝${RS}"
echo
echo -e "${C}  1. Set your JWT secret:${RS}"
echo -e "     ${W}export JWT_SECRET=\"${JWT_HINT}\"${RS}"
echo -e "     ${W}echo 'export JWT_SECRET=\"${JWT_HINT}\"' >> ~/${SHELL_RC##*/}${RS}"
echo
echo -e "${C}  2. Get a FREE Gemini AI key:${RS}"
echo -e "     ${W}https://aistudio.google.com/app/apikey${RS}"
echo
echo -e "${C}  3. Start:${RS}"
echo -e "     ${W}source ${SHELL_RC} && netrunner start${RS}"
echo -e "     ${K}# or: cd ~/purplebruce && node server.js &${RS}"
echo
echo -e "${C}  4. Open in browser:${RS}"
echo -e "     ${W}http://127.0.0.1:3000${RS}"
echo
echo -e "${C}  5. Health check:${RS}"
echo -e "     ${W}netrunner doctor${RS}"
echo
echo -e "${Y}  ⚡ Grok  🔮 Venice  ✨ Gemini (free)  — set keys in Settings ⚙${RS}"
echo -e "${Y}  BlackArch tools: pacman -S blackarch  (full meta-package)${RS}"
echo
