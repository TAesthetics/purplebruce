#!/usr/bin/env bash
# Purple Bruce Lucy — Dotfiles + Environment Setup
# Run INSIDE Arch proot: proot-distro login archlinux
# Then: bash ~/purplebruce/netrunner/dotfiles/install.sh

set -uo pipefail

V='\033[38;5;135m'; C='\033[38;5;51m'; Y='\033[38;5;220m'
M='\033[38;5;201m'; G='\033[38;5;46m'; D='\033[38;5;240m'; RS='\033[0m'

ok()   { echo -e "  ${G}✔${RS}  ${C}${1}${RS}"; }
warn() { echo -e "  ${Y}⚠${RS}  ${1}"; }
info() { echo -e "  ${V}→${RS}  ${1}"; }
die()  { echo -e "  \033[31m✘ FATAL:${RS} ${1}"; exit 1; }

PB_DIR="${PURPLEBRUCE_DIR:-$HOME/purplebruce}"
DOT_DIR="${PB_DIR}/netrunner/dotfiles"

echo -e "\n${M}  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}"
echo -e "  ${V}  PURPLE BRUCE LUCY v7.1 — Neural Setup   ${RS}"
echo -e "  ${M}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}\n"

[ -d "$PB_DIR" ] || die "Purple Bruce not found at $PB_DIR — run install-arch.sh first"
[ -d "$DOT_DIR" ] || die "Dotfiles dir not found: $DOT_DIR"

# ── Sync package DB first ─────────────────────────────────────────
info "Syncing package database..."
pacman -Sy --noconfirm 2>/dev/null && ok "Package DB synced" || warn "DB sync failed — continuing"

# ── 1. CA certs + Zsh + plugins (pacman) ─────────────────────────
info "Installing ca-certificates + zsh + plugins..."
pacman -S --noconfirm --needed ca-certificates 2>/dev/null && ok "ca-certificates" || warn "ca-certificates skipped"
pacman -S --noconfirm --needed zsh 2>/dev/null && ok "zsh" || warn "zsh skipped"
pacman -S --noconfirm --needed zsh-syntax-highlighting 2>/dev/null && ok "zsh-syntax-highlighting" || warn "zsh-syntax-highlighting skipped"
pacman -S --noconfirm --needed zsh-autosuggestions 2>/dev/null && ok "zsh-autosuggestions" || warn "zsh-autosuggestions skipped"

# Update trust store so HTTPS git clones work
update-ca-trust 2>/dev/null || trust extract-compat 2>/dev/null || true

# ── 2. Oh-My-Zsh ──────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh-My-Zsh..."
  RUNZSH=no CHSH=no GIT_SSL_NO_VERIFY=true \
    sh -c "$(wget --no-check-certificate -qO- \
      https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh 2>/dev/null)" \
    2>/dev/null && ok "Oh-My-Zsh installed" || warn "Oh-My-Zsh failed — using built-in fallback prompt"
else
  ok "Oh-My-Zsh already installed"
fi

# ── 3. Powerlevel10k ──────────────────────────────────────────────
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  info "Installing Powerlevel10k..."
  # Try pacman first (no network needed if already cached)
  pacman -S --noconfirm --needed zsh-theme-powerlevel10k 2>/dev/null && {
    mkdir -p "$(dirname "$P10K_DIR")"
    ln -sf /usr/share/zsh-theme-powerlevel10k "$P10K_DIR" 2>/dev/null
    ok "Powerlevel10k (pacman)"
  } || {
    GIT_SSL_NO_VERIFY=true git clone --depth=1 \
      https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" 2>/dev/null \
      && ok "Powerlevel10k (git)" || warn "p10k failed — fallback prompt active (built into zshrc)"
  }
else
  ok "Powerlevel10k already installed"
fi

# ── 4. zsh plugins via git (fallback — pacman already installed them) ─
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plug in zsh-autosuggestions zsh-syntax-highlighting; do
  PLUG_DIR="${ZSH_CUSTOM}/plugins/${plug}"
  if [ ! -d "$PLUG_DIR" ] && [ -d "$HOME/.oh-my-zsh" ]; then
    info "Linking ${plug} plugin..."
    # Prefer system-installed pacman version
    SYS_PLUG="/usr/share/zsh/plugins/${plug}"
    if [ -d "$SYS_PLUG" ]; then
      mkdir -p "$(dirname "$PLUG_DIR")"
      ln -sf "$SYS_PLUG" "$PLUG_DIR" && ok "${plug} (linked from pacman)"
    else
      GIT_SSL_NO_VERIFY=true git clone --depth=1 \
        "https://github.com/zsh-users/${plug}.git" "$PLUG_DIR" 2>/dev/null \
        && ok "${plug} (git)" || warn "${plug} skipped — system plugin will be used from zshrc"
    fi
  elif [ -d "$PLUG_DIR" ]; then
    ok "${plug} already present"
  fi
done

# ── 5. Copy dotfiles ──────────────────────────────────────────────
info "Deploying dotfiles..."

# .zshrc
cp "${DOT_DIR}/zshrc" "${HOME}/.zshrc"
ok ".zshrc deployed"

# .tmux.conf
cp "${DOT_DIR}/tmux.conf" "${HOME}/.tmux.conf"
ok ".tmux.conf deployed"

# p10k config (if exists)
[ -f "${DOT_DIR}/p10k.zsh" ] && cp "${DOT_DIR}/p10k.zsh" "${HOME}/.p10k.zsh" && ok ".p10k.zsh deployed"

# ── 6. netrunner CLI ─────────────────────────────────────────────
info "Setting up netrunner CLI..."
mkdir -p "${HOME}/.local/bin"

# netrunner CLI symlink — required for start/lucy/pb/scan aliases
NETRUNNER_BIN="${PB_DIR}/netrunner/bin/netrunner"
if [ -f "$NETRUNNER_BIN" ]; then
  chmod +x "$NETRUNNER_BIN"
  ln -sf "$NETRUNNER_BIN" "${HOME}/.local/bin/netrunner"
  ok "netrunner CLI linked → ~/.local/bin/netrunner"
else
  warn "netrunner bin not found at $NETRUNNER_BIN — start/lucy aliases use direct node fallback"
fi

# ── 7. NemoClaw CLI AI agent ─────────────────────────────────────
info "Installing NemoClaw (CLI AI agent)..."
NC_SCRIPT="${PB_DIR}/netrunner/nemoclaw/nemoclaw.py"
if [ -f "$NC_SCRIPT" ]; then
  chmod +x "$NC_SCRIPT"
  ln -sf "$NC_SCRIPT" "${HOME}/.local/bin/nemoclaw"
  ok "NemoClaw linked → ~/.local/bin/nemoclaw  (run: nc)"
  # Install Python deps for NemoClaw + drone tracker + patrol
  pacman -S --noconfirm --needed \
    python-requests python-websockets python-opencv python-numpy python-rich \
    2>/dev/null && ok "Python deps installed (NemoClaw / tracker / patrol)" || warn "Some Python deps skipped"
  # Make patrol script executable
  chmod +x "${PB_DIR}/netrunner/drone/patrol.py" 2>/dev/null || true
else
  warn "nemoclaw.py not found at $NC_SCRIPT"
fi

# ── 8. Additional hacking tools ───────────────────────────────────
info "Installing additional tools..."
pacman -S --noconfirm --needed \
  vim neovim tmux fzf bat fd ripgrep \
  python-rich python-click \
  2>/dev/null && ok "Extra tools installed" || warn "Some extras skipped"

# ── 9. Bluetooth audio deps ──────────────────────────────────────
info "Installing Bluetooth + audio stack (best-effort)..."
pacman -S --noconfirm --needed \
  bluez bluez-utils pulseaudio pulseaudio-bluetooth alsa-utils \
  2>/dev/null && ok "BT+audio stack installed" || warn "BT packages skipped (may not work in proot without kernel BT)"
chmod +x "${PB_DIR}/netrunner/audio/bt-setup.sh" 2>/dev/null || true

# ── 10. Single launch alias — write to Termux side if accessible ─
info "Writing single-command 'pb' alias..."
LAUNCH_SCRIPT="${PB_DIR}/netrunner/launch.sh"
chmod +x "$LAUNCH_SCRIPT" 2>/dev/null || true
# Detect Termux home
for TERMUX_HOME_TRY in "/data/data/com.termux/files/home" "$HOME/../.."; do
  if [ -d "$TERMUX_HOME_TRY" ] && [ -w "$TERMUX_HOME_TRY" ]; then
    for RC in "${TERMUX_HOME_TRY}/.bashrc" "${TERMUX_HOME_TRY}/.zshrc"; do
      [ -f "$RC" ] || continue
      if ! grep -q "purplebruce/netrunner/launch.sh" "$RC" 2>/dev/null; then
        echo "" >> "$RC"
        echo "# Purple Bruce Lucy v7.1 — single launch alias" >> "$RC"
        echo "alias pb='proot-distro login archlinux -- bash ~/purplebruce/netrunner/launch.sh'" >> "$RC"
        ok "Single alias 'pb' written to $RC"
      else
        ok "'pb' alias already in $RC"
      fi
    done
    break
  fi
done
ok "From Termux: type 'pb' to enter proot + auto-start server"

# ── 11. Set zsh as default shell ─────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH=$(command -v zsh)
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" >> /etc/shells 2>/dev/null || true
  fi
  chsh -s "$ZSH_PATH" 2>/dev/null && ok "zsh set as default shell" || warn "chsh failed — run: exec zsh"
fi

# ── 10. PATH in all shells ────────────────────────────────────────
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null \
    || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
ok "PATH updated in shell configs"

# ── Done ──────────────────────────────────────────────────────────
echo
echo -e "  ${M}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}"
echo -e "  ${V}  NEURAL SETUP COMPLETE  ·  v7.1     ${RS}"
echo -e "  ${M}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}"
echo
echo -e "  ${G}NOW:${RS}        ${Y}exec zsh${RS}       ${D}← activate the new shell${RS}"
echo -e "  ${G}START:${RS}      ${Y}go${RS}             ${D}← launch server${RS}"
echo -e "  ${G}AI:${RS}         ${Y}nc${RS}             ${D}← NemoClaw CLI agent${RS}"
echo -e "  ${G}AUDIO:${RS}      ${Y}bt${RS}             ${D}← HOCO EQ3 Bluetooth${RS}"
echo -e "  ${G}TRACKER:${RS}    ${Y}drone-track${RS}    ${D}← autonomous drone${RS}"
echo -e "  ${G}ARSENAL:${RS}    ${Y}toolcheck${RS}      ${D}← BlackArch check${RS}"
echo
echo -e "  ${D}From Termux (outside proot):${RS}"
echo -e "  ${Y}pb${RS}   ${D}← ONE command enters proot + starts server${RS}"
echo
