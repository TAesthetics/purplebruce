#!/usr/bin/env bash
# Purple Bruce Lucy — Master Chaos Environment Setup
# Run INSIDE Arch proot: bash ~/purplebruce/netrunner/setup-chaos.sh

set -uo pipefail

V='\033[38;5;135m'; C='\033[38;5;51m'; Y='\033[38;5;220m'
M='\033[38;5;201m'; G='\033[38;5;46m'; D='\033[38;5;240m'; RS='\033[0m'

echo -e "\n${M}  ╔═══════════════════════════════════════════════════╗"
echo    "  ║  PURPLE BRUCE LUCY — Chaos Setup v6.0             ║"
echo    "  ║  ZSH Environment · Occult Tools · BlackArch       ║"
echo -e "  ╚═══════════════════════════════════════════════════╝${RS}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Step 1: ZSH + Oh-My-Zsh + dotfiles + occult tools ───────────────
echo -e "  ${V}━━ Step 1 · ZSH Environment & Occult Tools ━━━━━━━━━━━━${RS}\n"
if [[ -f "$SCRIPT_DIR/dotfiles/install.sh" ]]; then
  bash "$SCRIPT_DIR/dotfiles/install.sh"
else
  echo -e "  ${Y}⚠${RS}  dotfiles/install.sh not found — skipping ZSH setup"
fi

# ── Step 2: BlackArch Hacking Arsenal ───────────────────────────────
echo -e "\n  ${V}━━ Step 2 · BlackArch Hacking Arsenal ━━━━━━━━━━━━━━━━${RS}\n"
if [[ -f "$SCRIPT_DIR/dotfiles/tools.sh" ]]; then
  bash "$SCRIPT_DIR/dotfiles/tools.sh"
else
  echo -e "  ${Y}⚠${RS}  dotfiles/tools.sh not found — skipping tool installation"
fi

# ── Done ─────────────────────────────────────────────────────────────
echo -e "\n  ${M}╔══════════════════════════════════════════════════╗${RS}"
echo -e "  ${M}║${RS}  ${G}Chaos environment ready.${RS}                      ${M}║${RS}"
echo -e "  ${M}╚══════════════════════════════════════════════════╝${RS}"
echo -e "\n  ${V}Apply environment:${RS}  ${Y}exec zsh${RS}"
echo -e "  ${V}Verify tools:${RS}       ${Y}toolcheck${RS}"
echo -e "  ${V}Occult REPL:${RS}        ${Y}sigil · moon · tarot · rune · ritual${RS}"
echo -e "  ${V}Launch server:${RS}      ${Y}start${RS}  ${D}(netrunner)${RS}\n"
