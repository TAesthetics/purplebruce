#!/usr/bin/env python3
"""
Chaos Magic Sigil Generator — Purple Bruce Lucy Occult Arsenal
Uses the letters method: statement of intent → remove duplicates →
remove vowels → combine remaining letters into a sigil description.
"""
import sys, random, hashlib

V = "\033[38;5;135m"; C = "\033[38;5;51m"; Y = "\033[38;5;220m"
M = "\033[38;5;201m"; G = "\033[38;5;46m"; D = "\033[38;5;240m"
W = "\033[1;37m"; RS = "\033[0m"

VOWELS = set("AEIOU")

def letters_method(intent):
    """Remove spaces, uppercase, deduplicate preserving order, remove vowels."""
    seen = set()
    result = []
    for c in intent.upper():
        if c.isalpha() and c not in seen:
            seen.add(c)
            if c not in VOWELS:
                result.append(c)
    return result

def sigil_hash(intent):
    """Deterministic sigil seed from intent."""
    return hashlib.sha256(intent.encode()).hexdigest()[:16]

def draw_sigil_ascii(letters, seed):
    """Generate a simple ASCII sigil grid from the letters."""
    random.seed(seed)
    # Build a 9x9 grid with letter-derived strokes
    grid = [["." for _ in range(9)] for _ in range(9)]
    # Place letters at positions derived from their ordinal values
    symbols = ["⬡","◈","◇","⊕","⊗","⊙","◉","⋈","⌬","⍟","⎔","⏣","⬟"]
    for i, letter in enumerate(letters[:12]):
        x = (ord(letter) * 7 + i * 3) % 9
        y = (ord(letter) * 5 + i * 4) % 9
        grid[y][x] = random.choice(symbols)
    # Connect with lines
    line_chars = ["─","│","╱","╲","·","×"]
    for _ in range(len(letters) * 2):
        x, y = random.randint(0, 8), random.randint(0, 8)
        if grid[y][x] == ".":
            grid[y][x] = random.choice(line_chars)
    return grid

def print_sigil(intent):
    letters = letters_method(intent)
    seed = sigil_hash(intent)
    grid = draw_sigil_ascii(letters, seed)

    print(f"\n  {V}╔══ SIGIL GENERATOR ═══════════════════════════╗{RS}")
    print(f"  {V}║{RS}  {D}Statement:{RS} {W}{intent[:44]}{RS}")
    print(f"  {V}║{RS}  {D}Letters:  {RS} {Y}{' '.join(letters)}{RS}")
    print(f"  {V}║{RS}  {D}Seed:     {RS} {D}{seed}{RS}")
    print(f"  {V}╠══════════════════════════════════════════════╣{RS}")
    print(f"  {V}║{RS}                                              {V}║{RS}")
    for row in grid:
        line = "  ".join(row)
        print(f"  {V}║{RS}    {M}{line}{RS}    {V}║{RS}")
    print(f"  {V}║{RS}                                              {V}║{RS}")
    print(f"  {V}╠══════════════════════════════════════════════╣{RS}")
    print(f"  {V}║{RS}  {Y}Method:{RS} Chaos Magic — Letters Method         {V}║{RS}")
    print(f"  {V}║{RS}  {C}Charge:{RS} Meditate on sigil → forget intent    {V}║{RS}")
    print(f"  {V}║{RS}  {G}Deploy:{RS} Gnosis state → fire → destroy paper  {V}║{RS}")
    print(f"  {V}╚══════════════════════════════════════════════╝{RS}")
    print(f"\n  {D}INPUT:   {W}{intent}{RS}")
    print(f"  {D}PROCESS: Remove vowels/duplicates → encode → charge{RS}")
    print(f"  {D}OUTPUT:  Sigil ready for deployment in gnosis state{RS}\n")

def main():
    if len(sys.argv) > 1:
        intent = " ".join(sys.argv[1:])
    else:
        print(f"\n  {V}SIGIL GENERATOR{RS} — {D}Chaos Magic Letters Method{RS}")
        print(f"  {D}Enter your statement of intent (present tense, positive):{RS}")
        print(f"  {D}Example: 'I WIN THE SCHULSPRECHERWAHL'{RS}\n")
        intent = input(f"  {Y}⚡ Intent: {RS}").strip()
        if not intent:
            intent = "I MANIFEST MY WILL"
    print_sigil(intent)

if __name__ == "__main__":
    main()
