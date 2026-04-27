# Emerald Garden Theme Rebuild Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce theme catalog to 3 themes (warmInviting, royalAmethyst, emeraldGarden) and bespoke-rebuild every screen for the emeraldGarden theme using parallel `EmeraldGarden/` view files switched in by a router helper.

**Architecture:** Theme-gated router. `ThemeManager.shared.selectedTheme == .emeraldGarden` ⇒ top-level routers (`ContentView`, `MainTabView`, `NavigationLink` destinations, sheet presenters) substitute `EG*` parallel views. Non-EG themes unchanged. All EG views consume palette tokens exclusively from `ThemeManager` (no private palette enums).

**Tech Stack:** Swift 5+, SwiftUI, Xcode (`xcodebuild` for compile checks), iOS Simulator for visual verification. No unit/UI tests in repo — verification gate is `xcodebuild` clean build + Simulator walkthrough.

**Design doc:** `docs/plans/2026-04-13-emerald-garden-theme-rebuild-design.md`

**Reference mockup (visual language source):** `AlBayan/Views/EmeraldGardenSurahDetailView.swift` — read this before starting Task 2.

---

## Global conventions for this plan

- **Compile check:** after every task, run `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build` and confirm exit 0. If it fails, fix before committing.
- **Commit cadence:** one commit per task. Message format `feat(theme): <task subject>` or `refactor(theme): <…>` or `chore(theme): <…>`. Do not squash.
- **File header:** every new `EG*.swift` file starts with the block:
  ```swift
  //
  //  <EGFileName>.swift
  //  AlBayan
  //
  //  Emerald Garden theme variant of <OriginalViewName>.
  //  Visual language: ivory parchment + mihrab arch cards + stepped
  //  emerald bezels + brass hairlines + 8-point star corner motifs.
  //
  ```
- **Palette access:** EG views read colors ONLY through `ThemeManager.shared.*`. If a needed color isn't on `ThemeManager`, add a token in Task 1 before using it. No private palette enums in any EG view.
- **RTL scope:** `.environment(\.layoutDirection, .rightToLeft)` wraps Arabic text views only — never the whole screen.
- **No feature changes.** EG views reproduce the functional behavior of their source view exactly (data, navigation, state). Visual-only delta.

---

## Task 1: Remove modernLight/modernDark theme cases

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift`
- Modify: `AlBayan/ContentView.swift`
- Modify: `AlBayan/Views/HomeView.swift`
- Modify: `AlBayan/Views/SurahDetailView.swift`
- Modify: `AlBayan/Views/ThemeSelectionView.swift`
- Modify: `AlBayan/Views/Onboarding/FinalScreen.swift`

**Step 1: Find every reference**

Run: `grep -rn '\.modernLight\|\.modernDark' AlBayan/`

Record each hit. Expected locations: 6 files listed above. If more appear, include them in this task.

**Step 2: Edit `ThemeManager.swift`**

- Remove `case modernLight` and `case modernDark` from `enum ThemeVariant`.
- Remove `.modernLight` and `.modernDark` arms from every `switch` in the file (`displayName`, `description`, `colorScheme`, `primaryBackground`, `secondaryBackground`, `tertiaryBackground`, `primaryText`, `secondaryText`, `tertiaryText`, `accentGradient`, `accentColor`, `purpleGradient`, `glassEffect`, `strokeColor`, `floatingOrbColors`).
- `isDarkMode` becomes: `selectedTheme == .royalAmethyst` only.
- `colorScheme` returns `.dark` only for `.royalAmethyst`; all other cases return `.light`.
- In `init()`, replace the fallback with:
  ```swift
  if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
     let theme = ThemeVariant(rawValue: savedTheme) {
      self.selectedTheme = theme
  } else {
      self.selectedTheme = .warmInviting
      UserDefaults.standard.removeObject(forKey: "isDarkMode")
  }
  ```
  Note: because `ThemeVariant(rawValue:)` now returns `nil` for saved `"modernLight"`/`"modernDark"` strings, the else branch auto-falls back to `warmInviting`. No extra migration code needed.

**Step 3: Edit every other hit from step 1**

For each `if themeManager.selectedTheme == .modernLight` or `.modernDark` branch in `ContentView.swift`, `HomeView.swift`, `SurahDetailView.swift`, `ThemeSelectionView.swift`, `Onboarding/FinalScreen.swift`: delete the branch. If it was part of a ternary, collapse to the remaining branch. If it was the only non-warmInviting branch, collapse the `if/else` to just the surviving code path.

**Step 4: Update ThemeSelectionView to show only 3 themes**

`ThemeVariant.allCases` now naturally emits only 3 values — the picker UI should already reflect this. Visually scan for hardcoded 5-theme assumptions (e.g., grid columns, pagination dots).

**Step 5: Compile**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0. If failure, fix every error before proceeding.

**Step 6: Verify no references remain**

Run: `grep -rn '\.modernLight\|\.modernDark' AlBayan/`
Expected: zero output.

**Step 7: Commit**

```bash
git add AlBayan/
git commit -m "refactor(theme): remove modernLight and modernDark themes"
```

---

## Task 2: Add Emerald Garden tokens to ThemeManager

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift`

**Step 1: Read the reference palette**

Open `AlBayan/Views/EmeraldGardenSurahDetailView.swift` and locate the `private enum EG { ... }` block. Note the six new tokens needed: `cardIvory`, `brass`, `emerald`, `deepEmerald`, `mutedOlive`, `agedIvory`.

**Step 2: Add new token properties to `ThemeManager`**

Append six new computed properties following the same `switch self.selectedTheme` pattern used by existing tokens. All three theme cases must be covered.

```swift
// Emerald Garden specific tokens (used by EG views; other themes get sensible values)

var ivoryCard: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 1.0, green: 0.976, blue: 0.961)
    case .emeraldGarden:
        return Color(red: 0.992, green: 0.973, blue: 0.918) // #FDF8EA
    case .royalAmethyst:
        return Color(red: 0.40, green: 0.27, blue: 0.36)
    }
}

var brassStroke: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 0.761, green: 0.725, blue: 0.573).opacity(0.5)
    case .emeraldGarden:
        return Color(red: 0.761, green: 0.725, blue: 0.573) // #C2B992
    case .royalAmethyst:
        return Color(red: 0.88, green: 0.70, blue: 0.50)
    }
}

var emerald: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 0.498, green: 0.722, blue: 0.604)
    case .emeraldGarden:
        return Color(red: 0.278, green: 0.369, blue: 0.271) // #475E45
    case .royalAmethyst:
        return Color(red: 0.65, green: 0.38, blue: 0.58)
    }
}

var deepEmerald: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 0.42, green: 0.54, blue: 0.44)
    case .emeraldGarden:
        return Color(red: 0.208, green: 0.294, blue: 0.176) // #354B2D
    case .royalAmethyst:
        return Color(red: 0.50, green: 0.28, blue: 0.45)
    }
}

var mutedOlive: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 0.69, green: 0.64, blue: 0.6)
    case .emeraldGarden:
        return Color(red: 0.627, green: 0.643, blue: 0.478) // #A0A47A
    case .royalAmethyst:
        return Color(red: 0.98, green: 0.91, blue: 0.70).opacity(0.7)
    }
}

var agedIvory: Color {
    switch selectedTheme {
    case .warmInviting:
        return Color(red: 0.969, green: 0.945, blue: 0.882)
    case .emeraldGarden:
        return Color(red: 0.890, green: 0.831, blue: 0.722) // #E3D4B8
    case .royalAmethyst:
        return Color(red: 0.51, green: 0.35, blue: 0.44)
    }
}
```

**Step 3: Compile**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0.

**Step 4: Commit**

```bash
git add AlBayan/Services/ThemeManager.swift
git commit -m "feat(theme): add Emerald Garden palette tokens to ThemeManager"
```

---

## Task 3: Create router helper and EmeraldGarden folder scaffolding

**Files:**
- Create: `AlBayan/Views/EmeraldGarden/EGRouter.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/` (folder)
- Create: `AlBayan/Views/EmeraldGarden/Tabs/` (folder)
- Create: `AlBayan/Views/EmeraldGarden/Onboarding/` (folder)

**Step 1: Create the folders**

```bash
mkdir -p AlBayan/Views/EmeraldGarden/Components
mkdir -p AlBayan/Views/EmeraldGarden/Tabs
mkdir -p AlBayan/Views/EmeraldGarden/Onboarding
```

**Step 2: Create `EGRouter.swift`**

```swift
//
//  EGRouter.swift
//  AlBayan
//
//  Theme-gated router helper. Use at every navigation/presentation boundary
//  that has an Emerald Garden counterpart view.
//

import SwiftUI

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

**Step 3: Add files to Xcode project**

Open `AlBayan.xcodeproj` in Xcode. Right-click the `Views` group → Add Files. Select the `EmeraldGarden` folder with "Create groups" option. Confirm new groups appear in the navigator.

Alternative: if `xcodeproj` Ruby gem or `xcodegen` is set up in the repo, use that. (Check `Gemfile` / `project.yml` first.)

**Step 4: Compile**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0.

**Step 5: Commit**

```bash
git add AlBayan/
git commit -m "chore(theme): scaffold EmeraldGarden folder and EGRouter helper"
```

---

## Task 4: Extract shared EG components from mockup

**Files:**
- Create: `AlBayan/Views/EmeraldGarden/Components/MihrabCardShape.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/SteppedBezel.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/EightPointStar.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/CornerMotifs.swift`
- Modify: `AlBayan/Views/EmeraldGardenSurahDetailView.swift` (remove the now-shared private types)

**Step 1: Create `MihrabCardShape.swift`**

Copy the `MihrabCardShape` struct verbatim from `EmeraldGardenSurahDetailView.swift` (currently lines ~320–402). Remove `private`. Conforms to `InsettableShape`. No other changes.

**Step 2: Create `SteppedBezel.swift`**

Copy the `SteppedBezel` struct from the mockup. Remove `private`. Replace the two references to `EG.emerald` and `EG.deepEmerald` with `ThemeManager.shared.emerald` and `ThemeManager.shared.deepEmerald`. Make `themeManager` an `@ObservedObject` property:

```swift
import SwiftUI

struct SteppedBezel: View {
    enum Side { case left, right }
    let side: Side
    @ObservedObject private var themeManager = ThemeManager.shared

    private let blocks: [CGSize] = [
        CGSize(width: 10, height: 14),
        CGSize(width: 18, height: 28),
        CGSize(width: 26, height: 42),
        CGSize(width: 22, height: 36),
        CGSize(width: 14, height: 22)
    ]

    var body: some View {
        VStack(alignment: side == .left ? .trailing : .leading, spacing: 3) {
            ForEach(0..<blocks.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.emerald, themeManager.deepEmerald],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: blocks[i].width, height: blocks[i].height)
                    .shadow(color: themeManager.deepEmerald.opacity(0.25), radius: 2, x: 0, y: 1)
            }
        }
        .frame(width: 32)
    }
}
```

**Step 3: Create `EightPointStar.swift`**

Copy the `EightPointStar` struct verbatim. Remove `private`. It's pure geometry — no palette refs.

**Step 4: Create `CornerMotifs.swift`**

Copy the `CornerMotifs` struct. Remove `private`. Replace `EG.brass` references with `ThemeManager.shared.brassStroke`. Make `themeManager` an `@ObservedObject`.

**Step 5: Remove the now-duplicated types from the mockup file**

Delete the `MihrabCardShape`, `SteppedBezel`, `EightPointStar`, `CornerMotifs`, and `private enum EG` blocks from `EmeraldGardenSurahDetailView.swift`. Replace every `EG.xxx` reference in the remaining file with `themeManager.xxx` (and add `@ObservedObject private var themeManager = ThemeManager.shared` to the view struct if not already present).

**Step 6: Add files to Xcode project**

Same as Task 3 Step 3.

**Step 7: Compile**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0.

**Step 8: Simulator check**

Build and run on iPhone 15 simulator. Navigate to a preview of `EmeraldGardenSurahDetailView`. Confirm it renders identically to before the refactor.

**Step 9: Commit**

```bash
git add AlBayan/
git commit -m "refactor(theme): extract shared EG shape components from mockup"
```

---

## Task 5: Create EG button, badge, and card-background components

**Files:**
- Create: `AlBayan/Views/EmeraldGarden/Components/EGPrimaryButton.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/EGSecondaryButton.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/EGNumberBadge.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/EGActionIconButton.swift`
- Create: `AlBayan/Views/EmeraldGarden/Components/EGCardBackground.swift`

**Step 1: `EGPrimaryButton.swift`** — emerald-gradient capsule (Play Sequence style).

```swift
import SwiftUI

struct EGPrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(themeManager.ivoryCard)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [themeManager.emerald, themeManager.deepEmerald],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .shadow(color: themeManager.emerald.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}
```

**Step 2: `EGSecondaryButton.swift`** — aged-ivory capsule with brass hairline (View Commentary style).

```swift
import SwiftUI

struct EGSecondaryButton: View {
    let title: String
    let systemImage: String?
    let fillWidth: Bool
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    init(_ title: String, systemImage: String? = nil, fillWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.fillWidth = fillWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(themeManager.deepEmerald)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .padding(.horizontal, fillWidth ? 0 : 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(themeManager.agedIvory.opacity(0.7)))
            .overlay(Capsule().strokeBorder(themeManager.brassStroke.opacity(0.45), lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }
}
```

**Step 3: `EGNumberBadge.swift`** — ivory circle 36×36 with brass hairline and sepia rounded-semibold numeral.

```swift
import SwiftUI

struct EGNumberBadge: View {
    let number: Int
    let size: CGFloat
    @ObservedObject private var themeManager = ThemeManager.shared

    init(_ number: Int, size: CGFloat = 36) {
        self.number = number
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.ivoryCard)
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(themeManager.brassStroke.opacity(0.6), lineWidth: 1))
            Text("\(number)")
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.primaryText)
        }
    }
}
```

**Step 4: `EGActionIconButton.swift`** — small ivory circle 34×34 for play/heart/bookmark icons.

```swift
import SwiftUI

struct EGActionIconButton: View {
    let systemImage: String
    let size: CGFloat
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    init(_ systemImage: String, size: CGFloat = 34, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(themeManager.deepEmerald)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(themeManager.ivoryCard)
                        .overlay(Circle().strokeBorder(themeManager.brassStroke.opacity(0.5), lineWidth: 0.75))
                )
        }
        .buttonStyle(.plain)
    }
}
```

**Step 5: `EGCardBackground.swift`** — reusable mihrab-arch card background modifier.

```swift
import SwiftUI

struct EGCardBackground: ViewModifier {
    var archHeight: CGFloat = 14
    var archWidthRatio: CGFloat = 0.42
    var cornerRadius: CGFloat = 20
    var showBrassHairline: Bool = true
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .background(
                MihrabCardShape(archHeight: archHeight, archWidthRatio: archWidthRatio, cornerRadius: cornerRadius)
                    .fill(themeManager.ivoryCard)
            )
            .overlay(
                MihrabCardShape(archHeight: archHeight, archWidthRatio: archWidthRatio, cornerRadius: cornerRadius)
                    .strokeBorder(themeManager.brassStroke.opacity(showBrassHairline ? 0.55 : 0), lineWidth: 0.9)
            )
            .shadow(color: themeManager.primaryText.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func egCard(archHeight: CGFloat = 14, archWidthRatio: CGFloat = 0.42, cornerRadius: CGFloat = 20, brassHairline: Bool = true) -> some View {
        modifier(EGCardBackground(archHeight: archHeight, archWidthRatio: archWidthRatio, cornerRadius: cornerRadius, showBrassHairline: brassHairline))
    }
}
```

**Step 6: Add files to Xcode project.**

**Step 7: Compile.**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0.

**Step 8: Commit**

```bash
git add AlBayan/
git commit -m "feat(theme): add EG primitive components (buttons, badge, card)"
```

---

## Task 6: Promote SurahDetail mockup to production EG view

**Files:**
- Move: `AlBayan/Views/EmeraldGardenSurahDetailView.swift` → `AlBayan/Views/EmeraldGarden/EGSurahDetailView.swift`
- Reference: `AlBayan/Views/SurahDetailView.swift` (source of data-wiring to mirror)

**Step 1: Move and rename**

```bash
git mv AlBayan/Views/EmeraldGardenSurahDetailView.swift AlBayan/Views/EmeraldGarden/EGSurahDetailView.swift
```

Rename the struct inside the file: `EmeraldGardenSurahDetailView` → `EGSurahDetailView`.

**Step 2: Study the data wiring in the source view**

Read `AlBayan/Views/SurahDetailView.swift`. Identify:
- The init signature (surah number, data manager, etc.)
- The verses property (how they load from `DataManager` / `QuranDataManager`)
- State objects and environment objects used
- Navigation callbacks (play audio, open commentary, bookmark)
- Any audio player or commentary sheet presentation

**Step 3: Replace hardcoded verses**

Delete the `private let verses: [(arabic: String, english: String)] = [...]` array. Replace with the same data source `SurahDetailView` uses (likely `DataManager.shared.verses(forSurah: ...)` or similar — exact API to be discovered in step 2).

Add the same initializer signature as `SurahDetailView` so it's a drop-in replacement.

**Step 4: Wire navigation actions**

- Hero "Play Sequence" button: invoke the same audio-play action `SurahDetailView` uses.
- Per-verse play icon: same.
- Per-verse heart icon: toggle bookmark via the same bookmark manager.
- Per-verse "View Commentary" button: present `EGFullScreenCommentaryView` (will be built in Task 13; use a TODO stub until then that opens the existing `FullScreenCommentaryView`).

**Step 5: Replace any remaining `EG.xxx` references**

Confirm zero references to the old private palette enum. All color reads through `themeManager`.

**Step 6: Compile**

Run: `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build`
Expected: exit 0.

**Step 7: Simulator check**

Run the app in simulator. Switch to Emerald Garden theme (Theme Selection). Open a surah and confirm:
- Real verse data renders (not the Al-Fatiha hardcoded set unless the opened surah is Al-Fatiha).
- Play buttons trigger audio.
- Heart toggle persists a bookmark.
- "View Commentary" opens the current commentary view (EG version will come later).

**Step 8: Commit**

```bash
git add AlBayan/
git commit -m "feat(theme): promote Emerald Garden Surah Detail mockup to production"
```

---

## Task 7: Wire EGSurahDetailView into the router

**Files:**
- Modify: `AlBayan/Views/HomeView.swift` (or wherever SurahDetailView is navigated to)

**Step 1: Locate every `SurahDetailView(...)` construction site**

Run: `grep -rn 'SurahDetailView(' AlBayan/`

**Step 2: Wrap each call in `emeraldOr`**

For each navigation destination or sheet content that constructs `SurahDetailView`, replace:
```swift
SurahDetailView(surahNumber: n, ...)
```
with:
```swift
emeraldOr {
    EGSurahDetailView(surahNumber: n, ...)
} std: {
    SurahDetailView(surahNumber: n, ...)
}
```

**Step 3: Compile.**

**Step 4: Simulator check** — switch themes, open a surah in each theme, confirm the right view renders.

**Step 5: Commit**

```bash
git add AlBayan/
git commit -m "feat(theme): route EmeraldGarden theme to EGSurahDetailView"
```

---

## View Restyle Template (Tasks 8–60)

**Every view-restyle task follows this template exactly.** Deviations are noted in the per-view task entries below.

### Template steps

1. **Read the source view** (`AlBayan/Views/<Source>.swift`). Identify:
   - Init signature and stored properties.
   - `@StateObject`/`@ObservedObject`/`@EnvironmentObject` dependencies.
   - Navigation destinations, sheet presentations, callbacks.
   - Structural layout regions (header, body, footer, cards, buttons).
   - Dynamic lists (ForEach) and their data source.

2. **Create `AlBayan/Views/EmeraldGarden/<EGFilename>.swift`** with:
   - Same struct init signature as source (drop-in compatible).
   - Same state/environment dependencies.
   - EG visual language:
     - Screen background = `themeManager.primaryBackground` + optional `CornerMotifs()` overlay.
     - Major cards wrapped with `.egCard(...)`.
     - Section headers: `.font(.system(size: 22, weight: .bold, design: .serif))` + `.foregroundColor(themeManager.deepEmerald)`.
     - Primary actions: `EGPrimaryButton`.
     - Secondary actions: `EGSecondaryButton`.
     - Numbered list items: `EGNumberBadge`.
     - Small icon buttons: `EGActionIconButton`.
     - Arabic text: serif + `themeManager.deepEmerald` + scoped RTL.
     - English body: rounded system + `themeManager.primaryText`.
     - Dividers: 1px `themeManager.brassStroke.opacity(0.35)`.
     - Color reads only via `themeManager`.
   - Preserve all navigation callbacks and data bindings exactly.

3. **Add file to Xcode project.**

4. **Compile:** `xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' -quiet build` → exit 0.

5. **Wire into router:** find every `<Source>(...)` call site and wrap in `emeraldOr { EG<Source>(...) } std: { <Source>(...) }`. (Often co-located with the task; sometimes touching the same router site as another task — batch wiring into nearby tasks when natural.)

6. **Simulator check:** switch to EG theme, navigate to the view, confirm layout + interactions.

7. **Commit:** `git commit -m "feat(theme): add EG variant of <Source>"`.

---

## Tasks 8–12: Core reading flow

### Task 8: EGHomeView
- **Source:** `AlBayan/Views/HomeView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGHomeView.swift`
- **Notes:** Surah list is the centerpiece — each surah row becomes a mihrab card with the Arabic surah name (serif, emerald) on the right, English name + meaning + verse count + revelation pill on the left, optional progress indicator. Daily verse hero card at top with emerald-gradient "Continue Reading" `EGPrimaryButton`. Corner motifs on.

### Task 9: EGHomeTab
- **Source:** `AlBayan/Views/Tabs/HomeTab.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/Tabs/EGHomeTab.swift`
- **Notes:** If HomeTab is a thin NavigationStack wrapper around HomeView, this task is small — mostly routing updates.

### Task 10: EGFullScreenCommentaryView
- **Source:** `AlBayan/Views/FullScreenCommentaryView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGFullScreenCommentaryView.swift`
- **Notes:** Each commentary layer renders in a mihrab card. Close/back button as `EGActionIconButton` top-left. Use serif section headers per layer. Arabic citations in deep emerald, scoped RTL. Important: this is the screen opened from EGSurahDetailView's "View Commentary" button — after this task, go back to EGSurahDetailView and switch its TODO stub to `EGFullScreenCommentaryView` (update the router there).

### Task 11: EGTafsirSourcesView
- **Source:** `AlBayan/Views/TafsirSourcesView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGTafsirSourcesView.swift`
- **Notes:** Each tafsir source entry is a small mihrab card with source name, scholar, and brief description. Toggle/selection state via brass hairline → emerald-filled border on selected.

### Task 12: EGVerseSummaryView & EGQuickOverviewView
- **Sources:** `AlBayan/Views/VerseSummaryView.swift`, `AlBayan/Views/QuickOverviewView.swift`
- **EG files:** `AlBayan/Views/EmeraldGarden/EGVerseSummaryView.swift`, `EGQuickOverviewView.swift`
- **Notes:** Batch these two since they're short and related. Summary card layout: Arabic verse, divider, English, then summary body. Overview: concept "bubbles" become pill chips with `themeManager.agedIvory` fill + brass hairline.

---

## Tasks 13–19: Tabs & Explore

### Task 13: EGMainTabView
- **Source:** `AlBayan/Views/MainTabView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGMainTabView.swift`
- **Notes:** TabView chrome tinted with `themeManager.accentColor`. Tab content uses `EGHomeTab`, `EGExploreTab`, `EGProgressTab`, `EGRamadanJourneyView`. **Router wiring:** update `ContentView` to use `emeraldOr` for `MainTabView` vs `EGMainTabView`.

### Task 14: EGExploreTab & EGExploreView
- **Sources:** `AlBayan/Views/Tabs/ExploreTab.swift`, `AlBayan/Views/ExploreView.swift`
- **EG files:** `AlBayan/Views/EmeraldGarden/Tabs/EGExploreTab.swift`, `AlBayan/Views/EmeraldGarden/EGExploreView.swift`
- **Notes:** Section headers serif bold. Carousel cards become small mihrab cards. Keep the same sections (Prophetic Stories, Life Moments, Questions, Ahlul Bayt Quran, Prophetic Parallels, Fasting Verses) and their data sources.

### Task 15: EGProgressTab & EGProgressRingsView
- **Sources:** `AlBayan/Views/Tabs/ProgressTab.swift`, `AlBayan/Views/ProgressRingsView.swift`, `AlBayan/Views/Components/ProgressRingView.swift`, `AlBayan/Views/Components/ProgressRingsStack.swift`
- **EG files:** `AlBayan/Views/EmeraldGarden/Tabs/EGProgressTab.swift`, `AlBayan/Views/EmeraldGarden/EGProgressRingsView.swift`, `Components/EGProgressRingView.swift`, `Components/EGProgressRingsStack.swift`
- **Notes:** Progress rings use `themeManager.emerald` for filled arc, `themeManager.brassStroke.opacity(0.3)` for unfilled track. Ring labels serif. Outer card mihrab-shaped.

### Task 16: EGRamadanJourneyView & EGRamadanDayDetailView
- **Sources:** `AlBayan/Views/RamadanJourneyView.swift`, `AlBayan/Views/RamadanDayDetailView.swift`
- **EG files:** `AlBayan/Views/EmeraldGarden/EGRamadanJourneyView.swift`, `EGRamadanDayDetailView.swift`
- **Notes:** 30-day calendar grid with each day as a small mihrab card; completed days filled emerald, pending outlined brass. Day detail reuses verse-card pattern from EGSurahDetailView.

### Task 17: EGFastingVersesView & EGFastingCategoryDetailView
- **Sources:** `AlBayan/Views/FastingVersesView.swift`, `AlBayan/Views/FastingCategoryDetailView.swift`
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Category cards = mihrab cards. Detail view = verse list with verse cards from the EGSurahDetail pattern.

### Task 18: EGPropheticStoriesView, EGStoryDetailView, EGPropheticParallelsView, EGParallelDetailView, EGLifeMomentsView
- **Sources:** Corresponding files in `AlBayan/Views/`.
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Batch these five — all share the "list of story cards → detail with narrative body + Quranic references" pattern. Story cards: large ivory mihrab card with title (serif), Prophet name (serif italic muted-olive), brief summary (rounded sepia), and a small brass "read more" chevron. Detail: narrative in rounded sepia paragraphs, Quranic reference blocks in deep-emerald serif with RTL, verse cards for cited verses.

### Task 19: EGQuestionsView, EGQuestionDetailView, EGAhlulbaytQuranView, EGAhlulbaytEntryDetailView, EGBookmarksView
- **Sources:** Corresponding files in `AlBayan/Views/`.
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Batch. Questions: each question is a mihrab card with serif question text + tap-to-expand answer. Ahlul Bayt: scholar/figure cards with name (serif) + dates + biography snippet. Bookmarks: grouped mihrab cards by surah, verse rows use the EGSurahDetail verse-card pattern (compact variant).

---

## Tasks 20–27: Detail & modal views

### Task 20: EGSurahAudioPlayerView
- **Source:** `AlBayan/Views/SurahAudioPlayerView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGSurahAudioPlayerView.swift`
- **Notes:** Large mihrab card with surah name (Arabic serif emerald + English serif italic muted-olive). Scrubber: brass track with emerald filled portion and brass handle circle (`EGActionIconButton`-style). Transport controls: 3 `EGActionIconButton`s (prev, play/pause, next) — play/pause is the larger emerald-gradient-filled variant. Speed/reciter pickers as `EGSecondaryButton`.

### Task 21: EGQuizView & EGQuizResultsView & EGBadgeAwardView
- **Sources:** `QuizView.swift`, `QuizResultsView.swift`, `BadgeAwardView.swift`
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Batch. Quiz question card = hero mihrab card with question body (rounded sepia). Answer options = `EGSecondaryButton` variants; selected answer gets emerald border; correct after-submit fills emerald; wrong fills deep-rose (new token needed? Use `themeManager.accentColor` for incorrect-state as approximation). Results: score in a hero card with progress-ring visual. Badge award: decorative 8-point star with badge icon centered, confetti stars motif.

### Task 22: EGPaywallView & EGPremiumBadgeView
- **Sources:** `PaywallView.swift`, `PremiumBadgeView.swift`
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Hero mihrab card with crown/gem icon + serif "Premium" title. Feature bullets as mihrab mini-cards with icon + one-line description. Plan selection: two `EGSecondaryButton` variants (monthly/annual), selected fills emerald gradient. CTA: large `EGPrimaryButton` "Subscribe". Premium badge view: small emerald-gradient pill with "Premium" text.

### Task 23: EGTTSVoicePickerView & EGNotificationsView
- **Sources:** `TTSVoicePickerView.swift`, `NotificationsView.swift`
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Batch. Voice picker: each voice = mihrab row card with name + language + play-sample `EGActionIconButton` + selected checkmark. Notifications settings: grouped list of toggle rows in mihrab card groups.

---

## Tasks 24–28: Settings & Auth

### Task 24: EGSettingsView
- **Source:** `SettingsView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGSettingsView.swift`
- **Notes:** Grouped mihrab-card sections. Section headers serif bold deep-emerald. Rows: label + chevron/toggle/value, divider = 1px brass @ 0.35.

### Task 25: EGThemeSelectionView
- **Source:** `ThemeSelectionView.swift`
- **EG file:** `AlBayan/Views/EmeraldGarden/EGThemeSelectionView.swift`
- **Notes:** Three theme preview cards (one per theme) in a vertical stack. Each card is a mihrab card showing a miniature visual preview + name + description. Selected theme gets emerald border + brass inset stroke. Also update the *standard* `ThemeSelectionView` (non-EG) in a separate pass if it still assumes 5 themes — grid/column count may need a tweak.

### Task 26: EGAccountDeletionView
- **Source:** `AccountDeletionView.swift`
- **EG file:** `EmeraldGarden/EGAccountDeletionView.swift`
- **Notes:** Warning hero mihrab card. Destructive CTA keeps red tint (not from theme — use `Color.red` with opacity for the warning semantics).

### Task 27: EGAuthenticationView & EGWelcomeView
- **Sources:** `AuthenticationView.swift`, `WelcomeView.swift`
- **EG files:** Matching in `EmeraldGarden/`.
- **Notes:** Batch. Welcome: large mihrab hero card with serif Arabic brand mark, English tagline, `EGPrimaryButton` "Get Started", `EGSecondaryButton` "Sign In". Auth: email/password fields styled with ivory fill + brass hairline; provider buttons (Apple/Google) as `EGSecondaryButton` variants.

---

## Tasks 28–38: Onboarding (one per screen + flow)

Each is small since onboarding screens are single-purpose. Batch into fewer commits only if structurally near-identical.

### Task 28: EGOnboardingFlowView
- **Source:** `Onboarding/OnboardingFlowView.swift`
- **EG file:** `EmeraldGarden/Onboarding/EGOnboardingFlowView.swift`
- **Notes:** Page indicator = 11 small dots, selected = emerald filled, unselected = brass ring. Next/Back chrome as `EGSecondaryButton`/`EGPrimaryButton`.

### Task 29: EGMissionScreen
- **Source:** `Onboarding/MissionScreen.swift` — **Notes:** Hero serif title deep-emerald + body rounded sepia + decorative 8-point star accent.

### Task 30: EGFiveLayersScreen
- **Source:** `Onboarding/FiveLayersScreen.swift` — **Notes:** Each of the 5 layers as a small mihrab row card with layer number badge + layer name + one-line description.

### Task 31: EGQuickGemsScreen
- **Source:** `Onboarding/QuickGemsScreen.swift` — **Notes:** Example "gem" card = verse card pattern from EGSurahDetail with a "gem" serif header.

### Task 32: EGQuizFeatureScreen
- **Source:** `Onboarding/QuizFeatureScreen.swift` — **Notes:** Illustrative quiz preview using the same quiz-card language from Task 21.

### Task 33: EGHadithScreen
- **Source:** `Onboarding/HadithScreen.swift` — **Notes:** Hadith card pattern — Arabic block + English block + source chain (scroll-like brass divider between).

### Task 34: EGSeasonalFeaturesScreen
- **Source:** `Onboarding/SeasonalFeaturesScreen.swift` — **Notes:** Feature list (Ramadan, Hajj, etc.) as mihrab row cards with seasonal icons.

### Task 35: EGDailyVerseScreen
- **Source:** `Onboarding/DailyVerseScreen.swift` — **Notes:** Hero mihrab card showing a daily-verse example.

### Task 36: EGProgressTrackingScreen & EGProgressNotificationsScreen
- **Sources:** Two onboarding screens. **Notes:** Batch. Progress rings preview for the first; notification preview cards for the second (different times of day).

### Task 37: EGFinalScreen
- **Source:** `Onboarding/FinalScreen.swift` — **Notes:** Celebratory 8-point star centered, serif "Welcome" title, `EGPrimaryButton` "Enter Al-Bayan".

### Task 38: Wire onboarding router
- **Files:** `AlBayan/ContentView.swift` (or wherever `OnboardingFlowView` is presented).
- **Notes:** Wrap the presentation in `emeraldOr { EGOnboardingFlowView() } std: { OnboardingFlowView() }`.
- **Compile + simulator check + commit.**

---

## Task 39: EG components for Explore carousels

**Files:**
- Create: `EmeraldGarden/Components/EGAhlulbaytQuranCarouselCard.swift`
- Create: `EmeraldGarden/Components/EGDiscoveryCarousel.swift`
- Create: `EmeraldGarden/Components/EGExploreRow.swift`
- Create: `EmeraldGarden/Components/EGExploreSectionHeader.swift`
- Create: `EmeraldGarden/Components/EGLifeMomentsCarouselCard.swift`
- Create: `EmeraldGarden/Components/EGPropheticStoriesCarouselCard.swift`
- Create: `EmeraldGarden/Components/EGQuestionsCarouselCard.swift`
- Create: `EmeraldGarden/Components/EGIslamicGeometricPattern.swift`

**Steps:** one sub-commit per component; each mirrors its source from `AlBayan/Views/Components/` with EG palette + mihrab-card wrapping where appropriate. Used by EGExploreView/EGExploreTab from Task 14 — if Task 14 was completed with inlined replacements, refactor Task 14 to consume these shared components now, and re-verify.

---

## Task 40: Router wiring sweep

**Files:**
- Audit every file listed by: `grep -rln 'NavigationLink\|\.sheet\|\.fullScreenCover' AlBayan/ | grep -v EmeraldGarden/`

**Step 1:** Open each file; for each navigation/presentation target that has an `EG*` counterpart, wrap in `emeraldOr`.

**Step 2:** Compile + simulator check. Switch themes. Walk through every major flow: onboarding → tabs → surah → verse → commentary → tafsir source → audio player → quiz → badge → paywall → settings → theme selection → auth.

**Step 3:** Commit `chore(theme): final router wiring sweep for EmeraldGarden`.

---

## Task 41: Final verification

**Step 1:** `grep -rn '\.modernLight\|\.modernDark' AlBayan/` → expect zero.

**Step 2:** `grep -rn 'private enum EG' AlBayan/Views/EmeraldGarden/` → expect zero.

**Step 3:** `grep -rn 'ThemeManager.shared' AlBayan/Views/EmeraldGarden/ | wc -l` → expect non-zero (EG views must use the theme manager).

**Step 4:** Full `xcodebuild` clean build.

**Step 5:** Simulator walkthrough in all three themes. Capture before/after screenshots in `screenshots/emerald-garden-rebuild/`.

**Step 6:** Manually set `UserDefaults` key `selectedTheme` to `"modernLight"` via:
```bash
xcrun simctl spawn booted defaults write <bundle-id> selectedTheme modernLight
```
Relaunch app; confirm it falls back to `warmInviting` without crashing.

**Step 7:** Commit any final touchups `chore(theme): emerald garden rebuild verification pass`.

---

## Success criteria (from design doc §11)

- `ThemeVariant` has exactly 3 cases.
- `xcodebuild` compiles cleanly, no unhandled-case warnings.
- Emerald Garden theme applies to every screen end-to-end.
- Warm & Inviting and Royal Amethyst unchanged.
- No private palette enums in `EmeraldGarden/`.
- `grep '\.modernLight\|\.modernDark'` returns zero.
