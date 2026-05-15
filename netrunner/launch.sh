#!/usr/bin/env bash
# Purple Bruce Lucy v7.1 — Single Launch Script
#
# This script runs INSIDE the Arch proot on startup.
# It starts the server (if not running) and drops into ZSH.
#
# Termux alias (add to ~/.bashrc or ~/.zshrc in Termux):
#   alias pb='proot-distro login archlinux -- bash ~/purplebruce/netrunner/launch.sh'
#
# Then just type:  pb

# Start Purple Bruce server in background if not already running
if ! pgrep -f "node server.js" >/dev/null 2>&1; then
  if [[ -d "$HOME/purplebruce" ]]; then
    (cd "$HOME/purplebruce" && node server.js >> "$HOME/.purplebruce/server.log" 2>&1 &)
  fi
fi

# Drop into ZSH with full environment
exec zsh -l
