#!/usr/bin/env bash
# CyberEnigma top bar — printed once at login.

P=$'\033[38;5;201m'
V=$'\033[38;5;129m'
C=$'\033[38;5;51m'
Y=$'\033[38;5;226m'
B=$'\033[1m'
R=$'\033[0m'

cols=$(tput cols 2>/dev/null || echo 80)
now=$(date '+%H:%M:%S')

printf '%b╔' "$V"; printf '═%.0s' $(seq 1 $((cols-2))); printf '╗%b\n' "$R"
printf '%b║%b %b %s %b│ %b🤖 IDLE%b  %b║%b\n' "$V" "$R" "$C" "$now" "$V" "$Y$B" "$R" "$V" "$R"
printf '%b╚' "$V"; printf '═%.0s' $(seq 1 $((cols-2))); printf '╝%b\n' "$R"
