# Generate UI Variant Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a project-local `generate-ui-variant` skill that takes a directory of app screenshots, proposes 3 restyling directions, generates variant mockups via Nano Banana Pro (layout preserved via image-to-image), and writes a SwiftUI-ready style guide mirroring `WARM_ROSE_THEME_STYLE_GUIDE.md`.

**Architecture:** Thin Python script handles one screenshot at a time (API call + image save + Pillow palette extraction). The main Claude session — which is multimodal — reads the screenshots, proposes variant directions, orchestrates the script calls, reads the generated variants, and writes the style guide. Zero duplicate model calls.

**Tech Stack:** Python 3 (argparse, requests, python-dotenv, Pillow), OpenRouter API with `google/gemini-3-pro-image-preview`, existing `.venv`. No new heavy dependencies — Pillow is the only new library if not already installed.

**Design doc:** `docs/plans/2026-04-09-ui-variant-skill-design.md`

**Reference file:** `.claude/skills/generate-verse-art/scripts/generate_art.py` — existing Nano Banana integration, parse pattern for `message.images[0].image_url.url`.

**Reference file:** `docs/WARM_ROSE_THEME_STYLE_GUIDE.md` — target structure for the generated `STYLE_GUIDE.md`.

**No automated tests.** Per the design doc Section 7, verification is manual — the skill is small enough (≈150 LOC script + SKILL.md prose) that pytest mocking would be more ceremony than signal. Each task has a concrete manual check instead of a failing-test step.

---

## Task 1: Add `ui_variants/` to .gitignore

**Files:**
- Modify: `.gitignore`

**Step 1: Read the current .gitignore and find the `verse_art/` line**

Use the Read tool on `.gitignore`. Confirm `verse_art/` is on line 112 (per the repo snapshot; adjust if the file has drifted).

**Step 2: Add `ui_variants/` directly below `verse_art/`**

Use the Edit tool:

- `old_string`: `verse_art/`
- `new_string`: `verse_art/
ui_variants/`

**Step 3: Verify the change**

Run: `git diff .gitignore`
Expected output: a one-line addition of `ui_variants/`.

**Step 4: Commit**

```bash
git add .gitignore
git commit -m "$(cat <<'EOF'
chore: gitignore ui_variants/ artifact directory

The generate-ui-variant skill will write experimental theme mockups and
extracted style guides into ui_variants/<slug>/. These are local
exploration artifacts, not source — keep them out of version control
alongside the existing verse_art/ convention.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Scaffold skill directory and verify Pillow availability

**Files:**
- Create: `.claude/skills/generate-ui-variant/SKILL.md` (skeleton)
- Create: `.claude/skills/generate-ui-variant/scripts/generate_variant.py` (empty stub with shebang)

**Step 1: Check Pillow is installed in the project venv**

Run:
```bash
source .venv/bin/activate && python3 -c "import PIL; print(PIL.__version__)"
```

Expected: version string like `10.4.0`.

If it fails with `ModuleNotFoundError`, install:
```bash
source .venv/bin/activate && pip install Pillow
```
Then rerun the version check to confirm.

**Step 2: Also verify requests and python-dotenv**

Run:
```bash
source .venv/bin/activate && python3 -c "import requests, dotenv; print('ok')"
```

Expected: `ok`. These should already be installed (used by `generate-verse-art`). If missing, `pip install requests python-dotenv`.

**Step 3: Create the SKILL.md skeleton**

Write `.claude/skills/generate-ui-variant/SKILL.md` with ONLY the frontmatter and a `# Generate UI Variant` heading — no body content yet. This reserves the file so Task 4 can use Edit to expand it.

```markdown
---
name: generate-ui-variant
description: Generate UI design variants for app screenshots using Nano Banana Pro. Analyzes screenshots, proposes 3 style directions, generates variant mockups, and writes a SwiftUI-ready style guide. Use when asked to explore theme/design variants of the app.
argument-hint: [screenshots-directory]
allowed-tools: Read, Bash, Glob, Write, AskUserQuestion
---

# Generate UI Variant

TODO: filled in Task 4.
```

**Step 4: Create the Python script stub**

Write `.claude/skills/generate-ui-variant/scripts/generate_variant.py` with just the shebang and docstring. The full implementation goes in Task 3.

```python
#!/usr/bin/env python3
"""
Generate a restyled UI variant for an app screenshot using OpenRouter's
Nano Banana Pro model, and extract the dominant color palette.

Usage:
    python3 generate_variant.py \\
        --screenshot path/to/home.png \\
        --prompt "Restyle this UI..." \\
        --slug moonlit_pearl \\
        --output-dir ui_variants/moonlit_pearl
"""

# TODO: implemented in Task 3.
```

**Step 5: Verify files exist**

Run:
```bash
ls .claude/skills/generate-ui-variant/ && ls .claude/skills/generate-ui-variant/scripts/
```

Expected:
```
SKILL.md
scripts
generate_variant.py
```

**Step 6: Commit**

```bash
git add .claude/skills/generate-ui-variant/
git commit -m "$(cat <<'EOF'
feat(skill): scaffold generate-ui-variant skill directory

Creates the skill frontmatter stub and an empty Python script placeholder.
Full workflow and script body land in the following commits. Scaffolded
separately so the later implementation commits produce clean, reviewable
diffs against real files.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Implement the Python script

**Files:**
- Modify: `.claude/skills/generate-ui-variant/scripts/generate_variant.py`

**Step 1: Replace the stub with the full script**

Use the Write tool to replace the file contents entirely with:

```python
#!/usr/bin/env python3
"""
Generate a restyled UI variant for an app screenshot using OpenRouter's
Nano Banana Pro model, and extract the dominant color palette.

Usage:
    python3 generate_variant.py \\
        --screenshot path/to/home.png \\
        --prompt "Restyle this UI..." \\
        --slug moonlit_pearl \\
        --output-dir ui_variants/moonlit_pearl
"""

import argparse
import base64
import json
import os
import shutil
from pathlib import Path

import requests
from dotenv import load_dotenv
from PIL import Image

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
MODEL = "google/gemini-3-pro-image-preview"
API_URL = "https://openrouter.ai/api/v1/chat/completions"


def build_payload(screenshot_path: Path, prompt: str) -> dict:
    """Build the OpenRouter multimodal chat-completions payload."""
    with open(screenshot_path, "rb") as f:
        img_bytes = f.read()
    b64 = base64.b64encode(img_bytes).decode("utf-8")
    data_url = f"data:image/png;base64,{b64}"

    return {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": data_url}},
                ],
            }
        ],
        "modalities": ["image", "text"],
    }


def call_nano_banana(payload: dict) -> bytes:
    """Call OpenRouter and return the generated image bytes."""
    if not OPENROUTER_API_KEY:
        raise ValueError("OPENROUTER_API_KEY not found in .env file")

    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://albayan.app",
        "X-Title": "AlBayan UI Variant Generator",
    }

    response = requests.post(API_URL, headers=headers, json=payload, timeout=180)

    if response.status_code != 200:
        raise Exception(f"API error {response.status_code}: {response.text}")

    result = response.json()

    choices = result.get("choices", [])
    if not choices:
        raise Exception(f"No choices in API response: {result}")

    message = choices[0].get("message", {})
    images = message.get("images", [])

    for img in images:
        if isinstance(img, dict) and "image_url" in img:
            url = img["image_url"].get("url", "")
            if url.startswith("data:"):
                b64_data = url.split(",", 1)[1]
                return base64.b64decode(b64_data)
            elif url:
                img_response = requests.get(url, timeout=60)
                img_response.raise_for_status()
                return img_response.content

    raise Exception(f"No image found in API response: {result}")


def extract_palette(image_path: Path, n_colors: int = 8) -> list:
    """
    Extract dominant colors from an image using Pillow's median-cut quantize.

    Returns a list of hex strings sorted by pixel frequency (most common first).
    """
    img = Image.open(image_path).convert("RGB")
    quantized = img.quantize(colors=n_colors, method=Image.Quantize.MEDIANCUT)

    palette_flat = quantized.getpalette()[: n_colors * 3]
    hex_by_index = [
        f"#{palette_flat[i]:02x}{palette_flat[i + 1]:02x}{palette_flat[i + 2]:02x}"
        for i in range(0, n_colors * 3, 3)
    ]

    counts = quantized.getcolors()  # [(count, index), ...]
    if counts is None:
        return hex_by_index

    counts.sort(reverse=True)
    return [hex_by_index[idx] for _, idx in counts if idx < len(hex_by_index)]


def update_palette_json(output_dir: Path, original_filename: str, palette: list) -> None:
    """Append palette data to the shared palette.json in the output dir."""
    palette_path = output_dir / "palette.json"

    data = {"screenshots": {}}
    if palette_path.exists():
        with open(palette_path, "r") as f:
            data = json.load(f)
        if "screenshots" not in data:
            data["screenshots"] = {}

    data["screenshots"][original_filename] = palette

    with open(palette_path, "w") as f:
        json.dump(data, f, indent=2)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a UI variant via Nano Banana Pro"
    )
    parser.add_argument("--screenshot", required=True, type=Path)
    parser.add_argument("--prompt", required=True, type=str)
    parser.add_argument("--slug", required=True, type=str)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    if not args.screenshot.exists():
        raise FileNotFoundError(f"Screenshot not found: {args.screenshot}")

    args.output_dir.mkdir(parents=True, exist_ok=True)

    original_filename = args.screenshot.name
    original_copy_path = args.output_dir / f"original_{original_filename}"
    variant_path = args.output_dir / f"variant_{original_filename}"

    print(f"[1/4] Copying original to {original_copy_path}")
    shutil.copy(args.screenshot, original_copy_path)

    print(f"[2/4] Calling Nano Banana Pro for {original_filename}...")
    payload = build_payload(args.screenshot, args.prompt)
    image_bytes = call_nano_banana(payload)
    print(f"      Received {len(image_bytes)} bytes")

    print(f"[3/4] Saving variant to {variant_path}")
    with open(variant_path, "wb") as f:
        f.write(image_bytes)

    print(f"[4/4] Extracting palette from variant")
    palette = extract_palette(variant_path, n_colors=8)
    update_palette_json(args.output_dir, original_filename, palette)
    print(f"      Palette: {palette}")

    print(f"\nSuccess. Slug: {args.slug}")
    print(f"  Original: {original_copy_path}")
    print(f"  Variant:  {variant_path}")
    print(f"  Palette:  {args.output_dir / 'palette.json'}")


if __name__ == "__main__":
    main()
```

**Step 2: Verify it parses and `--help` works**

Run:
```bash
source .venv/bin/activate && python3 .claude/skills/generate-ui-variant/scripts/generate_variant.py --help
```

Expected: argparse help output listing `--screenshot`, `--prompt`, `--slug`, `--output-dir`. If there's a SyntaxError, ImportError, or import fails on PIL/requests/dotenv, fix before moving on.

**Step 3: Smoke-test palette extraction in isolation**

This verifies the non-API path works. Feed it an existing PNG from the repo:

```bash
source .venv/bin/activate && python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, '.claude/skills/generate-ui-variant/scripts')
from generate_variant import extract_palette
palette = extract_palette(Path('AlBayan/Assets.xcassets/AppIcon.appiconset/icon-1024.png'), n_colors=8)
print('Palette:', palette)
assert len(palette) <= 8, f'expected <=8 colors, got {len(palette)}'
assert all(p.startswith('#') and len(p) == 7 for p in palette), f'bad hex format: {palette}'
print('OK')
"
```

Expected: a list of up to 8 hex strings like `['#abc123', '#def456', ...]` followed by `OK`. Any exception = fix before continuing.

**Step 4: Smoke-test argument validation**

Run with a non-existent screenshot:
```bash
source .venv/bin/activate && python3 .claude/skills/generate-ui-variant/scripts/generate_variant.py \
  --screenshot /tmp/does_not_exist.png \
  --prompt "test" \
  --slug test \
  --output-dir /tmp/ui_variants_test 2>&1 | head -5
```

Expected: `FileNotFoundError: Screenshot not found: /tmp/does_not_exist.png`. The script should exit non-zero.

**Step 5: Clean up any stray test artifacts**

If `/tmp/ui_variants_test` was created, remove it:
```bash
rm -rf /tmp/ui_variants_test
```

**Step 6: Commit**

```bash
git add .claude/skills/generate-ui-variant/scripts/generate_variant.py
git commit -m "$(cat <<'EOF'
feat(skill): implement generate-ui-variant Python script

Thin per-screenshot driver: accepts --screenshot/--prompt/--slug/--output-dir,
posts a multimodal image-to-image request to OpenRouter's Nano Banana Pro,
saves the restyled variant alongside a copy of the original, and extracts
an 8-color dominant palette via Pillow's median-cut quantize (merged into
a shared palette.json per slug).

Pure function: no loop over screenshots, no prompt building, no style
guide writing — orchestration lives in SKILL.md and the main Claude
session. Matches the generate-verse-art script's OpenRouter response
parsing pattern.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Write the full SKILL.md workflow

**Files:**
- Modify: `.claude/skills/generate-ui-variant/SKILL.md`

**Step 1: Replace the stub with the full workflow**

Use the Write tool to replace the file contents entirely with:

````markdown
---
name: generate-ui-variant
description: Generate UI design variants for app screenshots using Nano Banana Pro. Analyzes screenshots, proposes 3 style directions, generates variant mockups, and writes a SwiftUI-ready style guide. Use when asked to explore theme/design variants of the app.
argument-hint: [screenshots-directory]
allowed-tools: Read, Bash, Glob, Write, AskUserQuestion
---

# Generate UI Variant

Given a directory of app screenshots, propose 3 design directions, let the user pick one, generate restyled mockups via Nano Banana Pro (layout preserved via image-to-image), and write a SwiftUI-ready style guide another Claude session can implement against the existing `ThemeManager`.

## Instructions

Follow these steps IN ORDER. Do not skip or reorder.

### Step 1 — Validate input

- Parse `$ARGUMENTS` as the screenshots directory path
- Use the Glob tool to find `*.png`, `*.jpg`, and `*.jpeg` files in that directory
- If 0 files: tell the user "No PNG/JPG files found in <dir>" and stop
- If >6 files: warn the user, take the first 6 alphabetically, continue
- Report: "Found N screenshots: a.png, b.png, ..."

### Step 2 — Analyze current design

Use the Read tool on each screenshot. Do not output the analysis — it is internal context. Build a mental model of:

- Dominant palette (background, text, accent colors)
- Typography character (rounded/serif/sans, weight, size impression)
- Component treatments (cards, gradients, shadows, corner radii, borders)
- Overall mood (warm/cool, flat/material, dense/airy, playful/reverent)

### Step 3 — Propose 3 distinct variant directions

Generate 3 directions that would work well for a calm, reverent, legible Quranic contemplation app. Each direction MUST have:

- `slug`: lowercase_underscore, e.g. `moonlit_pearl`
- `name`: human title, e.g. "Moonlit Pearl"
- `mood`: 2-3 sentences describing palette, material treatment, and feel

Make the 3 directions genuinely distinct — different palette temperatures, different material philosophies, different moods. Do not propose minor tweaks of the same idea.

### Step 4 — Ask the user to pick one

Use the `AskUserQuestion` tool with the 3 directions as options. Each option's `label` is the name, `description` is the mood. Wait for the user's pick before continuing. If the user cancels, stop cleanly.

### Step 5 — Build the Nano Banana image-to-image prompt

Construct a detailed prompt for the chosen direction. The prompt MUST include all of these clauses verbatim (paraphrasing weakens layout preservation):

- "Restyle this exact UI screenshot with [your palette description], [typography mood], [material treatment from the chosen direction]."
- "PRESERVE every component, its exact position, every word of text, and the overall layout."
- "Only change visual styling — colors, gradients, textures, shadows, corner treatments, material."
- "Do NOT add or remove any UI elements. Do NOT change the structure."
- "The output must be the same screen, restyled."

### Step 6 — Generate variants (one script call per screenshot)

For each screenshot from Step 1, run via the Bash tool:

```bash
source .venv/bin/activate && \
python3 .claude/skills/generate-ui-variant/scripts/generate_variant.py \
  --screenshot "<absolute-path-to-screenshot>" \
  --prompt "<the full prompt from Step 5>" \
  --slug "<slug>" \
  --output-dir "ui_variants/<slug>"
```

If ANY script call fails (non-zero exit), STOP the entire workflow and report the error to the user. Do NOT continue with remaining screenshots. Do NOT write a style guide from a partial set — an incomplete variant set produces an incoherent guide.

### Step 7 — Read the variants and the palette

- Use the Read tool on each `ui_variants/<slug>/variant_*.png` to see what Nano Banana produced
- Use the Read tool on `ui_variants/<slug>/palette.json` to get exact hex codes (these are the authoritative hex values — do not eyeball colors from the image)

### Step 8 — Write `STYLE_GUIDE.md`

Write `ui_variants/<slug>/STYLE_GUIDE.md` using the Write tool. The structure MUST mirror `docs/WARM_ROSE_THEME_STYLE_GUIDE.md` exactly:

1. **Title + Overview** — include a "Theme Philosophy" paragraph drawn from the chosen direction's mood
2. **Color Palette** — four tables: Backgrounds, Text Colors, Accent Colors, Gradients. Each row has Purpose, Hex, RGB, Usage columns. Use hex codes from `palette.json`. Compute RGB tuples yourself as SwiftUI values 0-1 (e.g. `#2B2025` → `(0.169, 0.125, 0.145)`)
3. **Typography** — match the existing warm themes: SF Pro Rounded, same sizes (Large Title 34pt Bold, Headline 20pt SemiBold, Subheadline 18pt Medium, Body 17pt Regular, Caption 14pt Medium, Arabic 24-32pt Medium)
4. **Spacing** — match existing `WarmSpacing` enum values (tiny 4, small 8, medium 12, etc.). Do not invent new values.
5. **Component examples** — Card style, Button style, Header treatment
6. **SwiftUI code snippets** — show `LinearGradient` usage, `.background()` modifiers, text styles with the new palette
7. **Implementation Notes** — which case to add to `ThemeVariant` in `Services/ThemeManager.swift`, which `ThemeManager` properties to update, and a one-line "how to apply in a fresh session"

### Step 9 — Final report

Print to the user:

- The output folder path: `ui_variants/<slug>/`
- The list of all generated files (originals, variants, palette.json, STYLE_GUIDE.md)
- A one-liner showing how to apply the theme in a fresh session:
  > "To implement this theme: start a new Claude session and say 'Read `ui_variants/<slug>/STYLE_GUIDE.md` and add a new `<slug>` case to `ThemeVariant` in `Services/ThemeManager.swift`.'"

## Input Format

- Directory path: `screenshots/modern_light/`
- Files inside: `.png`, `.jpg`, `.jpeg`
- Max 6 files processed per run (alphabetical order if more)

## Output

- `ui_variants/<slug>/original_*.png` — copies of input screenshots
- `ui_variants/<slug>/variant_*.png` — Nano Banana Pro restyled variants
- `ui_variants/<slug>/palette.json` — extracted dominant colors per screenshot
- `ui_variants/<slug>/STYLE_GUIDE.md` — SwiftUI-ready style guide

## Requirements

- `.env` file with `OPENROUTER_API_KEY`
- Python virtual environment at `.venv` with `requests`, `python-dotenv`, `Pillow` installed

## Error Handling

- Any API failure → stop immediately, no partial results
- Missing API key → stop, tell user to add `OPENROUTER_API_KEY` to `.env`
- Missing Python deps → stop, tell user to `pip install Pillow python-dotenv requests`
- Empty input directory → stop
- User cancels at Step 4 → clean exit, no files written
````

**Step 2: Sanity check the file**

Use the Read tool on `.claude/skills/generate-ui-variant/SKILL.md` and verify:

- Frontmatter is intact with all 4 fields
- All 9 workflow steps are present (Step 1 through Step 9)
- The bash snippet in Step 6 references the correct script path
- No stray `TODO` markers remain from the scaffold

**Step 3: Verify no markdown lint issues via a crude structure check**

Run:
```bash
grep -c "^### Step" .claude/skills/generate-ui-variant/SKILL.md
```

Expected: `9`.

**Step 4: Commit**

```bash
git add .claude/skills/generate-ui-variant/SKILL.md
git commit -m "$(cat <<'EOF'
feat(skill): add full generate-ui-variant workflow to SKILL.md

Nine-step instruction set: validate input dir, analyze screenshots via
Read, propose 3 distinct variant directions, ask user to pick, build an
image-to-image prompt that explicitly preserves layout, invoke the
Python script once per screenshot, read generated variants + palette.json,
write a STYLE_GUIDE.md mirroring WARM_ROSE_THEME_STYLE_GUIDE.md, and
report results with a one-liner for handing off to a fresh session.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Manual end-to-end verification (no commit)

This task has no code changes and no commit — it is a checklist that must pass before you can claim the skill works. It requires the user to provide real screenshots and have `OPENROUTER_API_KEY` set.

**Step 1: Ask the user for a test input**

Prompt the user: *"The skill is built. To verify end-to-end, I need a directory of 2–3 iOS simulator screenshots from the current app. Where are they, or shall I wait until you have some ready?"*

If the user says "just verify the parts you can without API calls" — stop at Step 3 of this task and report success.

**Step 2: Confirm `OPENROUTER_API_KEY` is set**

Run:
```bash
grep -q "OPENROUTER_API_KEY" .env && echo "key present" || echo "MISSING KEY"
```

Expected: `key present`. If missing, tell the user to add it and stop.

**Step 3: Dry-run check — verify skill discovery**

Simulating what happens at invocation time, just confirm the skill files load:

```bash
test -f .claude/skills/generate-ui-variant/SKILL.md && \
test -x .claude/skills/generate-ui-variant/scripts/generate_variant.py || \
test -f .claude/skills/generate-ui-variant/scripts/generate_variant.py && \
echo "skill files present"
```

Expected: `skill files present`.

Also re-run the palette extraction smoke test from Task 3 Step 3 to make sure that path still works:
```bash
source .venv/bin/activate && python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, '.claude/skills/generate-ui-variant/scripts')
from generate_variant import extract_palette
print(extract_palette(Path('AlBayan/Assets.xcassets/AppIcon.appiconset/icon-1024.png'), 8))
"
```

Expected: list of hex strings, no exceptions.

**Step 4: Full pipeline run (requires user-provided screenshots)**

Once the user has placed screenshots in e.g. `screenshots/modern_light/`:

1. Run the skill: `/generate-ui-variant screenshots/modern_light/`
2. Verify Claude reads all screenshots
3. Verify 3 distinct variant directions are proposed with slug + name + mood
4. Verify the `AskUserQuestion` tool presents the 3 options
5. Pick one
6. Verify script runs once per screenshot without error
7. Verify `ui_variants/<slug>/` contains:
   - `original_*.png` for each input
   - `variant_*.png` for each input
   - `palette.json` with 8 hex codes per screenshot
   - `STYLE_GUIDE.md` with all 7 sections (Title, Color Palette, Typography, Spacing, Components, Code Snippets, Implementation Notes)
8. Verify the hex codes in `STYLE_GUIDE.md` match values present in `palette.json` (Claude should have used them directly, not guessed)
9. Open one of the `variant_*.png` files visually and confirm the layout matches the original (same components in the same positions, restyled)

**Step 5: Failure-mode spot checks**

Only if time permits — not required to ship:

1. Empty directory:
   ```bash
   mkdir -p /tmp/empty_screenshots && /generate-ui-variant /tmp/empty_screenshots
   ```
   Expected: skill reports "No PNG/JPG files found" and stops.

2. Directory with 8 screenshots (>6 cap):
   Expected: skill warns, processes first 6 alphabetically.

3. Cancel the `AskUserQuestion` chooser:
   Expected: clean exit, no files written in `ui_variants/`.

**Step 6: Report to the user**

Write a short verification report summarizing:

- Which checks passed
- Any variance between the generated variant and the original layout
- Any issues with palette accuracy or style guide structure
- Suggestions for the first "real" theme variant to try

No commit for this task.

---

## Summary of commits

| Task | Commit subject |
|---|---|
| 1 | `chore: gitignore ui_variants/ artifact directory` |
| 2 | `feat(skill): scaffold generate-ui-variant skill directory` |
| 3 | `feat(skill): implement generate-ui-variant Python script` |
| 4 | `feat(skill): add full generate-ui-variant workflow to SKILL.md` |
| 5 | (no commit — manual verification) |

Four commits, one verification pass. End-to-end the skill is ready once Task 5's full-pipeline run succeeds against real screenshots.
