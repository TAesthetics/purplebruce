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

echo -e "\n${M}  ╔══════════════════════════════════════════════╗"
echo    "  ║  PURPLE BRUCE LUCY — Environment Setup v6.0  ║"
echo -e "  ╚══════════════════════════════════════════════╝${RS}\n"

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

# ── 6. Occult tools + netrunner CLI ──────────────────────────────
info "Setting up occult tools + netrunner CLI..."
mkdir -p "${HOME}/.local/bin"
chmod +x "${PB_DIR}/netrunner/occult/"*.py 2>/dev/null || true

# Occult tool symlinks
for tool in sigil moon tarot rune ritual; do
  ln -sf "${PB_DIR}/netrunner/occult/${tool}.py" "${HOME}/.local/bin/${tool}"
done
ok "Occult tools linked: sigil moon tarot rune ritual"

# netrunner CLI symlink — required for start/lucy/pb/scan aliases
NETRUNNER_BIN="${PB_DIR}/netrunner/bin/netrunner"
if [ -f "$NETRUNNER_BIN" ]; then
  chmod +x "$NETRUNNER_BIN"
  ln -sf "$NETRUNNER_BIN" "${HOME}/.local/bin/netrunner"
  ok "netrunner CLI linked → ~/.local/bin/netrunner"
else
  warn "netrunner bin not found at $NETRUNNER_BIN — start/lucy aliases use direct node fallback"
fi

# ── 7. Additional hacking tools ───────────────────────────────────
info "Installing additional tools..."
pacman -S --noconfirm --needed \
  vim neovim tmux fzf bat fd ripgrep \
  python-rich python-click \
  2>/dev/null && ok "Extra tools installed" || warn "Some extras skipped"

# ── 8. Set zsh as default shell ───────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH=$(command -v zsh)
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" >> /etc/shells 2>/dev/null || true
  fi
  chsh -s "$ZSH_PATH" 2>/dev/null && ok "zsh set as default shell" || warn "chsh failed — run: exec zsh"
fi

# ── 9. PATH in all shells ─────────────────────────────────────────
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null \
    || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
ok "PATH updated in shell configs"

# ── Done ──────────────────────────────────────────────────────────
echo
echo -e "  ${M}╔══════════════════════════════════════════════╗${RS}"
echo -e "  ${M}║${RS}  ${G}Environment setup complete!${RS}               ${M}║${RS}"
echo -e "  ${M}╚══════════════════════════════════════════════╝${RS}"
echo
echo -e "  ${V}Apply now:${RS}"
echo -e "    ${Y}exec zsh${RS}          ${D}← switch to new shell immediately${RS}"
echo -e "    ${Y}source ~/.zshrc${RS}   ${D}← reload config in current shell${RS}"
echo
echo -e "  ${V}Occult tools:${RS}"
echo -e "    ${Y}moon${RS}     ${D}← current moon phase + magical timing${RS}"
echo -e "    ${Y}sigil${RS}    ${D}← chaos magic sigil generator${RS}"
echo -e "    ${Y}tarot${RS}    ${D}← tarot card draw${RS}"
echo -e "    ${Y}rune${RS}     ${D}← Elder Futhark rune cast${RS}"
echo -e "    ${Y}ritual${RS}   ${D}← ritual protocol builder${RS}"
echo
echo -e "  ${V}Purple Bruce:${RS}"
echo -e "    ${Y}pbstart${RS}  ${D}← launch server (tmux)${RS}"
echo -e "    ${Y}go${RS}       ${D}← same, short form${RS}"
echo -e "    ${Y}lucy${RS}     ${D}← netrunner menu${RS}"
echo
