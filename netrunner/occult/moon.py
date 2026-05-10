#!/usr/bin/env python3
"""Moon phase calculator — Purple Bruce Lucy Occult Arsenal"""
import math
from datetime import datetime, timezone

def moon_phase(date=None):
    if date is None:
        date = datetime.now(timezone.utc)
    # Known new moon: Jan 6 2000 18:14 UTC
    known_new = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    cycle = 29.53058867  # synodic month in days
    elapsed = (date - known_new).total_seconds() / 86400
    phase = elapsed % cycle
    return phase, cycle

def phase_name(phase, cycle):
    p = phase / cycle
    if p < 0.025:   return "🌑 New Moon",        "Seed time. Set intent. Charge sigils."
    elif p < 0.25:  return "🌒 Waxing Crescent",  "Growth. Begin workings. Build momentum."
    elif p < 0.275: return "🌓 First Quarter",    "Action. Execute. Push through resistance."
    elif p < 0.5:   return "🌔 Waxing Gibbous",   "Refine. Strengthen. Amplify the work."
    elif p < 0.525: return "🌕 Full Moon",         "Peak power. Manifest. Maximum charge."
    elif p < 0.75:  return "🌖 Waning Gibbous",   "Gratitude. Integration. Absorb results."
    elif p < 0.775: return "🌗 Last Quarter",      "Release. Banish. Cut what no longer serves."
    elif p < 0.975: return "🌘 Waning Crescent",  "Rest. Cleanse. Prepare for the new cycle."
    else:           return "🌑 New Moon",          "Seed time. Set intent. Charge sigils."

def moon_bar(phase, cycle):
    pct = phase / cycle
    bars = 20
    filled = int(pct * bars)
    return "▓" * filled + "░" * (bars - filled)

def main():
    V = "\033[38;5;135m"; C = "\033[38;5;51m"; Y = "\033[38;5;220m"
    D = "\033[38;5;240m"; M = "\033[38;5;201m"; RS = "\033[0m"

    phase, cycle = moon_phase()
    name, meaning = phase_name(phase, cycle)
    bar = moon_bar(phase, cycle)
    pct = (phase / cycle) * 100
    days_to_full = cycle * 0.5 - phase if phase < cycle * 0.5 else cycle - phase + cycle * 0.5

    print(f"  {V}┌─ Moon Phase ──────────────────────────{RS}")
    print(f"  {V}│{RS}  {name}")
    print(f"  {V}│{RS}  {Y}{bar}{RS}  {D}{pct:.0f}%{RS}")
    print(f"  {V}│{RS}  {D}{meaning}{RS}")
    print(f"  {V}│{RS}  {C}Day {phase:.1f}/{cycle:.1f}{RS}  {D}· next full: ~{abs(days_to_full):.0f}d{RS}")
    print(f"  {V}└───────────────────────────────────────{RS}")

if __name__ == "__main__":
    main()
