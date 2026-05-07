#!/usr/bin/env bash
# Purple Bruce v6.0 — Termux X11 + GNOME Desktop Installer
# Supports: Kali proot, Arch/BlackArch proot
# Run this from TERMUX (not inside proot)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-x11-gnome.sh | bash

set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; C='\033[0;36m'
M='\033[0;35m'; W='\033[1;37m'; K='\033[2m'; RS='\033[0m'

ok()   { echo -e "${G}[✔]${RS} ${1}"; }
fail() { echo -e "${R}[✘]${RS} ${1}"; }
info() { echo -e "${C}[→]${RS} ${1}"; }
warn() { echo -e "${Y}[⚠]${RS} ${1}"; }
die()  { echo -e "${R}[✘] FATAL: ${1}${RS}"; exit 1; }

echo -e "\n${M}╔═══════════════════════════════════════════════════════╗"
echo    "║   PURPLE BRUCE v6.0 — Termux X11 + GNOME Desktop     ║"
echo -e "╚═══════════════════════════════════════════════════════╝${RS}\n"

# ─── Must run in Termux ───────────────────────────────────────────────────────
if [ -z "${TERMUX_VERSION:-}" ] && [ ! -d /data/data/com.termux ]; then
  die "Run this script from Termux (not inside a proot)"
fi

command -v proot-distro >/dev/null 2>&1 || {
  info "Installing proot-distro..."
  pkg install -y proot-distro || die "pkg install proot-distro failed"
}

# ─── Detect which proot is installed ─────────────────────────────────────────
DISTRO=""
if proot-distro list 2>/dev/null | grep -qi "kali.*installed"; then
  DISTRO="kali"
elif proot-distro list 2>/dev/null | grep -qi "archlinux.*installed"; then
  DISTRO="archlinux"
else
  warn "No proot distro found — installing Kali..."
  proot-distro install kali && DISTRO="kali" || die "proot-distro install kali failed"
fi
ok "Using proot: ${DISTRO}"

# ─── Termux X11 packages ─────────────────────────────────────────────────────
info "Setting up Termux X11..."
pkg install -y x11-repo 2>/dev/null || true
pkg install -y termux-x11-nightly 2>/dev/null \
  || pkg install -y termux-x11 2>/dev/null \
  || warn "termux-x11 not found in repos — install Termux:X11 APK manually from https://github.com/termux/termux-x11/releases"

pkg install -y pulseaudio 2>/dev/null && ok "PulseAudio installed" || warn "PulseAudio skipped (no audio)"
pkg install -y virglrenderer-android 2>/dev/null && ok "VirGL GPU accel installed" || info "VirGL skipped (optional GPU acceleration)"

# ─── Install GNOME inside proot ───────────────────────────────────────────────
info "Installing GNOME inside ${DISTRO} proot (this takes a few minutes)..."

if [ "$DISTRO" = "kali" ]; then
  proot-distro login kali -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends \
      kali-desktop-gnome \
      dbus-x11 \
      xorg \
      x11-xserver-utils \
      pulseaudio \
      gnome-tweaks \
      gnome-terminal \
      nautilus \
      gedit \
      firefox-esr \
      2>/dev/null || apt-get install -y --no-install-recommends \
        gnome-session gnome-shell gnome-control-center \
        gnome-terminal nautilus gedit \
        dbus-x11 xorg x11-xserver-utils pulseaudio
    echo 'GNOME install done'
  " && ok "GNOME installed in Kali proot" || warn "Some GNOME packages failed — desktop may still work"

elif [ "$DISTRO" = "archlinux" ]; then
  proot-distro login archlinux -- bash -c "
    set -e
    pacman -Sy --noconfirm
    pacman -S --noconfirm --needed \
      gnome gnome-extra \
      xorg-server xorg-xinit xorg-xrandr xorg-xhost \
      dbus \
      pulseaudio pulseaudio-alsa \
      gnome-tweaks \
      firefox \
      2>/dev/null || true
    echo 'GNOME install done'
  " && ok "GNOME installed in Arch proot" || warn "Some GNOME packages failed — desktop may still work"
fi

# ─── Create launcher script in Termux ────────────────────────────────────────
LAUNCHER="${HOME}/start-desktop.sh"
cat > "$LAUNCHER" <<LAUNCH
#!/usr/bin/env bash
# Purple Bruce — Termux X11 + GNOME Launcher
# Run from Termux: bash ~/start-desktop.sh

DISTRO="${DISTRO}"

echo -e "\n\033[1;35m╔════════════════════════════════════════╗"
echo    "║  PURPLE BRUCE — Starting Desktop       ║"
echo -e "╚════════════════════════════════════════╝\033[0m\n"

# Kill old X server if running
pkill -f "termux-x11" 2>/dev/null; sleep 0.5

# Start PulseAudio (audio support)
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1 2>/dev/null && echo "[✔] PulseAudio started" || true

# Start Termux X11 server
termux-x11 :1 -ac &
sleep 2
echo "[✔] X11 server started on :1"

# Launch GNOME inside proot
proot-distro login "\$DISTRO" -- bash -c "
  export DISPLAY=:1
  export PULSE_SERVER=tcp:127.0.0.1
  export XDG_RUNTIME_DIR=/tmp/runtime-\$(id -u)
  export DBUS_SESSION_BUS_ADDRESS=''
  mkdir -p \"\$XDG_RUNTIME_DIR\" && chmod 700 \"\$XDG_RUNTIME_DIR\"
  # Start dbus + GNOME session
  dbus-launch --exit-with-session gnome-session 2>/dev/null \
    || dbus-launch --exit-with-session gnome-session --session=gnome-xorg
" &

sleep 3

# Open Termux:X11 app automatically (if available)
am start --user 0 -a android.intent.action.MAIN \
  -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null \
  && echo "[✔] Termux:X11 app opened" \
  || echo "[→] Open Termux:X11 app manually"

echo
echo -e "\033[1;32m  Desktop launching — switch to Termux:X11 app\033[0m"
echo -e "\033[0;36m  Stop: pkill -f gnome-session && pkill -f termux-x11\033[0m"
echo
LAUNCH

chmod +x "$LAUNCHER"
ok "Launcher created: ~/start-desktop.sh"

# ─── Create stop script ───────────────────────────────────────────────────────
cat > "${HOME}/stop-desktop.sh" <<'STOP'
#!/usr/bin/env bash
pkill -f "gnome-session" 2>/dev/null
pkill -f "termux-x11"    2>/dev/null
pulseaudio --kill         2>/dev/null
echo "[✔] Desktop stopped"
STOP
chmod +x "${HOME}/stop-desktop.sh"
ok "Stop script: ~/stop-desktop.sh"

# ─── Add alias to .bashrc / .zshrc ───────────────────────────────────────────
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q "start-desktop" "$rc" 2>/dev/null && continue
  echo "alias desktop='bash ~/start-desktop.sh'" >> "$rc"
  echo "alias stopdesktop='bash ~/stop-desktop.sh'" >> "$rc"
done
ok "Aliases added: desktop / stopdesktop"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo
echo -e "${M}╔═══════════════════════════════════════════════════════╗${RS}"
echo -e "${M}║${RS}   ${G}Termux X11 + GNOME setup complete!${RS}                ${M}║${RS}"
echo -e "${M}╚═══════════════════════════════════════════════════════╝${RS}"
echo
echo -e "${C}  Requirements:${RS}"
echo -e "  ${W}1. Install Termux:X11 APK${RS}  ${K}(if not already installed)${RS}"
echo -e "     ${W}https://github.com/termux/termux-x11/releases${RS}"
echo
echo -e "${C}  Start desktop:${RS}"
echo -e "  ${W}bash ~/start-desktop.sh${RS}"
echo -e "  ${K}# or: desktop  (alias)${RS}"
echo
echo -e "${C}  Stop desktop:${RS}"
echo -e "  ${W}bash ~/stop-desktop.sh${RS}"
echo -e "  ${K}# or: stopdesktop  (alias)${RS}"
echo
echo -e "${C}  Purple Bruce in desktop:${RS}"
echo -e "  ${K}Open GNOME Terminal → cd ~/purplebruce → node server.js${RS}"
echo -e "  ${K}Then open Firefox → http://127.0.0.1:3000${RS}"
echo
echo -e "${Y}  Tip: Run 'source ~/.bashrc' to activate aliases${RS}"
echo
