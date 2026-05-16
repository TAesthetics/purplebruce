#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  PURPLE BRUCE LUCY — TUI Dashboard v7.0                             ║
# ║  Layer 1 (Termux) · Layer 2 (Arch/BlackArch proot)                  ║
# ║  Pure bash + ANSI — no ncurses required                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -uo pipefail

PB_PORT="${PURPLEBRUCE_PORT:-3000}"
PB_DIR="${PURPLEBRUCE_DIR:-$HOME/purplebruce}"
REFRESH=3  # seconds between auto-refresh

# ── ANSI palette ─────────────────────────────────────────────────────────────
RS=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

# 256-color palette
V=$'\033[38;5;135m'    # violet
C=$'\033[38;5;51m'     # cyan
G=$'\033[38;5;46m'     # green
Y=$'\033[38;5;220m'    # gold/yellow
M=$'\033[38;5;201m'    # magenta
R=$'\033[38;5;196m'    # red
D=$'\033[38;5;240m'    # dark grey
W=$'\033[1;37m'        # bright white
BK=$'\033[38;5;233m'   # near-black (for box interiors)

BG_S=$'\033[48;5;17m'  # deep-blue selection bg
BG_H=$'\033[48;5;53m'  # violet header bg

# box-drawing
TL='╭' TR='╮' BL='╰' BR='╯' H='─' V_='│' T='├' TE='┤' TT='┬' TB='┴' X='┼'

# ── terminal sizing ───────────────────────────────────────────────────────────
cols() { tput cols 2>/dev/null || echo 80; }
rows() { tput lines 2>/dev/null || echo 24; }

COLS=$(cols); ROWS=$(rows)

# ── cursor/screen helpers ─────────────────────────────────────────────────────
hide_cursor()  { printf '\033[?25l'; }
show_cursor()  { printf '\033[?25h'; }
clear_screen() { printf '\033[2J\033[H'; }
move()         { printf '\033[%d;%dH' "$1" "$2"; }   # row col (1-based)
save_pos()     { printf '\033[s'; }
restore_pos()  { printf '\033[u'; }

# ── environment detection ─────────────────────────────────────────────────────
detect_layer() {
  if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
    echo "LAYER_1"
  elif grep -qi "arch\|blackarch" /etc/os-release 2>/dev/null; then
    echo "LAYER_2"
  elif grep -qi "kali" /etc/os-release 2>/dev/null; then
    echo "LAYER_2K"
  else
    echo "LAYER_1"
  fi
}

LAYER=$(detect_layer)
case "$LAYER" in
  LAYER_2)  LAYER_LABEL="Layer 2 — BlackArch proot" ;;
  LAYER_2K) LAYER_LABEL="Layer 2 — NetHunter proot" ;;
  *)        LAYER_LABEL="Layer 1 — Termux"           ;;
esac

# ── API helpers ───────────────────────────────────────────────────────────────
_api() {
  curl -sf --max-time 2 "http://127.0.0.1:${PB_PORT}${1}" 2>/dev/null || echo ""
}
_json() {
  local resp="$1" key="$2"
  echo "$resp" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  keys='$key'.split('.')
  for k in keys:
    if isinstance(d,dict): d=d.get(k,'')
    elif isinstance(d,list) and k.isdigit(): d=d[int(k)]
    else: d=''
  print(d if d is not None else '')
except: print('')
" 2>/dev/null
}

# ── drawing primitives ────────────────────────────────────────────────────────
repeat_char() {
  local ch="$1" n="$2"
  printf '%*s' "$n" '' | tr ' ' "$ch"
}

# hline: draw a horizontal line segment (no box chars)
hline() {
  local n="${1:-$COLS}"
  repeat_char "$H" "$n"
}

# box_row: padded content row  │ content… spaces │
box_row() {
  local w="${1:-$COLS}" content="$2" color="${3:-}"
  local visible; visible=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n')
  local vlen=${#visible}
  local pad=$(( w - vlen - 2 ))
  [[ $pad -lt 0 ]] && pad=0
  printf "${D}${V_}${RS}${color}%s%${pad}s${RS}${D}${V_}${RS}\n" "$content" ""
}

# ── status fetching ───────────────────────────────────────────────────────────
fetch_status() {
  HEALTH=$(_api "/api/health")
  SERVER_UP=$([ -n "$HEALTH" ] && echo "1" || echo "0")
  SERVER_VER=$(_json "$HEALTH" "version")
  SERVER_UPTIME=$(_json "$HEALTH" "uptime")
  PROVIDER=$(_json "$HEALTH" "provider")
  DRONE_CONN=$(_json "$HEALTH" "drone.connected")
  DRONE_IP=$(_json "$HEALTH" "drone.ip")
  DRONE_BAT=$(_json "$HEALTH" "drone.telemetry.battery")
  # AI key checks from health endpoint
  GROK_OK=$(_json "$HEALTH" "providers.grok")
  CLAUDE_OK=$(_json "$HEALTH" "providers.claude")
  VENICE_OK=$(_json "$HEALTH" "providers.venice")
  GEMINI_OK=$(_json "$HEALTH" "providers.gemini")
  OR_OK=$(_json "$HEALTH" "providers.openrouter")
  OC_OK=$(_json "$HEALTH" "providers.openclaw")
}

# system stats (safe — works in proot/Termux)
fetch_sys() {
  MEM_USED=""
  MEM_TOTAL=""
  CPU_PCT=""
  DISK_USED=""
  DISK_TOTAL=""

  if command -v free >/dev/null 2>&1; then
    local mem; mem=$(free -m 2>/dev/null | awk '/^Mem/{printf "%d/%d MB",$3,$2}')
    MEM_USED=$(echo "$mem" | cut -d'/' -f1)
    MEM_TOTAL=$(free -m 2>/dev/null | awk '/^Mem/{print $2}')
  fi
  if [ -f /proc/stat ]; then
    # simple one-shot CPU
    local s1 s2 idle1 idle2 total1 total2
    s1=$(awk '/^cpu /{print}' /proc/stat 2>/dev/null)
    sleep 0.15
    s2=$(awk '/^cpu /{print}' /proc/stat 2>/dev/null)
    idle1=$(echo "$s1" | awk '{print $5}')
    idle2=$(echo "$s2" | awk '{print $5}')
    total1=$(echo "$s1" | awk '{s=0;for(i=2;i<=NF;i++)s+=$i;print s}')
    total2=$(echo "$s2" | awk '{s=0;for(i=2;i<=NF;i++)s+=$i;print s}')
    local dtotal=$(( total2 - total1 ))
    local didle=$(( idle2 - idle1 ))
    [[ $dtotal -gt 0 ]] && CPU_PCT=$(( (dtotal - didle) * 100 / dtotal )) || CPU_PCT=0
  fi
  if command -v df >/dev/null 2>&1; then
    DISK_USED=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $3}')
    DISK_TOTAL=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $2}')
  fi
}

# BlackArch / Layer 2 tool check
fetch_tools() {
  TOOLS_OK=()
  TOOLS_MISSING=()
  local check_list=(nmap masscan ffuf gobuster nuclei sqlmap hydra hashcat msfconsole radare2 wireshark)
  for t in "${check_list[@]}"; do
    if command -v "$t" >/dev/null 2>&1; then
      TOOLS_OK+=("$t")
    else
      TOOLS_MISSING+=("$t")
    fi
  done
}

# ── format helpers ────────────────────────────────────────────────────────────
prov_badge() {
  local name="$1" ok="$2"
  if [ "$ok" = "true" ] || [ "$ok" = "1" ]; then
    printf "${G}✔${RS} ${W}%-10s${RS}" "$name"
  else
    printf "${D}✘ %-10s${RS}" "$name"
  fi
}

srv_uptime() {
  local s="${SERVER_UPTIME:-0}"
  s=$(echo "$s" | python3 -c "import sys; v=sys.stdin.read().strip(); print(int(float(v)) if v else 0)" 2>/dev/null || echo 0)
  local h=$(( s / 3600 ))
  local m=$(( (s % 3600) / 60 ))
  local sec=$(( s % 60 ))
  printf '%dh %02dm %02ds' "$h" "$m" "$sec"
}

bar() {
  local val="${1:-0}" max="${2:-100}" width="${3:-20}" color="${4:-$G}"
  local filled=$(( val * width / max ))
  [[ $filled -gt $width ]] && filled=$width
  local empty=$(( width - filled ))
  printf "${color}%s${D}%s${RS}" "$(repeat_char '█' "$filled")" "$(repeat_char '░' "$empty")"
}

# ── top bar ───────────────────────────────────────────────────────────────────
draw_topbar() {
  local w=$COLS
  local ts; ts=$(date '+%H:%M:%S')
  local conn_txt; conn_txt=$([ "$SERVER_UP" = "1" ] && echo "${G}● ONLINE${RS}" || echo "${R}○ OFFLINE${RS}")
  local layer_col
  case "$LAYER" in LAYER_2*) layer_col="$C" ;; *) layer_col="$M" ;; esac

  printf "${BG_H}${V}  ${BOLD}${W}PURPLE BRUCE LUCY${RS}${BG_H}  ${DIM}v7.0${RS}${BG_H}"
  printf '%*s' $(( w - 40 )) ""
  printf "${layer_col}%-30s${RS}${BG_H}  ${Y}%s${RS}${BG_H}  ${RS}\n" "$LAYER_LABEL" "$ts"
}

# ── header row ────────────────────────────────────────────────────────────────
draw_header() {
  local w=$COLS
  printf "${V}${TL}$(repeat_char "$H" $(( w - 2 )))${TR}${RS}\n"
}

draw_footer_line() {
  local w=$COLS
  printf "${V}${BL}$(repeat_char "$H" $(( w - 2 )))${BR}${RS}\n"
}

draw_section_sep() {
  local w=$COLS
  printf "${V}${T}$(repeat_char "$H" $(( w - 2 )))${TE}${RS}\n"
}

# ── SERVER panel ──────────────────────────────────────────────────────────────
render_server_panel() {
  local w=$COLS
  local half=$(( w / 3 ))

  if [ "$SERVER_UP" = "1" ]; then
    printf "  ${G}${BOLD}● SERVER ONLINE${RS}    ${D}port ${W}${PB_PORT}${RS}    ${D}ver ${W}${SERVER_VER:-?}${RS}\n"
    printf "  ${D}uptime${RS}  ${C}$(srv_uptime)${RS}\n"
  else
    printf "  ${R}${BOLD}○ SERVER OFFLINE${RS}\n"
    printf "  ${D}run ${W}pbstart${D} or ${W}go${D} to launch${RS}\n"
  fi
}

# ── AI PROVIDERS panel ────────────────────────────────────────────────────────
render_providers() {
  printf "  "
  prov_badge "GROK"       "$GROK_OK"
  printf "  "
  prov_badge "CLAUDE"     "$CLAUDE_OK"
  printf "  "
  prov_badge "VENICE"     "$VENICE_OK"
  printf "\n  "
  prov_badge "GEMINI"     "$GEMINI_OK"
  printf "  "
  prov_badge "OPENROUTER" "$OR_OK"
  printf "  "
  prov_badge "OPENCLAW"   "$OC_OK"
  printf "\n"
  printf "  ${D}active${RS}  ${V}${BOLD}${PROVIDER:-—}${RS}\n"
}

# ── SYSTEM panel ──────────────────────────────────────────────────────────────
render_sys() {
  if [ -n "$MEM_USED" ] && [ -n "$MEM_TOTAL" ] && [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null; then
    local pct=$(( MEM_USED * 100 / MEM_TOTAL ))
    printf "  ${D}MEM  ${RS}$(bar "$pct" 100 16)  ${W}%dMB${D}/%dMB${RS}\n" "$MEM_USED" "$MEM_TOTAL"
  fi
  if [ -n "${CPU_PCT:-}" ]; then
    printf "  ${D}CPU  ${RS}$(bar "${CPU_PCT:-0}" 100 16)  ${W}%d%%${RS}\n" "${CPU_PCT:-0}"
  fi
  if [ -n "${DISK_USED:-}" ]; then
    printf "  ${D}DISK ${RS}${W}${DISK_USED}${D}/${DISK_TOTAL} used${RS}\n"
  fi
}

# ── DRONE panel ───────────────────────────────────────────────────────────────
render_drone() {
  if [ "$DRONE_CONN" = "true" ] || [ "$DRONE_CONN" = "1" ]; then
    printf "  ${G}${BOLD}● DRONE LINKED${RS}  ${D}ip${RS} ${C}${DRONE_IP}${RS}\n"
    if [ -n "$DRONE_BAT" ]; then
      local bat; bat=$(echo "$DRONE_BAT" | python3 -c "import sys; v=sys.stdin.read().strip(); print(int(float(v))) if v else print(0)" 2>/dev/null || echo 0)
      local bcol; [[ $bat -lt 10 ]] && bcol="$R" || { [[ $bat -lt 25 ]] && bcol="$Y" || bcol="$G"; }
      printf "  ${D}bat  ${RS}$(bar "$bat" 100 16 "$bcol")  ${bcol}${bat}%%${RS}\n"
    fi
  else
    printf "  ${D}○ No drone connected${RS}\n"
    printf "  ${D}run ${W}drone-bridge${D} or ${W}drone${D} to pair${RS}\n"
  fi
}

# ── LAYER 2 TOOLS panel ───────────────────────────────────────────────────────
render_tools() {
  local per_row=4
  local idx=0
  for t in "${TOOLS_OK[@]+"${TOOLS_OK[@]}"}"; do
    printf "  ${G}✔${RS} ${W}%-14s${RS}" "$t"
    idx=$(( idx + 1 ))
    [[ $(( idx % per_row )) -eq 0 ]] && printf "\n"
  done
  for t in "${TOOLS_MISSING[@]+"${TOOLS_MISSING[@]}"}"; do
    printf "  ${D}✘ %-14s${RS}" "$t"
    idx=$(( idx + 1 ))
    [[ $(( idx % per_row )) -eq 0 ]] && printf "\n"
  done
  [[ $(( idx % per_row )) -ne 0 ]] && printf "\n"
  if [ ${#TOOLS_OK[@]} -gt 0 ] || [ ${#TOOLS_MISSING[@]} -gt 0 ]; then
    printf "  ${D}${#TOOLS_OK[@]} ready · ${#TOOLS_MISSING[@]} missing${RS}  ${D}(pacman -S <tool> to install)${RS}\n"
  fi
}

# ── QUICK ACTIONS bar ─────────────────────────────────────────────────────────
render_actions() {
  local w=$COLS
  if [ "$SERVER_UP" = "1" ]; then
    printf "  ${G}[s]${RS} ${W}STOP${RS}   ${Y}[r]${RS} ${W}RESTART${RS}   ${C}[l]${RS} ${W}LOGS${RS}   ${V}[b]${RS} ${W}BROWSER${RS}   ${D}[R]${RS} ${W}REFRESH${RS}   ${R}[q]${RS} ${W}QUIT${RS}\n"
  else
    printf "  ${G}[s]${RS} ${W}START${RS}   ${D}[r] RESTART${RS}   ${C}[l]${RS} ${W}LOGS${RS}   ${D}[b] BROWSER${RS}   ${D}[R]${RS} ${W}REFRESH${RS}   ${R}[q]${RS} ${W}QUIT${RS}\n"
  fi
  if [[ "$LAYER" == LAYER_2* ]]; then
    printf "  ${D}[t]${RS} ${W}TOOLCHECK${RS}  ${D}[u]${RS} ${W}UPDATE${RS}  ${D}[d]${RS} ${W}DRONE BRIDGE${RS}  ${D}[f]${RS} ${W}FLASH BRUCE${RS}\n"
  fi
}

# ── FULL DRAW ─────────────────────────────────────────────────────────────────
draw() {
  COLS=$(cols)
  clear_screen
  move 1 1

  draw_topbar
  draw_header

  # row 1: server + provider + system
  echo ""
  printf "  ${V}${BOLD}SERVER${RS}\n"
  render_server_panel
  draw_section_sep

  echo ""
  printf "  ${C}${BOLD}AI PROVIDERS${RS}\n"
  render_providers
  draw_section_sep

  echo ""
  printf "  ${M}${BOLD}SYSTEM${RS}\n"
  render_sys
  draw_section_sep

  echo ""
  printf "  ${Y}${BOLD}DRONE${RS}\n"
  render_drone

  if [[ "$LAYER" == LAYER_2* ]]; then
    draw_section_sep
    echo ""
    printf "  ${G}${BOLD}BLACKARCH ARSENAL${RS}\n"
    render_tools
  fi

  draw_section_sep
  echo ""
  render_actions
  draw_footer_line

  printf "\n  ${D}auto-refresh in ${REFRESH}s · %s${RS}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
}

# ── INPUT HANDLER ─────────────────────────────────────────────────────────────
handle_key() {
  local key="$1"
  case "$key" in
    q|Q)
      show_cursor; clear_screen; echo -e "${V}  bye.${RS}"; exit 0 ;;
    s)
      if [ "$SERVER_UP" = "1" ]; then
        pkill -f "node server.js" 2>/dev/null
        sleep 0.5
      else
        _start_server
      fi ;;
    S)
      pkill -f "node server.js" 2>/dev/null ;;
    r|R_lower)
      pkill -f "node server.js" 2>/dev/null; sleep 1; _start_server ;;
    $'\x0c'|R)
      # Ctrl-L or R = refresh immediately
      : ;;
    l)
      show_cursor; clear_screen
      echo -e "${C}  [logs — Ctrl-C to return]${RS}"
      tail -f "${HOME}/.purplebruce/audit.log" 2>/dev/null || \
        tail -f "${PB_DIR}/server.log" 2>/dev/null || \
        echo "  No log file found."
      hide_cursor ;;
    b)
      # try to open browser
      if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "http://127.0.0.1:${PB_PORT}" 2>/dev/null &
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "http://127.0.0.1:${PB_PORT}" 2>/dev/null &
      fi ;;
    d)
      show_cursor; clear_screen
      echo -e "${Y}  [drone bridge — Ctrl-C to return]${RS}"
      python3 "${PB_DIR}/netrunner/drone/mini4k.py" 2>&1 || echo "  Failed to start drone bridge."
      hide_cursor ;;
    f)
      show_cursor; clear_screen
      bash "${PB_DIR}/netrunner/firmware/flash-bruce.sh"
      echo -e "  ${D}Press any key to return...${RS}"; read -rsn1
      hide_cursor ;;
    u)
      show_cursor; clear_screen
      echo -e "${C}  [update — pulling latest + npm install]${RS}"
      (cd "${PB_DIR}" && git pull origin main && npm install)
      echo -e "\n  ${D}Press any key to return...${RS}"; read -rsn1
      hide_cursor ;;
    t)
      show_cursor; clear_screen
      echo -e "${G}  [toolcheck]${RS}\n"
      for t in nmap masscan ffuf gobuster feroxbuster nuclei sqlmap commix hydra hashcat john \
                msfconsole msfvenom searchsploit crackmapexec evil-winrm impacket-smbclient \
                bloodhound pwncat chisel radare2 gdb wireshark tshark binwalk exiftool \
                steghide aircrack-ng theharvester amass subfinder httpx; do
        if command -v "$t" >/dev/null 2>&1; then
          printf "  ${G}✔${RS} ${W}%-22s${RS}\n" "$t"
        else
          printf "  ${D}✘ %-22s${RS}\n" "$t"
        fi
      done
      echo -e "\n  ${D}Press any key to return...${RS}"; read -rsn1
      hide_cursor ;;
  esac
}

_start_server() {
  if command -v tmux >/dev/null 2>&1; then
    tmux new-session -d -s purplebruce -x 220 -y 50 2>/dev/null || true
    tmux send-keys -t purplebruce \
      "cd ${PB_DIR} && node server.js 2>&1 | tee ~/.purplebruce/server.log" Enter
  else
    mkdir -p "${HOME}/.purplebruce"
    (cd "${PB_DIR}" && node server.js >> "${HOME}/.purplebruce/server.log" 2>&1 &)
  fi
  sleep 1
}

# ── MAIN LOOP ─────────────────────────────────────────────────────────────────
main() {
  # dependency check
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 required for TUI (for JSON parsing). Install it first." >&2
    exit 1
  fi

  hide_cursor
  trap 'show_cursor; clear_screen; exit 0' INT TERM EXIT

  fetch_status
  fetch_sys &
  SYS_PID=$!
  [[ "$LAYER" == LAYER_2* ]] && { fetch_tools; }
  wait "$SYS_PID" 2>/dev/null || true
  draw

  local last_refresh; last_refresh=$(date +%s)

  while true; do
    # non-blocking read with timeout
    local key=""
    if read -rsn1 -t 0.3 key 2>/dev/null; then
      # check for ESC sequences (arrow keys)
      if [[ "$key" == $'\033' ]]; then
        local rest=""
        read -rsn2 -t 0.1 rest 2>/dev/null || true
        key="${key}${rest}"
      fi
      handle_key "$key"
      # after action, re-draw immediately
      fetch_status
      draw
      last_refresh=$(date +%s)
    fi

    # auto-refresh
    local now; now=$(date +%s)
    if (( now - last_refresh >= REFRESH )); then
      fetch_status
      fetch_sys &
      SYS_PID=$!
      [[ "$LAYER" == LAYER_2* ]] && fetch_tools
      wait "$SYS_PID" 2>/dev/null || true
      draw
      last_refresh=$now
    fi
  done
}

main "$@"
