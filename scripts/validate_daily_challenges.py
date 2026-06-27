#!/usr/bin/env python3
"""Sanity-check daily_challenges.json.
  python3 scripts/validate_daily_challenges.py               # English-readiness
  python3 scripts/validate_daily_challenges.py --trilingual  # also require ur, ar
Exits non-zero on any failure.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "AlBayan", "AlBayan", "Data", "daily_challenges.json"))
FORMATS = {"multipleChoice", "trueFalse", "flashcard", "fillInBlank"}

def langs(tri): return ("en", "ur", "ar") if tri else ("en",)

def check_text(obj, field, where, tri):
    assert isinstance(obj, dict), f"{where}: {field} not an object"
    for k in langs(tri):
        assert obj.get(k), f"{where}: {field}.{k} missing/empty"

def main(tri):
    items = json.load(open(DATA, encoding="utf-8"))
    assert items, "no challenges"
    ids, by_format = set(), {f: 0 for f in FORMATS}
    for it in items:
        i = it["id"]
        assert i not in ids, f"duplicate id {i}"; ids.add(i)
        fmt = it["format"]
        assert fmt in FORMATS, f"{i}: bad format {fmt}"
        by_format[fmt] += 1
        check_text(it["prompt"], "prompt", i, tri)
        assert it.get("explanation"), f"{i}: missing explanation"
        check_text(it["explanation"], "explanation", i, tri)
        opts, ci = it.get("options"), it.get("correctIndex")
        if fmt in ("multipleChoice", "fillInBlank"):
            assert isinstance(opts, list) and len(opts) >= 3, f"{i}: needs >=3 options"
            for j, o in enumerate(opts): check_text(o, f"options[{j}]", i, tri)
            assert isinstance(ci, int) and 0 <= ci < len(opts), f"{i}: correctIndex out of range"
            assert it.get("answer") is None, f"{i}: {fmt} must not have answer"
        elif fmt == "trueFalse":
            assert opts is None, f"{i}: trueFalse options must be null"
            assert ci in (0, 1), f"{i}: trueFalse correctIndex must be 0 or 1"
            assert it.get("answer") is None, f"{i}: trueFalse must not have answer"
        elif fmt == "flashcard":
            assert opts is None, f"{i}: flashcard options must be null"
            assert ci is None, f"{i}: flashcard correctIndex must be null"
            assert it.get("answer"), f"{i}: flashcard needs answer"
            check_text(it["answer"], "answer", i, tri)
    print(f"CHALLENGES OK: {len(items)} items | "
          + " ".join(f"{f}={by_format[f]}" for f in FORMATS)
          + (" [trilingual]" if tri else " [English]"))

if __name__ == "__main__":
    try:
        main("--trilingual" in sys.argv)
    except (AssertionError, KeyError) as e:
        print("CHALLENGE VALIDATION FAILED:", e); sys.exit(1)
