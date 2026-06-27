#!/usr/bin/env python3
"""Lint the crossword term bank.
  python3 scripts/crossword/lint_bank.py              # English-readiness checks
  python3 scripts/crossword/lint_bank.py --trilingual # also require clue_ur, clue_ar
Exits non-zero on any failure. (The definitive 'enough words' gate is whether
generate.py reaches 365 puzzles — these thresholds are an early smell test.)
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
BANK = os.path.join(HERE, "bank.json")
# Imamate-enumeration / sect-identity terms removed per design §2:
FORBIDDEN = {"SHIA", "KHUMS", "MAHDI", "SADIQ", "BAQIR", "KAZIM", "JAWAD", "QUM"}

def main(trilingual):
    entries = json.load(open(BANK, encoding="utf-8"))["entries"]
    assert entries, "empty bank"
    seen, pool, short = set(), 0, 0
    for e in entries:
        a = e["answer"].upper()
        assert re.fullmatch(r"[A-Z]+", a), f"{a}: non A-Z answer"
        assert a not in FORBIDDEN, f"{a}: forbidden (Imamate/sect-specific) term"
        assert a not in seen, f"{a}: duplicate answer"
        seen.add(a)
        assert e.get("clue_en"), f"{a}: missing clue_en"
        if trilingual:
            for k in ("clue_ur", "clue_ar"):
                assert e.get(k), f"{a}: missing {k}"
        if 3 <= len(a) <= 6:
            pool += 1
            if len(a) <= 4:
                short += 1
    assert pool >= 90,  f"only {pool} usable (3-6 letter) terms; aim >=90"
    assert short >= 25, f"only {short} short (3-4 letter) connectors; aim >=25"
    print(f"BANK OK: {len(entries)} entries, {pool} usable, {short} connectors"
          + (", trilingual" if trilingual else ", English"))

if __name__ == "__main__":
    try:
        main("--trilingual" in sys.argv)
    except (AssertionError, KeyError, FileNotFoundError) as e:
        print("BANK LINT FAILED:", e); sys.exit(1)
