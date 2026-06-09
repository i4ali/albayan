#!/usr/bin/env python3
"""Generate the tafsir merge-status report.

Scans the bundled tafsir files in `AlBayan/AlBayan/Data` and the source
fragments in `new_tafsir/`, then writes a human-readable report to
`new_tafsir/MERGE_STATUS.md` (gitignored).

This report is the source of truth for "which Arabic/Urdu tafsir from
new_tafsir has been merged into the app bundle, what is still PENDING, and
where new_tafsir CONFLICTS with the bundle." It is derived entirely from the
files on disk, so it never drifts — re-run it after every merge to refresh:

    python3 scripts/tafsir_merge_status.py

Pending  = content present in new_tafsir but missing/empty in the bundle
           (safe to merge with consolidate_*_fragments.py + merge_*_layers.py).
Conflict = a layer present & non-empty in BOTH but with different text
           (the bundle copy is kept; review by hand before overwriting).
"""

import json
import re
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "AlBayan" / "AlBayan" / "Data"
NEW_DIR = PROJECT_ROOT / "new_tafsir"
OUTPUT = NEW_DIR / "MERGE_STATUS.md"

TOTAL_SURAHS = 114

# Chunk files look like: tafsir_<surah>_v<range>_<lang>.json  (lang = ar | ur)
CHUNK_RE = re.compile(r"^tafsir_(\d+)_v[\d-]+_(ar|ur)\.json$")
# Real tafsir layer fields the merge scripts operate on (layer1..5 per language).
LAYER_RE = re.compile(r"^layer[1-5]_(ar|urdu)$")

EN_LAYERS = ["layer1", "layer2", "layer3"]
AR_LAYERS = ["layer1_ar", "layer2_ar", "layer3_ar"]
UR_LAYERS = ["layer1_urdu", "layer2_urdu", "layer3_urdu"]


def nonempty(obj, key):
    v = obj.get(key)
    return isinstance(v, str) and v.strip() != ""


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def field_lang(field):
    """'layer2_ar' -> 'ar', 'layer3_urdu' -> 'ur'."""
    return "ar" if field.endswith("_ar") else "ur"


def scan_new_tafsir():
    """Return {surah: {verse_key: {field: value}}} merged across all chunks.

    Later fragments win on overlap, mirroring consolidate_*_fragments.py.
    """
    by_surah = {}
    for path in sorted(NEW_DIR.glob("tafsir_*_v*.json")):
        m = CHUNK_RE.match(path.name)
        if not m:
            continue
        surah = int(m.group(1))
        verses = by_surah.setdefault(surah, {})
        for vk, vd in load(path).items():
            if vk.isdigit() and isinstance(vd, dict):
                verses.setdefault(vk, {}).update(
                    {k: v for k, v in vd.items() if LAYER_RE.match(k)}
                )
    return by_surah


def analyze():
    new = scan_new_tafsir()
    rows = []
    pending = {}   # surah -> {'ar': set(verses), 'ur': set(verses)}
    conflicts = []  # (surah, verse, field)

    for surah in range(1, TOTAL_SURAHS + 1):
        dpath = DATA_DIR / f"tafsir_{surah}.json"
        data = load(dpath) if dpath.exists() else {}
        dverses = [k for k in data if k.isdigit()]
        total = len(dverses)

        def coverage(layers):
            return sum(1 for k in dverses if all(nonempty(data[k], f) for f in layers))

        en = coverage(EN_LAYERS)
        ar = coverage(AR_LAYERS)
        ur = coverage(UR_LAYERS)
        qo = sum(
            1 for k in dverses
            if isinstance(data[k].get("quickOverview"), dict)
            and data[k]["quickOverview"].get("concepts")
        )

        # Compare new_tafsir content against the bundle.
        for vk, fields in new.get(surah, {}).items():
            for fld, val in fields.items():
                if not (isinstance(val, str) and val.strip()):
                    continue
                cur = data.get(vk, {}).get(fld)
                if cur is None or (isinstance(cur, str) and not cur.strip()):
                    pending.setdefault(surah, {}).setdefault(field_lang(fld), set()).add(int(vk))
                elif cur != val:
                    conflicts.append((surah, int(vk), fld))

        has_new = surah in new
        rows.append({
            "surah": surah, "total": total,
            "en": en, "ar": ar, "ur": ur, "qo": qo,
            "has_new": has_new,
        })

    return rows, pending, conflicts


def cell(have, total):
    if total == 0:
        return "—"
    if have == 0:
        return "·"          # none
    if have == total:
        return "✅"          # complete
    return f"{have}/{total}"  # partial


def render(rows, pending, conflicts):
    today = datetime.now().strftime("%Y-%m-%d")
    ar_surahs = sorted({r["surah"] for r in rows if r["has_new"] and r["ar"] > 0} |
                       {s for s, langs in pending.items() if "ar" in langs})
    # Surahs new_tafsir touches, split by language presence:
    new_ar = sorted({int(p.name.split("_")[1]) for p in NEW_DIR.glob("tafsir_*_v*_ar.json")
                     if CHUNK_RE.match(p.name)})
    new_ur = sorted({int(p.name.split("_")[1]) for p in NEW_DIR.glob("tafsir_*_v*_ur.json")
                     if CHUNK_RE.match(p.name)})

    total_pending = sum(len(v) for langs in pending.values() for v in langs.values())

    L = []
    L.append("# Tafsir Merge Status")
    L.append("")
    L.append(f"_Auto-generated by `scripts/tafsir_merge_status.py` on {today}. "
             "Derived from the files on disk — **do not hand-edit; re-run the script** "
             "after each merge._")
    L.append("")
    L.append("## TL;DR")
    L.append("")
    L.append(f"- **new_tafsir provides** — Arabic: surahs {fmt_ranges(new_ar)} · "
             f"Urdu: surahs {fmt_ranges(new_ur)}")
    if total_pending:
        parts = []
        for s in sorted(pending):
            for lang, verses in sorted(pending[s].items()):
                parts.append(f"surah {s} ({'Urdu' if lang == 'ur' else 'Arabic'}: {len(verses)} verses)")
        L.append(f"- ⏳ **Pending merge** (in new_tafsir, not yet in bundle): {', '.join(parts)}")
    else:
        L.append("- ✅ **Pending merge: none** — everything new_tafsir currently contains is merged into the bundle.")
    if conflicts:
        by_s = {}
        for s, v, f in conflicts:
            by_s.setdefault(s, []).append((v, f))
        cs = ", ".join(f"surah {s} ({len(v)})" for s, v in sorted(by_s.items()))
        L.append(f"- ⚠️ **Conflicts** (new_tafsir differs; bundle kept): {len(conflicts)} fields — {cs}")
    else:
        L.append("- ✅ **Conflicts: none.**")

    # Surahs partially populated in the bundle (remainder is NOT in new_tafsir,
    # so it needs generating, not merging).
    partials = []
    for r in rows:
        if 0 < r["ar"] < r["total"]:
            partials.append(f"surah {r['surah']} Arabic {r['ar']}/{r['total']}")
        if 0 < r["ur"] < r["total"]:
            partials.append(f"surah {r['surah']} Urdu {r['ur']}/{r['total']}")
    if partials:
        L.append(f"- 🧩 **Partially populated** (remainder not in new_tafsir → needs generation): "
                 f"{', '.join(partials)}")
    L.append("")

    if total_pending:
        L.append("## ⏳ Pending — run these to merge")
        L.append("")
        L.append("```bash")
        for s in sorted(pending):
            if "ar" in pending[s]:
                L.append(f"python3 scripts/consolidate_arabic_fragments.py {s} && python3 scripts/merge_arabic_layers.py {s}")
            if "ur" in pending[s]:
                L.append(f"python3 scripts/consolidate_urdu_fragments.py {s} && python3 scripts/merge_urdu_layers.py {s}")
        L.append("```")
        L.append("")

    if conflicts:
        L.append("## ⚠️ Conflicts — review by hand before overwriting")
        L.append("")
        L.append("These layers exist in BOTH new_tafsir and the bundle with different text. "
                 "The merge intentionally keeps the bundle copy (it is the edited/richer version). "
                 "Verify before letting new_tafsir win.")
        L.append("")
        L.append("| Surah | Verse | Field |")
        L.append("|------:|------:|-------|")
        for s, v, f in sorted(conflicts):
            L.append(f"| {s} | {v} | `{f}` |")
        L.append("")

    L.append("## Full coverage (per surah, from the app bundle)")
    L.append("")
    L.append("Each cell = verses with all three layers populated. "
             "`✅` complete · `n/total` partial · `·` none · `—` no verses.")
    L.append("")
    L.append("| Surah | Verses | EN 1–3 | AR 1–3 | UR 1–3 | QuickOverview | new_tafsir? |")
    L.append("|------:|------:|:------:|:------:|:------:|:-------------:|:-----------:|")
    for r in rows:
        L.append(
            f"| {r['surah']} | {r['total']} | "
            f"{cell(r['en'], r['total'])} | {cell(r['ar'], r['total'])} | "
            f"{cell(r['ur'], r['total'])} | {cell(r['qo'], r['total'])} | "
            f"{'yes' if r['has_new'] else ''} |"
        )
    L.append("")
    return "\n".join(L) + "\n"


def fmt_ranges(nums):
    """[1,2,3,17,18,19] -> '1–3, 17–19'."""
    if not nums:
        return "none"
    nums = sorted(nums)
    out, start, prev = [], nums[0], nums[0]
    for n in nums[1:] + [None]:
        if n == prev + 1:
            prev = n
            continue
        out.append(f"{start}" if start == prev else f"{start}–{prev}")
        start = prev = n
    return ", ".join(out)


def main():
    rows, pending, conflicts = analyze()
    report = render(rows, pending, conflicts)
    OUTPUT.write_text(report, encoding="utf-8")

    total_pending = sum(len(v) for langs in pending.values() for v in langs.values())
    print(f"Wrote {OUTPUT}")
    print(f"  surahs with bundled tafsir: {sum(1 for r in rows if r['total'] > 0)}/{TOTAL_SURAHS}")
    print(f"  pending merge fields:       {total_pending}")
    print(f"  conflicts:                  {len(conflicts)}")


if __name__ == "__main__":
    main()
