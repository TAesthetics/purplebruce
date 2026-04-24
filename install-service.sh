#!/usr/bin/env bash
# install-service.sh — Purple Bruce 24/7 background service installer for Termux.
# Defensive / lab-only. No external targets, no sudo, no systemd.
#
# Commands:
#   ./install-service.sh install       # set up service (termux-services if available, else nohup watchdog)
#   ./install-service.sh uninstall     # stop and remove watchdog / service
#   ./install-service.sh status        # show running state
#   ./install-service.sh restart       # stop + reinstall
#   ./install-service.sh enable-cron   # nightly harden/hunt/report against 127.0.0.1
#   ./install-service.sh disable-cron  # remove the nightly cron entry
#   ./install-service.sh logs          # tail the service log

set -u

MODE="${1:-help}"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PURPLE_HOME="$HOME/.purplebruce"
LOG_FILE="$PURPLE_HOME/service.log"
PID_FILE="$PURPLE_HOME/node.pid"
WATCHDOG_PID_FILE="$PURPLE_HOME/watchdog.pid"
NIGHTLY_SCRIPT="$PURPLE_HOME/nightly.sh"
PORT="${PORT:-3000}"
BIND="${BIND:-127.0.0.1}"
MAX_LOG_BYTES=10485760   # 10 MB — rotate once exceeded

mkdir -p "$PURPLE_HOME"

# ── detection ──────────────────────────────────────────────────────────────
is_termux()        { [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; }
has_termux_svcs()  { command -v sv >/dev/null 2>&1 && [ -d "${PREFIX:-/data/data/com.termux/files/usr}/var/service" ]; }

ts()  { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '[%s] %s\n' "$(ts)" "$*"; }

rotate_log() {
  if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)" -gt "$MAX_LOG_BYTES" ]; then
    mv -f "$LOG_FILE" "$LOG_FILE.1"
    : > "$LOG_FILE"
  fi
}

# ── node pre-flight ────────────────────────────────────────────────────────
preflight() {
  if ! command -v node >/dev/null 2>&1; then
    log "[!] node not found. Install Node ≥ 18 first."
    exit 1
  fi
  local maj
  maj=$(node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))')
  if [ "$maj" -lt 18 ]; then
    log "[!] Node $maj too old — need ≥ 18."
    exit 1
  fi
  if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    log "[*] Installing npm dependencies..."
    ( cd "$PROJECT_DIR" && npm install --no-audit --no-fund ) >> "$LOG_FILE" 2>&1
  fi
}

# ── Path A: termux-services (preferred on Termux when available) ───────────
install_termux_svcs() {
  local svc_dir="${PREFIX:-/data/data/com.termux/files/usr}/var/service/purplebruce"
  mkdir -p "$svc_dir/log"

  cat > "$svc_dir/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
cd "$PROJECT_DIR"
exec env PORT=$PORT HOST=$BIND node server.js
EOF

  cat > "$svc_dir/log/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt "$PURPLE_HOME"
EOF

  chmod +x "$svc_dir/run" "$svc_dir/log/run"
  sv-enable purplebruce 2>/dev/null || true
  sv up purplebruce 2>/dev/null || true
  log "[✓] Installed via termux-services."
  log "    Control: sv up|down|status purplebruce"
}

# ── Path B: nohup watchdog loop (fallback — works in any proot / bare shell) ─
watchdog_running() {
  [ -f "$WATCHDOG_PID_FILE" ] && kill -0 "$(cat "$WATCHDOG_PID_FILE" 2>/dev/null)" 2>/dev/null
}

start_watchdog() {
  if watchdog_running; then
    log "[*] watchdog already running (pid $(cat "$WATCHDOG_PID_FILE"))"
    return 0
  fi
  rotate_log
  # Spawn a detached supervisor that restarts node on any exit, with back-off.
  nohup bash -c '
    PROJECT_DIR="'"$PROJECT_DIR"'"
    LOG_FILE="'"$LOG_FILE"'"
    PID_FILE="'"$PID_FILE"'"
    MAX_LOG_BYTES='"$MAX_LOG_BYTES"'
    PORT="'"$PORT"'"
    BIND="'"$BIND"'"
    backoff=1
    while true; do
      if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)" -gt "$MAX_LOG_BYTES" ]; then
        mv -f "$LOG_FILE" "$LOG_FILE.1"; : > "$LOG_FILE"
      fi
      printf "[%s] [watchdog] starting node server.js\n" "$(date +%F\ %T)" >> "$LOG_FILE"
      cd "$PROJECT_DIR"
      PORT="$PORT" HOST="$BIND" node server.js >> "$LOG_FILE" 2>&1 &
      NODE_PID=$!
      echo "$NODE_PID" > "$PID_FILE"
      wait "$NODE_PID"
      CODE=$?
      printf "[%s] [watchdog] node exited code=%s — restart in %ss\n" "$(date +%F\ %T)" "$CODE" "$backoff" >> "$LOG_FILE"
      rm -f "$PID_FILE"
      sleep "$backoff"
      if [ "$backoff" -lt 30 ]; then backoff=$((backoff*2)); fi
      if [ "$CODE" = "0" ]; then backoff=1; fi
    done
  ' >/dev/null 2>&1 &
  echo "$!" > "$WATCHDOG_PID_FILE"
  disown "$!" 2>/dev/null || true
  sleep 1
  if watchdog_running; then
    log "[✓] watchdog started (pid $(cat "$WATCHDOG_PID_FILE")). Logs: $LOG_FILE"
  else
    log "[!] watchdog failed to start — see $LOG_FILE"
    exit 1
  fi
}

stop_watchdog() {
  if [ -f "$WATCHDOG_PID_FILE" ]; then
    kill "$(cat "$WATCHDOG_PID_FILE")" 2>/dev/null || true
    rm -f "$WATCHDOG_PID_FILE"
  fi
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  # Extra safety — nuke any stray node server.js for this project
  pkill -f "node .*${PROJECT_DIR}/server.js" 2>/dev/null || true
  log "[*] service stopped."
}

# ── cron: nightly defensive sweep, strictly localhost ──────────────────────
write_nightly_script() {
  cat > "$NIGHTLY_SCRIPT" <<EOF
#!/usr/bin/env bash
# Purple Bruce nightly defensive sweep — localhost only.
# Runs harden + hunt + report against the local Node server and archives
# the combined output to ~/.purplebruce/reports/YYYY-MM-DD.txt.

set -u
BASE="http://127.0.0.1:$PORT"
REPORTS="$PURPLE_HOME/reports"
mkdir -p "\$REPORTS"
OUT="\$REPORTS/\$(date +%Y-%m-%d).txt"

post() {
  curl -s --max-time 120 -X POST "\$BASE/api/cli" \\
    -H "Content-Type: application/json" -d "\$1"
}

{
  printf '=== harden %s ===\n' "\$(date -Iseconds)"
  post '{"cmd":"harden"}'
  printf '\n\n=== hunt %s ===\n' "\$(date -Iseconds)"
  post '{"cmd":"hunt"}'
  printf '\n\n=== report %s ===\n' "\$(date -Iseconds)"
  post '{"cmd":"report"}'
  printf '\n=== end ===\n'
} >> "\$OUT" 2>&1
EOF
  chmod +x "$NIGHTLY_SCRIPT"
}

enable_cron() {
  write_nightly_script
  if ! command -v crontab >/dev/null 2>&1; then
    log "[!] crontab not found."
    log "    Termux            :  pkg install termux-services cronie"
    log "    Proot Ubuntu/Kali :  apt install -y cron  &&  service cron start"
    log "    Arch / BlackArch  :  pacman -S --needed cronie  &&  crond &"
    log "    Then re-run       :  $0 enable-cron"
    exit 1
  fi
  local tag="# purplebruce-nightly"
  ( crontab -l 2>/dev/null | grep -v "$tag"; echo "30 3 * * * $NIGHTLY_SCRIPT $tag" ) | crontab -
  log "[✓] Cron installed: nightly sweep at 03:30 → $NIGHTLY_SCRIPT"
  log "    Reports land in : $PURPLE_HOME/reports/"
}

disable_cron() {
  if ! command -v crontab >/dev/null 2>&1; then
    log "[*] crontab not installed — nothing to remove."
    return 0
  fi
  local tag="# purplebruce-nightly"
  ( crontab -l 2>/dev/null | grep -v "$tag" ) | crontab - 2>/dev/null || true
  log "[*] Cron entry removed."
}

# ── status / dispatch ──────────────────────────────────────────────────────
status() {
  printf '  project  : %s\n' "$PROJECT_DIR"
  printf '  log      : %s\n' "$LOG_FILE"
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    printf '  node     : RUNNING (pid %s) on %s:%s\n' "$(cat "$PID_FILE")" "$BIND" "$PORT"
  else
    printf '  node     : stopped\n'
  fi
  if watchdog_running; then
    printf '  watchdog : RUNNING (pid %s)\n' "$(cat "$WATCHDOG_PID_FILE")"
  else
    printf '  watchdog : stopped\n'
  fi
  if command -v crontab >/dev/null 2>&1 && crontab -l 2>/dev/null | grep -q purplebruce-nightly; then
    printf '  cron     : enabled (03:30 harden/hunt/report → localhost)\n'
  else
    printf '  cron     : not installed\n'
  fi
  # Liveness probe
  if command -v curl >/dev/null 2>&1; then
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://${BIND}:${PORT}/api/status" 2>/dev/null || echo 000)
    printf '  probe    : http://%s:%s/api/status → HTTP %s\n' "$BIND" "$PORT" "$code"
  fi
}

case "$MODE" in
  install)
    preflight
    if is_termux && has_termux_svcs; then
      install_termux_svcs
    else
      stop_watchdog
      start_watchdog
    fi
    ;;
  uninstall)
    if is_termux && has_termux_svcs; then
      sv down purplebruce 2>/dev/null || true
      rm -rf "${PREFIX:-/data/data/com.termux/files/usr}/var/service/purplebruce"
      log "[*] termux-services entry removed."
    fi
    stop_watchdog
    ;;
  status)        status ;;
  restart)       stop_watchdog; sleep 1; preflight; if is_termux && has_termux_svcs; then install_termux_svcs; else start_watchdog; fi ;;
  enable-cron)   enable_cron ;;
  disable-cron)  disable_cron ;;
  logs)          tail -n 80 -f "$LOG_FILE" ;;
  help|--help|-h|"")
    cat <<EOF
Purple Bruce v5.0 — Lucy Edition · 24/7 service installer

usage: $0 <command>
  install        — set up Purple Bruce as a 24/7 background service
                   (uses termux-services if available, otherwise a detached
                   nohup watchdog loop with exponential back-off)
  uninstall      — stop and remove the service / watchdog
  status         — show node + watchdog + cron state + HTTP probe
  restart        — stop and reinstall
  enable-cron    — nightly 03:30 harden + hunt + report against 127.0.0.1,
                   reports in ~/.purplebruce/reports/YYYY-MM-DD.txt
  disable-cron   — remove the nightly cron entry
  logs           — tail ~/.purplebruce/service.log

Files:
  $PURPLE_HOME/service.log   — combined stdout/stderr
  $PURPLE_HOME/node.pid      — current node PID
  $PURPLE_HOME/watchdog.pid  — supervisor PID
  $PURPLE_HOME/nightly.sh    — cron job script (localhost only)
  $PURPLE_HOME/reports/      — archived nightly reports

All outbound calls target 127.0.0.1 only. No external scanning.
EOF
    ;;
  *) echo "unknown command: $MODE — try:  $0 help" ; exit 2 ;;
esac
