# Emerald Garden Theme Rebuild — Design

**Date:** 2026-04-13
**Status:** Approved, pending implementation plan
**Reference mockup:** `AlBayan/Views/EmeraldGardenSurahDetailView.swift`

## Goal

Reduce the theme catalog to three themes and rebuild the `emeraldGarden` theme from scratch so that every screen in the app has a bespoke Emerald Garden layout — paradisal-manuscript aesthetic with mihrab arch cards, stepped emerald bezels, brass hairlines, 8-point Islamic-star corner motifs, ivory parchment backgrounds, and serif Arabic titles — built by extrapolating the visual language established in the existing Surah Detail mockup.

When the user picks a non-Emerald-Garden theme (`warmInviting` or `royalAmethyst`), every existing view is unchanged. When the user picks `emeraldGarden`, top-level routers substitute the new parallel `EmeraldGarden*` views.

## Non-goals

- No feature changes, data model changes, onboarding copy changes, or analytics changes. Strictly visual.
- No visual changes to `warmInviting` or `royalAmethyst` themes.
- No automated UI tests (repo has none; not in scope to introduce).
- No new mockup generations — all new views are coded directly from the Surah Detail visual language.

## 1. Theme catalog change

`ThemeVariant` shrinks from 5 cases to 3:

| Case | Keep | Notes |
|------|------|-------|
| `warmInviting` | yes | Untouched |
| `royalAmethyst` | yes | Untouched |
| `emeraldGarden` | yes, rebuilt | Color tokens retained (already match mockup), layouts rebuilt |
| `modernLight` | **remove** | All references deleted |
| `modernDark` | **remove** | All references deleted |

**Migration for saved user preference:** If `UserDefaults` contains `modernLight` or `modernDark`, `ThemeManager.init` falls back to `warmInviting`.

**Files with theme references that need audit:** `ContentView.swift`, `HomeView.swift`, `SurahDetailView.swift`, `ThemeSelectionView.swift`, `ThemeManager.swift`, `Onboarding/FinalScreen.swift` — plus any others surfaced by `grep -r '\.modernLight\|\.modernDark'`.

## 2. File organization

New folder `AlBayan/Views/EmeraldGarden/` mirrors the existing view structure.

```
AlBayan/Views/EmeraldGarden/
├── Components/
│   ├── MihrabCardShape.swift
│   ├── SteppedBezel.swift
│   ├── EightPointStar.swift
│   ├── CornerMotifs.swift
│   ├── EGPrimaryButton.swift        // Emerald-gradient capsule (Play Sequence style)
│   ├── EGSecondaryButton.swift      // Aged-ivory capsule (View Commentary style)
│   ├── EGNumberBadge.swift          // Ivory circle + brass hairline + sepia number
│   ├── EGActionIconButton.swift     // Small ivory circle icon button
│   └── EGCardBackground.swift       // Reusable mihrab-card fill+stroke+shadow modifier
├── Tabs/
│   ├── EGHomeTab.swift
│   ├── EGExploreTab.swift
│   └── EGProgressTab.swift
├── Onboarding/
│   ├── EGMissionScreen.swift
│   ├── EGFiveLayersScreen.swift
│   ├── EGQuickGemsScreen.swift
│   ├── EGQuizFeatureScreen.swift
│   ├── EGHadithScreen.swift
│   ├── EGSeasonalFeaturesScreen.swift
│   ├── EGDailyVerseScreen.swift
│   ├── EGProgressTrackingScreen.swift
│   ├── EGProgressNotificationsScreen.swift
│   ├── EGFinalScreen.swift
│   └── EGOnboardingFlowView.swift
├── EGHomeView.swift
├── EGSurahDetailView.swift          // Promoted from existing mockup
├── EGFullScreenCommentaryView.swift
├── EGTafsirSourcesView.swift
├── EGQuickOverviewView.swift
├── EGVerseSummaryView.swift
├── EGRamadanJourneyView.swift
├── EGRamadanDayDetailView.swift
├── EGFastingVersesView.swift
├── EGFastingCategoryDetailView.swift
├── EGPropheticStoriesView.swift
├── EGStoryDetailView.swift
├── EGPropheticParallelsView.swift
├── EGParallelDetailView.swift
├── EGLifeMomentsView.swift
├── EGQuestionsView.swift
├── EGQuestionDetailView.swift
├── EGAhlulbaytQuranView.swift
├── EGAhlulbaytEntryDetailView.swift
├── EGBookmarksView.swift
├── EGSurahAudioPlayerView.swift
├── EGQuizView.swift
├── EGQuizResultsView.swift
├── EGBadgeAwardView.swift
├── EGPaywallView.swift
├── EGPremiumBadgeView.swift
├── EGTTSVoicePickerView.swift
├── EGNotificationsView.swift
├── EGSettingsView.swift
├── EGAccountDeletionView.swift
├── EGAuthenticationView.swift
├── EGWelcomeView.swift
├── EGMainTabView.swift
└── EGExploreView.swift
```

Shared components read palette values from `ThemeManager.shared` (never a private palette enum).

## 3. Router strategy

Theme switching happens at view boundaries via a helper:

```swift
@ViewBuilder
func emeraldOr<EG: View, Std: View>(
    @ViewBuilder eg: () -> EG,
    @ViewBuilder std: () -> Std
) -> some View {
    if ThemeManager.shared.selectedTheme == .emeraldGarden {
        eg()
    } else {
        std()
    }
}
```

Used at:
- `ContentView` body (root router — onboarding vs main tabs, both branches emerald-aware).
- `MainTabView` (swaps each `Tab` body: `HomeTab()` ↔ `EGHomeTab()`).
- Every `NavigationLink { ... }` destination that leads to a view with an EG counterpart.
- Every sheet/fullScreenCover presenter.

`warmInviting`/`royalAmethyst` branches use the existing views unchanged.

## 4. ThemeManager changes

**Removals:**
- `case modernLight`, `case modernDark` from `ThemeVariant`.
- All `case .modernLight:` / `case .modernDark:` arms in every `switch` inside `ThemeManager`.
- `isDarkMode` keeps working but now only checks `royalAmethyst`.
- `colorScheme` drops the dark-returning branch for `modernDark`.

**Additions** — new emeraldGarden-specific tokens so EG components don't need a private palette enum. For parity, non-EG themes get sensible values (they won't be read by non-EG views, but the compiler requires them):

| Token | emeraldGarden | Source |
|-------|---------------|--------|
| `ivoryCard` | `#FDF8EA` | mockup `EG.cardIvory` |
| `brassStroke` | `#C2B992` | mockup `EG.brass` |
| `emerald` | `#475E45` | mockup `EG.emerald` |
| `deepEmerald` | `#354B2D` | mockup `EG.deepEmerald` |
| `mutedOlive` | `#A0A47A` | mockup `EG.mutedOlive` |
| `agedIvory` | `#E3D4B8` | mockup `EG.agedIvory` |

**Retained values:** existing `emeraldGarden` values in `primaryBackground`, `secondaryBackground`, `tertiaryBackground`, `primaryText`, `secondaryText`, `tertiaryText`, `accentColor`, `accentGradient`, `purpleGradient`, `strokeColor`, `floatingOrbColors` all match the mockup exactly — no changes.

## 5. Existing mockup fate

`AlBayan/Views/EmeraldGardenSurahDetailView.swift` is promoted to the production EG Surah Detail:

1. Move to `AlBayan/Views/EmeraldGarden/EGSurahDetailView.swift`.
2. Delete the private palette `enum EG` — tokens read from `ThemeManager.shared` instead.
3. Promote the four private shape types into `EmeraldGarden/Components/` (drop `private` modifier).
4. Replace the hardcoded `verses` array with `DataManager`-backed surah data.
5. Wire the "Play Sequence" button to the audio player (opens `EGSurahAudioPlayerView`).
6. Wire the "View Commentary" button per verse to open `EGFullScreenCommentaryView`.
7. Wire the heart button to bookmark toggle.

## 6. Build order (inside one big-bang PR)

Sequential batches, each one compiling cleanly before moving to the next:

1. **Theme surgery.** Remove `modernLight`/`modernDark` from `ThemeVariant`. Fix every `switch` and every `if theme == .modernX` in the 6 referencing files. Add new EG tokens to `ThemeManager`. Add fallback in `init` for saved `modernLight`/`modernDark`. Update `ThemeSelectionView` to display only 3 themes. Verify `xcodebuild` compiles.

2. **Shared components.** Extract `MihrabCardShape`, `SteppedBezel`, `EightPointStar`, `CornerMotifs` from the existing mockup into `EmeraldGarden/Components/`. Create the new button/badge components. All read from `ThemeManager.shared`.

3. **Promote Surah Detail mockup.** Move file, swap palette, wire data. Confirm it renders real Al-Fatiha data from `DataManager` and navigates correctly.

4. **Core reading flow.** `EGHomeView`, `EGHomeTab`, Surah list (inside `EGHomeView`), `EGFullScreenCommentaryView`, `EGTafsirSourcesView`, `EGQuickOverviewView`, `EGVerseSummaryView`.

5. **Tabs & Explore.** `EGExploreTab`, `EGProgressTab`, `EGExploreView`, `EGRamadanJourneyView`, `EGFastingVersesView`, `EGPropheticStoriesView`, `EGPropheticParallelsView`, `EGLifeMomentsView`, `EGQuestionsView`, `EGAhlulbaytQuranView`, `EGBookmarksView`, `EGMainTabView`.

6. **Detail/modal views.** `EGStoryDetailView`, `EGQuestionDetailView`, `EGParallelDetailView`, `EGFastingCategoryDetailView`, `EGRamadanDayDetailView`, `EGAhlulbaytEntryDetailView`, `EGSurahAudioPlayerView`, `EGQuizView`, `EGQuizResultsView`, `EGBadgeAwardView`, `EGPaywallView`, `EGPremiumBadgeView`, `EGTTSVoicePickerView`, `EGNotificationsView`.

7. **Settings & auth.** `EGSettingsView`, `EGAccountDeletionView`, `EGAuthenticationView`, `EGWelcomeView`. Update `ThemeSelectionView` for the 3-theme world (may stay as a single view since it's theme-picker chrome, or also get an EG variant — decide during build).

8. **Onboarding.** All 11 EG onboarding screens + `EGOnboardingFlowView`. Wire from `ContentView` via the router helper.

9. **Router wiring sweep.** Final pass through `ContentView`, `MainTabView`, every `NavigationLink`/sheet/fullScreenCover to ensure every branch routes through `emeraldOr`.

## 7. Design language rules (for extrapolating to new screens)

Consistency glue so the 57 un-mocked views feel cohesive:

- **Background.** Ivory parchment (`primaryBackground`) fills the screen. `CornerMotifs` decorates the top two corners. Brass mosaic edge strips optional on content-dense screens.
- **Primary cards.** `MihrabCardShape(archHeight: 14, archWidthRatio: 0.42, cornerRadius: 20)` fills with `ivoryCard`, strokes with `brassStroke @ 0.55`. Hero cards use `archHeight: 28, archWidthRatio: 0.58` and add an emerald outer stroke + brass inset stroke, flanked by `SteppedBezel`.
- **Primary buttons.** Emerald gradient capsule with ivory text.
- **Secondary buttons.** Aged-ivory capsule with brass hairline and deep-emerald text.
- **Small icon buttons.** Ivory circle, 34×34, brass hairline, deep-emerald glyph.
- **Number badges.** Ivory circle, 36×36, brass hairline, sepia rounded-semibold numeral.
- **Arabic.** Serif, deep-emerald, RTL environment scoped to the Arabic view only.
- **English titles.** Serif italic, muted-olive; section headers serif bold.
- **Body text.** Rounded system, sepia primary text color.
- **Dividers.** 1px brass @ 0.35 opacity.
- **Shadows.** Very soft — `primaryText @ 0.06–0.08`, radius 14–16, y-offset 6.

## 8. Open build-time questions

- **Custom tab bar?** Default = no (iOS `TabView`, tinted with `accentColor`). Revisit if it feels wrong once the EG tabs are in place.
- **ThemeSelectionView EG variant?** Default = no (single polymorphic view, updated for 3 themes). Revisit if it needs bespoke EG chrome.
- **Specific screens that may resist the visual language** (e.g., `SurahAudioPlayerView` with scrubber UI, `QuizView` with multi-choice chrome) — design call made per-screen during build; may need one iteration pass.

## 9. Testing

- `xcodebuild` clean compile after each batch in §6.
- iOS Simulator manual walkthrough per batch. Screenshot capture for visual regression tracking (stored in `screenshots/` — already gitignored).
- Manually verify theme switch from `emeraldGarden` → `warmInviting` → `royalAmethyst` leaves non-EG themes unaffected.
- Verify saved `modernLight`/`modernDark` preference falls back to `warmInviting` on launch.

## 10. Risks

- **Scale.** ~60 new SwiftUI files. Long review cycle for a single PR. Mitigation: sequential batches in §6 keep compile state clean at every step; any batch can be a natural review pause point even inside one PR.
- **Design drift on un-mocked screens.** Extrapolating a reading-screen vocabulary to Paywall, Quiz, Audio Player requires judgment. Some screens will need a second iteration pass once rendered.
- **Dead code from removed themes.** Six files reference `modernLight`/`modernDark`; missing a reference = compile break. Mitigation: explicit `grep` sweep in batch 1 before touching anything else.
- **State loss for current users on removed themes.** Small user base likely; fallback to `warmInviting` is acceptable. No data loss — only a preference reset for two themes.

## 11. Success criteria

- `ThemeVariant` has exactly 3 cases.
- `xcodebuild` compiles cleanly with no warnings about unhandled theme cases.
- Selecting Emerald Garden in Theme Selection switches every screen — onboarding through settings — to the new EG layouts.
- Selecting Warm & Inviting or Royal Amethyst restores the pre-existing look on every screen with zero visual regressions.
- Shared EG components in `EmeraldGarden/Components/` consume only `ThemeManager.shared` values (no private palette enums remain).
- `grep -r '\.modernLight\|\.modernDark'` under `AlBayan/` returns zero hits.
