#!/usr/bin/env python3
"""Elder Futhark Rune Cast — Purple Bruce Lucy Occult Arsenal"""
import random, sys

V = "\033[38;5;135m"; C = "\033[38;5;51m"; Y = "\033[38;5;220m"
M = "\033[38;5;201m"; G = "\033[38;5;46m"; D = "\033[38;5;240m"
R = "\033[38;5;196m"; W = "\033[1;37m"; RS = "\033[0m"

RUNES = [
    ("ᚠ", "Fehu",    "Wealth · Resources · Initial investment. Acquire the assets needed."),
    ("ᚢ", "Uruz",    "Raw power · Health · Primal force. Override by brute strength."),
    ("ᚦ", "Thurisaz","Thorn · Chaos · Disruptive force. Strike first, ask later."),
    ("ᚨ", "Ansuz",   "Communication · Signal · Intelligence. Intercept and read the data."),
    ("ᚱ", "Raidho",  "Journey · Motion · Right action. Choose the optimal path."),
    ("ᚲ", "Kenaz",   "Torch · Knowledge · Fire of craft. Illuminate the hidden."),
    ("ᚷ", "Gebo",    "Gift · Exchange · Alliance. Trade: value for value."),
    ("ᚹ", "Wunjo",   "Joy · Harmony · Success. The operation completes as intended."),
    ("ᚺ", "Hagalaz", "Hail · Disruption · External chaos. Adapt or fail."),
    ("ᚾ", "Nauthiz", "Need · Constraint · Necessity. Work within the limits."),
    ("ᛁ", "Isa",     "Ice · Stillness · Blockage. Pause. Reconnaissance. Wait."),
    ("ᛃ", "Jera",    "Year · Harvest · Cycles. Right timing is the key variable."),
    ("ᛇ", "Eihwaz",  "Yew · Death-rebirth · Axis mundi. Transform through the ordeal."),
    ("ᛈ", "Perthro", "Dice cup · Mystery · Hidden forces. The outcome is probabilistic."),
    ("ᛉ", "Algiz",   "Elk · Protection · Ward. Activate defenses. Harden the perimeter."),
    ("ᛊ", "Sowilo",  "Sun · Victory · Will-force. Direct the energy. Win."),
    ("ᛏ", "Tiwaz",   "Tyr · Justice · Sacrifice. Commit fully. Pay the cost."),
    ("ᛒ", "Berkana", "Birch · Growth · New growth. Nurture what is beginning."),
    ("ᛖ", "Ehwaz",   "Horse · Partnership · Movement. Two forces as one."),
    ("ᛗ", "Mannaz",  "Human · Intellect · Self. Know the operator. Know the enemy."),
    ("ᛚ", "Laguz",   "Water · Flow · Intuition. Trust the pattern beneath the surface."),
    ("ᛜ", "Ingwaz",  "Ing · Potential · Gestation. The plan is ready. Launch."),
    ("ᛞ", "Dagaz",   "Dawn · Breakthrough · Threshold. The paradigm shifts now."),
    ("ᛟ", "Othala",  "Homeland · Inheritance · Foundation. Return to core purpose."),
]

def cast(n=1, question=""):
    drawn = random.sample(RUNES, min(n, len(RUNES)))
    reversed_flags = [random.random() < 0.25 for _ in drawn]

    print(f"\n  {V}╔══ RUNE CAST {'═' * 35}╗{RS}")
    if question:
        print(f"  {V}║{RS}  {D}Query: {W}{question[:48]}{RS}")
        print(f"  {V}║{RS}  {D}{'─' * 52}{RS}")

    for i, ((glyph, name, meaning), rev) in enumerate(zip(drawn, reversed_flags)):
        rev_str = f"  {R}᛫ merkstave (reversed){RS}" if rev else ""
        if rev:
            meaning = "[Blockage/Shadow] " + meaning.split("·")[-1].strip()
        print(f"\n  {V}║{RS}  {M}{glyph}{RS}  {W}{name}{RS}{rev_str}")
        print(f"  {V}║{RS}  {C}{meaning}{RS}")

    print(f"\n  {V}║{RS}  {D}Elder Futhark · 24 runes · Germanic/Norse tradition{RS}")
    print(f"  {V}╚══{'═' * 48}╝{RS}\n")

def main():
    args = sys.argv[1:]
    n, question = 1, ""
    if args:
        try:
            n = int(args[0]); question = " ".join(args[1:])
        except ValueError:
            question = " ".join(args); n = 3
    else:
        print(f"\n  {V}RUNE CAST{RS} — {D}Elder Futhark{RS}")
        try:
            question = input(f"  {Y}⚡ Question: {RS}").strip()
            ni = input(f"  {Y}⚡ Runes [1-5]: {RS}").strip()
            n = int(ni) if ni.isdigit() else 1
        except (EOFError, KeyboardInterrupt):
            n = 1
    cast(max(1, min(n, 5)), question)

if __name__ == "__main__":
    main()
