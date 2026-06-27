# Daily Features (Sunni) — Content Authoring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Author the Sunni **content** for the two ported daily-habit features — `daily_challenges.json` (~72 items) and the crossword `bank.json` (~110 terms) → generated `daily_crosswords.json` (365 puzzles) — all trilingual (en/ur/ar), validated, and dropped into AlBayan's bundled data directory.

**Architecture:** Content-only track. The crossword content is produced by a deterministic Python pipeline (`bank.json` → `generate.py` → `daily_crosswords.json` → `validate.py`); the challenge pool is hand-authored JSON checked by a sanity script. English is authored first, then `ur`/`ar` are filled by the project's translator subagents. The validators **are** the test harness — each authoring task is gated by a validator going from red → green.

**Tech Stack:** Python 3 (stdlib only; verified 3.13.7), JSON, the repo's `urdu-translator` / `arabic-translator` / `arabic-quality-checker` subagents.

---

## ⚠️ Read before executing

1. **Scope is content only.** The Swift **engine** (copy-verbatim) and **UI** (rebuild-in-theme) are a *separate track*, fully specified in `daily-features-sunni/README.md` + the two feature docs. This plan does **not** build them. It produces the JSON those layers will load. Recommended sequencing: engine/UI port lands first, then this content.
2. **No auto-commit (project rule).** Every "Checkpoint" below means: stop, show the diff, let the **user** commit manually. Do **not** run `git commit` automatically.
3. **The design is the source of truth for *what* to author:** `docs/plans/2026-06-24-daily-features-sunni-content-design.md`. This plan covers *how* and the verification gates; it does not duplicate the 14-theme spine, the keep/add/reclue/remove term lists, or the voice — read the design doc alongside it.
4. **`arabicText` is never translated.** In the challenge pool it holds a verbatim Qur'an āyah or du'ā. Translators must leave it untouched.
5. **TDD-for-content:** "write the failing test" = the validator/linter script exists and fails on missing/incomplete content; "make it pass" = author the content; "commit" = checkpoint.

---

## Phase A — Crossword pipeline setup

### Task A1: Copy the crossword scripts and repoint their output path

**Files:**
- Create: `scripts/crossword/generate.py` (copy of `daily-features-sunni/src/crossword/generate.py`)
- Create: `scripts/crossword/validate.py` (copy of `daily-features-sunni/src/crossword/validate.py`)

**Step 1: Copy both scripts verbatim**

```bash
mkdir -p scripts/crossword
cp daily-features-sunni/src/crossword/generate.py scripts/crossword/generate.py
cp daily-features-sunni/src/crossword/validate.py scripts/crossword/validate.py
```

**Step 2: Repoint the `OUT` path in BOTH files**

In `scripts/crossword/generate.py` (line ~27) **and** `scripts/crossword/validate.py` (line ~6), change the hardcoded source-app path:

```python
# OLD (both files):
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "Thaqalayn", "Data", "daily_crosswords.json"))
# NEW (both files) — AlBayan's bundled data dir is AlBayan/AlBayan/Data/:
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "AlBayan", "AlBayan", "Data", "daily_crosswords.json"))
```

(`HERE` = `scripts/crossword/`; `../../` resolves to the repo root, then `AlBayan/AlBayan/Data/`.)

**Step 3: Verify the scripts run and look in the right place (expected failure)**

Run: `python3 scripts/crossword/generate.py`
Expected: a clean `FileNotFoundError` mentioning `scripts/crossword/bank.json` (the bank doesn't exist yet). This confirms the script parses and resolves paths correctly.

**Step 4: Checkpoint** — review, user commits (`scripts/crossword/{generate,validate}.py`).

---

## Phase B — Crossword bank (English) + linter

### Task B1: Write the bank linter (the test)

**Files:**
- Create: `scripts/crossword/lint_bank.py`

**Step 1: Write the linter**

```python
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
```

**Step 2: Run it to verify it fails**

Run: `python3 scripts/crossword/lint_bank.py`
Expected: FAIL — `BANK LINT FAILED:` … (no `bank.json` yet).

**Step 3: Checkpoint** — user commits the linter.

### Task B2: Author the English term bank

**Files:**
- Create: `scripts/crossword/bank.json`

**Step 1: Author `bank.json`** following design §5 exactly:
- Same shape as `daily-features-sunni/src/crossword/bank.json` (`{ "_note": "...", "entries": [ {answer, theme, clue_en, clue_ur, clue_ar}, ... ] }`).
- **Leave `clue_ur` / `clue_ar` as empty strings `""` for now** (filled in Phase D). `clue_en` required.
- Apply the design's **KEEP / ADD / RECLUE / REMOVE** lists:
  - KEEP the ~80 already-neutral terms (prayers, surah-letters, prophets, names of God, concepts, places).
  - ADD the 14 virtue terms (`SABR SHUKR TAWBA RAHMA RIDA RAJA YAQIN NIYYA IKHLAS DHIKR KHULUQ AFW HILM SIDQ`), prophet-exemplars (`AYYUB YUNUS YUSUF SALIH IDRIS LUT HARUN DAWUD YAHYA ILYAS ISHAQ YAQUB ISMAIL SHUAYB`), Companions/Caliphs/Mothers (`ABU UMAR UTHMAN AISHA HAFSA HAMZA KHALID SAAD TALHA SALMAN ANAS MUADH`).
  - RECLUE `ALI HASAN ZAHRA ABBAS TALIB JAFAR KUFA BAYT IMAM` with the Sunni clues in design §5.
  - REMOVE `SHIA KHUMS MAHDI SADIQ BAQIR KAZIM JAWAD QUM` (the linter enforces these are absent).
- Target **~110 entries**, with **≥25 three-to-four-letter connectors**. Clues in the reflective voice (design §5 examples).

**Step 2: Run the linter (English mode)**

Run: `python3 scripts/crossword/lint_bank.py`
Expected: PASS — `BANK OK: ~110 entries, … connectors, English`.

**Step 3: Checkpoint** — user commits `bank.json`.

---

## Phase C — Challenge pool (English) + sanity script

### Task C1: Write the challenge sanity-check script (the test)

**Files:**
- Create: `scripts/validate_daily_challenges.py`

**Step 1: Write the script**

```python
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
```

**Step 2: Run it to verify it fails**

Run: `python3 scripts/validate_daily_challenges.py`
Expected: FAIL / `FileNotFoundError` (no `daily_challenges.json` yet).

**Step 3: Checkpoint** — user commits the script.

### Task C2: Author the English challenge pool

**Files:**
- Create: `AlBayan/AlBayan/Data/daily_challenges.json`

**Step 1: Author ~72 items** per design §3 (14-theme spine) and §4 (format spec, field rules, voice, sample templates):
- **~5 items per theme**, each theme spanning ≥3 of the 4 formats.
- Format totals near: `multipleChoice ≈ 24`, `fillInBlank ≈ 16`, `flashcard ≈ 16`, `trueFalse ≈ 16`.
- Stable ids `dc_001`…; `topic` = theme slug; `arabicText` = verbatim āyah/du'ā where used (never a translation); `source` = Sunni citation (Qur'an `surah:ayah`; hadith from Bukhārī/Muslim/Sunan/Riyāḍ aṣ-Ṣāliḥīn/Ḥiṣn al-Muslim).
- **Leave `ur`/`ar` absent for now** (filled in Phase D); populate `en` on every `LocalizedText`.
- Use the 4 worked examples in design §4 as the texture/voice template.

**Step 2: Run the sanity script (English mode)**

Run: `python3 scripts/validate_daily_challenges.py`
Expected: PASS — `CHALLENGES OK: 72 items | multipleChoice=24 trueFalse=16 flashcard=16 fillInBlank=16 [English]` (counts approximate).

**Step 3: Checkpoint** — user commits `daily_challenges.json`.

---

## Phase D — Translation (ur / ar) via subagents

> Phases D-challenges and D-bank are independent and may run in parallel. Batch to keep agent outputs reliable and parseable.

### Task D1: Translate the challenge pool

**Files:**
- Modify: `AlBayan/AlBayan/Data/daily_challenges.json`

**Step 1: Dispatch translators, batched by theme (~5 items/batch).** For each batch, dispatch `urdu-translator` then `arabic-translator` with this instruction:

> Translate the user-facing strings of these Daily-Challenge JSON objects into {Urdu|Arabic}. For every `LocalizedText` object (`prompt`, each entry of `options`, `answer`, `explanation`) add a `{"ur"|"ar"}` key alongside `en`. **Do NOT modify** `id`, `format`, `topic`, `correctIndex`, `source`, or `arabicText` (that field is a verbatim Qur'an/du'ā — leave it exactly as-is). Keep transliterated proper nouns natural in the target script. Preserve the warm, reflective register. Return valid JSON with identical structure.

**Step 2: Quality-check Arabic.** Dispatch `arabic-quality-checker` over the Arabic strings; apply fixes.

**Step 3: Run the trilingual gate**

Run: `python3 scripts/validate_daily_challenges.py --trilingual`
Expected: PASS — `… [trilingual]`.

**Step 4: Checkpoint** — user commits.

### Task D2: Translate the crossword bank clues

**Files:**
- Modify: `scripts/crossword/bank.json`

**Step 1: Dispatch translators in batches (~25 terms/batch).** Instruction:

> For each bank entry, fill `clue_ur` and `clue_ar` by translating `clue_en` into {Urdu|Arabic}. **Do NOT change** `answer` or `theme`. Clues are short and reflective — keep that tone. Return valid JSON with identical structure.

**Step 2: Quality-check Arabic** via `arabic-quality-checker`; apply fixes.

**Step 3: Run the trilingual lint**

Run: `python3 scripts/crossword/lint_bank.py --trilingual`
Expected: PASS — `… trilingual`.

**Step 4: Checkpoint** — user commits `bank.json`.

---

## Phase E — Generate & validate the crosswords

### Task E1: Generate the puzzles

**Files:**
- Create (generated): `AlBayan/AlBayan/Data/daily_crosswords.json`

**Step 1: Run the generator**

Run: `python3 scripts/crossword/generate.py`
Expected: `wrote 365 puzzles to .../AlBayan/AlBayan/Data/daily_crosswords.json (in N attempts)`.
- If it writes **fewer than 365**, the bank lacks interlocking short words → add more 3–4 letter connectors to `bank.json` (translate the additions), then re-run. (Deterministic: seed=11, so re-runs are identical.)

**Step 2: Checkpoint** — user commits `daily_crosswords.json`.

### Task E2: Validate the puzzles (the gate)

**Step 1: Run the validator**

Run: `python3 scripts/crossword/validate.py`
Expected: `ALL 365 PUZZLES VALID  (ids unique, crossings consistent, trilingual clues present)`.
- On `VALIDATION FAILED: … missing clue.ur/ar` → a bank clue wasn't translated; fix in `bank.json`, re-run E1 then E2.

**Step 2: Checkpoint.**

---

## Phase F — Final gates & handoff notes

### Task F1: Full content verification

**Step 1: Run all three validators clean, in order**

```bash
python3 scripts/crossword/lint_bank.py --trilingual
python3 scripts/validate_daily_challenges.py --trilingual
python3 scripts/crossword/generate.py && python3 scripts/crossword/validate.py
```
Expected: all pass; `daily_challenges.json` and `daily_crosswords.json` both present in `AlBayan/AlBayan/Data/`.

**Step 2: Checkpoint.**

### Task F2: Handoff notes (not code — record for the engine/UI track and release)

- **Bundle membership:** both `daily_challenges.json` and `daily_crosswords.json` must be added to the AlBayan Xcode target's "Copy Bundle Resources" (the providers `fatalError` if a file is missing — that's intended). This is done in the engine/UI track, but flag it so it isn't missed.
- **Scholar review (hard pre-release gate, design §7):** a qualified Sunni scholar reviews the full challenge pool + crossword clues before release.
- **Chrome strings:** when the engine/UI track copies `DailyChallengeStrings.swift` / `DailyCrosswordStrings.swift`, confirm wording reads Sunni-neutral (it already is).

---

## Acceptance criteria (whole plan)

- [ ] `scripts/crossword/{generate,validate}.py` copied, `OUT` repointed to `AlBayan/AlBayan/Data/`.
- [ ] `scripts/crossword/lint_bank.py` and `scripts/validate_daily_challenges.py` exist and gate the content.
- [ ] `bank.json` ~110 terms, no forbidden terms, central figures reclued; `lint_bank.py --trilingual` passes.
- [ ] `daily_challenges.json` ~72 items, format spread ≈24/16/16/16, all trilingual; `validate_daily_challenges.py --trilingual` passes.
- [ ] `generate.py` writes 365 puzzles; `validate.py` prints `ALL 365 PUZZLES VALID`.
- [ ] No Imamate/Twelve-Imams/Ghadeer/Kumayl/Khums/Shia-identity content anywhere; sources are Sunni.
- [ ] Nothing committed automatically — user reviewed and committed at each checkpoint.
