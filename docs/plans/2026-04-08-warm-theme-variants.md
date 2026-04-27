# Warm Theme Variants Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add two new light theme variants (Warm Rose and Warm Sand) as subtle hue-shifted alternatives to Warm & Inviting.

**Architecture:** Add two new cases to the `ThemeVariant` enum and extend all 23 switch statements across 4 files with the new color values. Both themes share identical typography, spacing, radii, and layout -- only colors differ.

**Tech Stack:** SwiftUI, iOS 15+

---

### Task 1: Add enum cases and metadata to ThemeVariant

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:10-36`

**Step 1: Add enum cases**

Add `warmRose` and `warmSand` to the `ThemeVariant` enum, `displayName`, and `description`:

```swift
enum ThemeVariant: String, CaseIterable {
    case warmInviting = "warmInviting"
    case warmRose = "warmRose"
    case warmSand = "warmSand"
    case royalAmethyst = "royalAmethyst"
    case modernDark = "modernDark"

    var displayName: String {
        switch self {
        case .warmInviting: return "Warm & Inviting"
        case .warmRose: return "Warm Rose"
        case .warmSand: return "Warm Sand"
        case .royalAmethyst: return "Royal Amethyst"
        case .modernDark: return "Modern Dark"
        }
    }

    var description: String {
        switch self {
        case .warmInviting: return "Sanctuary-like warm design"
        case .warmRose: return "Gentle rose-tinted sanctuary"
        case .warmSand: return "Earthy parchment sanctuary"
        case .royalAmethyst: return "Luxurious purple with gold accents"
        case .modernDark: return "Dark glassmorphism design"
        }
    }
}
```

**Step 2: Update isDarkMode**

Both new themes are light themes, so group them with `.warmInviting`:

```swift
var isDarkMode: Bool {
    selectedTheme == .modernDark || selectedTheme == .royalAmethyst
}
```
(No change needed -- the default false covers the new cases.)

**Step 3: Update colorScheme**

```swift
var colorScheme: ColorScheme {
    switch selectedTheme {
    case .modernDark, .royalAmethyst: return .dark
    case .warmInviting, .warmRose, .warmSand: return .light
    }
}
```

**Step 4: Build to verify no missing cases**

Run: Xcode build
Expected: Compiler errors for all remaining switch statements (this is expected -- we fix them in Task 2)

---

### Task 2: Add color values for all ThemeManager properties

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:83-262`

For each property, add cases for `.warmRose` and `.warmSand` right after `.warmInviting`. Values come from the style guide docs.

**Properties to update (12 switch statements):**

1. `primaryBackground` -- Rose: `(1.0, 0.961, 0.973)`, Sand: `(0.984, 0.965, 0.937)`
2. `secondaryBackground` -- Rose: `(0.992, 0.973, 0.965)`, Sand: `(0.976, 0.961, 0.941)`
3. `tertiaryBackground` -- Rose: `(1.0, 0.969, 0.953)`, Sand: `(1.0, 0.973, 0.937)`
4. `primaryText` -- Rose: `(0.169, 0.125, 0.145)`, Sand: `(0.176, 0.145, 0.094)`
5. `secondaryText` -- Rose: `(0.396, 0.329, 0.361)`, Sand: `(0.42, 0.365, 0.282)`
6. `tertiaryText` -- Rose: `(0.659, 0.608, 0.639)`, Sand: `(0.69, 0.64, 0.557)`
7. `accentGradient` -- Rose: dusty rose to deep rose, Sand: terracotta to deep terracotta
8. `accentColor` -- Rose: `(0.749, 0.561, 0.627)`, Sand: `(0.71, 0.561, 0.478)`
9. `purpleGradient` -- Rose: rose gradient, Sand: terracotta gradient
10. `glassEffect` -- Both: `.ultraThin` (same as warmInviting)
11. `strokeColor` -- Rose: rose-charcoal 0.1 opacity, Sand: brown-charcoal 0.1 opacity
12. `floatingOrbColors` -- Rose: rose/coral/sage tints, Sand: terracotta/sienna/sage tints

**Step 1: Build to verify all switch statements compile**

Run: Xcode build
Expected: SUCCESS with no errors

---

### Task 3: Update ContentView.swift switch statements

**Files:**
- Modify: `AlBayan/ContentView.swift:477-509`

**Step 1: Add cases to surahNumberGradient**

- Rose: coral gradient `(0.91, 0.522, 0.435)` to `(0.847, 0.459, 0.373)`
- Sand: sienna gradient `(0.769, 0.478, 0.322)` to `(0.706, 0.416, 0.259)`

**Step 2: Add cases to surahNumberShadowColor**

- Rose: `Color(red: 0.91, green: 0.522, blue: 0.435).opacity(0.3)`
- Sand: `Color(red: 0.769, green: 0.478, blue: 0.322).opacity(0.3)`

---

### Task 4: Update ThemeSelectionView.swift helper functions

**Files:**
- Modify: `AlBayan/Views/ThemeSelectionView.swift:163-216`

**Step 1: Add cases to all 5 helper functions**

- `getBackgroundColor` -- Rose: `(1.0, 0.961, 0.973)`, Sand: `(0.984, 0.965, 0.937)`
- `getTextColor` -- Rose: `(0.169, 0.125, 0.145)`, Sand: `(0.176, 0.145, 0.094)`
- `getSecondaryTextColor` -- Rose: `(0.396, 0.329, 0.361)`, Sand: `(0.42, 0.365, 0.282)`
- `getAccentColor` -- Rose: `(0.749, 0.561, 0.627)`, Sand: `(0.71, 0.561, 0.478)`
- `getStrokeColor` -- Rose: `(0.169, 0.125, 0.145).opacity(0.1)`, Sand: `(0.176, 0.145, 0.094).opacity(0.1)`

---

### Task 5: Update FinalScreen.swift onboarding preview

**Files:**
- Modify: `AlBayan/Views/Onboarding/FinalScreen.swift:261-282`

**Step 1: Add cases to themePreviewGradient**

- Rose: `(1.0, 0.961, 0.973)` to `(1.0, 0.969, 0.953)`
- Sand: `(0.984, 0.965, 0.937)` to `(1.0, 0.973, 0.937)`

---

### Task 6: Build and verify

**Step 1: Full build**

Run: Xcode build
Expected: SUCCESS, 0 errors, 0 warnings related to themes

**Step 2: Visual check**

Run in simulator, navigate to Theme Selection, verify all 5 themes appear and preview correctly.
