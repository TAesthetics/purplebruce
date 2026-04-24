#!/usr/bin/env bash
# motd.sh — Cyberpunk netrunner banner. Prints top bar + ASCII logo + system info.
# Colors: 201=pink, 129=purple, 51=cyan, 226=yellow, 0=black.

set -u
ASSET_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGO="${ASSET_DIR}/logo.ascii"

c() { printf '\033[38;5;%sm' "$1"; }
R=$'\033[0m'
BOLD=$'\033[1m'
P=$(c 201)   # pink
V=$(c 129)   # purple
C=$(c 51)    # cyan
Y=$(c 226)   # yellow
DIM=$'\033[2m'

cols=$(tput cols 2>/dev/null || echo 80)
now=$(date '+%H:%M:%S')

# ── Top bar ────────────────────────────────────────────────────────────────
title="${BOLD}${P}█ PURPLE BRUCE v5.0 ${V}— ${C}LUCY EDITION ${P}█${R}"
plain_title="█ PURPLE BRUCE v5.0 — LUCY EDITION █"
pad=$(( cols - ${#plain_title} - ${#now} - 4 ))
(( pad < 2 )) && pad=2
printf "%b%*s%b%s%b\n" "$title" "$pad" " " "$C" "$now" "$R"
printf "%b" "$V"
printf '═%.0s' $(seq 1 "$cols")
printf "%b\n" "$R"

# ── Logo + system info side-by-side ────────────────────────────────────────
palette=(129 129 201 201 51 51 226 226 201 201 129 129 51 51 201 201 129 129 226 226)

os=$(grep -m1 PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
os=${os:-$(uname -s)}
kernel=$(uname -r)
uptime=$(uptime -p 2>/dev/null | sed 's/^up //' || uptime)
shell="${SHELL##*/}"
term="${TERM:-unknown}"
cpu=$(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null | sed 's/^[ \t]*//')
cpu=${cpu:-$(uname -m)}
mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3" / "$2}')
ip=$(hostname -I 2>/dev/null | awk '{print $1}')
ip=${ip:-127.0.0.1}

info=(
  "${P}${BOLD}$(whoami)${V}@${P}${BOLD}$(hostname)${R}"
  "${V}───────────────${R}"
  "${C}OS${R}      ${os}"
  "${C}Kernel${R}  ${kernel}"
  "${C}Uptime${R}  ${uptime}"
  "${C}Shell${R}   ${shell}"
  "${C}Term${R}    ${term}"
  "${C}CPU${R}     ${cpu}"
  "${C}Mem${R}     ${mem}"
  "${C}IP${R}      ${ip}"
  ""
  "${Y}${BOLD}FIDES ${P}• ${Y}${BOLD}MERCATUS ${P}• ${Y}${BOLD}LIBERTAS${R}"
)

if [ -f "$LOGO" ]; then
  mapfile -t logo_lines < "$LOGO"
else
  logo_lines=("[logo missing]")
fi

rows=${#logo_lines[@]}
(( ${#info[@]} > rows )) && rows=${#info[@]}

for ((i=0; i<rows; i++)); do
  line="${logo_lines[i]:-}"
  col=${palette[$((i % ${#palette[@]}))]}
  printf '%b%-26s%b  %s\n' "$(c "$col")" "$line" "$R" "${info[i]:-}"
done

printf "%b" "$V"
printf '═%.0s' $(seq 1 "$cols")
printf "%b\n" "$R"

# ── Command hint row ───────────────────────────────────────────────────────
printf '  %b%b netrunner%b   %b help%b   %b status%b   %b exit%b\n\n' \
  "$P" "$BOLD" "$R" "$C" "$R" "$Y" "$R" "$P" "$R"

# ── Pink blinking bar cursor ───────────────────────────────────────────────
printf '\033]12;#ff2bd6\007'   # OSC 12: cursor color
printf '\e[5 q'                # blinking bar shape
