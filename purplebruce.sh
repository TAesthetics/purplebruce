#!/bin/bash
# purplebruce.sh

set -u

echo "╔════════════════════════════════════════════╗"
echo "║ PURPLE BRUCE v5.0 — LUCY EDITION ║"
echo "╚════════════════════════════════════════════╝"

if [ "$EUID" -ne 0 ]; then
 echo "Need root. Restarting with sudo..."
 exec sudo "$0" "$@"
fi

cd "$(dirname "$0")"

PORT="${PORT:-3000}"
BASE="http://localhost:${PORT}"

mkdir -p .purplebruce

if [ ! -d node_modules ]; then
 echo "Installing dependencies..."
 npm install
fi

echo "Starting Lucy Web UI on ${BASE} ..."
node server.js > server.log 2>&1 &
SERVER_PID=$!

cleanup() {
 echo -e "\nShutting down..."
 kill "$SERVER_PID" 2>/dev/null
 exit 0
}
trap cleanup INT TERM EXIT

echo "Lucy is running. Open browser → ${BASE}"
echo "CLI ready. Type 'help' for commands."

while true; do
 printf "\e[36mpurple> \e[0m"
 read -r cmd || { echo ""; cleanup; }
 if [ -z "$cmd" ]; then continue; fi

 case "$cmd" in
 exit|quit) cleanup ;;
 help) echo "scan <target> | harden | hunt | agent <msg> | report | setkey <grok|venice> <key>" ;;
 *) curl -s -X POST "${BASE}/api/cli" -H "Content-Type: application/json" -d "{\"cmd\":\"chat\",\"message\":\"$cmd\"}" ;;
 esac
done
