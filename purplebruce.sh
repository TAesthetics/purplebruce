#!/bin/bash
# ═══════════════════════════════════════════════════════
#  purplebruce.sh v5.0 — JARVIS EDITION
#  Chat = Agent · SOC Analyst · Scope Lock · Audit Log
#  Purple Team CLI — syncs with Web UI
# ═══════════════════════════════════════════════════════

HIST="$HOME/.purple_history"
REPORT="$HOME/purple_report.txt"
GROK_KEY=""
VENICE_KEY=""
AI_PROVIDER="grok"
DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${PORT:-3000}"
SERVER_PID=""
API="http://127.0.0.1:$PORT/api/cli"

touch "$HIST"
[ -f "$HOME/.grok_key" ] && GROK_KEY="$(cat "$HOME/.grok_key")"
[ -f "$HOME/.venice_key" ] && VENICE_KEY="$(cat "$HOME/.venice_key")"
[ -f "$HOME/.ai_provider" ] && AI_PROVIDER="$(cat "$HOME/.ai_provider")"

R='\033[0;31m'; G='\033[0;32m'; B='\033[0;34m'; Y='\033[0;33m'
C='\033[0;36m'; M='\033[0;35m'; W='\033[1;37m'; D='\033[2m'; NC='\033[0m'

banner() {
  printf "${C}"
  cat << 'ASCII'
╔══════════════════════════════════════════════╗
║  ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗      ║
║  ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║      ║
║  ██████╔╝██║   ██║██████╔╝██████╔╝██║      ║
║  ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║      ║
║  ██║     ╚██████╔╝██║  ██║██║     ███████╗ ║
║  ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝ ║
║  ██████╗ ██████╗ ██╗   ██╗ ██████╗███████╗  ║
║  ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔════╝  ║
║  ██████╔╝██████╔╝██║   ██║██║     █████╗    ║
║  ██╔══██╗██╔══██╗██║   ██║██║     ██╔══╝    ║
║  ██████╔╝██║  ██║╚██████╔╝╚██████╗███████╗  ║
║  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝  ║
║          J A R V I S   v 5 . 0               ║
║     Chat = Agent · SOC Active · Scope: LAN   ║
╚══════════════════════════════════════════════╝
ASCII
  printf "${NC}\n"
  printf "  ${D}Host: ${W}%s${NC}  ${D}|  Time: ${W}%s${NC}\n" "$(hostname)" "$(date '+%H:%M:%S')"
  printf "  ${D}Scope: ${R}UNRESTRICTED — FULL SYSTEM ACCESS${NC}\n"
  printf "  ${D}Audit: ${Y}~/.purplebruce/audit.log${NC}\n"
  printf "  ${D}SOC:   ${C}Blue Team Analyst running in background${NC}\n\n"
}

show_help() {
  printf "\n  ${C}COMMANDS${NC}\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${G}purple scan${NC} <target>     ${D}│${NC} Port scan + SSL + headers\n"
  printf "  ${G}purple harden${NC}            ${D}│${NC} Security audit\n"
  printf "  ${G}purple hunt${NC}              ${D}│${NC} Threat hunting\n"
  printf "  ${G}purple report${NC}            ${D}│${NC} Save full report\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${M}(just type anything)${NC}     ${D}│${NC} → NetGhost Agent\n"
  printf "  ${M}chat${NC} \"message\"           ${D}│${NC} → NetGhost Agent\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${R}red emulate${NC} <tactic>     ${D}│${NC} MITRE ATT&CK emulation\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${M}autonomous on|off${NC}        ${D}│${NC} Toggle auto-exec\n"
  printf "  ${C}soc on|off${NC}               ${D}│${NC} Toggle SOC analyst\n"
  printf "  ${Y}abort${NC}                    ${D}│${NC} Stop running agent\n"
  printf "  ${Y}tasks${NC}                    ${D}│${NC} List tasks\n"
  printf "  ${Y}kill${NC} <id>                ${D}│${NC} Kill task\n"
  printf "  ${Y}settings${NC}                 ${D}│${NC} AI + keys config\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${W}history${NC} / ${W}clear${NC} / ${R}exit${NC}\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "\n  ${Y}RED TACTICS:${NC} cred-dump lateral c2-https ransomware fileless\n"
  printf "              sched-task dns-exfil persistence recon discovery exfiltration\n"
  printf "\n  ${M}★${NC} Just type naturally — NetGhost thinks, plans & executes.\n\n"
}

cleanup() {
  printf "\n  ${R}[SHUTDOWN]${NC} Killing server (PID: $SERVER_PID)...\n"
  [ -n "$SERVER_PID" ] && { kill "$SERVER_PID" 2>/dev/null; wait "$SERVER_PID" 2>/dev/null; } || true
  printf "  ${R}[SHUTDOWN]${NC} Purple Bruce offline. Stay frosty, choom.\n"
  exit 0
}
trap cleanup SIGINT SIGTERM

check_deps() {
  cd "$DIR"
  if [ ! -d "node_modules" ]; then
    printf "  ${Y}[SETUP]${NC} Installing dependencies...\n"
    npm install --silent 2>&1 | tail -3
    printf "  ${G}[SETUP]${NC} Done.\n"
  fi
}

start_server() {
  cd "$DIR"
  printf "  ${C}[BOOT]${NC} Starting server...\n"
  node server.js &
  SERVER_PID=$!
  local retries=0
  while ! curl -s "http://127.0.0.1:$PORT/api/status" > /dev/null 2>&1; do
    sleep 0.5; retries=$((retries + 1))
    [ $retries -gt 20 ] && { printf "  ${R}[ERROR]${NC} Server failed.\n"; exit 1; }
  done
  printf "\n"
  printf "  ${G}╔══════════════════════════════════════════════╗${NC}\n"
  printf "  ${G}║${NC}  ${W}JARVIS ONLINE${NC}   ${C}Chat = Agent${NC}                ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${C}Web UI:${NC}  ${W}http://127.0.0.1:${PORT}${NC}              ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${C}PID:${NC}     ${W}${SERVER_PID}${NC}                               ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${C}SOC:${NC}     ${W}Active — monitoring system${NC}           ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${Y}Scope:${NC}   ${W}localhost · LAN · own IP${NC}           ${G}║${NC}\n"
  printf "  ${G}╚══════════════════════════════════════════════╝${NC}\n\n"
}

sync_keys() {
  [ -n "$GROK_KEY" ] && curl -s -X POST "$API" -H "Content-Type: application/json" -d "{\"cmd\":\"set_key\",\"key\":\"$GROK_KEY\",\"provider\":\"grok\"}" > /dev/null 2>&1
  [ -n "$VENICE_KEY" ] && curl -s -X POST "$API" -H "Content-Type: application/json" -d "{\"cmd\":\"set_key\",\"key\":\"$VENICE_KEY\",\"provider\":\"venice\"}" > /dev/null 2>&1
  [ -n "$AI_PROVIDER" ] && curl -s -X POST "$API" -H "Content-Type: application/json" -d "{\"cmd\":\"set_provider\",\"provider\":\"$AI_PROVIDER\"}" > /dev/null 2>&1
}

cli_cmd() {
  local response
  response=$(curl -s -X POST "$API" -H "Content-Type: application/json" -d "$1" 2>/dev/null)
  [ $? -ne 0 ] && { printf "  ${R}[ERROR]${NC} Server unreachable.\n"; return; }
  echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if isinstance(data, dict) and 'lines' in data:
        for line in data['lines']:
            t = line.get('type', 'stdout')
            text = line.get('text', '')
            colors = {'error':'\033[0;31m','warn':'\033[0;33m','info':'\033[0;36m','cmd':'\033[1;37m','next':'\033[0;35m','stdout':'\033[2m','stderr':'\033[0;33m'}
            c = colors.get(t, '\033[2m')
            print(f'  {c}{text}\033[0m')
    elif isinstance(data, dict) and 'message' in data:
        print(f'  \033[0;36m{data[\"message\"]}\033[0m')
    elif isinstance(data, dict) and 'error' in data:
        print(f'  \033[0;31m{data[\"error\"]}\033[0m')
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                sid = item.get('id','?'); stype = item.get('type','?')
                label = item.get('label','?'); status = item.get('status','?')
                colors = {'running':'\033[0;32m','completed':'\033[2m','killed':'\033[0;31m','crashed':'\033[0;31m'}
                c = colors.get(status, '\033[2m')
                print(f'  {c}[{status.upper()}]\033[0m {sid}  {stype}  {label}')
    else: print(f'  {data}')
except Exception as e: print(str(e))
" 2>/dev/null || printf "  ${D}${response}${NC}\n"
}

do_scan() { local t="$1"; [ -z "$t" ] && { printf "  ${R}[!]${NC} Usage: purple scan <target>\n"; return; }; printf "  ${C}[RECON]${NC} Target: ${W}%s${NC}\n" "$t"; cli_cmd "{\"cmd\":\"scan\",\"target\":\"$t\",\"mode\":\"STANDARD\"}"; }
do_harden() { printf "  ${G}[FORTRESS]${NC} Running audit...\n"; cli_cmd '{"cmd":"harden"}'; }
do_hunt() { printf "  ${Y}[GHOST]${NC} Hunting...\n"; cli_cmd '{"cmd":"hunt"}'; }
do_report() {
  printf "  ${C}[REPORT]${NC} Generating...\n"; cli_cmd '{"cmd":"report"}'
  printf "========================================\n" > "$REPORT"
  printf "  PURPLE BRUCE v5.0 JARVIS REPORT\n" >> "$REPORT"
  printf "  Date: %s | Host: %s | User: %s\n" "$(date)" "$(hostname)" "$(whoami)" >> "$REPORT"
  printf "========================================\n\n" >> "$REPORT"
  printf "--- HARDEN ---\n" >> "$REPORT"
  curl -s -X POST "$API" -H "Content-Type: application/json" -d '{"cmd":"harden"}' 2>/dev/null | python3 -c "import sys,json;[print(l.get('text','')) for l in json.load(sys.stdin).get('lines',[])]" >> "$REPORT" 2>/dev/null
  printf "\n--- HUNT ---\n" >> "$REPORT"
  curl -s -X POST "$API" -H "Content-Type: application/json" -d '{"cmd":"hunt"}' 2>/dev/null | python3 -c "import sys,json;[print(l.get('text','')) for l in json.load(sys.stdin).get('lines',[])]" >> "$REPORT" 2>/dev/null
  printf "\n=== END ===\n" >> "$REPORT"
  printf "  ${G}[REPORT]${NC} Saved: ${W}%s${NC}\n" "$REPORT"
}
do_chat() {
  local msg="$1"; [ -z "$msg" ] && { printf "  ${R}[!]${NC} Type something.\n"; return; }
  printf "  ${M}[NETGHOST]${NC} 🧠 Thinking...\n"
  local json_msg; json_msg=$(echo "$msg" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null)
  cli_cmd "{\"cmd\":\"chat\",\"message\":$json_msg}"
}
do_emulate() {
  local tc="$1"; [ -z "$tc" ] && { printf "  ${R}[!]${NC} Usage: red emulate <tactic>\n"; return; }
  printf "  ${R}[BLACK ICE]${NC} Emulating ${W}%s${NC}...\n" "$tc"
  cli_cmd "{\"cmd\":\"red\",\"tactic\":\"$tc\"}"
}

do_settings() {
  printf "\n  ${C}╔══════════════════════════════════════════════╗${NC}\n"
  printf "  ${C}║${NC}  ${W}SETTINGS${NC}                                    ${C}║${NC}\n"
  printf "  ${C}╚══════════════════════════════════════════════╝${NC}\n\n"
  printf "  ${D}Provider: ${NC}${W}%s${NC}\n" "$AI_PROVIDER"
  printf "  ${D}Grok:     ${NC}%s\n" "$([ -n "$GROK_KEY" ] && echo "${G}SET${NC}" || echo "${R}NOT SET${NC}")"
  printf "  ${D}Venice:   ${NC}%s\n" "$([ -n "$VENICE_KEY" ] && echo "${G}SET${NC}" || echo "${R}NOT SET${NC}")"
  printf "\n  ${Y}1${NC}) Set Grok key  ${Y}2${NC}) Set Venice key  ${Y}3${NC}) Grok  ${Y}4${NC}) Venice  ${Y}0${NC}) Back\n\n  ${D}Select:${NC} "
  read -r choice
  case "$choice" in
    1) printf "  Grok key: "; read -r key; [ -n "$key" ] && { GROK_KEY="$key"; printf "%s" "$key" > "$HOME/.grok_key"; chmod 600 "$HOME/.grok_key"; cli_cmd "{\"cmd\":\"set_key\",\"key\":\"$key\",\"provider\":\"grok\"}"; printf "  ${G}[OK]${NC}\n"; } ;;
    2) printf "  Venice key: "; read -r key; [ -n "$key" ] && { VENICE_KEY="$key"; printf "%s" "$key" > "$HOME/.venice_key"; chmod 600 "$HOME/.venice_key"; cli_cmd "{\"cmd\":\"set_key\",\"key\":\"$key\",\"provider\":\"venice\"}"; printf "  ${G}[OK]${NC}\n"; } ;;
    3) AI_PROVIDER="grok"; printf "grok" > "$HOME/.ai_provider"; cli_cmd '{"cmd":"set_provider","provider":"grok"}'; printf "  ${G}[OK]${NC} Grok\n" ;;
    4) AI_PROVIDER="venice"; printf "venice" > "$HOME/.ai_provider"; cli_cmd '{"cmd":"set_provider","provider":"venice"}'; printf "  ${G}[OK]${NC} Venice\n" ;;
    *) ;;
  esac
}

# ══�� MAIN ═══
clear
banner
check_deps
start_server
sync_keys
show_help

while true; do
  printf "  ${R}pb${NC}${D}@${NC}${M}v5${NC} ${R}>${NC} "
  read -r cmd
  [ -z "$cmd" ] && continue
  echo "$cmd" >> "$HIST"
  set -- $cmd; c1="$1"; c2="$2"; c3="$3"

  case "$c1" in
    purple)
      case "$c2" in
        scan) do_scan "$c3" ;; harden) do_harden ;; hunt) do_hunt ;; report) do_report ;;
        chat) do_chat "$(echo "$cmd" | sed 's/^purple chat //')" ;;
        setkey) do_settings ;;
        *) printf "  ${R}[!]${NC} Unknown: purple %s\n" "$c2" ;;
      esac ;;
    red) [ "$c2" = "emulate" ] && do_emulate "$c3" || printf "  ${R}[!]${NC} Usage: red emulate <tactic>\n" ;;
    chat) do_chat "$(echo "$cmd" | sed 's/^chat //')" ;;
    autonomous)
      amode="$(echo "$c2" | tr '[:upper:]' '[:lower:]')"
      case "$amode" in
        on) printf "  ${M}[AGENT]${NC} ${G}AUTONOMOUS ON${NC}\n"; cli_cmd '{"cmd":"autonomous","mode":"on"}' ;;
        off) printf "  ${M}[AGENT]${NC} ${R}AUTONOMOUS OFF${NC}\n"; cli_cmd '{"cmd":"autonomous","mode":"off"}' ;;
        *) printf "  ${R}[!]${NC} autonomous on|off\n" ;;
      esac ;;
    soc)
      smode="$(echo "$c2" | tr '[:upper:]' '[:lower:]')"
      case "$smode" in
        on) printf "  ${C}[SOC]${NC} ${G}Analyst ACTIVATED${NC}\n"; cli_cmd '{"cmd":"soc_toggle","mode":"on"}' ;;
        off) printf "  ${C}[SOC]${NC} ${R}Analyst DEACTIVATED${NC}\n"; cli_cmd '{"cmd":"soc_toggle","mode":"off"}' ;;
        *) printf "  ${R}[!]${NC} soc on|off\n" ;;
      esac ;;
    abort) printf "  ${R}[ABORT]${NC} Stopping agent...\n"; cli_cmd '{"cmd":"agent_abort"}' ;;
    tasks) cli_cmd '{"cmd":"tasks"}' ;;
    kill) [ -z "$c2" ] && printf "  ${R}[!]${NC} kill <id>\n" || { printf "  ${R}[KILL]${NC} %s\n" "$c2"; cli_cmd "{\"cmd\":\"kill\",\"id\":\"$c2\"}"; } ;;
    settings) do_settings ;; help) show_help ;; history) cat "$HIST" 2>/dev/null ;;
    clear) clear; banner ;; exit|quit|q) cleanup ;;
    *)
      printf "  ${M}[NETGHOST]${NC} 🧠 Thinking...\n"
      json_msg=$(echo "$cmd" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null)
      cli_cmd "{\"cmd\":\"chat\",\"message\":$json_msg}"
      ;;
  esac
done