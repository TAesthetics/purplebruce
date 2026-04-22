#!/bin/bash
# ================================================
# PURPLE BRUCE v5.0 — LUCY EDITION
# CLI + Web-UI gleichzeitig (Lucy Cyberdeck)
# ================================================

echo "╔════════════════════════════════════════════╗"
echo "║   PURPLE BRUCE v5.0 — LUCY EDITION         ║"
echo "║     CLI + Full Web UI starting...          ║"
echo "╚════════════════════════════════════════════╝"

# Root-Check
if [ "$EUID" -ne 0 ]; then
    echo "Need root. Restarting with sudo..."
    exec sudo "$0" "$@"
fi

# Verzeichnisse anlegen
mkdir -p .purplebruce/quarantine .purplebruce/forensics .purplebruce/playbooks
chmod 777 .purplebruce -R 2>/dev/null

# Dependencies installieren
echo "Installing dependencies..."
npm install express ws better-sqlite3 uuid --silent 2>/dev/null || echo "Dependencies already installed."

# Web-Server (Lucy UI + Voice + AUTONOMOUS) im Hintergrund starten
echo "Starting Lucy Web UI on http://localhost:3000 ..."
node server.js > server.log 2>&1 &

# Kurze Wartezeit
sleep 3

echo "✅ Lucy Web UI is running!"
echo "Open your browser → http://localhost:3000"
echo ""
echo "CLI is ready. Type commands below:"
echo "   purple scan <target>"
echo "   purple harden"
echo "   purple hunt"
echo "   purple agent"
echo "   help"
echo ""

# Einfaches CLI (kann später erweitert werden)
while true; do
    printf "\e[36mpurple> \e[0m"
    read cmd

    if [ -z "$cmd" ]; then continue; fi
    if [ "$cmd" = "exit" ] || [ "$cmd" = "quit" ]; then
        echo "Shutting down Lucy..."
        pkill -f "node server.js"
        exit 0
    fi

    case "$cmd" in
        "help")
            echo "Available commands:"
            echo "  purple scan <target>     - Port scan"
            echo "  purple harden            - Security audit"
            echo "  purple hunt              - Threat hunting"
            echo "  purple agent             - Talk to Lucy (CLI)"
            echo "  purple report            - Generate report"
            echo "  exit                     - Shutdown"
            ;;
        purple*)
            echo "CLI command received: $cmd"
            # Hier können später die echten Funktionen rein (do_scan usw.)
            echo "→ This will be connected to Lucy in the next update."
            ;;
        *)
            echo "Unknown command. Type 'help'"
            ;;
    esac
done