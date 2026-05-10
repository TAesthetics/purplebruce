#!/usr/bin/env python3
"""
Ritual Protocol Builder — Purple Bruce Lucy Occult Arsenal
Generates structured ritual scripts as Input/Process/Output protocols.
"""
import sys, random
from datetime import datetime, timezone

V = "\033[38;5;135m"; C = "\033[38;5;51m"; Y = "\033[38;5;220m"
M = "\033[38;5;201m"; G = "\033[38;5;46m"; D = "\033[38;5;240m"
W = "\033[1;37m"; RS = "\033[0m"

# Moon phase for timing recommendation
def get_moon_phase():
    try:
        from moon import moon_phase, phase_name
        phase, cycle = moon_phase()
        name, _ = phase_name(phase, cycle)
        return name
    except Exception:
        return "Unknown"

ELEMENT_MAP = {
    "offense":    ("Fire",  "⚡", "Caliburn G4 — dopamine load",  "Wax candle — red"),
    "defense":    ("Water", "💧","Silence + cold water",          "Wax candle — blue"),
    "recon":      ("Air",   "🌬","Deep breath — 4-7-8 pattern",   "Incense — smoke"),
    "osint":      ("Earth", "⬡", "Grounding — bare feet",         "Salt + stone"),
    "success":    ("Fire",  "⚡", "Caliburn G4 + visualization",  "Gold candle"),
    "protection": ("Earth", "⬡", "Eigenblut — biometric seal",    "Black candle"),
    "banish":     ("Water", "💧","Cold shower — release intent",   "White candle"),
    "manifest":   ("Fire",  "⚡", "THC micro-dose — trance state","Purple candle"),
    "election":   ("Air",   "🌬","Public speaking posture + breath","Green candle"),
    "company":    ("Earth", "⬡", "Grounding + written contract",   "Gold candle"),
}

ORTHODOX = [
    "Lord Jesus Christ, Son of God, have mercy on me.",
    "By the intercession of the Holy Theotokos.",
    "Lord have mercy — Kyrie Eleison — three times.",
    "St. Tryphon, intercessor. St. Spyridon, shield.",
]

WICCA_QUARTERS = {
    "Fire":  "East  — Air of thought precedes; South — Fire of will executes.",
    "Water": "West  — Water of emotion guides; North — Earth grounds the result.",
    "Air":   "East  — Call Air. Set intention clearly before action.",
    "Earth": "North — Ground first. Build from solid foundation.",
}

def build_ritual(intent, objective="manifest"):
    obj = objective.lower()
    element, icon, tool, candle = ELEMENT_MAP.get(obj, ELEMENT_MAP["manifest"])
    moon = get_moon_phase()
    now = datetime.now(timezone.utc)

    print(f"\n  {V}╔══ RITUAL PROTOCOL ═══════════════════════════════════╗{RS}")
    print(f"  {V}║{RS}  {W}OBJECTIVE:{RS} {Y}{intent[:50]}{RS}")
    print(f"  {V}║{RS}  {D}Element: {element} {icon}  ·  Moon: {moon}  ·  Time: {now.strftime('%H:%M UTC')}{RS}")
    print(f"  {V}╠══════════════════════════════════════════════════════╣{RS}")

    print(f"\n  {V}║{RS}  {M}━━ INPUT — Variables ━━{RS}")
    print(f"  {V}║{RS}  {C}Icons:{RS}        {D}Activate Tryphon + Spyridon — divine API{RS}")
    print(f"  {V}║{RS}  {C}Cross:{RS}        {D}Hold or wear — energy archive{RS}")
    print(f"  {V}║{RS}  {C}Tool:{RS}         {D}{tool}{RS}")
    print(f"  {V}║{RS}  {C}Candle:{RS}       {D}{candle}{RS}")
    print(f"  {V}║{RS}  {C}Sigil:{RS}        {D}Run: sigil '{intent}' → charge the output{RS}")

    print(f"\n  {V}║{RS}  {M}━━ PROCESS — Execution Sequence ━━{RS}")
    print(f"  {V}║{RS}  {G}[1]{RS} {D}Ground. Feet flat. Breathe 4-7-8 three cycles.{RS}")
    print(f"  {V}║{RS}  {G}[2]{RS} {D}Quarter: {WICCA_QUARTERS[element]}{RS}")
    print(f"  {V}║{RS}  {G}[3]{RS} {D}Orthodox anchor: {random.choice(ORTHODOX)}{RS}")
    print(f"  {V}║{RS}  {G}[4]{RS} {D}{tool} — enter light gnosis state.{RS}")
    print(f"  {V}║{RS}  {G}[5]{RS} {D}Visualize: intent already fulfilled. Present tense.{RS}")
    print(f"  {V}║{RS}  {G}[6]{RS} {D}Fire the sigil. Peak of emotional charge. Release.{RS}")
    print(f"  {V}║{RS}  {G}[7]{RS} {D}Close: thank the quarter. Extinguish candle.{RS}")
    print(f"  {V}║{RS}  {G}[8]{RS} {D}Forget. Do not lust for result. Let it process.{RS}")

    print(f"\n  {V}║{RS}  {M}━━ OUTPUT — Expected Manifestation ━━{RS}")
    print(f"  {V}║{RS}  {Y}Target:{RS}  {W}{intent}{RS}")
    print(f"  {V}║{RS}  {Y}Vector:{RS}  {D}{element} path — {['action','synchronicity','insight','patience'][hash(intent)%4]}{RS}")
    print(f"  {V}║{RS}  {Y}Status:{RS}  {G}PROTOCOL ARMED — monitor for synchronicities{RS}")

    print(f"\n  {V}╠══════════════════════════════════════════════════════╣{RS}")
    print(f"  {V}║{RS}  {D}Chaos Magic rule: belief is a tool, not a truth.{RS}")
    print(f"  {V}║{RS}  {D}Use what works. Discard what doesn't. Move on.{RS}")
    print(f"  {V}╚══════════════════════════════════════════════════════╝{RS}\n")

def main():
    args = sys.argv[1:]
    if args:
        intent = " ".join(args)
        # detect objective from keywords
        obj = "manifest"
        kw = intent.lower()
        if any(w in kw for w in ["schulsprech","election","wahl","president"]): obj = "election"
        elif any(w in kw for w in ["firma","company","business","gründ"]): obj = "company"
        elif any(w in kw for w in ["protect","shield","ward","schutz"]): obj = "protection"
        elif any(w in kw for w in ["banish","remove","weg","löschen"]): obj = "banish"
        elif any(w in kw for w in ["recon","scan","find","search"]): obj = "recon"
        elif any(w in kw for w in ["hack","exploit","attack","angriff"]): obj = "offense"
        build_ritual(intent, obj)
    else:
        print(f"\n  {V}RITUAL PROTOCOL BUILDER{RS}")
        print(f"  {D}Objectives: manifest · offense · defense · recon · election · company · protection · banish{RS}\n")
        try:
            intent = input(f"  {Y}⚡ Intent: {RS}").strip() or "I manifest my will"
            obj = input(f"  {Y}⚡ Objective [{'/'.join(ELEMENT_MAP.keys())}]: {RS}").strip() or "manifest"
        except (EOFError, KeyboardInterrupt):
            intent, obj = "I manifest my will", "manifest"
        build_ritual(intent, obj)

if __name__ == "__main__":
    main()
