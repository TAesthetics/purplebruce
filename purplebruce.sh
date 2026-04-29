#!/usr/bin/env bash
# purplebruce.sh — Termux / proot-distro / Linux friendly launcher.
# No hard `sudo` requirement — inside proot-distro you are already root.

set -u

banner() {
  local P=$'\033[38;5;201m' V=$'\033[38;5;129m' C=$'\033[38;5;51m' Y=$'\033[38;5;226m' N=$'\033[0m'
  printf '%b╔══════════════════════════════════════════════╗%b\n' "$P" "$N"
  printf '%b║%b  %bPURPLE BRUCE v6.0%b · %bNETRUNNER EDITION%b      %b║%b\n' "$P" "$N" "$P" "$N" "$C" "$N" "$P" "$N"
  printf '%b╚══════════════════════════════════════════════╝%b\n' "$P" "$N"
}

banner
cd "$(dirname "$0")"

# Escalate only if needed AND possible.
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    echo "[*] Re-exec with sudo..."
    exec sudo "$0" "$@"
  else
    echo "[*] Running as non-root (sudo unavailable) — continuing."
  fi
fi

PORT="${PORT:-3000}"
BIND="${BIND:-127.0.0.1}"
BASE="http://${BIND}:${PORT}"

# ANSI colors for pretty output / TUI chat
C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_CYAN=$'\033[0;36m'
C_MAG=$'\033[0;35m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[0;33m'
C_RED=$'\033[0;31m'
C_WHITE=$'\033[1;37m'

# Encode arbitrary text to a JSON string literal (incl. quotes) via Node.
# Usage:  json_str "hello \"world\""   →   "hello \"world\""
json_str() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' -- "$1"
}

# Pretty-render a /api/cli chat response (lines[] with {type,text}).
# Reads JSON from stdin, writes colorized, CoT-styled lines to stdout.
render_chat_lines() {
  node -e '
    let s="";process.stdin.on("data",c=>s+=c);
    process.stdin.on("end",()=>{
      try{
        const d=JSON.parse(s);
        const lines=Array.isArray(d?.lines)?d.lines:[];
        if(!lines.length&&d?.error){process.stdout.write("\x1b[0;31m│ error: "+d.error+"\x1b[0m\n");return;}
        for(const l of lines){
          const raw=(l.text||"").replace(/\x1b\[[0-9;]*m/g,"");
          let c="\x1b[0;37m";
          if(/^🧠|\[THINK\]/.test(raw)) c="\x1b[0;35m";
          else if(/^📋|\[PLAN\]/.test(raw)) c="\x1b[0;36m";
          else if(/^(⚡\s*)?CMD:|\[CMD\]/.test(raw)) c="\x1b[1;37m";
          else if(/^📊|\[ANALYSIS\]/.test(raw)) c="\x1b[0;33m";
          else if(/^✅|\[DONE\]/.test(raw)) c="\x1b[0;32m";
          else if(/^🔄|\[NEXT\]/.test(raw)) c="\x1b[0;35m";
          else if(l.type==="error"||/🔴|CRITICAL/.test(raw)) c="\x1b[0;31m";
          else if(l.type==="stderr"||/🟠|HIGH/.test(raw)) c="\x1b[0;33m";
          process.stdout.write(c+"│ "+raw+"\x1b[0m\n");
        }
      }catch(e){process.stdout.write("\x1b[2m│ "+s.slice(0,500)+"\x1b[0m\n");}
    });'
}

# Send a free-form message to Lucy's chat endpoint and pretty-print the reply
send_chat() {
  local msg="$1"
  [ -z "$msg" ] && return 1
  local msg_json
  msg_json=$(json_str "$msg")
  printf "%s🧠 lucy is thinking...%s\n" "$C_YELLOW" "$C_RESET"
  printf "%s┌─ lucy ─────────────────────────────────%s\n" "$C_CYAN" "$C_RESET"
  curl -s -X POST "${BASE}/api/cli" \
    -H "Content-Type: application/json" \
    -d "{\"cmd\":\"chat\",\"message\":${msg_json}}" \
    | render_chat_lines
  printf "%s└────────────────────────────────────────%s\n\n" "$C_CYAN" "$C_RESET"
}

# Interactive TUI chat mode — type freely, Lucy replies in terminal.
do_tui() {
  clear
  printf "%s╔════════════════════════════════════════════╗%s\n" "$C_MAG" "$C_RESET"
  printf "%s║       LUCY TERMINAL CHAT — v5.0            ║%s\n" "$C_MAG" "$C_RESET"
  printf "%s║       'exit' to leave · 'clear' screen     ║%s\n" "$C_MAG" "$C_RESET"
  printf "%s╚════════════════════════════════════════════╝%s\n\n" "$C_MAG" "$C_RESET"
  while true; do
    printf "%smaster>%s " "$C_MAG" "$C_RESET"
    IFS= read -r -e msg || { echo; break; }
    [ -z "${msg}" ] && continue
    case "$msg" in
      exit|quit) printf "%s[*] leaving TUI.%s\n" "$C_DIM" "$C_RESET"; break ;;
      clear) clear; continue ;;
    esac
    send_chat "$msg"
  done
}

mkdir -p .purplebruce

if ! command -v node >/dev/null 2>&1; then
  echo "[!] node not found. Install Node.js ≥ 18 first."
  echo "    Termux proot (Ubuntu/Kali): apt install -y nodejs npm"
  echo "    Arch/BlackArch            : pacman -S --needed nodejs npm"
  exit 1
fi

NODE_MAJOR=$(node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))')
if [ "${NODE_MAJOR}" -lt 18 ]; then
  echo "[!] Node ${NODE_MAJOR} too old. Need Node 18+ (native fetch / Blob / FormData)."
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "[*] Installing npm dependencies..."
  npm install --no-audit --no-fund
fi

# Rebuild native module if the prebuilt binary doesn't match this arch
if [ -d node_modules/better-sqlite3 ] && ! node -e "require('better-sqlite3')" 2>/dev/null; then
  echo "[*] Rebuilding better-sqlite3 for this arch..."
  npm rebuild better-sqlite3 || true
fi

echo "[*] Starting Lucy on ${BASE} ..."
PORT="${PORT}" HOST="${BIND}" node server.js > server.log 2>&1 &
SERVER_PID=$!

cleanup() {
  echo -e "\n[*] Shutting down..."
  kill "$SERVER_PID" 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM EXIT

sleep 1
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "[!] Server failed to start. Last log lines:"
  tail -n 20 server.log 2>/dev/null
  exit 1
fi

printf '\n%b[✓]%b lucy is alive @ %b%s%b — open this in your phone browser\n' "$C_GREEN" "$C_RESET" "$C_YELLOW" "$BASE" "$C_RESET"
printf '%b    type %b/help%b for the CLI · %bexit%b to shut down%b\n\n' "$C_DIM" "$C_CYAN" "$C_DIM" "$C_CYAN" "$C_DIM" "$C_RESET"

show_help() {
  cat <<EOF
  ${C_WHITE}CHAT${C_RESET}
    ${C_GREEN}agent${C_RESET} "<prompt>"            free-form question to Lucy (use quotes)
    ${C_GREEN}chat${C_RESET}  "<prompt>"            alias for agent
    ${C_GREEN}tui${C_RESET}                         open interactive chat TUI (exit with 'exit')

  ${C_WHITE}RECON / AUDIT${C_RESET}
    ${C_GREEN}scan${C_RESET}   <target>             recon scan
    ${C_GREEN}harden${C_RESET}                      hardening audit
    ${C_GREEN}hunt${C_RESET}                        blue-team threat hunt
    ${C_GREEN}report${C_RESET}                      latest report

  ${C_WHITE}KEYS / VOICE${C_RESET}
    ${C_GREEN}setkey${C_RESET} <provider> <key>     grok | venice | elevenlabs | groq | openai
    ${C_GREEN}setvoice${C_RESET} <voice_id>         ElevenLabs voice ID

  ${C_WHITE}SYSTEM${C_RESET}
    ${C_GREEN}logs${C_RESET}                        tail server.log
    ${C_GREEN}help${C_RESET}                        show this help
    ${C_GREEN}exit${C_RESET}                        shut down and quit

  ${C_DIM}Tip: wrap the prompt in double quotes so spaces survive:
       agent "wie härte ich meinen ssh server, master?"${C_RESET}
EOF
}

while true; do
  printf "%spurple>%s " "$C_CYAN" "$C_RESET"
  IFS= read -r -e cmd || { echo ""; cleanup; }
  [ -z "${cmd}" ] && continue

  # Split off the first word as the verb, preserve the rest verbatim as args
  verb="${cmd%% *}"
  args=""
  if [ "$cmd" != "$verb" ]; then args="${cmd#* }"; fi

  case "$verb" in
    exit|quit) cleanup ;;
    help|"?") show_help ;;
    logs) tail -n 40 server.log 2>/dev/null ;;
    tui)  do_tui ;;

    agent|chat|ask)
      if [ -z "${args}" ]; then
        printf "%sUsage:%s %s \"your free-form prompt\"\n" "$C_YELLOW" "$C_RESET" "$verb"
        printf "%sTip:  '%s' (no args) = open full TUI chat.%s\n" "$C_DIM" "tui" "$C_RESET"
        continue
      fi
      send_chat "$args"
      ;;

    scan)
      target="${args%% *}"
      if [ -z "${target}" ]; then printf "%sUsage:%s scan <target>\n" "$C_YELLOW" "$C_RESET"; continue; fi
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"scan\",\"target\":$(json_str "$target"),\"mode\":\"STANDARD\"}" \
        | render_chat_lines
      echo ""
      ;;
    harden)
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d '{"cmd":"harden"}' | render_chat_lines
      echo ""
      ;;
    hunt)
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d '{"cmd":"hunt"}' | render_chat_lines
      echo ""
      ;;
    report)
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d '{"cmd":"report"}' | render_chat_lines
      echo ""
      ;;

    setkey)
      provider="${args%% *}"
      key="${args#* }"
      if [ -z "${provider}" ] || [ "${provider}" = "${key}" ] || [ -z "${key}" ]; then
        printf "%sUsage:%s setkey <grok|venice|elevenlabs|groq|openai> <key>\n" "$C_YELLOW" "$C_RESET"
        continue
      fi
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"set_key\",\"provider\":$(json_str "$provider"),\"key\":$(json_str "$key")}"
      echo ""
      ;;
    setvoice)
      vid="${args%% *}"
      if [ -z "${vid}" ]; then printf "%sUsage:%s setvoice <voice_id>\n" "$C_YELLOW" "$C_RESET"; continue; fi
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"set_voice_id\",\"voiceId\":$(json_str "$vid")}"
      echo ""
      ;;

    *)
      # Unknown verb — treat the whole line as a chat message so free-typing still works.
      send_chat "$cmd"
      ;;
  esac
done
