# Design: Royal Sapphire — Premium Dark Theme

**Date:** 2026-06-09
**Status:** Approved (design phase) — ready for implementation planning
**Source handoff:** `design_handoff_royal_sapphire/` (README + `design-files/sapphire.jsx`, `shared.jsx`, `Royal Sapphire.html`)

## Overview

Introduce **Royal Sapphire** — a deep royal-navy + champagne-gold gilt theme with editorial serif
typography and a sky-blue semantic accent — as the app's **dark theme**. It is added as a third,
selectable `ThemeVariant` alongside the two existing light themes (Warm & Inviting, Rosewater),
and becomes the **fresh-install default**.

The goal is to capture the handoff's **colors and premium feel** with full fidelity to its visual
language (gilt cards, gold-gradient CTAs, soft glows, serif titles, Amiri Arabic, line icons,
floating tab bar) across the primary screens — **with one deliberate exception: the Progress tab
keeps its existing Apple-Watch-style rings** (`ProgressRingsView`), recolored to the Sapphire
palette rather than restructured.

This is **presentation-only**: no data model, manager, or feature/IA changes.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Fidelity | Full handoff adoption (typography + icons + restructured screens + floating tab bar) — **except** the Progress screen stays Apple-style |
| Activation | A **selectable theme** (3rd tile in Settings); dark color scheme applies only while Sapphire is active |
| Existing themes | **Keep** Warm & Rosewater; Royal Sapphire is the **fresh-install default** |
| Architecture | **Approach A** — separate `Sapphire/` view files + a shared `Sp*` component library, switched at the router by theme. Warm/Rosewater views untouched |
| Tab bar | **Floating custom bar** (rounded, blurred navy, gold active dot) while Sapphire is active; native bar retained for light themes |

## Architecture (Approach A)

Royal Sapphire is a different *layout language*, not just a palette. To deliver it at full fidelity
without regressing the shipping light themes, Sapphire screens are **built fresh** as their own
views and selected at the container/router based on the active theme.

- `MainTabView` (and pushed detail routes) pick the Sapphire variant when
  `themeManager.selectedTheme == .royalSapphire`, otherwise the existing views.
- A shared `Sp*` SwiftUI component library encodes the handoff's primitives once.
- Sapphire views read **all** color/type from `ThemeManager` tokens — so they inherently avoid the
  ~203 hardcoded `Color.white`/`.black` literals that live in the warm views (those views are never
  shown under Sapphire).
- **Progress** is the exception: the existing `ProgressRingsView` is reused and recolored via tokens.

**Why not B/C:** Branching inside existing views (B) bloats them and risks breaking Warm/Rosewater on
every edit. A single shared restructured layout (C) would silently redesign the light themes, which
we are explicitly keeping as-is.

## Theme tokens (`Services/ThemeManager.swift`)

Add `case royalSapphire` to `ThemeVariant`. The Swift compiler forces every `switch selectedTheme`
to gain the new case (in `ThemeManager` and in `SettingsView.ThemePickerTile`), which guarantees
completeness.

### Palette mapping (handoff `SP` → existing getters)

| Handoff token | Value | `ThemeManager` getter (Sapphire returns) |
|---|---|---|
| `bg0` | `#0A1124` | `primaryBackground` |
| `bg1` | `#101E40` | (gradient top — see `backgroundGradient`) |
| `bg2` | `#070C1C` | `secondaryBackground` / sheet base |
| `card` | white @ 5% | `cardBackground` / `glassEffect` |
| `ink` | `#EAEFFB` | `primaryText` |
| `ink2` | ink @ 62% | `secondaryText` |
| `ink3` | ink @ 40% | `tertiaryText` |
| `hair` | gold @ 18% | `strokeColor` |
| `gold` | `#D9C079` | `accentColor` |
| `goldDeep` | `#B5963F` | `accentColorDark` |
| `azure` | `#5B9BE0` | `accentSecondary` |
| `goldGrad` | `#F2E2A8`→`#B5963F` | `accentGradient`, `purpleGradient` (both return gold grad for Sapphire) |

### New getters (added for the premium texture; default to existing behavior for light themes)

- `backgroundGradient: some ShapeStyle` — radial `bg1`→`bg0`(~55%)→`bg2`, top-center anchored.
- `goldGlow` — soft radial gold @ 14% → transparent (~460×320), anchored above the top edge.
- `goldGradient: LinearGradient` — `#F2E2A8`→`#B5963F`, 135°.
- `cardElevated` (white @ 7.5%), `strokeSoft` (`hairSoft`, gold @ 10%).
- `goldBright` (`#F2E2A8`), `goldChipFill` (gold @ 15%).
- `azureChip` (azure @ 18%), `onAccentText` (`#1B1606`, text/icons on gold buttons).
- `cardShadow` / `cardShadowElevated` (`rgba(4,9,24,0.35)` / `0.55`), `goldButtonShadow`.

For the **light themes** these new getters return sensible existing equivalents (e.g. `goldGradient`
→ `accentGradient`, `goldGlow` → `.clear`) so nothing about Warm/Rosewater changes.

### Color scheme

- `colorScheme` returns **`.dark`** for `royalSapphire`, `.light` otherwise. Already wired through
  `ContentView`'s `.preferredColorScheme(themeManager.colorScheme)` (status bar, keyboard, system chrome).
- `isDarkMode` returns `true` for Sapphire.
- Add `isSapphire` / `useSapphireLayout` (parallel to existing `useWarmLayout`) for router/view branching.
- Default: `init()` falls back to `.royalSapphire` when no stored selection (fresh install); existing
  users keep their stored theme.

## `Sp*` component library (new — `Views/Sapphire/Components/`)

Faithful SwiftUI ports of the handoff's authoritative components (`sapphire.jsx`):

- **`SpShell`** — background gradient + gold top glow wrapper.
- **`SpHeading`** — uppercase gold eyebrow (11/700, +3 tracking) over Cormorant 40/600 title; optional sub (`ink2`) and centered variant.
- **`SpCard`** — radius 20, `card` fill, 1pt `hair` border, soft shadow; `elev` (`cardElev`) / `glow` (stronger shadow) variants.
- **`SpNumeral`** — circle, 1pt gold stroke, `goldChip` fill, Cormorant numeral in `goldBright` (sizes 30/42–46).
- **`SpIconChip`** — rounded-14, `goldChip` + `hair`, line icon in gold; active = `goldGrad` fill + `onAccentText` icon.
- **`SpGoldCTA`** — `goldGrad` button, radius 15, `onAccentText` label, gold glow shadow + inset top highlight; `small` variant.
- **`SpDivider`** — hairline rule each side of a centered gold diamond (6pt, rotated 45°) or an uppercase label.
- **`SpTabBar`** — floating bar (see Tab bar).

## Typography (`Views/Sapphire/SapphireFont.swift` + `Info.plist`)

Bundle two OFL fonts (free to ship; sourced from the Google Fonts repo) and register under
`UIAppFonts`:

- **Cormorant Garamond** — serif display (weights 500/600 + italic): screen titles, section/surah names, card headlines, big stat numerals, verse translations.
- **Amiri** — Arabic Naskh (400/700): all Qur'anic script + Arabic surah names, RTL.
- **System SF** — sans UI role (body, labels, eyebrows, tab labels, buttons).

`SapphireFont` exposes the handoff type scale (title 40/600, eyebrow 11/700, headline 21–27/600,
numeral 26–36, body/verse 17–20/500, Arabic 27–30/400, etc.).

## Icons

Map the handoff's thin line set to **SF Symbols** (no SVG porting): `book`, `safari`/`location.north`
(compass), `chart.bar`, `moon.stars`, `bell`, `flame`/`flame.fill`, `heart`/`heart.fill`,
`bookmark`/`bookmark.fill`, `play.fill`, `brain`, `sparkles`, `scalemass`/`scale.3d`,
`building.columns`, `books.vertical`, `globe`, `star`/`star.fill`, `leaf`, `checkmark.seal`,
`trophy`, `clock`. Sapphire screens drop the legacy emoji icons. Where no SF Symbol matches closely,
port the path from `shared.jsx`'s `Icon` set as a `Shape`.

## Tab bar (floating)

While Sapphire is active, hide the native `TabView` bar and overlay a custom floating bar:
inset 18, 30 from bottom, radius 22, fill `rgba(10,17,36,0.74)` + blur(22), 1pt `hair`, shadow
`0 14 36 rgba(4,9,24,0.6)`. Active item = icon + label in `goldBright` with a 4pt gold dot beneath;
inactive in `ink3`. **Keeps the app's current 5-tab IA** (Today, Quran, Explore, Progress, Journey) —
not the handoff's outdated 4-tab set. Native bar (dark-tinted) is retained for the light themes.

## Settings (`Views/SettingsView.swift`)

- Add a **Royal Sapphire** tile to the picker (`ThemeVariant.allCases` already drives the list).
- Fill `ThemePickerTile`'s per-variant `switch`es with a dark navy preview swatch + gold/azure dots.
- `ThemeVariant.displayName` = "Royal Sapphire", `description` = e.g. "Gilded royal-navy dark theme".

## Screen plan

| # | Handoff | App view → new Sapphire view | Treatment |
|---|---|---|---|
| 01 | Home / Read | `HomeView`/`HomeTab` → `SapphireHomeView` | Full redesign: greeting row, Continue-Reading `glow` card, search, "114 surahs" divider, surah list |
| 02 | Surah Detail | `SurahDetailView` → `SapphireSurahDetailView` | Header `glow` card, verse cards w/ action chips, 5-layer divider |
| 03 | **Progress** | `ProgressRingsView` | **Recolor only** — keep Apple-style rings |
| 04 | Seasons / Ramadan | `RamadanJourneyView` (+ Muharram/Hajj) → Sapphire variant | Progress `glow` card + day list (done/current/upcoming markers) |
| 05 | Life Moments | `LifeMomentsView` → Sapphire variant | Header, search, emotion cards w/ icon chips |
| 06 | Quick Gems | gems modal → Sapphire sheet | Verse `glow` card, gem chips, pinned insight sheet |
| 07 | Q&A | `QuestionsView` → Sapphire variant | Category pills, question cards w/ azure "verified" badge |
| 08 | Commentary | `FullScreenCommentaryView` → Sapphire variant | Layer selector, active-layer header, serif body |
| 09 | Quiz intro | `QuizView` intro → Sapphire variant | Hero tile w/ glow, stats card, pinned "Begin Quiz" CTA |

All reuse existing managers (`DataManager`, `TafsirReader`, `CommentaryLanguageManager`,
`AudioManager`, `BookmarkManager`, `ProgressManager`, `QuizManager`, journey managers, etc.).

## Phasing

- **P0 — Foundation:** tokens + new getters + `.dark` wiring + default; bundle fonts; `Sp*` library; floating tab bar; Settings tile.
- **P1 — Core read:** `SapphireHomeView` + `SapphireSurahDetailView`.
- **P2 — Insight:** Quick Gems + Commentary + Quiz.
- **P3 — Discovery:** Life Moments + Q&A + Seasons.
- **Progress:** recolor `ProgressRingsView`.

Each phase is independently reviewable (compiles, runnable under the Sapphire theme).

## Non-goals / untouched

- Warm & Rosewater views, palettes, and the native tab bar.
- App information architecture and feature set (5 tabs, all features).
- Data models, managers, persistence, CloudKit.
- The handoff's alternate Progress layout (ignored).

## Risks & open items

- **Font sourcing/licensing:** Cormorant Garamond + Amiri are OFL — fine to bundle; confirm files added to target + `Info.plist` and that they render under both LTR/RTL.
- **Progress recolor:** `ProgressRingsView` currently assumes light surfaces; audit its hardcoded colors when recoloring for dark.
- **Floating tab bar:** safe-area insets, scroll content bottom padding, and gesture/scroll-edge behavior need care so content isn't occluded.
- **Long verses in Quick Gems:** handoff notes the highlighted-fragment + scrolling insight sheet is "explored separately" — keep the full verse visible and let the insight sheet scroll; revisit if needed.
- **Feature parity:** Sapphire views must preserve every action the warm views expose (bookmarks, audio, language toggle, deep-link targets).

## Implementation note

Per project preference, the design doc is **not auto-committed** — left staged for the author to
commit. Next step: produce a phased implementation plan (writing-plans).
