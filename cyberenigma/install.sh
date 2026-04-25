#!/usr/bin/env bash
# cyberenigma · install.sh — Layer 1 Termux setup (zsh + neofetch + HUD + netrunner).
# Reproducible, minimal, beginner-friendly.

set -u

MODE="${1:-install}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NEOFETCH_DIR="$HOME/.config/neofetch"
HUD_DIR="$HOME/.cyberenigma/hud"
BIN_DIR="$HOME/cyberenigma/bin"
ZSH_PLUGINS="$HOME/.zsh"

c()    { printf '\033[38;5;%sm' "$1"; }
P=$(c 201); V=$(c 129); C=$(c 51); Y=$(c 226); R=$'\033[0m'
log()  { printf '%b[*]%b %s\n' "$C" "$R" "$*"; }
ok()   { printf '%b[✓]%b %s\n' "$Y" "$R" "$*"; }
warn() { printf '%b[!]%b %s\n' "$P" "$R" "$*"; }

banner() {
  printf '\n%b╔══════════════════════════════════════════════╗%b\n' "$V" "$R"
  printf '%b║%b   %bCYBERENIGMA%b · %bLayer 1 Termux setup%b        %b║%b\n' "$V" "$R" "$P" "$R" "$C" "$R" "$V" "$R"
  printf '%b╚══════════════════════════════════════════════╝%b\n\n' "$V" "$R"
}

backup() {
  [ -e "$1" ] && [ ! -L "$1" ] && mv "$1" "$1.cyberenigma-backup.$(date +%s)" || true
}

need_termux() {
  if [ -z "${TERMUX_VERSION:-}" ] && [ ! -d /data/data/com.termux ]; then
    warn "This layer is intended for Termux (Android). pkg / termux paths won't exist elsewhere."
  fi
}

install_pkgs() {
  if ! command -v pkg >/dev/null 2>&1; then
    warn "pkg not found — skipping package install."
    return 0
  fi
  log "pkg update & install (zsh, git, curl, jq, neofetch, proot-distro)…"
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y zsh git curl jq neofetch proot-distro >/dev/null 2>&1 \
    || warn "one or more packages failed (check pkg output manually)"
}

install_plugins() {
  mkdir -p "$ZSH_PLUGINS"
  if [ ! -d "$ZSH_PLUGINS/zsh-autosuggestions" ]; then
    log "clone zsh-autosuggestions …"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_PLUGINS/zsh-autosuggestions" >/dev/null 2>&1 || warn "clone failed"
  fi
}

deploy() {
  mkdir -p "$NEOFETCH_DIR" "$HUD_DIR" "$BIN_DIR"
  backup "$HOME/.zshrc"
  install -m 644 "$SCRIPT_DIR/zshrc"                        "$HOME/.zshrc"
  install -m 644 "$SCRIPT_DIR/config/neofetch/config.conf"  "$NEOFETCH_DIR/config.conf"
  install -m 644 "$SCRIPT_DIR/config/neofetch/ascii.txt"    "$NEOFETCH_DIR/ascii.txt"
  install -m 755 "$SCRIPT_DIR/hud/topbar.sh"                "$HUD_DIR/topbar.sh"
  install -m 755 "$SCRIPT_DIR/bin/netrunner"                "$BIN_DIR/netrunner"
  install -m 755 "$SCRIPT_DIR/bin/agent"                    "$BIN_DIR/agent"
  ok "dotfiles deployed"
}

set_zsh() {
  local z; z="$(command -v zsh || true)"
  if [ -z "$z" ]; then
    warn "zsh not found — cannot chsh"
    return
  fi
  if [ "${SHELL:-}" != "$z" ]; then
    chsh -s "$z" 2>/dev/null && ok "login shell → zsh" \
      || warn "chsh failed — run 'chsh -s zsh' manually"
  fi
}

case "$MODE" in
  install)
    banner
    need_termux
    install_pkgs
    install_plugins
    deploy
    set_zsh
    echo
    ok "installation complete — open a new session or run:  ${C}exec zsh${R}"
    ;;
  uninstall)
    banner
    local_latest() { ls -1t "${1}.cyberenigma-backup."* 2>/dev/null | head -1; }
    for f in "$HOME/.zshrc"; do
      b=$(local_latest "$f")
      [ -n "$b" ] && mv -f "$b" "$f" && log "restored $(basename "$f")" || rm -f "$f"
    done
    rm -rf "$HOME/.cyberenigma" "$HOME/cyberenigma"
    rm -rf "$NEOFETCH_DIR"
    ok "uninstalled"
    ;;
  status)
    printf '  zsh          : %s\n' "$(command -v zsh || echo missing)"
    printf '  neofetch     : %s\n' "$(command -v neofetch || echo missing)"
    printf '  proot-distro : %s\n' "$(command -v proot-distro || echo missing)"
    printf '  ~/.zshrc     : %s\n' "$([ -f "$HOME/.zshrc" ] && echo ok || echo missing)"
    printf '  ascii.txt    : %s\n' "$([ -f "$NEOFETCH_DIR/ascii.txt" ] && echo ok || echo missing)"
    printf '  topbar.sh    : %s\n' "$([ -x "$HUD_DIR/topbar.sh" ] && echo ok || echo missing)"
    printf '  netrunner    : %s\n' "$(command -v netrunner || echo 'not in PATH — open new shell')"
    ;;
  *)
    echo "usage: $0 {install|uninstall|status}"
    exit 2
    ;;
esac
