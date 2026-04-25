#!/usr/bin/env bash
# agi/safe_exec.sh — Safe Execution Wrapper.
# Preview · explain · confirm · log · dry-run.
# Designed to be called by the AGI Operator role; never auto-runs destructive ops.

set -u

LOG_DIR="${AGI_LOG_DIR:-$HOME/.agi/logs}"
LOG_FILE="$LOG_DIR/exec.log"
mkdir -p "$LOG_DIR"

DRY_RUN=0
ASSUME_YES=0
EXPLAIN=""

usage() {
  cat <<'EOF'
safe_exec.sh — preview · confirm · log · run a command

usage:
  safe_exec.sh [-n] [-y] [-e "explanation"] -- <command...>

flags:
  -n              dry-run: show what would happen, don't execute
  -y              assume yes (skip confirmation prompt)
  -e "<text>"     short explanation shown in the preview
  -h              this help

env:
  AGI_LOG_DIR     log directory (default: ~/.agi/logs)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n) DRY_RUN=1; shift ;;
    -y) ASSUME_YES=1; shift ;;
    -e) EXPLAIN="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  usage; exit 2
fi

CMD="$*"

# ── Hard refuse list (extend as needed) ──────────────────────────────────────
DANGEROUS_RX='(^|[[:space:]])(rm[[:space:]]+-rf?[[:space:]]+/[^a-zA-Z0-9._-]?($|[[:space:]])|:\(\)\{ :\|:& \};:|mkfs(\.|[[:space:]])|dd[[:space:]]+if=.*[[:space:]]of=/dev/(sda|nvme|mmcblk)|>([[:space:]])*/dev/sd[a-z]|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/|shutdown[[:space:]]|reboot([[:space:]]|$)|halt([[:space:]]|$)|init[[:space:]]+0|userdel[[:space:]]+-r[[:space:]]+root|curl[[:space:]].*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh)([[:space:]]|$))'
if printf '%s' "$CMD" | grep -qE "$DANGEROUS_RX"; then
  printf '\033[1;31m[!] BLOCKED — pattern matches the destructive denylist:\033[0m %s\n' "$CMD"
  printf '%s [BLOCKED] %s\n' "$(date -Iseconds)" "$CMD" >> "$LOG_FILE"
  exit 1
fi

# ── Preview ──────────────────────────────────────────────────────────────────
P=$'\033[38;5;201m'; V=$'\033[38;5;129m'; C=$'\033[38;5;51m'; Y=$'\033[38;5;226m'; R=$'\033[0m'
printf '%b┌─[ SAFE EXEC ]──────────────────────────────────%b\n' "$V" "$R"
[ -n "$EXPLAIN" ] && printf '%b│%b %bwhy:%b %s\n' "$V" "$R" "$Y" "$R" "$EXPLAIN"
printf '%b│%b %bcmd:%b %s\n' "$V" "$R" "$C" "$R" "$CMD"
printf '%b│%b %bcwd:%b %s\n' "$V" "$R" "$C" "$R" "$(pwd)"
printf '%b│%b %blog:%b %s\n' "$V" "$R" "$C" "$R" "$LOG_FILE"
[ "$DRY_RUN" -eq 1 ] && printf '%b│%b %bmode:%b dry-run\n' "$V" "$R" "$P" "$R"
printf '%b└────────────────────────────────────────────────%b\n' "$V" "$R"

if [ "$DRY_RUN" -eq 1 ]; then
  printf '%s [DRY-RUN] %s\n' "$(date -Iseconds)" "$CMD" >> "$LOG_FILE"
  exit 0
fi

# ── Confirm ──────────────────────────────────────────────────────────────────
if [ "$ASSUME_YES" -eq 0 ]; then
  printf '%brun? [y/N]:%b ' "$P" "$R"
  read -r ans
  case "${ans:-}" in
    y|Y|yes|YES) : ;;
    *) printf '%s [SKIPPED] %s\n' "$(date -Iseconds)" "$CMD" >> "$LOG_FILE"
       printf '%b[*] skipped%b\n' "$Y" "$R"; exit 0 ;;
  esac
fi

# ── Run ──────────────────────────────────────────────────────────────────────
START=$(date +%s)
printf '%s [RUN] %s\n' "$(date -Iseconds)" "$CMD" >> "$LOG_FILE"
bash -c "$CMD"
RC=$?
END=$(date +%s)
printf '%s [EXIT %s in %ss] %s\n' "$(date -Iseconds)" "$RC" "$((END-START))" "$CMD" >> "$LOG_FILE"
exit "$RC"
