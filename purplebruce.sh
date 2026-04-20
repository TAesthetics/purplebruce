#!/bin/bash
# ═══════════════════════════════════════════════════════
#  purplebruce.sh v4.2 — CYBERDECK EDITION
#  Purple Team CLI for Kali NetHunter / Termux / macOS
#  Hybrid: CLI Terminal + Web UI on same agent engine
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
if [ -f "$HOME/.grok_key" ]; then
  GROK_KEY="$(cat "$HOME/.grok_key")"
fi
if [ -f "$HOME/.venice_key" ]; then
  VENICE_KEY="$(cat "$HOME/.venice_key")"
fi
if [ -f "$HOME/.ai_provider" ]; then
  AI_PROVIDER="$(cat "$HOME/.ai_provider")"
fi

# ═══ COLORS ═══
R='\033[0;31m'
G='\033[0;32m'
B='\033[0;34m'
Y='\033[0;33m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
D='\033[2m'
NC='\033[0m'

# ═══ BANNER ═══
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
║          CYBERDECK v4.2                      ║
║          Purple Team // Hybrid CLI + Web     ║
╚══════════════════════════════════════════════╝
ASCII
  printf "${NC}\n"
  printf "  ${D}Host: ${W}%s${NC}  ${D}|  Time: ${W}%s${NC}\n\n" "$(hostname)" "$(date '+%H:%M:%S')"
}

# ═══ HELP ═══
show_help() {
  printf "\n  ${C}COMMANDS${NC}\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${G}purple scan${NC} <target>     ${D}│${NC} Port scan + SSL + headers\n"
  printf "  ${G}purple harden${NC}            ${D}│${NC} Security audit\n"
  printf "  ${G}purple hunt${NC}              ${D}│${NC} Threat hunting\n"
  printf "  ${G}purple report${NC}            ${D}│${NC} Save full report to file\n"
  printf "  ${G}purple agent${NC}             ${D}│${NC} Grok/Venice AI analysis\n"
  printf "  ${G}purple chat${NC} \"message\"    ${D}│${NC} Ask NetGhost anything\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${R}red emulate${NC} <tactic>     ${D}│${NC} MITRE ATT&CK emulation\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${M}autonomous on${NC}            ${D}│${NC} Agent runs tools on its own\n"
  printf "  ${M}autonomous off${NC}           ${D}│${NC} Stop autonomous mode\n"
  printf "  ${M}agent start${NC} [rounds]     ${D}│${NC} Start agent (0 = unlimited)\n"
  printf "  ${M}agent stop${NC}               ${D}│${NC} Abort running agent\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${Y}tasks${NC}                    ${D}│${NC} List running tasks\n"
  printf "  ${Y}kill${NC} <id>                ${D}│${NC} Kill task by ID\n"
  printf "  ${Y}settings${NC}                 ${D}│${NC} AI provider + API keys\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "  ${W}history${NC}                  ${D}│${NC} Show command history\n"
  printf "  ${W}clear${NC}                    ${D}│${NC} Clear screen\n"
  printf "  ${R}exit${NC}                     ${D}│${NC} Shutdown everything\n"
  printf "  ${D}──────────────────────────────────────────${NC}\n"
  printf "\n  ${Y}RED TACTICS:${NC} persistence lateral-movement exfiltration recon discovery\n"
  printf "                cred-dump c2-https ransomware fileless sched-task dns-exfil\n\n"
}

# ═══ CLEANUP ═══
cleanup() {
  printf "\n  ${R}[SHUTDOWN]${NC} Killing server (PID: $SERVER_PID)...\n"
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  printf "  ${R}[SHUTDOWN]${NC} Purple Bruce offline. Stay frosty, choom.\n"
  exit 0
}
trap cleanup SIGINT SIGTERM

# ═══ DEPS CHECK ═══
check_deps() {
  cd "$DIR"
  if [ ! -d "node_modules" ]; then
    printf "  ${Y}[SETUP]${NC} Installing dependencies...\n"
    npm install --silent 2>&1 | tail -3
    printf "  ${G}[SETUP]${NC} Dependencies installed.\n"
  fi
}

# ═══ START SERVER ═══
start_server() {
  cd "$DIR"
  printf "  ${C}[BOOT]${NC} Starting server...\n"
  node server.js &
  SERVER_PID=$!

  local retries=0
  while ! curl -s "http://127.0.0.1:$PORT/api/status" > /dev/null 2>&1; do
    sleep 0.5
    retries=$((retries + 1))
    if [ $retries -gt 20 ]; then
      printf "  ${R}[ERROR]${NC} Server failed to start.\n"
      exit 1
    fi
  done

  printf "\n"
  printf "  ${G}╔══════════════════════════════════════════════╗${NC}\n"
  printf "  ${G}║${NC}  ${W}SERVER ONLINE${NC}                                ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${C}Web UI:${NC}  ${W}http://127.0.0.1:${PORT}${NC}              ${G}║${NC}\n"
  printf "  ${G}║${NC}  ${C}PID:${NC}     ${W}${SERVER_PID}${NC}                               ${G}║${NC}\n"
  printf "  ${G}╚══════════════════════════════════════════════╝${NC}\n\n"
}

# ═══ CLI COMMAND (call server API) ═══
cli_cmd() {
  local response
  response=$(curl -s -X POST "$API" \
    -H "Content-Type: application/json" \
    -d "$1" 2>/dev/null)

  if [ $? -ne 0 ]; then
    printf "  ${R}[ERROR]${NC} Server unreachable.\n"
    return
  fi

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
                sid = item.get('id','?')
                stype = item.get('type','?')
                label = item.get('label','?')
                status = item.get('status','?')
                colors = {'running':'\033[0;32m','completed':'\033[2m','killed':'\033[0;31m','crashed':'\033[0;31m'}
                c = colors.get(status, '\033[2m')
                print(f'  {c}[{status.upper()}]\033[0m {sid}  {stype}  {label}')
    else:
        print(f'  {data}')
except Exception as e:
    print(str(e))
" 2>/dev/null || printf "  ${D}${response}${NC}\n"
}

# ═══ SCAN (local fallback if server is down) ═══
do_scan() {
  local t="$1"
  if [ -z "$t" ]; then
    printf "  ${R}[!]${NC} Usage: purple scan <target>\n"
    return
  fi
  printf "  ${C}[RECON]${NC} Target: ${W}%s${NC}\n" "$t"
  cli_cmd "{\"cmd\":\"scan\",\"target\":\"$t\",\"mode\":\"STANDARD\"}"
}

# ═══ HARDEN ═══
do_harden() {
  printf "  ${G}[FORTRESS]${NC} Running security audit...\n"
  cli_cmd '{"cmd":"harden"}'
}

# ═══ HUNT ═══
do_hunt() {
  printf "  ${Y}[GHOST]${NC} Threat hunting...\n"
  cli_cmd '{"cmd":"hunt"}'
}

# ═══ REPORT ═══
do_report() {
  printf "  ${C}[REPORT]${NC} Generating report...\n"
  cli_cmd '{"cmd":"report"}'

  # also save to file
  printf "========================================\n" > "$REPORT"
  printf "  PURPLE BRUCE CYBERDECK REPORT\n" >> "$REPORT"
  printf "  Date: %s\n" "$(date)" >> "$REPORT"
  printf "  Host: %s\n" "$(hostname)" >> "$REPORT"
  printf "  User: %s\n" "$(whoami)" >> "$REPORT"
  printf "  Kern: %s\n" "$(uname -a)" >> "$REPORT"
  printf "========================================\n\n" >> "$REPORT"

  printf "--- HARDEN ---\n" >> "$REPORT"
  curl -s -X POST "$API" -H "Content-Type: application/json" -d '{"cmd":"harden"}' 2>/dev/null | \
    python3 -c "import sys,json;[print(l.get('text','')) for l in json.load(sys.stdin).get('lines',[])]" >> "$REPORT" 2>/dev/null

  printf "\n--- HUNT ---\n" >> "$REPORT"
  curl -s -X POST "$API" -H "Content-Type: application/json" -d '{"cmd":"hunt"}' 2>/dev/null | \
    python3 -c "import sys,json;[print(l.get('text','')) for l in json.load(sys.stdin).get('lines',[])]" >> "$REPORT" 2>/dev/null

  printf "\n=== END ===\n" >> "$REPORT"
  printf "  ${G}[REPORT]${NC} Saved: ${W}%s${NC}\n" "$REPORT"
}

# ═══ CHAT (interactive question) ═══
do_chat() {
  local msg="$1"
  if [ -z "$msg" ]; then
    printf "  ${R}[!]${NC} Usage: purple chat \"your question here\"\n"
    return
  fi
  printf "  ${M}[NETGHOST]${NC} Processing...\n"
  local json_msg
  json_msg=$(echo "$msg" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null)
  cli_cmd "{\"cmd\":\"chat\",\"message\":$json_msg}"
}

# ═══ AGENT (auto-analysis) ═══
do_agent() {
  printf "  ${M}[AGENT]${NC} Starting AI analysis...\n"
  cli_cmd '{"cmd":"agent_start","rounds":5}'
}

# ═══ RED EMULATE ═══
do_emulate() {
  local tc="$1"
  if [ -z "$tc" ]; then
    printf "  ${R}[!]${NC} Usage: red emulate <tactic>\n"
    printf "  ${Y}Tactics:${NC} persistence lateral-movement exfiltration recon discovery\n"
    printf "          cred-dump c2-https ransomware fileless sched-task dns-exfil\n"
    return
  fi
  printf "  ${R}[BLACK ICE]${NC} Emulating ${W}%s${NC}...\n" "$tc"
  cli_cmd "{\"cmd\":\"red\",\"tactic\":\"$tc\"}"
}

# ═══ SETTINGS ═══
do_settings() {
  printf "\n  ${C}╔══════════════════════════════════════════════╗${NC}\n"
  printf "  ${C}║${NC}  ${W}SETTINGS${NC}                                    ${C}║${NC}\n"
  printf "  ${C}╚══════════════════════════════════════════════╝${NC}\n\n"

  printf "  ${D}Current Provider: ${NC}${W}%s${NC}\n" "$AI_PROVIDER"
  printf "  ${D}Grok Key:         ${NC}%s\n" "$([ -n "$GROK_KEY" ] && echo "${G}SET${NC} (${GROK_KEY:0:8}...)" || echo "${R}NOT SET${NC}")"
  printf "  ${D}Venice Key:       ${NC}%s\n" "$([ -n "$VENICE_KEY" ] && echo "${G}SET${NC} (${VENICE_KEY:0:8}...)" || echo "${R}NOT SET${NC}")"
  printf "\n"
  printf "  ${Y}1${NC}) Set Grok API key\n"
  printf "  ${Y}2${NC}) Set Venice.ai API key\n"
  printf "  ${Y}3${NC}) Switch to Grok\n"
  printf "  ${Y}4${NC}) Switch to Venice.ai\n"
  printf "  ${Y}0${NC}) Back\n\n"
  printf "  ${D}Select:${NC} "
  read -r choice

  case "$choice" in
    1)
      printf "  Enter Grok API key: "
      read -r key
      if [ -n "$key" ]; then
        GROK_KEY="$key"
        printf "%s" "$key" > "$HOME/.grok_key"
        chmod 600 "$HOME/.grok_key"
        cli_cmd "{\"cmd\":\"set_key\",\"key\":\"$key\",\"provider\":\"grok\"}"
        printf "  ${G}[OK]${NC} Grok key saved.\n"
      fi
      ;;
    2)
      printf "  Enter Venice.ai API key: "
      read -r key
      if [ -n "$key" ]; then
        VENICE_KEY="$key"
        printf "%s" "$key" > "$HOME/.venice_key"
        chmod 600 "$HOME/.venice_key"
        cli_cmd "{\"cmd\":\"set_key\",\"key\":\"$key\",\"provider\":\"venice\"}"
        printf "  ${G}[OK]${NC} Venice key saved.\n"
      fi
      ;;
    3)
      AI_PROVIDER="grok"
      printf "grok" > "$HOME/.ai_provider"
      cli_cmd '{"cmd":"set_provider","provider":"grok"}'
      printf "  ${G}[OK]${NC} Switched to Grok.\n"
      ;;
    4)
      AI_PROVIDER="venice"
      printf "venice" > "$HOME/.ai_provider"
      cli_cmd '{"cmd":"set_provider","provider":"venice"}'
      printf "  ${G}[OK]${NC} Switched to Venice.ai.\n"
      ;;
    *) ;;
  esac
}

# ═══════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════

clear
banner
check_deps
start_server
show_help

while true; do
  printf "  ${R}pb${NC}${D}@${NC}${M}v4.2${NC} ${R}>${NC} "
  read -r cmd

  if [ -z "$cmd" ]; then continue; fi

  # save to history
  echo "$cmd" >> "$HIST"

  # parse command
  set -- $cmd
  c1="$1"
  c2="$2"
  c3="$3"

  case "$c1" in
    purple)
      case "$c2" in
        scan)    do_scan "$c3" ;;
        harden)  do_harden ;;
        hunt)    do_hunt ;;
        report)  do_report ;;
        agent)   do_agent ;;
        chat)
          # extract everything after "purple chat "
          local_msg="$(echo "$cmd" | sed 's/^purple chat //')"
          do_chat "$local_msg"
          ;;
        setkey)  do_settings ;;
        *)       printf "  ${R}[!]${NC} Unknown: purple %s\n" "$c2" ;;
      esac
      ;;
    red)
      if [ "$c2" = "emulate" ]; then
        do_emulate "$c3"
      else
        printf "  ${R}[!]${NC} Usage: red emulate <tactic>\n"
      fi
      ;;
    chat)
      # extract everything after "chat "
      local_msg="$(echo "$cmd" | sed 's/^chat //')"
      do_chat "$local_msg"
      ;;
    autonomous)
      amode="$(echo "$c2" | tr '[:upper:]' '[:lower:]')"
      if [ "$amode" = "on" ]; then
        printf "  ${M}[AGENT]${NC} ${G}Autonomous mode ENABLED${NC}\n"
        cli_cmd '{"cmd":"autonomous","mode":"on"}'
      elif [ "$amode" = "off" ]; then
        printf "  ${M}[AGENT]${NC} ${R}Autonomous mode DISABLED${NC}\n"
        cli_cmd '{"cmd":"autonomous","mode":"off"}'
      else
        printf "  ${R}[!]${NC} Usage: autonomous on|off\n"
      fi
      ;;
    agent)
      sub="$(echo "$c2" | tr '[:upper:]' '[:lower:]')"
      if [ "$sub" = "stop" ]; then
        printf "  ${R}[AGENT]${NC} Stopping...\n"
        cli_cmd '{"cmd":"agent_stop"}'
      elif [ "$sub" = "start" ]; then
        rounds="${c3:-0}"
        printf "  ${M}[AGENT]${NC} Starting (rounds: %s)...\n" "${rounds:-unlimited}"
        cli_cmd "{\"cmd\":\"agent_start\",\"rounds\":$rounds}"
      else
        do_agent
      fi
      ;;
    tasks)   cli_cmd '{"cmd":"tasks"}' ;;
    kill)
      if [ -z "$c2" ]; then
        printf "  ${R}[!]${NC} Usage: kill <task-id>\n"
      else
        printf "  ${R}[KILL]${NC} Terminating %s...\n" "$c2"
        cli_cmd "{\"cmd\":\"kill\",\"id\":\"$c2\"}"
      fi
      ;;
    settings) do_settings ;;
    help)     show_help ;;
    history)  cat "$HIST" 2>/dev/null ;;
    clear)    clear; banner ;;
    exit|quit|q) cleanup ;;
    *)
      # anything else → send as chat to NetGhost
      printf "  ${M}[NETGHOST]${NC} Processing...\n"
      json_msg=$(echo "$cmd" | python3 -c 'import sys,json;print(json.dumps(sys.stdin.read().strip()))' 2>/dev/null)
      cli_cmd "{\"cmd\":\"chat\",\"message\":$json_msg}"
      ;;
  esac
done
