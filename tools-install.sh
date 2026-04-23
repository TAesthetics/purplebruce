#!/usr/bin/env bash
# tools-install.sh — install a pragmatic pentest toolkit inside proot-distro
# (Ubuntu / Kali / Arch / BlackArch) or native Linux. Idempotent, re-runnable.
#
# Usage:
#   ./tools-install.sh          # install core + extras for detected distro
#   ./tools-install.sh --core   # only the essentials (faster, smaller)
#   ./tools-install.sh --kali   # also pull Kali-only bundles (metasploit etc.)
#
# Runs as root (no sudo needed in proot-distro). Best-effort: missing packages
# are logged and skipped so one failure doesn't abort the whole run.

set -u

MODE="full"
case "${1:-}" in
  --core) MODE="core" ;;
  --kali) MODE="kali" ;;
  --full|"") MODE="full" ;;
  -h|--help) sed -n '1,15p' "$0"; exit 0 ;;
esac

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"
  else
    echo "[!] Not root and sudo missing. In proot-distro run as root."
    exit 1
  fi
fi

run() { echo "+ $*" >&2; "$@" || echo "[!] skipped (non-zero exit)" >&2; }

# ─── Detect package manager + distro ──────────────────────────────────────────
PM=""
if   command -v apt-get >/dev/null 2>&1; then PM="apt"
elif command -v pacman  >/dev/null 2>&1; then PM="pacman"
elif command -v dnf     >/dev/null 2>&1; then PM="dnf"
elif command -v zypper  >/dev/null 2>&1; then PM="zypper"
fi

IS_KALI=0; IS_BLACKARCH=0
[ -r /etc/os-release ] && . /etc/os-release || true
case "${ID:-}${ID_LIKE:-}" in
  *kali*) IS_KALI=1 ;;
esac
command -v pacman >/dev/null 2>&1 && pacman -Sl blackarch >/dev/null 2>&1 && IS_BLACKARCH=1

echo "[*] Package manager: ${PM:-none}"
echo "[*] Mode           : ${MODE}"
echo "[*] Kali detected  : $([ $IS_KALI -eq 1 ] && echo yes || echo no)"
echo "[*] BlackArch repo : $([ $IS_BLACKARCH -eq 1 ] && echo yes || echo no)"
echo ""

if [ -z "$PM" ]; then
  echo "[!] No supported package manager (apt/pacman/dnf/zypper)."
  exit 1
fi

# ─── Package lists ────────────────────────────────────────────────────────────
APT_CORE=(
  nmap masscan sqlmap hydra john ncrack
  dnsutils whois curl wget git ca-certificates
  build-essential python3 python3-pip python3-venv pipx
  netcat-openbsd iputils-ping openssh-client
)
APT_EXTRA=(
  aircrack-ng tshark nikto ffuf gobuster wfuzz
  hashcat binwalk exiftool tcpdump
  openvpn tor proxychains4 net-tools bind9-dnsutils
  jq ripgrep fd-find
)
APT_KALI_BUNDLE=(
  metasploit-framework theharvester crackmapexec enum4linux-ng wpscan
  dirb dirbuster sslscan amass
)

PAC_CORE=(
  nmap masscan sqlmap hydra john
  bind whois curl wget git ca-certificates
  base-devel python python-pip python-pipx
  gnu-netcat iputils openssh
)
PAC_EXTRA=(
  aircrack-ng wireshark-cli nikto ffuf gobuster wfuzz
  hashcat binwalk perl-image-exiftool tcpdump
  openvpn tor proxychains-ng net-tools
  jq ripgrep fd
)
BLACKARCH_BUNDLE=(
  metasploit theharvester enum4linux-ng crackmapexec wpscan
  sslscan amass
)

# ─── Install ──────────────────────────────────────────────────────────────────
install_apt() {
  run $SUDO apt-get update -y
  local pkgs=("${APT_CORE[@]}")
  if [ "$MODE" != "core" ]; then pkgs+=("${APT_EXTRA[@]}"); fi
  # Install one-by-one — missing/renamed packages won't kill the whole batch
  for p in "${pkgs[@]}"; do
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends "$p" \
      >/tmp/_apt.log 2>&1 || echo "[!] apt skipped: $p"
  done
  if [ "$MODE" = "kali" ] || [ "$IS_KALI" -eq 1 ]; then
    for p in "${APT_KALI_BUNDLE[@]}"; do
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends "$p" \
        >/tmp/_apt.log 2>&1 || echo "[!] apt skipped: $p"
    done
  fi
}

install_pacman() {
  run $SUDO pacman -Sy --noconfirm
  local pkgs=("${PAC_CORE[@]}")
  if [ "$MODE" != "core" ]; then pkgs+=("${PAC_EXTRA[@]}"); fi
  for p in "${pkgs[@]}"; do
    $SUDO pacman -S --needed --noconfirm "$p" >/tmp/_pac.log 2>&1 || echo "[!] pacman skipped: $p"
  done
  if [ "$IS_BLACKARCH" -eq 1 ]; then
    for p in "${BLACKARCH_BUNDLE[@]}"; do
      $SUDO pacman -S --needed --noconfirm "$p" >/tmp/_pac.log 2>&1 || echo "[!] pacman skipped: $p"
    done
  fi
}

install_dnf()    { echo "[!] dnf path not automated yet — install manually."; return 1; }
install_zypper() { echo "[!] zypper path not automated yet — install manually."; return 1; }

case "$PM" in
  apt)    install_apt ;;
  pacman) install_pacman ;;
  dnf)    install_dnf ;;
  zypper) install_zypper ;;
esac

# ─── Python extras (impacket etc.) via pipx when available ────────────────────
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1 || true
  for p in impacket updog; do
    pipx install "$p" >/dev/null 2>&1 || echo "[!] pipx skipped: $p"
  done
elif command -v python3 >/dev/null 2>&1; then
  python3 -m pip install --user --break-system-packages impacket updog 2>/dev/null \
    || python3 -m pip install --user impacket updog 2>/dev/null \
    || echo "[!] pip impacket/updog skipped"
fi

# ─── Report ──────────────────────────────────────────────────────────────────
echo ""
echo "[*] Installed tool versions:"
for t in nmap masscan sqlmap hydra john aircrack-ng tshark nikto ffuf gobuster hashcat binwalk tcpdump; do
  if command -v "$t" >/dev/null 2>&1; then
    v=$("$t" --version 2>&1 | head -1 | tr -d '\r')
    printf "   %-14s → %s\n" "$t" "$v"
  else
    printf "   %-14s → missing\n" "$t"
  fi
done

echo ""
echo "[✓] tools-install.sh done."
echo "    Re-run with --core for minimal, --kali to pull Kali-only bundles."
