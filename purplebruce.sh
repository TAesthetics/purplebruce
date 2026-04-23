#!/usr/bin/env bash
# purplebruce.sh — Termux / proot-distro / Linux friendly launcher.
# No hard `sudo` requirement — inside proot-distro you are already root.

set -u

banner() {
  echo "╔════════════════════════════════════════════╗"
  echo "║ PURPLE BRUCE v5.0 — LUCY EDITION          ║"
  echo "╚════════════════════════════════════════════╝"
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

echo "[*] Lucy running (pid ${SERVER_PID}). Open ${BASE} in your browser."
echo "[*] CLI ready. Type 'help' for commands. 'exit' to stop."

while true; do
  printf "\e[36mpurple> \e[0m"
  read -r cmd || { echo ""; cleanup; }
  [ -z "${cmd}" ] && continue
  case "$cmd" in
    exit|quit) cleanup ;;
    help)
      echo "  scan <target>              - recon scan"
      echo "  harden                     - hardening audit"
      echo "  hunt                       - blue-team hunt"
      echo "  agent <msg>                - talk to Lucy"
      echo "  report                     - latest report"
      echo "  setkey <provider> <key>    - grok|venice|elevenlabs|groq|openai"
      echo "  setvoice <voice_id>        - ElevenLabs voice ID"
      echo "  logs                       - tail server.log"
      echo "  exit                       - quit"
      ;;
    logs) tail -n 40 server.log 2>/dev/null ;;
    setkey\ *)
      provider=$(awk '{print $2}' <<<"$cmd")
      key=$(awk '{print $3}' <<<"$cmd")
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"set_key\",\"provider\":\"${provider}\",\"key\":\"${key}\"}"
      echo ""
      ;;
    setvoice\ *)
      vid=$(awk '{print $2}' <<<"$cmd")
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"set_voice_id\",\"voiceId\":\"${vid}\"}"
      echo ""
      ;;
    *)
      msg_json=$(node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$cmd")
      curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" \
        -d "{\"cmd\":\"chat\",\"message\":${msg_json}}"
      echo ""
      ;;
  esac
done
