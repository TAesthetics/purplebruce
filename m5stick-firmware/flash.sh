#!/usr/bin/env bash
# Purple Bruce M5Stick — Termux Flash Script
#
# Detects the environment (Termux / Linux desktop) and flashes
# the compiled firmware to the M5Stick over USB-C.
#
# Non-root Termux users: use the web flash method (node serve.js)
# unless termux-usb is available — see README.md.
#
# Usage:
#   chmod +x flash.sh
#   ./flash.sh                    # auto-detect port
#   ./flash.sh /dev/ttyUSB0      # explicit port
#   ./flash.sh --build-only      # compile without flashing (Arduino CLI)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKETCH_DIR="$SCRIPT_DIR/purplebruce-m5stick"
FIRMWARE_BIN="$SCRIPT_DIR/web-flash/purplebruce-m5stick.merged.bin"
BAUD=1500000

# ── Colors ─────────────────────────────────────────────────────
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YLW=$'\033[0;33m'
CYN=$'\033[0;36m'; MAG=$'\033[0;35m'; RST=$'\033[0m'

banner() {
  echo ""
  echo "${MAG}  ⛧  PURPLE BRUCE M5Stick Flasher  ⛧${RST}"
  echo "${MAG}  ──────────────────────────────────${RST}"
  echo ""
}

die() { echo "${RED}[✗] $*${RST}" >&2; exit 1; }
ok()  { echo "${GRN}[✔] $*${RST}"; }
inf() { echo "${CYN}[·] $*${RST}"; }
warn(){ echo "${YLW}[!] $*${RST}"; }

banner

BUILD_ONLY=false
EXPLICIT_PORT=""
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    /dev/*)       EXPLICIT_PORT="$arg" ;;
  esac
done

# ── Detect environment ─────────────────────────────────────────
IS_TERMUX=false
[[ -d /data/data/com.termux ]] && IS_TERMUX=true

# ── Detect serial port ─────────────────────────────────────────
detect_port() {
  if [[ -n "$EXPLICIT_PORT" ]]; then
    echo "$EXPLICIT_PORT"; return
  fi
  for p in /dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyACM0 /dev/ttyACM1; do
    [[ -e "$p" ]] && { echo "$p"; return; }
  done
  # Termux: check /dev/bus/usb for serial adapters (CP2104)
  if $IS_TERMUX && command -v termux-usb &>/dev/null; then
    inf "Checking USB devices via termux-usb..."
    termux-usb -l 2>/dev/null | head -5 || true
    echo ""
    warn "No /dev/ttyUSB* found — use web flash instead:"
    warn "  node serve.js  →  open http://localhost:8080 in Chrome"
    echo ""
    exit 1
  fi
  die "No serial port found. Connect M5Stick via USB-C and retry."
}

# ── Method 1: esptool.py ───────────────────────────────────────
flash_esptool() {
  local port="$1"
  command -v esptool.py &>/dev/null || command -v esptool &>/dev/null \
    || die "esptool not found. Install: pip install esptool"

  local tool; tool=$(command -v esptool.py 2>/dev/null || command -v esptool)

  [[ -f "$FIRMWARE_BIN" ]] \
    || die "Compiled binary not found at: $FIRMWARE_BIN\n  Run './flash.sh --build-only' first or compile via Arduino IDE."

  inf "Flashing via esptool to $port ..."
  "$tool" \
    --port "$port" \
    --baud "$BAUD" \
    --chip esp32 \
    --before default_reset \
    --after  hard_reset \
    write_flash -z \
    --flash_mode dio \
    --flash_freq 80m \
    --flash_size 4MB \
    0x0 "$FIRMWARE_BIN"

  ok "Flash complete! Power-cycle or press reset on the M5Stick."
}

# ── Method 2: Arduino CLI ──────────────────────────────────────
flash_arduino_cli() {
  local port="$1"
  command -v arduino-cli &>/dev/null \
    || die "arduino-cli not found. See README.md → Install Arduino CLI"

  local fqbn="esp32:esp32:m5stick-c-plus"
  inf "Compiling sketch with arduino-cli (FQBN: $fqbn)..."

  arduino-cli compile \
    --fqbn "$fqbn" \
    --output-dir "$SCRIPT_DIR/build" \
    "$SKETCH_DIR"

  # also export merged binary for web-flash
  local built_bin
  built_bin=$(find "$SCRIPT_DIR/build" -name "*.merged.bin" | head -1)
  if [[ -n "$built_bin" ]]; then
    cp "$built_bin" "$FIRMWARE_BIN"
    ok "Merged binary saved to web-flash/ for web flash method"
  fi

  if $BUILD_ONLY; then
    ok "Build complete. Binary in $SCRIPT_DIR/build/"
    return
  fi

  inf "Uploading to $port ..."
  arduino-cli upload \
    --fqbn "$fqbn" \
    --port "$port" \
    --input-dir "$SCRIPT_DIR/build"

  ok "Flash complete! Power-cycle or press reset on the M5Stick."
}

# ── Main flow ──────────────────────────────────────────────────
if $BUILD_ONLY; then
  flash_arduino_cli "unused"
  exit 0
fi

PORT=$(detect_port)
inf "Using port: $PORT"
echo ""

# Prefer arduino-cli (compiles + uploads in one step)
if command -v arduino-cli &>/dev/null; then
  flash_arduino_cli "$PORT"
elif command -v esptool.py &>/dev/null || command -v esptool &>/dev/null; then
  flash_esptool "$PORT"
else
  echo ""
  warn "No flash tool found."
  echo ""
  echo "  Option A — install Arduino CLI (Termux):"
  echo "    See README.md → Method 2"
  echo ""
  echo "  Option B — install esptool (Termux):"
  echo "    pip install esptool"
  echo ""
  echo "  Option C — Web flash (no root, no tools needed):"
  echo "    node serve.js  →  open http://localhost:8080 in Chrome"
  echo ""
  exit 1
fi
