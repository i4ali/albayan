# Modern Light Theme — Design Document

**Date:** 2026-04-09
**Status:** Approved (design phase)
**Related style guide:** `docs/MODERN_LIGHT_THEME_STYLE_GUIDE.md`

---

## 1. Goal

Add a fourth theme variant, `modernLight`, positioned as the cool-neutral minimalist light counterpart to the existing `modernDark`. The theme is a color/material variation only — no new architecture, no new enums, no new helper types, no call-site changes beyond Swift switch exhaustiveness.

## 2. Philosophy & Positioning

**Tagline:** "Refined earthy minimalism — serenity through breathable white space and warm terracotta accents."

Where `warmInviting` offers a lavender sanctuary feel and `modernDark` offers indigo-pink tech vibrancy, Modern Light offers earthy breathability: off-white backgrounds, pure white cards, a single warm terracotta accent, and subtle multi-pastel ambience. It is the "earthy minimalist" light option for users who want warmth over purple or tech clarity — Moleskine/Kinfolk/Muji rather than lavender sanctuary or iOS clinical.

### Distinguishing Traits vs. `warmInviting`

| Aspect | warmInviting | modernLight |
|---|---|---|
| Primary background | Soft lavender `#F8F5FF` | Off-white cool `#F8F9FB` |
| Primary text | Warm charcoal `#2D2520` | True charcoal `#1A1A1A` |
| Primary accent | Peaceful purple `#9B8FBF` | Warm terracotta `#B86E5C` |
| Card shadow opacity | `0.04` | `0.05` |
| Floating orbs | Purple / orange / green | Sage / amber / rose |
| Overall feel | Lavender sanctuary | Earthy minimalism |

## 3. Color Palette

### Backgrounds

| Purpose | Hex | RGB |
|---|---|---|
| Primary Background | `#F8F9FB` | `(0.973, 0.976, 0.984)` |
| Secondary Background | `#FFFFFF` | `(1.0, 1.0, 1.0)` |
| Tertiary Background | `#F1F3F7` | `(0.945, 0.953, 0.969)` |

### Text

| Purpose | Hex | RGB |
|---|---|---|
| Primary Text | `#1A1A1A` | `(0.102, 0.102, 0.102)` |
| Secondary Text | `#757575` | `(0.459, 0.459, 0.459)` |
| Tertiary Text | `#A8A8A8` | `(0.659, 0.659, 0.659)` |

### Primary Accent

| Purpose | Hex | RGB |
|---|---|---|
| Warm Terracotta (accent) | `#B86E5C` | `(0.722, 0.431, 0.361)` |
| Deep Terracotta (gradient end) | `#9A5A4B` | `(0.604, 0.353, 0.294)` |

> **Post-QA adjustments (2026-04-09):** This theme went through three accent iterations. Initial `#90BCE1` (muted baby blue) read washed-out. Second iteration `#5B9DD9` (steel blue) was more confident but still too cold/clinical against off-white. Final choice: `#B86E5C` warm terracotta — shifts personality from "cool-neutral tech minimal" to "warm earthy minimal" (Moleskine/Kinfolk/Muji). The name "Modern Light" is retained but the feel is now earthy rather than tech. The original `#90BCE1` is retained as the Quizzes category pastel in progress rings.

### Supporting Pastels (ambient use only, `floatingOrbColors`)

| Purpose | Hex | RGB | Opacity |
|---|---|---|---|
| Sage Green | `#89C9B4` | `(0.537, 0.788, 0.706)` | `0.08` |
| Soft Amber | `#EBC078` | `(0.922, 0.753, 0.471)` | `0.07` |
| Dusty Rose | `#D995A1` | `(0.851, 0.584, 0.631)` | `0.06` |

### Stroke

| Purpose | Value |
|---|---|
| Stroke Color | `Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08)` |

## 4. Typography, Spacing, Radii

All inherited from the existing theme system with zero changes:

- **Fonts** — SF Pro `.rounded` at the existing sizes (34pt Bold title, 20pt SemiBold headline, 17pt Regular body, 14pt Medium caption, 24-32pt Arabic).
- **Spacing** — reuses `WarmSpacing` enum unchanged (4 / 8 / 12 / 16 / 20 / 24 / 28 / 32).
- **Radii** — reuses `WarmRadius` enum unchanged (12 / 16 / 20 / 24). The style guide's 24-32pt card radius directive is intentionally *not* adopted so Modern Light stays visually consistent with other themes on shared components.
- **Glass material** — `.ultraThin` (same as `warmInviting`).

## 5. ThemeManager Property Mapping

Every switch case in `AlBayan/Services/ThemeManager.swift` needs a `.modernLight` branch. Exhaustive list:

| Property | Value |
|---|---|
| `colorScheme` | `.light` |
| `isDarkMode` | `false` (default `== .modernDark \|\| == .royalAmethyst` covers it) |
| `primaryBackground` | `Color(red: 0.973, green: 0.976, blue: 0.984)` |
| `secondaryBackground` | `Color(red: 1.0, green: 1.0, blue: 1.0)` |
| `tertiaryBackground` | `Color(red: 0.945, green: 0.953, blue: 0.969)` |
| `primaryText` | `Color(red: 0.102, green: 0.102, blue: 0.102)` |
| `secondaryText` | `Color(red: 0.459, green: 0.459, blue: 0.459)` |
| `tertiaryText` | `Color(red: 0.659, green: 0.659, blue: 0.659)` |
| `accentColor` | `Color(red: 0.722, green: 0.431, blue: 0.361)` |
| `accentGradient` | Linear, `#B86E5C → #9A5A4B`, topLeading → bottomTrailing |
| `purpleGradient` | Same as `accentGradient` (legacy name — terracotta gradient) |
| `glassEffect` | `.ultraThin` |
| `strokeColor` | `Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08)` |
| `floatingOrbColors` | `[sage@0.08, amber@0.07, rose@0.06]` |

## 6. Files Touched

**4 files total. No new files created in code — only the two doc files listed at the top.**

1. **`AlBayan/Services/ThemeManager.swift`**
   - Add `case modernLight = "modernLight"` to `ThemeVariant` enum.
   - Add `displayName` branch: `"Modern Light"`.
   - Add `description` branch: `"Refined minimalist light design"`.
   - Add `.modernLight` to `colorScheme` returning `.light`.
   - Add 12 color-property branches per the table in §5.

2. **`AlBayan/ContentView.swift`** (2 switch statements at ~line 478 and ~line 501)
   - `surahNumberGradient` — `#90BCE1 → #6FA3CE` linear gradient.
   - `surahNumberShadowColor` — `Color(red: 0.565, green: 0.737, blue: 0.882).opacity(0.3)`.

3. **`AlBayan/Views/ThemeSelectionView.swift`** (5 helper functions at lines 163-216)
   - `getBackgroundColor` — `(0.973, 0.976, 0.984)`
   - `getTextColor` — `(0.102, 0.102, 0.102)`
   - `getSecondaryTextColor` — `(0.459, 0.459, 0.459)`
   - `getAccentColor` — `(0.565, 0.737, 0.882)`
   - `getStrokeColor` — `Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08)`

4. **`AlBayan/Views/Onboarding/FinalScreen.swift`** (`themePreviewGradient` at ~line 261)
   - Linear gradient `(0.973, 0.976, 0.984) → (1.0, 1.0, 1.0)`, topLeading → bottomTrailing.

## 7. Error Handling

Not applicable — this is a purely additive theme variant. Any missing switch case is a compile-time error (Swift enforces exhaustiveness), which is the desired safety net.

## 8. Testing Strategy

1. **Compile-driven coverage.** Swift's exhaustive switch requirement guarantees every `switch` on `ThemeVariant` across the 4 files must handle `.modernLight` or the build fails. This is the primary safety net; no unit tests needed.

2. **Visual verification in simulator.** After build succeeds:
   - Settings → Theme Selection renders "Modern Light" as a 4th preview card with correct off-white background, charcoal text, and muted-blue accent dot.
   - Selecting Modern Light transitions every screen smoothly: Home, Explore, Progress, Surah list, Surah Detail, Full Screen Commentary, Bookmarks, Settings.
   - Arabic verse rendering has acceptable contrast against `#F8F9FB` (charcoal on off-white is WCAG AAA).
   - Floating orbs visible but subtle in background ambience.

3. **Theme persistence.** Kill app, relaunch, confirm Modern Light persists via `UserDefaults` key `"selectedTheme"`.

4. **Onboarding preview.** In the onboarding `FinalScreen`, confirm the Modern Light preview card renders with the subtle off-white → white vertical gradient.

**Build command:**
```
build_run_sim_name_proj({
  projectPath: "AlBayan.xcodeproj",
  scheme: "AlBayan",
  simulatorName: "iPhone 17"
})
```
**Acceptance:** `0 errors, 0 warnings`.

## 9. Rollback

Each file has a clean git diff. Reverting is a single `git checkout` per file if visual results are unsatisfactory.

## 10. Out of Scope

- Category-specific multi-accent system (amber=Ramadan, blue=Quizzes, rose=Surahs, sage=Quran). Explicitly rejected during brainstorming in favor of single-accent parity with existing themes.
- Higher card radii (24-32pt per style guide). Rejected to preserve cross-theme component consistency.
- `warmRose` / `warmSand` variants from `docs/plans/2026-04-08-warm-theme-variants.md`. Marked dead by product decision; not coordinated with.
- Unit tests, snapshot tests, or accessibility audits. Compile-driven coverage plus manual visual QA is sufficient.
