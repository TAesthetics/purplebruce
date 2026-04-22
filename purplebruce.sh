#!/bin/bash
# ================================================
# PURPLE BRUCE v5.0 — LUCY EDITION
# CLI + Web-UI gleichzeitig (Lucy Cyberdeck)
# ================================================

set -u

echo "╔════════════════════════════════════════════╗"
echo "║   PURPLE BRUCE v5.0 — LUCY EDITION         ║"
echo "║     CLI + Full Web UI starting...          ║"
echo "╚════════════════════════════════════════════╝"

# Root-Check (required for some hunt/audit commands)
if [ "$EUID" -ne 0 ]; then
    echo "Need root. Restarting with sudo..."
    exec sudo "$0" "$@"
fi

cd "$(dirname "$0")"

PORT="${PORT:-3000}"
BASE="http://localhost:${PORT}"

# Arbeitsverzeichnisse anlegen
mkdir -p .purplebruce/quarantine .purplebruce/forensics .purplebruce/playbooks

# Dependencies sicherstellen
if [ ! -d node_modules ]; then
    echo "Installing dependencies..."
    npm install --silent 2>/dev/null || npm install
fi

# Web-Server im Hintergrund starten
echo "Starting Lucy Web UI on ${BASE} ..."
node server.js > server.log 2>&1 &
SERVER_PID=$!

cleanup() {
    echo ""
    echo "Shutting down Lucy..."
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

# Warten bis Server erreichbar
for i in 1 2 3 4 5 6 7 8 9 10; do
    if curl -s -o /dev/null "${BASE}/api/status"; then break; fi
    sleep 1
done

echo "✅ Lucy Web UI is running!"
echo "Open your browser → ${BASE}"
echo ""
echo "CLI is ready. Type commands below:"
echo "   scan <target>    - Port-Scan"
echo "   harden           - Security-Audit"
echo "   hunt             - Threat-Hunting"
echo "   agent <msg>      - Lucy fragen (single round)"
echo "   report           - Gesamtbericht"
echo "   tasks            - Laufende Tasks"
echo "   help | exit"
echo ""

post_api() {
    local payload="$1"
    curl -s -X POST "${BASE}/api/cli" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

print_lines() {
    # extrahiert "lines":[{type,text},...] und druckt nur text
    node -e '
        let data = "";
        process.stdin.on("data", c => data += c);
        process.stdin.on("end", () => {
            try {
                const j = JSON.parse(data);
                if (j.error) { console.log("[ERR]", j.error); return; }
                const lines = j.lines || (Array.isArray(j) ? j : null);
                if (Array.isArray(lines)) {
                    for (const l of lines) console.log(l.text != null ? l.text : JSON.stringify(l));
                } else if (j.message) {
                    console.log(j.message);
                } else {
                    console.log(JSON.stringify(j, null, 2));
                }
            } catch(e) { console.log(data); }
        });
    '
}

while true; do
    printf "\e[36mpurple> \e[0m"
    if ! read -r cmd; then echo ""; cleanup; fi
    [ -z "$cmd" ] && continue

    # erstes Wort + Rest
    verb="${cmd%% *}"
    rest="${cmd#"$verb"}"
    rest="${rest# }"

    case "$verb" in
        exit|quit) cleanup ;;
        help|\?)
            echo "  scan <target>    - Port-Scan"
            echo "  harden           - Security-Audit"
            echo "  hunt             - Threat-Hunting"
            echo "  agent <msg>      - Lucy fragen"
            echo "  report           - Gesamtbericht"
            echo "  tasks            - Laufende Tasks"
            echo "  exit             - Shutdown"
            ;;
        scan)
            if [ -z "$rest" ]; then echo "Usage: scan <target>"; continue; fi
            target_json=$(printf '%s' "$rest" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.stringify(s.trim())))')
            post_api "{\"cmd\":\"scan\",\"target\":${target_json},\"mode\":\"STANDARD\"}" | print_lines
            ;;
        harden) post_api '{"cmd":"harden"}' | print_lines ;;
        hunt)   post_api '{"cmd":"hunt"}'   | print_lines ;;
        report) post_api '{"cmd":"report"}' | print_lines ;;
        tasks)  post_api '{"cmd":"tasks"}'  | print_lines ;;
        agent)
            if [ -z "$rest" ]; then echo "Usage: agent <message>"; continue; fi
            msg_json=$(printf '%s' "$rest" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.stringify(s)))')
            post_api "{\"cmd\":\"chat\",\"message\":${msg_json}}" | print_lines
            ;;
        *)
            echo "Unknown command: $verb (type 'help')"
            ;;
    esac
done
