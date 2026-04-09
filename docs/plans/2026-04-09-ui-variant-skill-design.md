# Design: `generate-ui-variant` Skill

**Date:** 2026-04-09
**Status:** Approved, ready for implementation plan

## Problem

We want to explore new theme/design variants for AlBayan without
hand-designing mockups. Given a directory of screenshots from the running
app, we want an AI-driven pipeline that:

1. Understands the current UI (layout, palette, typography, mood)
2. Proposes multiple restyling directions that would suit a calm, reverent
   Quranic contemplation app
3. Generates restyled mockup images that preserve the exact layout
4. Produces a SwiftUI-ready style guide — in the same format as the
   existing `WARM_*_THEME_STYLE_GUIDE.md` docs — that a fresh Claude session
   can follow to implement the theme against `ThemeManager` / `ThemeVariant`

The goal is fast, cheap exploration of palette and material directions
without touching `ThemeManager.swift` until a variant is chosen.

## Solution Overview

A new project-local skill: `.claude/skills/generate-ui-variant/`.

It is modeled after the existing `generate-verse-art` skill (same
OpenRouter + Nano Banana Pro pipeline, same script location pattern) but
with very different responsibilities:

- **Multimodal analysis** happens in the main Claude session, not in the
  Python script. Claude reads the screenshots via the `Read` tool, proposes
  directions, picks exact hex codes from extracted palette data, and writes
  the style guide.
- **The Python script is a thin, pure function**: one screenshot in, one
  restyled variant + dominant-color palette out. No orchestration, no
  prompt-building, no guide-writing.
- **Layout is preserved exactly** via image-to-image: the screenshot is
  passed to Nano Banana Pro as an input image with instructions to change
  only visual treatment, not structure.

## Key Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | One end-to-end skill (not two) | Single command UX, matches `generate-verse-art` |
| 2 | Input = directory of screenshots | Natural for multi-screen style guides; iOS simulator exports fit directly |
| 3 | AI proposes variant directions, user does NOT provide them | User-requested — lets the model surface ideas the user wouldn't think of |
| 4 | Propose 3, user picks 1, generate just that one | Saves tokens vs. generating all 3; focused output |
| 5 | Preserve layout exactly (image-to-image) | Faithful mapping from variant back to style guide; clean diff = pure visual treatment |
| 6 | One variant per screenshot | Coherent multi-screen set; the style guide is extracted from the full set |
| 7 | Mirror `WARM_*_THEME_STYLE_GUIDE.md` structure | Another Claude session can implement directly against existing `ThemeManager` |
| 8 | Outputs to `ui_variants/<slug>/` (gitignored) | Self-contained artifact folder; parallels `verse_art/` convention |
| 9 | Vision analysis in main Claude session, not in Python | Main session is already multimodal and free to use; avoids duplicate model calls |
| 10 | Python script does k-means palette extraction via Pillow + numpy | Gives Claude exact hex codes instead of eyeballing them; minimal deps |
| 11 | Cap input at 6 screenshots, warn on overflow | Prevents accidental expensive runs |
| 12 | Do NOT cross-check against existing theme guides | User preference — keeps the skill simpler and trusts Claude's judgment |
| 13 | No fallback logic; fail fast on any step | Matches CLAUDE.md project rule; partial results would produce incoherent guides |

## Architecture

### Skill identity

- **Name:** `generate-ui-variant`
- **Path:** `.claude/skills/generate-ui-variant/`
- **Argument:** `$ARGUMENTS` = path to directory containing screenshots
- **Allowed tools:** `Read`, `Bash`, `Glob`, `Write`, `AskUserQuestion`
- **Example:** `/generate-ui-variant screenshots/modern_light/`

### File layout

```
.claude/skills/generate-ui-variant/
├── SKILL.md
└── scripts/
    └── generate_variant.py
```

### Runtime artifacts (created per run, gitignored)

```
ui_variants/
└── <slug>/
    ├── original_home.png        # copy of input screenshot
    ├── original_surah_detail.png
    ├── original_settings.png
    ├── variant_home.png         # Nano Banana output
    ├── variant_surah_detail.png
    ├── variant_settings.png
    ├── palette.json             # dominant colors per screenshot
    └── STYLE_GUIDE.md           # the deliverable
```

### End-to-end workflow (encoded in SKILL.md)

1. **Validate input.** Parse `$ARGUMENTS`; glob `*.png` / `*.jpg`; fail if
   empty; warn and take first 6 alphabetically if >6.
2. **Analyze current design.** Claude uses `Read` on each screenshot and
   builds an internal mental model: palette, typography character,
   components, mood. Not output to the user.
3. **Propose 3 distinct variant directions.** Each direction has a `slug`
   (lowercase_underscore), a `name`, and a 2–3 sentence `mood` description.
   Directions target a calm, reverent Quranic contemplation app.
4. **Ask the user to pick one** via `AskUserQuestion`.
5. **Build the Nano Banana prompt.** Image-to-image instructions:
   > "Restyle this exact UI screenshot with [palette], [typography mood],
   > [material treatment]. PRESERVE every component, its exact position,
   > every word of text, and the overall layout. Only change visual
   > styling — colors, gradients, textures, shadows, corner treatments,
   > material. Do NOT add or remove any UI elements. Do NOT change the
   > structure. The output must be the same screen, restyled."
6. **Generate variants.** One Python script call per screenshot:
   ```bash
   source .venv/bin/activate && \
   python3 .claude/skills/generate-ui-variant/scripts/generate_variant.py \
     --screenshot <path> \
     --prompt "<step 5 prompt>" \
     --slug <slug> \
     --output-dir ui_variants/<slug>
   ```
   Stop on first failure.
7. **Read the variants.** Claude uses `Read` on each `variant_*.png` and on
   `palette.json` to get exact hex codes from k-means extraction.
8. **Write `STYLE_GUIDE.md`** into `ui_variants/<slug>/` mirroring
   `docs/WARM_ROSE_THEME_STYLE_GUIDE.md` structure exactly:
   1. Title + Overview + theme philosophy
   2. Color Palette (Backgrounds / Text / Accents / Gradients tables with
      hex + RGB columns — hex values come from `palette.json`)
   3. Typography (SF Pro Rounded, same sizes as existing warm themes)
   4. Spacing (same `WarmSpacing` values as existing warm themes)
   5. Component examples
   6. SwiftUI code snippets
   7. Implementation Notes — which `ThemeVariant` case to add, which
      `ThemeManager` properties to update
9. **Final report.** Print output folder, list of files, and a one-liner
   showing how to apply the theme in a new session.

### Python script contract

**CLI:**
```
python3 generate_variant.py \
  --screenshot path/to/home.png \
  --prompt "Restyle this exact UI..." \
  --slug moonlit_pearl \
  --output-dir ui_variants/moonlit_pearl
```

**Responsibilities (and only these):**
1. Load `OPENROUTER_API_KEY` from `.env`
2. Base64-encode the input screenshot
3. Call OpenRouter `chat/completions` with `google/gemini-3-pro-image-preview`
   using a multimodal message:
   ```json
   [
     {"type": "text", "text": "<prompt>"},
     {"type": "image_url", "image_url": {"url": "data:image/png;base64,..."}}
   ]
   ```
   with `modalities: ["image", "text"]`
4. Parse image bytes from `message.images[0].image_url.url` (same parsing
   logic as `generate_art.py`)
5. Save variant to `<output-dir>/variant_<original_filename>`
6. Copy original to `<output-dir>/original_<original_filename>` for
   self-contained comparison
7. Run Pillow + numpy k-means to extract 8 dominant colors from the variant
   and append them to `<output-dir>/palette.json`, merging across
   invocations for the same slug:
   ```json
   {
     "screenshots": {
       "home.png": ["#2b2025", "#fff5f8", ...],
       "surah_detail.png": [...]
     }
   }
   ```
8. Print output paths and a success line

**Does NOT:** loop over screenshots, propose directions, read existing
tafsir/quran data, write the style guide, touch `ThemeManager.swift`.

**Dependencies:** `requests`, `python-dotenv`, `Pillow`, `numpy`.

**Errors:** raises on any API failure, missing env var, missing file, or
missing image in response. No fallback logic.

## Error Handling

| Situation | Behavior |
|---|---|
| `$ARGUMENTS` missing or dir doesn't exist | Stop, report, do nothing |
| Dir has 0 PNG/JPG files | Stop, report, do nothing |
| Dir has >6 files | Warn, process first 6 alphabetically |
| `OPENROUTER_API_KEY` missing | Script raises; Claude reports, stops |
| Nano Banana returns non-200 | Script raises with status+body; stop |
| Nano Banana returns no image | Script raises; stop |
| Pillow/numpy not installed | Import fails; Claude tells user to install |
| User cancels `AskUserQuestion` at step 4 | Exit cleanly, no files written |
| `ui_variants/<slug>/` exists from prior run | Overwrite without prompting |
| Screenshot N of 6 fails | Stop entire run; do NOT continue with N+1 |

Partial results are explicitly disallowed — an incomplete variant set
would produce an incoherent style guide.

## Testing

Manual smoke test on first run:

1. Export 3 screenshots from iOS simulator (Home, Surah Detail, Settings)
   into `screenshots/modern_light/`
2. Run `/generate-ui-variant screenshots/modern_light/`
3. Verify Claude reads all 3 images, proposes 3 named directions, presents
   the chooser
4. Pick one
5. Verify 3 `variant_*.png` files in `ui_variants/<slug>/` with layout
   matching originals but restyled
6. Verify `palette.json` has 6–8 hex codes per screenshot
7. Verify `STYLE_GUIDE.md` structurally matches `WARM_ROSE_THEME_STYLE_GUIDE.md`
   and its hex codes match `palette.json`

**Failure-mode checks:** empty dir, missing API key, cancel the question.

**Not included:** automated pytest, CI, linting. The skill is small enough
that manual verification on real runs is the test.

## Out of Scope

- Generating Swift code or modifying `ThemeManager.swift` / `ThemeVariant`
  (manual promotion step only)
- Any automated "promotion" of a chosen variant from `ui_variants/` into
  `docs/`
- Typography or spacing variation — only palette and material treatment
  vary between generated themes, matching how `WARM_ROSE` / `WARM_SAND`
  relate to `WARM_THEME` today
- Generating variants for non-iOS surfaces (web, macOS, etc.)
- Automated side-by-side comparison UI

## Manual Promotion Flow (after the skill runs)

When a variant is worth keeping:

1. Copy `ui_variants/<slug>/STYLE_GUIDE.md` → `docs/<SLUG>_THEME_STYLE_GUIDE.md`
2. Start a fresh Claude session: *"Read `docs/<SLUG>_THEME_STYLE_GUIDE.md`
   and add a new `<slug>` case to `ThemeVariant` in
   `Services/ThemeManager.swift`"*
3. The skill itself never touches Swift source — it only produces the guide.
