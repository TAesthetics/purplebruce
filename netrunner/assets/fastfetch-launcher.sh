#!/usr/bin/env bash
# netrunner/assets/fastfetch-launcher.sh — Layer 2 banner dispatcher.
# Picks fastfetch (with image logo) when available, falls back to motd.sh.
#
# Override:  NETRUNNER_BANNER=motd|fastfetch|auto   (default: auto)

set -u

NETRUNNER_BANNER="${NETRUNNER_BANNER:-auto}"
FF_CONFIG="$HOME/.netrunner/fastfetch.jsonc"
FF_LOGO="$HOME/.config/fastfetch/images/logo.png"
MOTD="$HOME/.netrunner/motd.sh"

run_motd()      { [ -x "$MOTD" ] && exec bash "$MOTD"; }
run_fastfetch() { exec fastfetch --config "$FF_CONFIG"; }

case "$NETRUNNER_BANNER" in
  motd)
    run_motd
    ;;
  fastfetch)
    command -v fastfetch >/dev/null 2>&1 && run_fastfetch
    run_motd
    ;;
  auto|*)
    # auto: prefer fastfetch only if the binary, config, and logo are all present.
    if command -v fastfetch >/dev/null 2>&1 \
       && [ -f "$FF_CONFIG" ] \
       && [ -f "$FF_LOGO" ]; then
      run_fastfetch
    fi
    run_motd
    ;;
esac
