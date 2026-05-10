#!/usr/bin/env python3
"""Tarot Card Draw — Purple Bruce Lucy Occult Arsenal"""
import random, sys

V = "\033[38;5;135m"; C = "\033[38;5;51m"; Y = "\033[38;5;220m"
M = "\033[38;5;201m"; G = "\033[38;5;46m"; D = "\033[38;5;240m"
R = "\033[38;5;196m"; W = "\033[1;37m"; RS = "\033[0m"

MAJOR_ARCANA = [
    ("0",  "The Fool",         "New beginning. Leap of faith. Zero = raw potential.",           "Chaos", "⬡"),
    ("I",  "The Magician",     "Willpower made manifest. All tools in hand. Execute.",          "Fire",  "⚡"),
    ("II", "The High Priestess","Hidden knowledge. Intuition. Read between the lines.",         "Water", "🌙"),
    ("III","The Empress",      "Creation. Abundance. Let things grow organically.",             "Earth", "🌿"),
    ("IV", "The Emperor",      "Authority. Structure. Dominate the system.",                    "Fire",  "👑"),
    ("V",  "The Hierophant",   "Tradition. Codes. Find the exploit in the institution.",       "Earth", "✝"),
    ("VI", "The Lovers",       "Choice. Alliance. Which path serves the Will?",                "Air",   "⚖"),
    ("VII","The Chariot",      "Victory through force of will. Drive forward. Win.",           "Water", "⬡"),
    ("VIII","Strength",        "Inner power. Tame the beast. Soft mastery.",                   "Fire",  "∞"),
    ("IX", "The Hermit",       "Withdraw. Analyze alone. The answer is within.",               "Earth", "🕯"),
    ("X",  "Wheel of Fortune", "Cycles turning. Timing is the key variable.",                  "Fire",  "☸"),
    ("XI", "Justice",          "Cause and effect. The code executes exactly as written.",      "Air",   "⚖"),
    ("XII","The Hanged Man",   "Surrender control. New perspective = new solution.",           "Water", "⊕"),
    ("XIII","Death",           "Transformation. Kill the old process. Reboot.",                "Water", "☽"),
    ("XIV","Temperance",       "Balance. Calibrate. Blend the elements precisely.",            "Fire",  "◈"),
    ("XV", "The Devil",        "Shadow work. Face the binding. Break the chain.",              "Earth", "⛧"),
    ("XVI","The Tower",        "Sudden collapse. The vulnerability was always there.",         "Fire",  "⚡"),
    ("XVII","The Star",        "Hope. Guidance. The north star of intent.",                    "Air",   "✦"),
    ("XVIII","The Moon",       "Illusion. Hidden forces. Scan deeper.",                        "Water", "🌕"),
    ("XIX","The Sun",          "Clarity. Success. The operation completes.",                   "Fire",  "☀"),
    ("XX", "Judgement",        "Awakening. Answer the call. The upgrade is ready.",            "Fire",  "📯"),
    ("XXI","The World",        "Completion. Integration. The sigil has fired.",               "Earth", "⊗"),
]

MINOR_SUITS = {
    "Wands": ("Fire", "Offense · Will · Action · Drive", "⚡"),
    "Cups":  ("Water","Defense · Emotion · Intuition",    "💧"),
    "Swords":("Air",  "Recon · Mind · Conflict · Truth",  "⚔"),
    "Pentacles":("Earth","OSINT · Material · Resources",  "⬡"),
}

MINOR_NAMES = ["Ace","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten",
               "Page","Knight","Queen","King"]
MINOR_MEANINGS = {
    "Ace":   "Pure potential. New channel. First strike.",
    "Two":   "Balance of forces. Dual vectors.",
    "Three": "Initial success. Proof of concept.",
    "Four":  "Stability. Establish the beachhead.",
    "Five":  "Conflict. Resistance in the system.",
    "Six":   "Harmony restored. Protocol adjusted.",
    "Seven": "Strategy under pressure. Stay patient.",
    "Eight": "Rapid movement. Execute fast.",
    "Nine":  "Near completion. One more push.",
    "Ten":   "Overload. Too many processes. Prune.",
    "Page":  "New information incoming. Receive it.",
    "Knight":"Swift action. Commit and drive forward.",
    "Queen": "Mastery through intuition. Read the system.",
    "King":  "Full command. Root access. Dominate.",
}

def build_deck():
    deck = list(MAJOR_ARCANA)
    for suit, (element, domain, icon) in MINOR_SUITS.items():
        for name in MINOR_NAMES:
            meaning = f"{MINOR_MEANINGS[name]} [{domain}]"
            deck.append((name, f"{name} of {suit}", meaning, element, icon))
    return deck

def draw(n=1, question=""):
    deck = build_deck()
    drawn = random.sample(deck, min(n, len(deck)))
    reversed_flags = [random.random() < 0.3 for _ in drawn]

    print(f"\n  {V}╔══ TAROT DRAW {'═' * 32}╗{RS}")
    if question:
        print(f"  {V}║{RS}  {D}Question: {W}{question[:46]}{RS}")
        print(f"  {V}║{RS}  {D}{'─'*50}{RS}")

    positions = ["Past", "Present", "Future"] if n == 3 else [f"Card {i+1}" for i in range(n)]

    for i, ((num, name, meaning, element, icon), rev) in enumerate(zip(drawn, reversed_flags)):
        pos = positions[i] if i < len(positions) else f"Card {i+1}"
        rev_str = f" {R}(reversed){RS}" if rev else ""
        if rev:
            meaning = meaning.replace(".", ". [Blocked]").replace("Execute","Blocked")
        print(f"\n  {V}║{RS}  {Y}{pos.upper()}{RS}")
        print(f"  {V}║{RS}  {M}{icon} {W}{name}{RS}{rev_str}  {D}[{element}]{RS}")
        print(f"  {V}║{RS}  {C}{meaning}{RS}")

    print(f"\n  {V}║{RS}")
    print(f"  {V}║{RS}  {D}INPUT:   {W}Query + present moment{RS}")
    print(f"  {V}║{RS}  {D}PROCESS: Stochastic oracle — pattern extraction{RS}")
    print(f"  {V}║{RS}  {D}OUTPUT:  Archetypal map of current probability field{RS}")
    print(f"  {V}╚══{'═'*48}╝{RS}\n")

def main():
    args = sys.argv[1:]
    n = 1
    question = ""
    if args:
        try:
            n = int(args[0])
            question = " ".join(args[1:])
        except ValueError:
            question = " ".join(args)
            n = 3 if len(question) > 3 else 1
    else:
        print(f"\n  {V}TAROT DRAW{RS} — {D}Chaos Magic Oracle{RS}")
        print(f"  {D}Cards: 1 (single), 3 (past/present/future){RS}")
        try:
            inp = input(f"  {Y}⚡ Question (Enter to skip): {RS}").strip()
            question = inp
            n_inp = input(f"  {Y}⚡ Cards [1/3]: {RS}").strip()
            n = int(n_inp) if n_inp.isdigit() else 1
        except (EOFError, KeyboardInterrupt):
            n = 1
    draw(max(1, min(n, 10)), question)

if __name__ == "__main__":
    main()
