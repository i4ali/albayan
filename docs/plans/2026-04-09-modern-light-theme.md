# Modern Light Theme Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a fourth theme variant `modernLight` — a cool-neutral minimalist light theme with muted blue primary accent — as the clarity-first counterpart to `modernDark`.

**Architecture:** Pure color/value variation. Add one new case to the `ThemeVariant` enum and extend 20+ switch statements across 4 files with the new color values. No new helpers, no new enums, no call-site changes. Swift's exhaustive switch is the primary safety net — any missed case is a compile error.

**Tech Stack:** SwiftUI, iOS 15+

**Design references:**
- Design doc: `docs/plans/2026-04-09-modern-light-theme-design.md`
- Style guide: `docs/MODERN_LIGHT_THEME_STYLE_GUIDE.md`

**Testing note:** This plan intentionally does NOT include unit tests. Swift's compiler enforces exhaustive switch coverage on enums, which catches every missed case at build time — that is the safety net. Visual QA in the simulator is the human acceptance step. Do not add XCTest cases; they would only verify static color values and add zero signal.

---

## Task 1: Add `modernLight` case to `ThemeVariant` enum

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:10-36`

**Step 1: Add the enum case**

Open `AlBayan/Services/ThemeManager.swift`. Find the `ThemeVariant` enum (line 10). Add `modernLight` as the fourth case, between `warmInviting` and `royalAmethyst`:

```swift
enum ThemeVariant: String, CaseIterable {
    case warmInviting = "warmInviting"
    case modernLight = "modernLight"
    case royalAmethyst = "royalAmethyst"
    case modernDark = "modernDark"

    var displayName: String {
        switch self {
        case .warmInviting:
            return "Warm & Inviting"
        case .modernLight:
            return "Modern Light"
        case .royalAmethyst:
            return "Royal Amethyst"
        case .modernDark:
            return "Modern Dark"
        }
    }

    var description: String {
        switch self {
        case .warmInviting:
            return "Sanctuary-like warm design"
        case .modernLight:
            return "Refined minimalist light design"
        case .royalAmethyst:
            return "Luxurious purple with gold accents"
        case .modernDark:
            return "Dark glassmorphism design"
        }
    }
}
```

**Step 2: Build to verify exhaustiveness errors surface**

Run the iOS build. Use MCP XcodeBuild tools:

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: **BUILD FAILS** with multiple "switch must be exhaustive" errors pointing at:
- `ThemeManager.swift` (colorScheme + 12 color properties)
- `ContentView.swift` (2 switches)
- `ThemeSelectionView.swift` (5 helper functions)
- `FinalScreen.swift` (1 function)

This is expected and desired — the compiler is telling us exactly where to wire up the new case. Do NOT fix these yet; we handle each in subsequent tasks.

**Step 3: Commit**

```bash
git add AlBayan/Services/ThemeManager.swift
git commit -m "feat(theme): add modernLight enum case + metadata"
```

---

## Task 2: Add `modernLight` to `colorScheme`

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:73-80`

**Step 1: Add the branch**

Find the `colorScheme` computed property (around line 73). It currently handles three cases. Add `.modernLight` to the `.light` group:

```swift
var colorScheme: ColorScheme {
    switch selectedTheme {
    case .modernDark, .royalAmethyst:
        return .dark
    case .warmInviting, .modernLight:
        return .light
    }
}
```

**Step 2: Verify `isDarkMode` needs no change**

Confirm that `isDarkMode` (line 49) is:

```swift
var isDarkMode: Bool {
    selectedTheme == .modernDark || selectedTheme == .royalAmethyst
}
```

No change needed — `.modernLight` correctly defaults to `false` (which is "light mode").

**Step 3: Do not commit yet**

We'll batch this with the color properties in the next task.

---

## Task 3: Add all color-property branches in `ThemeManager.swift`

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:83-262`

For each property, add a `.modernLight` case right after `.warmInviting`. Exact values below — copy them literally.

**Step 1: `primaryBackground` (around line 83)**

```swift
case .modernLight:
    return Color(red: 0.973, green: 0.976, blue: 0.984) // #F8F9FB - Off-white cool
```

**Step 2: `secondaryBackground` (around line 94)**

```swift
case .modernLight:
    return Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF - Pure white cards
```

**Step 3: `tertiaryBackground` (around line 105)**

```swift
case .modernLight:
    return Color(red: 0.945, green: 0.953, blue: 0.969) // #F1F3F7 - Accent areas
```

**Step 4: `primaryText` (around line 117)**

```swift
case .modernLight:
    return Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A - Charcoal
```

**Step 5: `secondaryText` (around line 128)**

```swift
case .modernLight:
    return Color(red: 0.459, green: 0.459, blue: 0.459) // #757575 - Medium grey
```

**Step 6: `tertiaryText` (around line 139)**

```swift
case .modernLight:
    return Color(red: 0.659, green: 0.659, blue: 0.659) // #A8A8A8 - Light grey
```

**Step 7: `accentGradient` (around line 151)**

```swift
case .modernLight:
    return LinearGradient(
        colors: [
            Color(red: 0.565, green: 0.737, blue: 0.882), // #90BCE1 - Muted blue
            Color(red: 0.435, green: 0.639, blue: 0.808)  // #6FA3CE - Deep muted blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
```

**Step 8: `accentColor` (around line 183)**

```swift
case .modernLight:
    return Color(red: 0.565, green: 0.737, blue: 0.882) // #90BCE1 - Muted blue
```

**Step 9: `purpleGradient` (around line 194)**

The `purpleGradient` name is legacy; for Modern Light it should return the same muted blue gradient as `accentGradient`:

```swift
case .modernLight:
    return LinearGradient(
        colors: [
            Color(red: 0.565, green: 0.737, blue: 0.882), // #90BCE1
            Color(red: 0.435, green: 0.639, blue: 0.808)  // #6FA3CE
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
```

**Step 10: `glassEffect` (around line 218)**

```swift
case .modernLight:
    return .ultraThin // Frosted minimalist glass for nav bar
```

**Step 11: `strokeColor` (around line 229)**

```swift
case .modernLight:
    return Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08) // Subtle charcoal hairline
```

**Step 12: `floatingOrbColors` (around line 241)**

This is where the supporting pastels live. Use sage/amber/rose at low opacity:

```swift
case .modernLight:
    return [
        Color(red: 0.537, green: 0.788, blue: 0.706).opacity(0.08), // #89C9B4 Sage
        Color(red: 0.922, green: 0.753, blue: 0.471).opacity(0.07), // #EBC078 Amber
        Color(red: 0.851, green: 0.584, blue: 0.631).opacity(0.06)  // #D995A1 Rose
    ]
```

**Step 13: Build to verify ThemeManager.swift compiles**

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: Build still fails, but errors should now only come from `ContentView.swift`, `ThemeSelectionView.swift`, and `FinalScreen.swift` — NOT from `ThemeManager.swift`. If `ThemeManager.swift` still has errors, go back and find the missed switch.

**Step 14: Commit**

```bash
git add AlBayan/Services/ThemeManager.swift
git commit -m "feat(theme): wire modernLight color palette in ThemeManager"
```

---

## Task 4: Add `modernLight` branches in `ContentView.swift`

**Files:**
- Modify: `AlBayan/ContentView.swift:477-509`

**Step 1: Add `.modernLight` to `surahNumberGradient` (line 477)**

Find the `surahNumberGradient` computed property. Add a case right after `.warmInviting`:

```swift
case .modernLight:
    return LinearGradient(
        colors: [Color(red: 0.565, green: 0.737, blue: 0.882), Color(red: 0.435, green: 0.639, blue: 0.808)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
```

**Step 2: Add `.modernLight` to `surahNumberShadowColor` (line 500)**

```swift
case .modernLight:
    return Color(red: 0.565, green: 0.737, blue: 0.882).opacity(0.3)
```

**Step 3: Build to verify ContentView.swift compiles**

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: Build still fails, but errors should now only come from `ThemeSelectionView.swift` and `FinalScreen.swift`.

**Step 4: Commit**

```bash
git add AlBayan/ContentView.swift
git commit -m "feat(theme): wire modernLight surah number badge in ContentView"
```

---

## Task 5: Add `modernLight` branches in `ThemeSelectionView.swift`

**Files:**
- Modify: `AlBayan/Views/ThemeSelectionView.swift:163-216`

There are 5 helper functions that drive the theme preview card. Each needs a `.modernLight` branch.

**Step 1: `getBackgroundColor` (line 163)**

```swift
case .modernLight:
    return Color(red: 0.973, green: 0.976, blue: 0.984) // #F8F9FB
```

**Step 2: `getTextColor` (line 174)**

```swift
case .modernLight:
    return Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A
```

**Step 3: `getSecondaryTextColor` (line 185)**

```swift
case .modernLight:
    return Color(red: 0.459, green: 0.459, blue: 0.459) // #757575
```

**Step 4: `getAccentColor` (line 196)**

```swift
case .modernLight:
    return Color(red: 0.565, green: 0.737, blue: 0.882) // #90BCE1
```

**Step 5: `getStrokeColor` (line 207)**

```swift
case .modernLight:
    return Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08)
```

**Step 6: Build to verify ThemeSelectionView.swift compiles**

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: Build still fails, but only on `FinalScreen.swift`.

**Step 7: Commit**

```bash
git add AlBayan/Views/ThemeSelectionView.swift
git commit -m "feat(theme): wire modernLight preview card in ThemeSelectionView"
```

---

## Task 6: Add `modernLight` branch in `FinalScreen.swift`

**Files:**
- Modify: `AlBayan/Views/Onboarding/FinalScreen.swift:261-282`

**Step 1: Add `.modernLight` to `themePreviewGradient`**

Find the `themePreviewGradient` computed property (line 261). Add a case right after `.warmInviting`:

```swift
case .modernLight:
    return LinearGradient(
        colors: [Color(red: 0.973, green: 0.976, blue: 0.984), Color(red: 1.0, green: 1.0, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
```

**Step 2: Build to verify everything compiles**

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: **BUILD SUCCEEDS** with 0 errors, 0 warnings related to themes.

If the build still fails, grep the codebase for any remaining switch statements you may have missed:

Use the Grep tool with pattern: `case \.warmInviting` and file type swift. Every file that matches should also have a `.modernLight` case. If you find one that doesn't, add `.modernLight` using values from the design doc.

**Step 3: Commit**

```bash
git add AlBayan/Views/Onboarding/FinalScreen.swift
git commit -m "feat(theme): wire modernLight onboarding preview in FinalScreen"
```

---

## Task 7: Visual verification in simulator

**No code changes — this is the human acceptance step.**

**Step 1: Launch the app**

```
build_run_sim_name_proj({ projectPath: "AlBayan.xcodeproj", scheme: "AlBayan", simulatorName: "iPhone 17" })
```

Expected: App launches with the currently-selected theme.

**Step 2: Open Theme Selection**

Navigate: Settings tab → Theme selection. Verify:

- [ ] "Modern Light" appears as the second preview card (after Warm & Inviting, before Royal Amethyst).
- [ ] Preview card shows off-white background (`#F8F9FB`).
- [ ] Arabic text renders in charcoal on off-white with good contrast.
- [ ] Accent dot (verse number circle) is muted blue (`#90BCE1`).
- [ ] Subtitle reads "Refined minimalist light design".
- [ ] Tapping the card selects it and shows a checkmark in muted blue.

**Step 3: Navigate through the app with Modern Light selected**

Check each major screen for theme application:

- [ ] **Home tab** — off-white background, pure white cards, muted blue highlights, charcoal text.
- [ ] **Explore tab** — discovery carousel reads correctly on off-white.
- [ ] **Progress tab** — progress rings render in muted blue.
- [ ] **Surah list** — surah number badges use the muted blue gradient.
- [ ] **Surah Detail** — Arabic verses render with good contrast on off-white. Floating orbs subtly visible in sage/amber/rose.
- [ ] **Full Screen Commentary** — three-layer tafsir text legible in charcoal.
- [ ] **Bookmarks** — cards float on off-white with subtle shadows.
- [ ] **Settings** — section headers in charcoal, row backgrounds in pure white.

**Step 4: Theme persistence**

- [ ] Kill the app from the multitasking switcher.
- [ ] Relaunch. Verify Modern Light is still selected (it should persist via `UserDefaults` key `"selectedTheme"`).

**Step 5: Onboarding preview (optional)**

If you can trigger the onboarding flow (by clearing onboarding completion state):

- [ ] In `FinalScreen`, the Modern Light preview card shows the subtle off-white → pure white vertical gradient.

**Step 6: If anything looks wrong**

Refer to `docs/MODERN_LIGHT_THEME_STYLE_GUIDE.md` for expected values. Each value traces back to `docs/plans/2026-04-09-modern-light-theme-design.md` §5 (ThemeManager property mapping). Rolling back any single file is a clean `git checkout` — no coordination needed across files.

**Step 7: Final commit (if no code changes needed)**

Nothing to commit. Visual QA is complete.

If you DID need to make tweaks based on visual QA, commit them as:

```bash
git commit -m "fix(theme): tweak modernLight <property> after visual QA"
```

---

## Completion Checklist

- [ ] Task 1: Enum case added, build fails with expected exhaustiveness errors
- [ ] Task 2: `colorScheme` branch added
- [ ] Task 3: All 12 ThemeManager color properties wired, only 3 files still fail
- [ ] Task 4: ContentView.swift wired, only 2 files still fail
- [ ] Task 5: ThemeSelectionView.swift wired, only 1 file still fails
- [ ] Task 6: FinalScreen.swift wired, build SUCCEEDS
- [ ] Task 7: Visual QA across all major screens passes
- [ ] 6 commits in history (one per task that makes code changes)

## Rollback

Each task is a single file change with its own commit. To abandon the feature entirely:

```bash
git reset --hard HEAD~6  # DESTRUCTIVE — confirm no other work is in-flight
```

Or revert individual tasks by checking out the previous commit for specific files.
