#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  BRUCE FIRMWARE FLASHER — M5StickC Plus2                    ║
# ║  https://github.com/pr3y/Bruce                               ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   bash flash-bruce.sh                    # auto-detect port
#   bash flash-bruce.sh /dev/ttyUSB0       # specify port
#   bash flash-bruce.sh /dev/ttyUSB0 erase # erase flash first

set -uo pipefail

V='\033[38;5;135m'; C='\033[38;5;51m'; Y='\033[38;5;220m'
M='\033[38;5;201m'; G='\033[38;5;46m'; D='\033[38;5;240m'; RS='\033[0m'

ok()   { echo -e "  ${G}✔${RS}  ${C}${1}${RS}"; }
warn() { echo -e "  ${Y}⚠${RS}  ${1}"; }
info() { echo -e "  ${V}→${RS}  ${1}"; }
die()  { echo -e "  \033[31m✘ FATAL:${RS} ${1}"; exit 1; }
sep()  { echo -e "  ${D}──────────────────────────────────────────${RS}"; }

CHIP="esp32"
BAUD="${BRUCE_BAUD:-1500000}"
FLASH_ADDR="0x0"
BRUCE_REPO="pr3y/Bruce"
FW_DIR="${HOME}/.purplebruce/firmware"
PORT_ARG="${1:-}"
ERASE="${2:-}"

echo ""
echo -e "  ${M}╔══════════════════════════════════════════════╗${RS}"
echo -e "  ${M}║${RS}  ${C}⚡${RS}  ${V}BRUCE FIRMWARE — M5StickC Plus2${RS}      ${M}║${RS}"
echo -e "  ${M}╚══════════════════════════════════════════════╝${RS}"
echo ""

# ── 1. esptool ────────────────────────────────────────────────────
info "Checking for esptool..."
if ! command -v esptool.py >/dev/null 2>&1 && ! python3 -m esptool --version >/dev/null 2>&1; then
  warn "esptool not found — installing..."
  if command -v pacman >/dev/null 2>&1; then
    pacman -S --noconfirm --needed python-esptool 2>/dev/null \
      || pip install esptool --break-system-packages 2>/dev/null \
      || pip install esptool 2>/dev/null \
      || die "Could not install esptool — run: pip install esptool"
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install esptool --break-system-packages 2>/dev/null \
      || pip3 install esptool 2>/dev/null \
      || die "Could not install esptool — run: pip3 install esptool"
  elif command -v pip >/dev/null 2>&1; then
    pip install esptool 2>/dev/null \
      || die "Could not install esptool — run: pip install esptool"
  else
    die "pip not found. Install python3-pip first, then: pip install esptool"
  fi
fi

# resolve esptool command
if command -v esptool.py >/dev/null 2>&1; then
  ESPTOOL="esptool.py"
else
  ESPTOOL="python3 -m esptool"
fi
ok "esptool ready ($($ESPTOOL version 2>&1 | head -1))"

# ── 2. Serial port ────────────────────────────────────────────────
sep
info "Detecting serial port..."

detect_port() {
  # Common USB-serial adapters on Linux/Android
  for pat in /dev/ttyUSB* /dev/ttyACM* /dev/tty.usbserial* /dev/tty.SLAB_USB*; do
    for p in $pat; do
      [ -e "$p" ] && echo "$p" && return 0
    done
  done
  return 1
}

if [ -n "$PORT_ARG" ]; then
  PORT="$PORT_ARG"
  [ -e "$PORT" ] || die "Port not found: $PORT"
  ok "Using port: $PORT"
else
  PORT=$(detect_port) || true
  if [ -z "${PORT:-}" ]; then
    echo ""
    echo -e "  ${Y}No device detected automatically.${RS}"
    echo -e "  ${D}Connect M5StickC Plus2 via USB, then:${RS}"
    echo -e "    ${C}ls /dev/ttyUSB* /dev/ttyACM*${RS}"
    echo ""
    printf "  Enter port manually: "
    read -r PORT
    [ -n "$PORT" ] || die "No port specified"
    [ -e "$PORT" ] || die "Port not found: $PORT"
  else
    ok "Auto-detected: $PORT"
  fi
fi

# Android proot: check USB access
if [ ! -r "$PORT" ] || [ ! -w "$PORT" ]; then
  warn "No read/write access to $PORT"
  echo -e "  ${D}Try one of:${RS}"
  echo -e "    ${C}chmod 666 $PORT${RS}        ${D}(if root)${RS}"
  echo -e "    ${C}usermod -aG dialout \$USER${RS} ${D}(Linux)${RS}"
  echo -e "  ${D}On Android proot you may need to run from Termux (not proot).${RS}"
  echo ""
  printf "  Continue anyway? [y/N] "
  read -r yn
  [[ "$yn" =~ ^[Yy]$ ]] || exit 0
fi

# ── 3. Download latest Bruce firmware ────────────────────────────
sep
info "Fetching latest Bruce release from GitHub..."
mkdir -p "$FW_DIR"

API_URL="https://api.github.com/repos/${BRUCE_REPO}/releases/latest"

# wget preferred (curl has ARM64 ngtcp2 bug on Android proot)
if command -v wget >/dev/null 2>&1; then
  RELEASE_JSON=$(wget -qO- "$API_URL" 2>/dev/null) || RELEASE_JSON=""
elif command -v curl >/dev/null 2>&1; then
  RELEASE_JSON=$(curl -sf "$API_URL" 2>/dev/null) || RELEASE_JSON=""
else
  die "Neither wget nor curl found"
fi

[ -n "$RELEASE_JSON" ] || die "Could not fetch release info from GitHub"

# Parse release tag and find M5StickCPlus2 asset
RELEASE_TAG=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tag_name','unknown'))
" 2>/dev/null) || RELEASE_TAG="unknown"

# Find the M5StickCPlus2 binary URL — tries multiple naming conventions
FW_URL=$(echo "$RELEASE_JSON" | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
patterns = [
    r'(?i)m5stickc.?plus2',
    r'(?i)m5stickc_plus2',
    r'(?i)m5stickCplus2',
]
for a in d.get('assets', []):
    name = a.get('name','')
    for pat in patterns:
        if re.search(pat, name) and name.endswith('.bin'):
            print(a['browser_download_url'])
            sys.exit(0)
print('')
" 2>/dev/null) || FW_URL=""

if [ -z "$FW_URL" ]; then
  # Fallback: list all .bin assets for user to pick
  echo ""
  warn "Could not auto-match M5StickCPlus2 binary. Available assets:"
  echo "$RELEASE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for i, a in enumerate(d.get('assets',[])):
    if a['name'].endswith('.bin'):
        print(f'  [{i}] {a[\"name\"]}')
        print(f'      {a[\"browser_download_url\"]}')
" 2>/dev/null
  echo ""
  printf "  Paste the firmware URL to use: "
  read -r FW_URL
  [ -n "$FW_URL" ] || die "No URL provided"
fi

FW_NAME=$(basename "$FW_URL")
FW_PATH="${FW_DIR}/${FW_NAME}"

info "Release: $RELEASE_TAG"
info "Firmware: $FW_NAME"

if [ -f "$FW_PATH" ]; then
  ok "Already downloaded: $FW_PATH"
else
  info "Downloading..."
  if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$FW_PATH" "$FW_URL" 2>/dev/null \
      || wget -q -O "$FW_PATH" "$FW_URL" \
      || die "Download failed"
  else
    curl -L --progress-bar -o "$FW_PATH" "$FW_URL" || die "Download failed"
  fi
  ok "Downloaded → $FW_PATH"
fi

# ── 4. Erase flash (optional) ─────────────────────────────────────
if [[ "${ERASE:-}" == "erase" ]]; then
  sep
  warn "Erasing flash on $PORT..."
  $ESPTOOL --chip $CHIP --port "$PORT" --baud "$BAUD" erase_flash \
    || die "Erase failed"
  ok "Flash erased"
fi

# ── 5. Flash ──────────────────────────────────────────────────────
sep
echo ""
echo -e "  ${M}Ready to flash:${RS}"
echo -e "    ${D}Device:${RS}   M5StickC Plus2"
echo -e "    ${D}Port:${RS}     $PORT"
echo -e "    ${D}Baud:${RS}     $BAUD"
echo -e "    ${D}Firmware:${RS} $FW_NAME"
echo -e "    ${D}Release:${RS}  $RELEASE_TAG"
echo ""
echo -e "  ${Y}Hold Button A (M5 button) while connecting USB to enter flash mode${RS}"
echo -e "  ${D}if the device is already connected, you can try flashing directly${RS}"
echo ""
printf "  Flash now? [Y/n] "
read -r yn
[[ "${yn:-y}" =~ ^[Nn]$ ]] && { echo "  Aborted."; exit 0; }

echo ""
info "Flashing Bruce $RELEASE_TAG → $PORT ..."
echo ""

$ESPTOOL \
  --chip "$CHIP" \
  --port "$PORT" \
  --baud "$BAUD" \
  write_flash \
  -z "$FLASH_ADDR" \
  "$FW_PATH"

EXIT=$?
echo ""
if [ $EXIT -eq 0 ]; then
  sep
  echo ""
  echo -e "  ${G}╔══════════════════════════════════════════════╗${RS}"
  echo -e "  ${G}║${RS}  ${C}⚡${RS}  ${V}Bruce firmware flashed!${RS}              ${G}║${RS}"
  echo -e "  ${G}╚══════════════════════════════════════════════╝${RS}"
  echo ""
  echo -e "  ${V}Next steps:${RS}"
  echo -e "    ${C}1.${RS} Unplug and replug the M5StickC Plus2"
  echo -e "    ${C}2.${RS} Bruce menu appears on screen"
  echo -e "    ${C}3.${RS} Button A = select · Button B = back"
  echo ""
  echo -e "  ${D}Firmware cached at: $FW_PATH${RS}"
  echo -e "  ${D}Bruce docs: https://github.com/pr3y/Bruce${RS}"
  echo ""
else
  die "Flash failed (exit $EXIT) — check USB cable and flash mode"
fi
