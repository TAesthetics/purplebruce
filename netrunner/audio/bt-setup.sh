#!/usr/bin/env bash
# Purple Bruce Lucy v7.1 — Bluetooth Audio Setup
# HOCO EQ3 + PulseAudio bridge for Arch proot on Android
#
# Usage:
#   bt               interactive menu
#   bt scan          scan for BT devices
#   bt connect       connect HOCO EQ3 (auto-finds by name)
#   bt connect MAC   connect specific MAC address
#   bt status        show BT + audio status
#   bt vol 80        set volume to 80%

set -uo pipefail

V=$'\e[38;5;135m'; C=$'\e[38;5;51m'; G=$'\e[38;5;46m'
Y=$'\e[38;5;220m'; M=$'\e[38;5;201m'; D=$'\e[38;5;240m'
W=$'\e[1;37m'; R=$'\e[0;31m'; RS=$'\e[0m'

ok()   { echo -e "  ${G}◈${RS}  ${C}${1}${RS}"; }
warn() { echo -e "  ${Y}⚠${RS}  ${1}"; }
info() { echo -e "  ${V}→${RS}  ${1}"; }
fail() { echo -e "  ${R}✘${RS}  ${1}"; }
hr()   { echo -e "  ${M}$(printf '%.0s─' {1..46})${RS}"; }

banner() {
  echo ""
  echo "  ${M}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}"
  echo "  ${V}  ◈ PURPLE BRUCE — AUDIO LINK v7.1${RS}"
  echo "  ${D}    HOCO EQ3 · BT · PulseAudio     ${RS}"
  echo "  ${M}⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿${RS}"
  echo ""
}

# ── Detect BT stack ──────────────────────────────────────────────
has_bluetoothctl() { command -v bluetoothctl >/dev/null 2>&1; }
has_termux_bt()    { command -v termux-bluetooth-scan >/dev/null 2>&1; }
has_pulse()        { command -v pactl >/dev/null 2>&1; }
has_pulseaudio()   { command -v pulseaudio >/dev/null 2>&1; }

# ── PulseAudio bridge setup ──────────────────────────────────────
setup_pulse() {
  info "Setting up PulseAudio..."

  # Try to start PulseAudio in proot (works if /dev/snd is available)
  if has_pulseaudio; then
    pulseaudio --start --log-target=syslog 2>/dev/null && ok "PulseAudio started" && return 0
  fi

  # Check if Termux's PulseAudio is running on the TCP bridge
  if nc -z 127.0.0.1 4713 2>/dev/null; then
    export PULSE_SERVER=tcp:127.0.0.1:4713
    ok "PulseAudio bridge detected at 127.0.0.1:4713"
    return 0
  fi

  # Guide: start PulseAudio in Termux
  warn "PulseAudio not reachable inside proot."
  echo ""
  echo "  ${W}To enable audio in proot, in a NEW Termux session (outside proot):${RS}"
  echo ""
  echo "  ${C}pkg install pulseaudio${RS}"
  echo "  ${C}pulseaudio --start --load=\"module-native-protocol-tcp auth-ip-acl=127.0.0.1\"${RS}"
  echo ""
  echo "  ${D}Then re-run: bt${RS}"
  return 1
}

# ── Bluetooth via bluetoothctl (Linux BlueZ) ─────────────────────
bt_scan_bluez() {
  info "Scanning for BT devices (10s)..."
  timeout 10 bluetoothctl scan on 2>/dev/null &
  sleep 8
  bluetoothctl devices 2>/dev/null | while read -r line; do
    local mac; mac=$(echo "$line" | awk '{print $2}')
    local name; name=$(echo "$line" | cut -d' ' -f3-)
    printf "  ${C}%s${RS}  ${W}%s${RS}\n" "$mac" "$name"
  done
  kill %1 2>/dev/null
}

bt_connect_bluez() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    # Auto-detect HOCO EQ3
    info "Looking for HOCO EQ3..."
    target=$(bluetoothctl devices 2>/dev/null | grep -i "EQ3\|HOCO\|EQ-3" | awk '{print $2}' | head -1)
    if [[ -z "$target" ]]; then
      warn "HOCO EQ3 not found. Run: bt scan  then  bt connect <MAC>"
      return 1
    fi
    ok "Found HOCO EQ3 at ${target}"
  fi

  info "Pairing ${target}..."
  bluetoothctl pair "$target" 2>/dev/null && ok "Paired"
  info "Connecting ${target}..."
  bluetoothctl connect "$target" 2>/dev/null && ok "Connected: ${target}" || {
    fail "Connection failed"
    echo "  Make sure HOCO EQ3 is in pairing mode (long-press power)"
    return 1
  }
  info "Trusting ${target}..."
  bluetoothctl trust "$target" 2>/dev/null

  # Set as default audio sink
  sleep 2
  _set_bt_sink "$target"
}

_set_bt_sink() {
  local mac="${1:-}"
  if has_pulse; then
    local sink; sink=$(pactl list sinks short 2>/dev/null | grep -i "bluez\|bt\|hoco" | awk '{print $2}' | head -1)
    if [[ -n "$sink" ]]; then
      pactl set-default-sink "$sink" 2>/dev/null && ok "Audio → ${sink} (BT sink)"
    else
      warn "BT audio sink not registered yet — wait 5s and run: bt status"
    fi
  fi
}

# ── Bluetooth via Termux:API (no BlueZ needed) ───────────────────
bt_scan_termux() {
  info "Scanning via Termux:API (10s)..."
  termux-bluetooth-scan -d 10 2>/dev/null | python3 -c "
import sys, json
try:
  for dev in json.load(sys.stdin):
    print(f\"  {dev.get('address','?')}  {dev.get('name','Unknown')}\")
except:
  print('  [no results]')
"
}

# ── Status ───────────────────────────────────────────────────────
bt_status() {
  echo ""
  hr
  echo "  ${V}Bluetooth${RS}"
  hr
  if has_bluetoothctl; then
    local adapter; adapter=$(bluetoothctl show 2>/dev/null | head -3)
    if [[ -n "$adapter" ]]; then
      ok "BlueZ stack: active"
      bluetoothctl info 2>/dev/null | grep -E "Name|Connected|Paired|Trusted" | \
        while IFS= read -r line; do echo "  ${D}${line}${RS}"; done
    else
      warn "BlueZ: adapter not found (Android kernel may not expose BT to proot)"
      info "Alternative: pair HOCO EQ3 in Android Bluetooth settings, then re-check"
    fi
  else
    warn "bluetoothctl not installed: pacman -S bluez bluez-utils"
  fi

  echo ""
  hr
  echo "  ${V}Audio${RS}"
  hr
  if has_pulse; then
    local sinks; sinks=$(pactl list sinks short 2>/dev/null)
    if [[ -n "$sinks" ]]; then
      ok "PulseAudio: active"
      echo "$sinks" | while IFS= read -r line; do
        local name; name=$(echo "$line" | awk '{print $2}')
        local state; state=$(echo "$line" | awk '{print $5}')
        local sym; sym="  ${D}○${RS}"
        [[ "$state" == "RUNNING" ]] && sym="  ${G}◈${RS}"
        printf "${sym} ${W}%s${RS} ${D}%s${RS}\n" "$name" "$state"
      done
    else
      warn "PulseAudio: no sinks (audio not active)"
    fi
    local vol; vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1)
    [[ -n "$vol" ]] && ok "Volume: ${vol}"
  else
    warn "PulseAudio not found: pacman -S pulseaudio pulseaudio-bluetooth"
  fi
  echo ""
}

# ── Volume ────────────────────────────────────────────────────────
bt_vol() {
  local v="${1:-75}"
  if has_pulse; then
    pactl set-sink-volume @DEFAULT_SINK@ "${v}%" 2>/dev/null && ok "Volume → ${v}%"
  else
    warn "PulseAudio not running"
  fi
}

# ── Install BT stack (inside Arch proot) ─────────────────────────
bt_install() {
  info "Installing Bluetooth + audio stack..."
  pacman -S --noconfirm --needed \
    bluez bluez-utils bluez-tools \
    pulseaudio pulseaudio-bluetooth \
    pavucontrol alsa-utils \
    2>/dev/null && ok "BT + audio stack installed" || warn "Some packages skipped"

  # Enable BT service
  if command -v systemctl >/dev/null 2>&1; then
    systemctl start bluetooth 2>/dev/null && ok "bluetooth.service started"
  elif command -v bluetoothd >/dev/null 2>&1; then
    bluetoothd -n 2>/dev/null & ok "bluetoothd started"
  fi
  ok "Run: bt scan  →  bt connect"
}

# ── Test audio ───────────────────────────────────────────────────
bt_test() {
  info "Playing test tone..."
  if command -v speaker-test >/dev/null 2>&1; then
    timeout 2 speaker-test -t sine -f 440 -l 1 2>/dev/null && ok "Audio test OK"
  elif command -v paplay >/dev/null 2>&1; then
    # Generate a short WAV with python3 and play it
    python3 -c "
import wave, struct, math, tempfile, os, subprocess
fn = '/tmp/pb_test.wav'
with wave.open(fn, 'w') as wf:
    wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(44100)
    for i in range(22050):
        v = int(16000 * math.sin(2*math.pi*440*i/44100))
        wf.writeframes(struct.pack('<h', v))
subprocess.run(['paplay', fn])
os.unlink(fn)
" 2>/dev/null && ok "Audio test OK via paplay" || warn "paplay test failed"
  else
    warn "No audio test tool available"
  fi
}

# ── Interactive menu ─────────────────────────────────────────────
bt_menu() {
  banner
  echo "  ${W}[1]${RS} ${C}Scan${RS}        scan for BT devices"
  echo "  ${W}[2]${RS} ${C}Connect${RS}     connect HOCO EQ3 (auto)"
  echo "  ${W}[3]${RS} ${C}Status${RS}      BT + audio status"
  echo "  ${W}[4]${RS} ${C}Volume${RS}      set volume (0-100)"
  echo "  ${W}[5]${RS} ${C}Test${RS}        play test tone"
  echo "  ${W}[6]${RS} ${C}Install${RS}     install BT+audio stack"
  echo "  ${W}[q]${RS} ${D}quit${RS}"
  echo ""
  printf "  ${M}bt ❯${RS} "
  read -r choice
  case "$choice" in
    1) has_bluetoothctl && bt_scan_bluez || bt_scan_termux ;;
    2) setup_pulse; has_bluetoothctl && bt_connect_bluez || echo "  Use Android Bluetooth settings to pair" ;;
    3) bt_status ;;
    4) printf "  Volume (0-100): "; read -r v; bt_vol "$v" ;;
    5) bt_test ;;
    6) bt_install ;;
    q|Q) return 0 ;;
    *) warn "Invalid choice" ;;
  esac
}

# ── Entry ─────────────────────────────────────────────────────────
CMD="${1:-menu}"
shift 2>/dev/null || true
case "$CMD" in
  menu)    bt_menu ;;
  scan)    has_bluetoothctl && bt_scan_bluez || bt_scan_termux ;;
  connect) setup_pulse; has_bluetoothctl && bt_connect_bluez "$@" || echo "  Pair via Android Bluetooth settings, then: bt status" ;;
  status)  bt_status ;;
  vol)     bt_vol "${1:-75}" ;;
  test)    bt_test ;;
  install) bt_install ;;
  *)       bt_menu ;;
esac
