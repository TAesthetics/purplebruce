#!/usr/bin/env bash
# netrunner/install.sh — Cyberpunk terminal installer for Ubuntu proot-distro (Debian/Kali also).
# Deploys: zsh + Oh-My-Zsh + Powerlevel10k + fzf + zoxide + bat + eza + tmux + cyberpunk dotfiles.
# Idempotent. Backs up existing .zshrc / .p10k.zsh / .tmux.conf before overwriting.

set -u

MODE="${1:-install}"
REPO="${NETRUNNER_REPO:-TAesthetics/purplebruce}"
BRANCH="${NETRUNNER_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/netrunner"

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo '')"
NETRUNNER_HOME="$HOME/.netrunner"

SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO=sudo

c() { printf '\033[38;5;%sm' "$1"; }
P=$(c 201); V=$(c 129); C=$(c 51); Y=$(c 226); R=$'\033[0m'
log()  { printf '%b[*]%b %s\n' "$C" "$R" "$*"; }
ok()   { printf '%b[✓]%b %s\n' "$Y" "$R" "$*"; }
warn() { printf '%b[!]%b %s\n' "$P" "$R" "$*"; }

banner() {
  printf '\n%b╔══════════════════════════════════════════════╗%b\n' "$P" "$R"
  printf '%b║%b   %bNETRUNNER%b · %bcyberpunk terminal setup%b     %b║%b\n' "$P" "$R" "$P" "$R" "$C" "$R" "$P" "$R"
  printf '%b╚══════════════════════════════════════════════╝%b\n\n' "$P" "$R"
}

# fetch <rel-path> <dest>
#   Uses local file if running from a cloned repo; otherwise downloads from GitHub.
fetch() {
  local rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$rel" ]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    if ! curl -fsSL "$BASE_URL/$rel" -o "$dest"; then
      warn "could not fetch $rel (offline? branch=$BRANCH)"
      return 1
    fi
  fi
}

backup_if_exists() {
  local f="$1"
  [ -e "$f" ] && [ ! -L "$f" ] || return 0
  local ts; ts=$(date +%s)
  mv "$f" "${f}.netrunner-backup.${ts}"
  log "backed up $(basename "$f") → ${f}.netrunner-backup.${ts}"
}

apt_install() {
  if ! command -v apt-get >/dev/null 2>&1; then
    warn "apt-get not found — this installer targets Debian/Ubuntu/Kali proot-distros."
    return 1
  fi
  log "apt update ..."
  $SUDO apt-get update -y >/dev/null 2>&1 || true
  local pkgs=(zsh git curl wget ca-certificates fzf tmux bat fastfetch chafa)
  # eza / zoxide may not be in older distros; try and fall back.
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}" eza zoxide 2>/dev/null || {
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}" 2>/dev/null || true
  }
  # Debian names bat -> batcat. Symlink for consistency.
  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    $SUDO ln -sf "$(command -v batcat)" /usr/local/bin/bat
  fi
  # Fallbacks when distro packages are missing.
  if ! command -v zoxide >/dev/null 2>&1; then
    log "zoxide not in apt — installing via upstream script"
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | $SUDO bash >/dev/null 2>&1 || true
  fi
}

install_omz() {
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  if [ -d "$ZSH" ]; then
    log "Oh-My-Zsh already installed → update"
    ( cd "$ZSH" && git pull --quiet --ff-only 2>/dev/null ) || true
  else
    log "installing Oh-My-Zsh ..."
    RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null
  fi
  local CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
  # Powerlevel10k
  [ -d "$CUSTOM/themes/powerlevel10k" ] \
    || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$CUSTOM/themes/powerlevel10k" >/dev/null
  # Plugins
  [ -d "$CUSTOM/plugins/zsh-autosuggestions" ] \
    || git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM/plugins/zsh-autosuggestions" >/dev/null
  [ -d "$CUSTOM/plugins/zsh-syntax-highlighting" ] \
    || git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null
  [ -d "$CUSTOM/plugins/zsh-completions" ] \
    || git clone --depth=1 https://github.com/zsh-users/zsh-completions "$CUSTOM/plugins/zsh-completions" >/dev/null
}

# populate_logo — Layer 2 image-logo populator. Cross is the canonical
# Layer 1 identity; snake stays as a fallback. Deterministic priority.
populate_logo() {
  local LOGO_PATH="$HOME/.config/fastfetch/images/logo.png"
  # Idempotence guard: skip unless explicitly refreshed.
  [ -f "$LOGO_PATH" ] && [ "${NETRUNNER_REFRESH_LOGO:-0}" != "1" ] && return 0
  # Ensure target dir exists before any write.
  mkdir -p "$HOME/.config/fastfetch/images"
  if [ -n "${CROSS_IMAGE_URL:-}" ] && [ "$CROSS_IMAGE_URL" != "<TBD-URL>" ]; then
    # Tier 1: explicit URL override.
    curl -fsSL "$CROSS_IMAGE_URL" -o "$LOGO_PATH" \
      || warn "logo fetch failed → fallback"
  elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/assets/cross.png" ]; then
    # Tier 2a: cross asset shipped in cloned repo (canonical).
    cp "$SCRIPT_DIR/assets/cross.png" "$LOGO_PATH"
  elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/assets/snake.png" ]; then
    # Tier 2b: snake fallback from cloned repo.
    cp "$SCRIPT_DIR/assets/snake.png" "$LOGO_PATH"
  elif curl -fsSL "$BASE_URL/assets/cross.png" -o "$LOGO_PATH" 2>/dev/null; then
    : # Tier 3a: cross from remote (curl-piped install).
  else
    # Tier 3b: snake from remote (curl-piped install).
    curl -fsSL "$BASE_URL/assets/snake.png" -o "$LOGO_PATH" \
      || rm -f "$LOGO_PATH"
  fi
  # Nothing populated → launcher falls back to motd.sh on its own.
}

deploy_dotfiles() {
  mkdir -p "$NETRUNNER_HOME" "$HOME/.cache"
  fetch dotfiles/zshrc     "$HOME/.zshrc.netrunner"
  fetch dotfiles/p10k.zsh  "$HOME/.p10k.zsh.netrunner"
  fetch dotfiles/tmux.conf "$HOME/.tmux.conf.netrunner"
  fetch assets/logo.ascii  "$NETRUNNER_HOME/logo.ascii"
  fetch assets/motd.sh     "$NETRUNNER_HOME/motd.sh"
  chmod +x "$NETRUNNER_HOME/motd.sh"

  # Layer 2: fastfetch config + launcher.
  fetch assets/fastfetch.jsonc        "$NETRUNNER_HOME/fastfetch.jsonc"
  fetch assets/fastfetch-launcher.sh  "$NETRUNNER_HOME/fastfetch-launcher.sh"
  chmod +x "$NETRUNNER_HOME/fastfetch-launcher.sh"
  populate_logo

  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.p10k.zsh"
  backup_if_exists "$HOME/.tmux.conf"
  mv "$HOME/.zshrc.netrunner"     "$HOME/.zshrc"
  mv "$HOME/.p10k.zsh.netrunner"  "$HOME/.p10k.zsh"
  mv "$HOME/.tmux.conf.netrunner" "$HOME/.tmux.conf"
}

install_netrunner_bin() {
  local bin="/usr/local/bin/netrunner"
  fetch bin/netrunner "$NETRUNNER_HOME/netrunner.bin"
  $SUDO install -m 755 "$NETRUNNER_HOME/netrunner.bin" "$bin" 2>/dev/null || {
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$NETRUNNER_HOME/netrunner.bin" "$HOME/.local/bin/netrunner"
    warn "/usr/local/bin not writable — installed to ~/.local/bin/netrunner. Add to PATH."
  }
  rm -f "$NETRUNNER_HOME/netrunner.bin"
}

set_shell() {
  local zsh_path; zsh_path="$(command -v zsh)"
  [ -z "$zsh_path" ] && { warn "zsh not found — skip chsh"; return; }
  # shell must be in /etc/shells
  grep -qxF "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
  if [ "${SHELL:-}" != "$zsh_path" ]; then
    if $SUDO chsh -s "$zsh_path" "$(id -un)" 2>/dev/null; then
      ok "login shell → $zsh_path"
    else
      warn "could not chsh automatically. Run manually:  chsh -s $zsh_path"
      warn "or start zsh from your current shell: exec zsh"
    fi
  fi
}

do_install() {
  banner
  apt_install
  install_omz
  deploy_dotfiles
  install_netrunner_bin
  set_shell
  printf '\n'
  ok "netrunner installed. Open a new shell or run:  ${C}exec zsh${R}"
  ok "then:  ${P}netrunner${R}   (from Termux → proot)  ·  inside proot → launches Purple Bruce"
  printf '\n'
}

do_uninstall() {
  banner
  for f in "$HOME/.zshrc" "$HOME/.p10k.zsh" "$HOME/.tmux.conf"; do
    local latest; latest=$(ls -1t "${f}.netrunner-backup."* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
      mv -f "$latest" "$f"
      log "restored $(basename "$f") from $(basename "$latest")"
    else
      rm -f "$f"
    fi
  done
  rm -rf "$NETRUNNER_HOME"
  # Layer 2: fastfetch logo asset. Remove file; rmdir dir if empty.
  rm -f "$HOME/.config/fastfetch/images/logo.png"
  rmdir "$HOME/.config/fastfetch/images" 2>/dev/null || true
  rmdir "$HOME/.config/fastfetch"        2>/dev/null || true
  $SUDO rm -f /usr/local/bin/netrunner
  rm -f "$HOME/.local/bin/netrunner"
  ok "netrunner uninstalled (Oh-My-Zsh + plugins left intact)."
}

logo_identity() {
  # cross | snake | custom | missing — compare deployed logo.png against
  # the in-repo cross.png and snake.png by exact bytes.
  local p="$HOME/.config/fastfetch/images/logo.png"
  [ -f "$p" ] || { echo missing; return; }
  local cross="$SCRIPT_DIR/assets/cross.png"
  local snake="$SCRIPT_DIR/assets/snake.png"
  if [ -f "$cross" ] && cmp -s "$p" "$cross" 2>/dev/null; then
    echo cross
  elif [ -f "$snake" ] && cmp -s "$p" "$snake" 2>/dev/null; then
    echo snake
  else
    echo custom
  fi
}

do_status() {
  printf '  zsh             : %s\n'  "$(command -v zsh  || echo 'missing')"
  printf '  oh-my-zsh       : %s\n'  "$([ -d "$HOME/.oh-my-zsh" ] && echo ok || echo missing)"
  printf '  powerlevel10k   : %s\n'  "$([ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] && echo ok || echo missing)"
  printf '  .zshrc          : %s\n'  "$([ -f "$HOME/.zshrc"    ] && echo ok || echo missing)"
  printf '  .p10k.zsh       : %s\n'  "$([ -f "$HOME/.p10k.zsh" ] && echo ok || echo missing)"
  printf '  motd.sh         : %s\n'  "$([ -f "$NETRUNNER_HOME/motd.sh" ] && echo ok || echo missing)"
  printf '  fastfetch       : %s\n'  "$(command -v fastfetch || echo 'missing')"
  printf '  fastfetch.jsonc : %s\n'  "$([ -f "$NETRUNNER_HOME/fastfetch.jsonc" ] && echo ok || echo missing)"
  printf '  logo.png        : %s\n'  "$(logo_identity)"
  printf '  netrunner cmd   : %s\n'  "$(command -v netrunner  || echo 'missing')"
  printf '  login shell     : %s\n'  "${SHELL:-?}"
}

case "$MODE" in
  install)    do_install ;;
  uninstall)  do_uninstall ;;
  status)     do_status ;;
  help|--help|-h|"")
    cat <<EOF
usage: $0 <command>
  install     — install zsh + Oh-My-Zsh + Powerlevel10k + plugins + cyberpunk dotfiles
  uninstall   — restore backed-up dotfiles and remove the netrunner command
  status      — show what's installed
EOF
    ;;
  *) warn "unknown command: $MODE (try: help)"; exit 2 ;;
esac
