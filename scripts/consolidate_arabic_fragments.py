#!/usr/bin/env python3
"""Consolidate Arabic tafsir fragments into a single per-surah file.

Reads all fragment files matching `new_tafsir/tafsir_<N>_v<start>-<end>_ar.json`
for a given surah and merges them into a single `new_tafsir/tafsir_<N>_ar.json`
suitable for `scripts/merge_arabic_layers.py`.

Usage:
    python3 scripts/consolidate_arabic_fragments.py <surah_number> [--dry-run]

Example:
    python3 scripts/consolidate_arabic_fragments.py 16
    python3 scripts/consolidate_arabic_fragments.py 16 --dry-run
"""

import json
import re
import sys
from pathlib import Path

FRAGMENT_RE = re.compile(r"^tafsir_(\d+)_v(\d+)-(\d+)_ar\.json$")


def consolidate(surah_num: int, dry_run: bool = False):
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    fragments_dir = project_root / "new_tafsir"
    output_path = fragments_dir / f"tafsir_{surah_num}_ar.json"

    if not fragments_dir.is_dir():
        print(f"Error: Fragments directory not found: {fragments_dir}")
        sys.exit(1)

    fragments = []
    for entry in fragments_dir.iterdir():
        m = FRAGMENT_RE.match(entry.name)
        if not m:
            continue
        if int(m.group(1)) != surah_num:
            continue
        start = int(m.group(2))
        end = int(m.group(3))
        if start > end:
            print(f"Error: Invalid range in filename: {entry.name}")
            sys.exit(1)
        fragments.append((start, end, entry))

    if not fragments:
        print(f"Error: No fragments found for surah {surah_num} in {fragments_dir}")
        sys.exit(1)

    fragments.sort(key=lambda t: (t[0], t[1]))

    print(f"Found {len(fragments)} fragments for surah {surah_num}:")
    for start, end, path in fragments:
        print(f"  {path.name}  (verses {start}-{end})")

    merged: dict = {}
    seen_verses: dict[str, str] = {}
    overlaps: list[tuple[str, str, str]] = []

    for start, end, path in fragments:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        for verse_key, verse_data in data.items():
            try:
                verse_num = int(verse_key)
            except ValueError:
                print(f"  Warning: Non-numeric verse key '{verse_key}' in {path.name}, skipping")
                continue
            if verse_num < start or verse_num > end:
                print(
                    f"  Warning: Verse {verse_key} in {path.name} is outside its declared range {start}-{end}"
                )
            if verse_key in seen_verses:
                overlaps.append((verse_key, seen_verses[verse_key], path.name))
            seen_verses[verse_key] = path.name
            merged[verse_key] = verse_data

    if overlaps:
        print("\nWarning: overlapping verse keys (later fragment wins):")
        for verse_key, first, second in overlaps:
            print(f"  verse {verse_key}: {first} -> overridden by {second}")

    sorted_keys = sorted(merged.keys(), key=lambda k: int(k))
    expected_keys = list(range(int(sorted_keys[0]), int(sorted_keys[-1]) + 1))
    present_set = {int(k) for k in sorted_keys}
    missing = [v for v in expected_keys if v not in present_set]
    if missing:
        print(f"\nWarning: missing verses in consolidated range: {missing}")

    print("\n--- Consolidation Summary ---")
    print(f"Surah:                    {surah_num}")
    print(f"Fragments merged:         {len(fragments)}")
    print(f"Total verses:             {len(merged)}")
    print(f"Verse range:              {sorted_keys[0]} - {sorted_keys[-1]}")
    print(f"Output file:              {output_path}")

    if dry_run:
        print("\n[DRY RUN] No file written.")
        return

    ordered = {k: merged[k] for k in sorted_keys}
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(ordered, f, ensure_ascii=False, indent=2)

    print("Done!")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 consolidate_arabic_fragments.py <surah_number> [--dry-run]")
        sys.exit(1)

    try:
        surah_num = int(sys.argv[1])
    except ValueError:
        print(f"Error: '{sys.argv[1]}' is not a valid surah number")
        sys.exit(1)

    if surah_num < 1 or surah_num > 114:
        print("Error: Surah number must be between 1 and 114")
        sys.exit(1)

    dry_run = "--dry-run" in sys.argv
    consolidate(surah_num, dry_run=dry_run)


if __name__ == "__main__":
    main()
