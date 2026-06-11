# Royal Sapphire Dark Theme — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add "Royal Sapphire" — a premium royal-navy + champagne-gold dark theme — as a third, selectable theme and the fresh-install default, with full handoff-fidelity redesigns of the primary screens (Progress excepted) built as a separate Sapphire view tree.

**Architecture:** Approach A. Royal Sapphire is a new `ThemeVariant` whose tokens live in `ThemeManager`. Its screens are *separate* SwiftUI views (`Views/Sapphire/…`) composed from a shared `Sp*` component library, selected at the router/tab level when Sapphire is active. The two light themes (Warm, Rosewater) and their views are untouched. The Progress tab reuses the existing `ProgressRingsView`, recolored via tokens.

**Tech Stack:** SwiftUI, iOS, SwiftData/CloudKit (unchanged), bundled fonts (Cormorant Garamond + Amiri), SF Symbols.

---

## Pre-flight (read once before Task 1)

**Reference material (source of truth for geometry/colors):**
- Design doc: `docs/plans/2026-06-09-royal-sapphire-dark-theme-design.md`
- Handoff spec: `design_handoff_royal_sapphire/README.md` (§Design Tokens, §Screens)
- Authoritative components/values: `design_handoff_royal_sapphire/design-files/sapphire.jsx` (the `SP` object + `Sp*` + `SC0n_*` screen functions) and `shared.jsx` (`Icon` set)

**There is no test target.** Verification is by compile + simulator. Two reusable verification steps referenced throughout:

- **Verify (build)** — fast compile check, no signing:
  ```bash
  xcodebuild -project AlBayan.xcodeproj -scheme AlBayan \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
  ```
  Expected: `** BUILD SUCCEEDED **`.

- **Verify (simulator)** — run + screenshot to check visually. Build **without** `CODE_SIGNING_ALLOWED=NO` (that flag traps in CloudKit on launch). Easiest path: use the project's **/run** skill, or:
  ```bash
  xcodebuild -project AlBayan.xcodeproj -scheme AlBayan \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
  # then install the .app on a booted sim and launch, or run via Xcode/​/run skill
  ```
  Then screenshot and compare against `design_handoff_royal_sapphire/design-files/Royal Sapphire.html` (open in a browser; frames are 390×844 pt).

**Project conventions:**
- Commit steps are included as checkpoints, but **per project preference do NOT auto-commit**: stage the listed files and pause for the author to run `git commit`. (Execution uses implementer + spec review only — no separate code-quality reviewer.)
- Views consume color/type **only** through `ThemeManager.shared.<getter>` — never hardcode hex in Sapphire views.
- Use `themeManager.isSapphire` to branch routers; never check `selectedTheme == .royalSapphire` outside `ThemeManager`/`SettingsView`.

**Token quick-reference (handoff `SP`):**
```
bg0 #0A1124  bg1 #101E40  bg2 #070C1C
card white@5%  cardElev white@7.5%
ink #EAEFFB  ink2 ink@62%  ink3 ink@40%
hair gold@18%  hairSoft gold@10%
gold #D9C079  goldBright #F2E2A8  goldDeep #B5963F  goldChip gold@15%
azure #5B9BE0  azureChip azure@18%
goldGrad = LinearGradient(#F2E2A8 → #B5963F, .topLeading → .bottomTrailing)
ctaText/SPC #1B1606   (text/icons on gold)
```

---

## Phase 0 — Foundation

### Task 0.1: Add the `royalSapphire` theme case

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift:12-31` (enum)

**Step 1: Add the case + metadata**

In `enum ThemeVariant`:
```swift
enum ThemeVariant: String, CaseIterable, Identifiable {
    case warmInviting  = "warmInviting"
    case rosewater     = "rosewater"
    case royalSapphire = "royalSapphire"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmInviting:  return "Warm & Inviting"
        case .rosewater:     return "Rosewater"
        case .royalSapphire: return "Royal Sapphire"
        }
    }

    var description: String {
        switch self {
        case .warmInviting:  return "Sanctuary-like warm design"
        case .rosewater:     return "Soft dusty-rose blush palette"
        case .royalSapphire: return "Gilded royal-navy dark theme"
        }
    }
}
```

**Step 2: Verify (build)** — will FAIL to compile: every non-exhaustive `switch selectedTheme` in `ThemeManager` and `SettingsView` now errors. That is expected and drives Tasks 0.2–0.4 and 0.8. Note the errors.

**Step 3: Commit** (stage, author commits): `AlBayan/Services/ThemeManager.swift`

---

### Task 0.2: Core flags — dark color scheme, default, layout switch

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift` (`isDarkMode`, `colorScheme`, `useWarmLayout`, `init`, add `isSapphire`)

**Step 1: Dark color scheme + flags**
```swift
var isDarkMode: Bool { selectedTheme == .royalSapphire }

var colorScheme: ColorScheme { selectedTheme == .royalSapphire ? .dark : .light }

/// True when the Sapphire editorial layout (separate view tree) should be used.
var isSapphire: Bool { selectedTheme == .royalSapphire }

var useWarmLayout: Bool {
    switch selectedTheme {
    case .warmInviting, .rosewater: return true
    case .royalSapphire:            return false
    }
}
```

**Step 2: Default to Sapphire on fresh install**

In `init()`, change the fallback:
```swift
private init() {
    if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
       let stored = ThemeVariant(rawValue: raw) {
        self.selectedTheme = stored
    } else {
        self.selectedTheme = .royalSapphire   // fresh-install default
    }
}
```

**Step 3: Verify (build)** — still fails on the color getters (Task 0.3). Confirm the flag code itself has no new errors beyond the unfilled palette switches.

**Step 4: Commit** (stage): `AlBayan/Services/ThemeManager.swift`

---

### Task 0.3: Fill the existing palette getters for Sapphire

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift` — every `switch selectedTheme` getter.

Add a `.royalSapphire` branch to each. Use a small private `Color(hex:)`/opacity helper (the `Color(hex:)` initializer already exists in `WarmThemeModifiers.swift`). Complete values:

```swift
// Backgrounds
var primaryBackground: Color {
    switch selectedTheme {
    case .warmInviting:  return Color(red: 0.973, green: 0.961, blue: 1.0)
    case .rosewater:     return Color(red: 0.992, green: 0.953, blue: 0.949)
    case .royalSapphire: return Color(hex: "#0A1124")            // bg0
    }
}
var secondaryBackground: Color {
    switch selectedTheme {
    case .warmInviting:  return Color(red: 0.987, green: 0.969, blue: 0.980)
    case .rosewater:     return Color(red: 1.000, green: 0.988, blue: 0.988)
    case .royalSapphire: return Color(hex: "#070C1C")            // bg2 (sheet base)
    }
}
var tertiaryBackground: Color {
    switch selectedTheme {
    case .warmInviting:  return Color(red: 1.0, green: 0.976, blue: 0.961)
    case .rosewater:     return Color(red: 0.969, green: 0.902, blue: 0.894)
    case .royalSapphire: return Color(hex: "#101E40")            // bg1
    }
}

// Text
var primaryText: Color {        // … + case .royalSapphire: Color(hex: "#EAEFFB")
var secondaryText: Color {      // … + case .royalSapphire: Color(hex: "#EAEFFB").opacity(0.62)
var tertiaryText: Color {       // … + case .royalSapphire: Color(hex: "#EAEFFB").opacity(0.40)

// Card surface (translucent white over the navy gradient)
var cardBackground: Color {     // … + case .royalSapphire: Color.white.opacity(0.05)

// Accents
var accentColor: Color {        // … + case .royalSapphire: Color(hex: "#D9C079")  // gold
var accentColorDark: Color {    // … + case .royalSapphire: Color(hex: "#B5963F")  // goldDeep
var accentSecondary: Color {    // … + case .royalSapphire: Color(hex: "#5B9BE0")  // azure
var accentSecondaryDark: Color {// … + case .royalSapphire: Color(hex: "#3F7BC0")

// Gradients — Sapphire uses the gold gradient for the primary/accent slots
var purpleGradient: LinearGradient {   // … + .royalSapphire: goldGradient
var accentGradient: LinearGradient {   // … + .royalSapphire: goldGradient
var reminderGradient: LinearGradient { // … + .royalSapphire: LinearGradient(
    //   [Color(hex:"#101E40"), Color(hex:"#070C1C")], .topLeading, .bottomTrailing)

// Material / stroke
// glassEffect already returns cardBackground — OK.
var strokeColor: Color {        // … + case .royalSapphire: Color(hex: "#D9C079").opacity(0.18) // hair

var floatingOrbColors: [Color] { // … + .royalSapphire:
    //   [Color(hex:"#D9C079").opacity(0.10), Color(hex:"#5B9BE0").opacity(0.07),
    //    Color(hex:"#F2E2A8").opacity(0.06)]
}
```
(For each getter above, keep the existing `.warmInviting`/`.rosewater` branches verbatim and add the `.royalSapphire` branch shown.)

**Step 2: Verify (build)** — should now compile *if* `goldGradient` exists; it doesn't yet, so add Task 0.4 first or stub `goldGradient` here. Recommended: do Task 0.4 in the same edit pass, then build once.

**Step 3: Commit** (stage): `AlBayan/Services/ThemeManager.swift`

---

### Task 0.4: Add new premium-texture getters

**Files:**
- Modify: `AlBayan/Services/ThemeManager.swift` (append new computed vars)

Each returns Sapphire's premium value and a safe equivalent for the light themes so nothing about Warm/Rosewater changes.

```swift
// MARK: - Royal Sapphire premium tokens

/// 135° champagne-gold gradient for CTAs, rings, active chips.
var goldGradient: LinearGradient {
    switch selectedTheme {
    case .royalSapphire:
        return LinearGradient(colors: [Color(hex: "#F2E2A8"), Color(hex: "#B5963F")],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    default:
        return accentGradient   // light themes reuse their accent gradient
    }
}

/// Bright gold for numerals, hero figures, Arabic hero.
var accentBright: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#F2E2A8") : accentColor
}

/// Elevated/featured card fill.
var cardElevated: Color {
    selectedTheme == .royalSapphire ? Color.white.opacity(0.075) : cardBackground
}

/// Faint inner border.
var strokeSoft: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#D9C079").opacity(0.10) : strokeColor
}

/// Icon-chip / numeral fill.
var goldChipFill: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#D9C079").opacity(0.15) : accentColor.opacity(0.12)
}

/// Semantic "verified / answered" accent + its chip.
var semanticAzure: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#5B9BE0") : accentSecondary
}
var semanticAzureChip: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#5B9BE0").opacity(0.18) : accentSecondary.opacity(0.15)
}

/// Text/icon color ON gold buttons (near-black).
var onAccentText: Color {
    selectedTheme == .royalSapphire ? Color(hex: "#1B1606") : .white
}

/// Background: radial bg1→bg0→bg2 (Sapphire) or a flat primaryBackground.
@ViewBuilder var backgroundLayer: some View {
    if selectedTheme == .royalSapphire {
        ZStack {
            Color(hex: "#0A1124")
            RadialGradient(colors: [Color(hex: "#101E40"), Color(hex: "#0A1124"), Color(hex: "#070C1C")],
                           center: .top, startRadius: 0, endRadius: 700)
            // gold top glow
            RadialGradient(colors: [Color(hex: "#D9C079").opacity(0.14), .clear],
                           center: .init(x: 0.5, y: -0.02), startRadius: 0, endRadius: 240)
                .frame(height: 320).allowsHitTesting(false)
        }
        .ignoresSafeArea()
    } else {
        primaryBackground.ignoresSafeArea()
    }
}

// Shadows
var cardShadow: Color { Color(hex: "#040918").opacity(selectedTheme == .royalSapphire ? 0.35 : 0.06) }
var cardShadowElevated: Color { Color(hex: "#040918").opacity(selectedTheme == .royalSapphire ? 0.55 : 0.10) }
var goldButtonShadow: Color { Color(hex: "#D9C079").opacity(selectedTheme == .royalSapphire ? 0.24 : 0.0) }
```

**Step 2: Verify (build)** — should now be `BUILD SUCCEEDED` (palette + new getters complete). `SettingsView` still errors on its preview switches → Task 0.8.

> If `SettingsView` blocks the build, do Task 0.8 now, then return. Order 0.3 → 0.4 → 0.8 → build.

**Step 3: Commit** (stage): `AlBayan/Services/ThemeManager.swift`

---

### Task 0.5: Bundle Cormorant Garamond + Amiri fonts

**Files:**
- Create: `AlBayan/Resources/Fonts/CormorantGaramond-Medium.ttf`, `…-SemiBold.ttf`, `…-MediumItalic.ttf`, `…-SemiBoldItalic.ttf`, `Amiri-Regular.ttf`, `Amiri-Bold.ttf`
- Modify: `AlBayan/Info.plist` (add `UIAppFonts`)
- Modify: `AlBayan.xcodeproj/project.pbxproj` (add font files + Resources/Fonts group to the AlBayan target — do this in Xcode, "Add Files to AlBayan", *Copy if needed*, target checked)
- Create: `AlBayan/Views/Sapphire/SapphireFont.swift`

**Step 1: Fetch the fonts (OFL — free to bundle).** From the Google Fonts repo (verify paths; repo layout may differ — fall back to fonts.google.com download if a URL 404s):
```bash
mkdir -p AlBayan/Resources/Fonts && cd AlBayan/Resources/Fonts
base=https://raw.githubusercontent.com/google/fonts/main/ofl
curl -fL -o Amiri-Regular.ttf "$base/amiri/Amiri-Regular.ttf"
curl -fL -o Amiri-Bold.ttf    "$base/amiri/Amiri-Bold.ttf"
# Cormorant Garamond static instances:
for w in Medium SemiBold MediumItalic SemiBoldItalic; do
  curl -fL -o "CormorantGaramond-$w.ttf" "$base/cormorantgaramond/CormorantGaramond-$w.ttf"
done
cd -
```
Verify each file is a real TTF: `file AlBayan/Resources/Fonts/*.ttf` (each should say "TrueType"). Re-download any that came back as HTML.

**Step 2: Add the files to the Xcode target** (Resources/Fonts group, target membership = AlBayan).

**Step 3: Register in `Info.plist`** — add inside the top-level `<dict>`:
```xml
<key>UIAppFonts</key>
<array>
    <string>CormorantGaramond-Medium.ttf</string>
    <string>CormorantGaramond-SemiBold.ttf</string>
    <string>CormorantGaramond-MediumItalic.ttf</string>
    <string>CormorantGaramond-SemiBoldItalic.ttf</string>
    <string>Amiri-Regular.ttf</string>
    <string>Amiri-Bold.ttf</string>
</array>
```

**Step 4: Font helper** — `AlBayan/Views/Sapphire/SapphireFont.swift`:
```swift
import SwiftUI

/// Royal Sapphire type scale. Serif = Cormorant Garamond, Arabic = Amiri, sans = system.
/// PostScript names (verify with the print in Step 5): "CormorantGaramond-Medium",
/// "CormorantGaramond-SemiBold", "Amiri", "Amiri-Bold".
enum SapphireFont {
    static func serif(_ size: CGFloat, semibold: Bool = true, italic: Bool = false) -> Font {
        let name: String
        switch (semibold, italic) {
        case (true,  false): name = "CormorantGaramond-SemiBold"
        case (true,  true):  name = "CormorantGaramond-SemiBoldItalic"
        case (false, false): name = "CormorantGaramond-Medium"
        case (false, true):  name = "CormorantGaramond-MediumItalic"
        }
        return .custom(name, size: size)
    }
    static func arabic(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Amiri-Bold" : "Amiri", size: size)
    }

    // Scale (handoff)
    static var screenTitle: Font { serif(40) }                       // 40/600
    static func headline(_ s: CGFloat = 24) -> Font { serif(s) }     // 21–27/600
    static func numeral(_ s: CGFloat = 30) -> Font { serif(s) }      // 26–36/600
    static func body(_ s: CGFloat = 17) -> Font { serif(s, semibold: false) } // 17–20/500
    static var eyebrow: Font { .system(size: 11, weight: .bold) }    // UPPERCASE +3 tracking
    static func arabicVerse(_ s: CGFloat = 28) -> Font { arabic(s) } // 27–30/400
}
```

**Step 5: Verify fonts register.** Add a temporary `.onAppear` (or a `#Preview`) that prints families, run once in simulator:
```swift
for f in UIFont.familyNames.sorted() where f.contains("Cormorant") || f.contains("Amiri") {
    print(f, UIFont.fontNames(forFamilyName: f))
}
```
Expected: Cormorant Garamond + Amiri families with the exact PostScript names. Fix `SapphireFont` names if they differ, then remove the temporary print.

**Step 6: Verify (build)** + **Step 7: Commit** (stage): fonts, `Info.plist`, `SapphireFont.swift`, `project.pbxproj`.

---

### Task 0.6: `Sp*` component library

**Files:**
- Create: `AlBayan/Views/Sapphire/Components/SapphireComponents.swift`

Port the handoff primitives (source: `sapphire.jsx` lines for `SpShell`/`SpHeading`/`SpCard`/`SpNumeral`/`SpGoldCTA`/`SpDivider`/`SpIconChip`). All read from `ThemeManager`. Skeleton (fill remaining per handoff geometry):

```swift
import SwiftUI

private let tm = ThemeManager.shared

/// Page wrapper: navy gradient + gold glow behind content.
struct SpShell<Content: View>: View {
    @StateObject private var themeManager = ThemeManager.shared
    @ViewBuilder var content: Content
    var body: some View {
        ZStack { themeManager.backgroundLayer; content }
    }
}

/// Gold eyebrow + Cormorant title (+ optional sub, centered variant).
struct SpHeading: View {
    @StateObject private var themeManager = ThemeManager.shared
    var eyebrow: String? = nil
    var title: String
    var sub: String? = nil
    var center: Bool = false
    var body: some View {
        VStack(alignment: center ? .center : .leading, spacing: 7) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(SapphireFont.eyebrow).tracking(3)
                    .foregroundColor(themeManager.accentColor)
            }
            Text(title)
                .font(SapphireFont.screenTitle).tracking(0.2)
                .foregroundColor(themeManager.primaryText)
                .lineSpacing(0)
            if let sub {
                Text(sub).font(.system(size: 13.5))
                    .foregroundColor(themeManager.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
    }
}

/// Rounded card: card fill, hair border, soft shadow; elev/glow variants.
struct SpCard<Content: View>: View {
    @StateObject private var themeManager = ThemeManager.shared
    var elev = false
    var glow = false
    var radius: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(elev ? themeManager.cardElevated : themeManager.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1)
            )
            .shadow(color: glow ? themeManager.cardShadowElevated : themeManager.cardShadow,
                    radius: glow ? 20 : 12, x: 0, y: glow ? 16 : 8)
    }
}

/// Gold-stroke circle with Cormorant numeral.
struct SpNumeral: View {
    @StateObject private var themeManager = ThemeManager.shared
    var n: String
    var size: CGFloat = 46
    var body: some View {
        Text(n).font(SapphireFont.numeral(size * 0.42))
            .foregroundColor(themeManager.accentBright)
            .frame(width: size, height: size)
            .background(Circle().fill(themeManager.goldChipFill))
            .overlay(Circle().stroke(themeManager.accentColor, lineWidth: 1))
    }
}

/// Full-width (or inline) gold CTA.
struct SpGoldCTA: View {
    @StateObject private var themeManager = ThemeManager.shared
    var title: String
    var systemIcon: String? = nil
    var small = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let systemIcon { Image(systemName: systemIcon) }
                Text(title).tracking(0.3)
            }
            .font(.system(size: small ? 14 : 15.5, weight: .bold))
            .foregroundColor(themeManager.onAccentText)
            .frame(maxWidth: .infinity).padding(.vertical, small ? 12 : 16)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(themeManager.goldGradient))
            .shadow(color: themeManager.goldButtonShadow, radius: 14, x: 0, y: 10)
        }
        .buttonStyle(SpPressStyle())
    }
}

/// Hairline rule each side of a centered gold diamond or uppercase label.
struct SpDivider: View {
    @StateObject private var themeManager = ThemeManager.shared
    var label: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(LinearGradient(colors: [.clear, themeManager.strokeColor],
                startPoint: .leading, endPoint: .trailing)).frame(height: 1)
            if let label {
                Text(label.uppercased()).font(.system(size: 11, weight: .bold)).tracking(2.5)
                    .foregroundColor(themeManager.tertiaryText)
            } else {
                Rectangle().fill(themeManager.accentColor).frame(width: 6, height: 6).rotationEffect(.degrees(45))
            }
            Rectangle().fill(LinearGradient(colors: [themeManager.strokeColor, .clear],
                startPoint: .leading, endPoint: .trailing)).frame(height: 1)
        }
    }
}

/// Rounded-14 icon chip; active = gold gradient fill.
struct SpIconChip: View {
    @StateObject private var themeManager = ThemeManager.shared
    var systemIcon: String
    var size: CGFloat = 46
    var active = false
    var body: some View {
        Image(systemName: systemIcon)
            .font(.system(size: size * 0.40, weight: .regular))
            .foregroundColor(active ? themeManager.onAccentText : themeManager.accentColor)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(active ? AnyShapeStyle(themeManager.goldGradient) : AnyShapeStyle(themeManager.goldChipFill)))
            .overlay(active ? nil : RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(themeManager.strokeColor, lineWidth: 1))
    }
}

/// Subtle press feedback (scale + opacity), consistent across Sapphire.
struct SpPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
```

**Step 2: Verify (build).** **Step 3:** Add a `#Preview` exercising each component on the Sapphire background; screenshot. **Step 4: Commit** (stage): `SapphireComponents.swift`.

---

### Task 0.7: Floating Sapphire tab bar

**Files:**
- Create: `AlBayan/Views/Sapphire/Components/SpTabBar.swift`
- Modify: `AlBayan/Views/MainTabView.swift`

**Step 1: `SpTabBar`** (source: `sapphire.jsx` `SpTabBar`, lines ~105-140). Items = the app's current 5 tabs (Today `sun.max`, Quran `book`, Explore `sparkles`, Progress `chart.bar.fill`, Journey `map`). Active = `goldBright` icon+label + 4pt gold dot beneath; inactive `ink3`. Bar: inset 18, 30 from bottom, radius 22, fill `Color(hex:"#0A1124").opacity(0.74)` + `.background(.ultraThinMaterial)`, 1pt `hair`, shadow `cardShadowElevated`.

```swift
struct SpTabBar: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var selection: Int
    struct Item { let title: String; let icon: String; let tag: Int }
    private let items = [
        Item(title: "Today", icon: "sun.max", tag: 0),
        Item(title: "Quran", icon: "book", tag: 1),
        Item(title: "Explore", icon: "sparkles", tag: 2),
        Item(title: "Progress", icon: "chart.bar.fill", tag: 3),
        Item(title: "Journey", icon: "map", tag: 4),
    ]
    var body: some View {
        HStack {
            ForEach(items, id: \.tag) { item in
                let active = selection == item.tag
                Button { selection = item.tag } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon).font(.system(size: 18, weight: .regular))
                        Text(item.title).font(.system(size: 10, weight: .semibold)).tracking(0.4)
                        Circle().fill(active ? themeManager.accentBright : .clear).frame(width: 4, height: 4)
                    }
                    .foregroundColor(active ? themeManager.accentBright : themeManager.tertiaryText)
                    .frame(maxWidth: .infinity)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#0A1124").opacity(0.74)).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(themeManager.strokeColor, lineWidth: 1))
        .shadow(color: themeManager.cardShadowElevated, radius: 18, x: 0, y: 14)
        .padding(.horizontal, 18).padding(.bottom, 30)
    }
}
```

**Step 2: Integrate in `MainTabView`** — keep `TabView` for content/state; hide the native bar and overlay `SpTabBar` when Sapphire is active:
```swift
var body: some View {
    TabView(selection: $selectedTab) { /* unchanged tabs */ }
        .tint(themeManager.accentColor)
        .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
        .overlay(alignment: .bottom) {
            if themeManager.isSapphire { SpTabBar(selection: $selectedTab) }
        }
        // … existing .onReceive handlers unchanged …
}
```
Also: when Sapphire, each tab root must add bottom content padding (~110pt) so content clears the floating bar — handled per-screen in Phase 1–3 (and for the recolored Progress tab).

**Step 3: Verify (simulator)** — Sapphire active: floating bar shows, switches tabs, native bar hidden. Toggle to Warm in Settings: native bar returns, no floating bar. **Step 4: Commit** (stage): `SpTabBar.swift`, `MainTabView.swift`.

---

### Task 0.8: Settings picker — Sapphire tile + preview swatch

**Files:**
- Modify: `AlBayan/Views/SettingsView.swift` (`ThemePickerTile` `previewBackground`/`previewPurpleGradient`/`previewAccentGradient` switches, ~738-781)

Add `.royalSapphire` to each preview switch so the tile renders a dark navy swatch with gold + azure dots:
```swift
private var previewBackground: Color {
    switch variant {
    case .warmInviting: return Color(red: 0.973, green: 0.961, blue: 1.0)
    case .rosewater:    return Color(red: 0.992, green: 0.953, blue: 0.949)
    case .royalSapphire: return Color(hex: "#0A1124")
    }
}
private var previewPurpleGradient: LinearGradient {   // gold dot
    switch variant {
    // … existing …
    case .royalSapphire:
        return LinearGradient(colors: [Color(hex: "#F2E2A8"), Color(hex: "#B5963F")],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
private var previewAccentGradient: LinearGradient {   // azure dot
    switch variant {
    // … existing …
    case .royalSapphire:
        return LinearGradient(colors: [Color(hex: "#5B9BE0"), Color(hex: "#3F7BC0")],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
```

**Step 2: Verify (simulator)** — Settings shows three tiles; the Royal Sapphire tile has a dark swatch; tapping it flips the whole app to dark (status bar, etc.) with an animated transition. **Step 3: Commit** (stage): `SettingsView.swift`.

> **Checkpoint:** After 0.8 the app builds, runs, defaults to Sapphire (fresh install), shows the floating tab bar and dark chrome, and is selectable in Settings — even though the per-screen Sapphire layouts aren't built yet (tabs still show the warm screens on the navy background until Phase 1–3). Confirm a full **Verify (simulator)** pass here.

---

### Task 0.9: Recolor the Progress tab for dark (keep Apple-style)

**Files:**
- Modify: `AlBayan/Views/ProgressRingsView.swift`

**Step 1:** Audit for hardcoded light-only colors (`Color.white`, `Color.black`, fixed grays) and route them through `themeManager` tokens so the Apple-style rings read correctly on navy. Background → `themeManager.backgroundLayer`; cards → `cardBackground` + `strokeColor`; text → `primaryText`/`secondaryText`; ring tracks → `strokeColor`; keep ring *progress* colors (or map to `goldGradient`/`semanticAzure` if you want them on-theme — keep Apple-style structure either way). Add ~110pt bottom padding so content clears the floating bar.

**Step 2: Verify (simulator)** — Progress tab under Sapphire: rings + stats legible on navy, no white boxes; under Warm: unchanged. **Step 3: Commit** (stage): `ProgressRingsView.swift`.

---

## Phase 1 — Core read path

> Pattern for every Sapphire screen: create `AlBayan/Views/Sapphire/Sapphire<Name>View.swift`, compose from `Sp*` + `SapphireFont` + tokens, wire the **same** managers the warm view uses, then branch the router (the tab wrapper or the pushed-detail call site) on `themeManager.isSapphire`. Geometry/colors come from `README.md` §Screens and `sapphire.jsx` `SC0n_*`. Each screen ends with **Verify (simulator)** against the matching frame in `Royal Sapphire.html`, plus a parity check that every action of the warm view exists.

### Task 1.1: `SapphireHomeView` (Handoff 01)

**Files:**
- Create: `AlBayan/Views/Sapphire/SapphireHomeView.swift`
- Modify: `AlBayan/Views/Tabs/HomeTab.swift` (branch: `if themeManager.isSapphire { SapphireHomeView() } else { HomeView() }`)

**Build (compose, per README §01):**
- `SpShell` wrapping a `ScrollView` (bottom padding 110).
- Fixed greeting row: avatar circle (1pt gold stroke, `goldChipFill`, "ع" in `accentBright` via `SapphireFont.arabic(20)`) + "Assalāmu ʿalaykum" (`tertiaryText` 11) over user name (14/600); right = streak pill (`flame.fill` + count, `strokeColor` border) + bell button (36 circle).
- `SpHeading(eyebrow: "The Noble Qur'an", title: "Read & Reflect")`.
- Continue-Reading `SpCard(glow: true)`: eyebrow "Continue Reading", surah name `SapphireFont.headline(27)`, "Verse x of y · z% complete" (`secondaryText`), 4pt gold progress track, small `SpGoldCTA(small: true, systemIcon: "play.fill", title: "Resume")`, faint Arabic numeral watermark (Amiri 96, `accentColor.opacity(0.08)`) top-right.
- Search field: `SpCard`-like rounded-14, `magnifyingglass` in gold + placeholder (`tertiaryText`). Wire to existing Home search.
- `SpDivider(label: "114 Surahs")`.
- Surah list (existing surah array from `DataManager`): row = `SpNumeral(n:, size: 42)` + English name (16/600) + transliteration (`tertiaryText` 12) + meta "n verses · Meccan/Medinan · p%" (% in gold) + Arabic surah name right-aligned (`SapphireFont.arabic(24)`, `accentBright`). Tap → push Surah Detail (Task 1.2 / branch).

**Wire:** reuse `HomeView`'s managers (DataManager, ProgressManager, ReadingStreak, navigation to surah). Preserve verse deep-link entry (`.navigateToVerse` routes here).

**Verify (simulator)** vs HTML frame 01 + parity check. **Commit** (stage): `SapphireHomeView.swift`, `HomeTab.swift`.

### Task 1.2: `SapphireSurahDetailView` (Handoff 02)

**Files:**
- Create: `AlBayan/Views/Sapphire/SapphireSurahDetailView.swift`
- Modify: the push site (in `SapphireHomeView` and anywhere Surah Detail is presented) to branch on `isSapphire`.

**Build (per README §02):** top bar (back 38-circle, "EN" globe language pill, bookmark); surah header `SpCard(glow)` centered (Arabic name `SapphireFont.arabic(40)` `accentBright`, italic English `SapphireFont.serif(19, semibold:false, italic:true)` `secondaryText`, centered `SpDivider()` diamond, meta row, `SpGoldCTA("Play Recitation", systemIcon:"play.fill")` + 46 brain/quiz `SpIconChip`); section row "Verses" / "p% read"; verse cards (gap 12): `SpNumeral(size:30)` + 3 action chips (play, bookmark fill-when-saved, sparkles/gems) + Arabic verse (`SapphireFont.arabicVerse(27)`, RTL, trailing-aligned, lineSpacing for 1.9) + English (`SapphireFont.body(17)` `secondaryText`) + `SpDivider(label:"5-Layer Tafsir")`.

**Wire:** `DataManager`/`TafsirReader` verses, `AudioManager` play/pause per verse + surah, `BookmarkManager` bookmark toggle, `CommentaryLanguageManager` EN/UR/AR, gems → Quick Gems sheet (Phase 2), tafsir → Commentary cover (Phase 2). Honor the reading text-size setting.

**Verify (simulator)** vs HTML frame 02 + parity (audio, bookmark, language, gems, tafsir all reachable). **Commit** (stage): both files.

---

## Phase 2 — Insight path

> Same pattern. Detail per README §06/§08/§09 + `SC06/SC08/SC09`.

### Task 2.1: Quick Gems (Handoff 06) — modal sheet
- Create `AlBayan/Views/Sapphire/SapphireQuickGemsView.swift`; branch the gems-sheet presentation. Grabber; header (active gem `SpIconChip(active:true)` + "Quick Gems" `headline(26)` + sub); verse `SpCard(glow)` centered with Arabic (`arabicVerse(30)`) + highlighted keyword in `accentBright` + gem chips (pills; active = gold border + `goldChipFill` + `accentBright`); pinned bottom insight sheet (`secondaryBackground`/bg2, top radius 26, top hairline): "The Core Insight" + serif paragraph, "Why It Matters" + body, `SpGoldCTA("Read Full Tafsir")`. Long verses: keep verse visible, let insight sheet scroll. Wire existing gems/tafsir source. **Verify + Commit.**

### Task 2.2: Commentary 5-layer (Handoff 08) — full-screen cover
- Create `SapphireFullScreenCommentaryView.swift`; branch the cover presentation. Top bar (×, centered "Commentary" + "Surah · Verse n", EN pill); horizontal layer selector (92pt cards: Foundation/Classical/Modern/Ahl al-Bayt/Comparative; active = `goldGradient` + `onAccentText` + gold shadow, others `cardBackground`+`strokeColor`); active-layer header (`SpIconChip` + name `headline(24)` + desc); `SpDivider(label:"Section 1 of N")`; body serif `body(20)` lineSpacing for 1.55, inline emphasis italic `accentBright`. Wire `TafsirReader` 5 layers + `CommentaryLanguageManager`. **Verify + Commit.**

### Task 2.3: Quiz intro (Handoff 09) — cover
- Create `SapphireQuizView.swift` (intro state only; branch presentation). Top bar (× + eyebrow "Test Your Knowledge"); centered 120pt rounded-36 hero tile (`accentColor` border, `goldChipFill`, `brain` in `accentBright`) + radial gold glow; title `serif(38)` + Arabic surah `arabic(26)` `accentColor`; stats `SpCard` with 3 hairline-separated columns (icon + `numeral(26)` figure + `tertiaryText` label): Questions / Minutes / Ḥasanāt; pinned `SpGoldCTA("Begin Quiz")`. Wire `QuizManager`. Quiz *in-progress/results* keep existing views (recolor only if needed). **Verify + Commit.**

---

## Phase 3 — Discovery / journey

### Task 3.1: Life Moments (Handoff 05)
- Create `SapphireLifeMomentsView.swift`; branch. Back pill; `SpHeading(eyebrow:"Guidance", title:"Life Moments", sub:…)`; search field; cards = `SpIconChip` + serif title (22) + gold meta "Qur'an 2:155" + chevron. Wire `LifeMomentsManager`. **Verify + Commit.**

### Task 3.2: Questions & Answers (Handoff 07)
- Create `SapphireQuestionsView.swift`; branch. Back pill; `SpHeading` (title wraps two lines); category pills (selected = `goldGradient`+`onAccentText`, others `cardBackground`+`strokeColor`); `SpDivider(label:)`; question cards = `SpIconChip` + serif question (21, lineSpacing 1.25) + meta row with azure "✓ n verses" badge (`semanticAzureChip`/`semanticAzure`) + refs (`tertiaryText`) + chevron. Wire `QuestionsManager`. **Verify + Commit.**

### Task 3.3: Seasons / Ramadan (Handoff 04)
- Create `SapphireRamadanJourneyView.swift` (and reuse for Muharram/Hajj variants, or branch within their views); branch the Journey-hub routing. Header row eyebrow "30-Day Journey" + title + 56 `SpIconChip(moon.stars)`; progress `SpCard(glow)` ("n days until…", "x of 30 days", big "p%" `serif(30)` `accentBright`, 5pt gold track); `SpDivider(label:"The Path")`; day list: done = gold-gradient filled circle + `onAccentText` check; current = `strokeColor` border + `goldChipFill` + `SpNumeral`; upcoming = `SpNumeral` + standard `SpCard`; each row theme name `headline(21)` + Arabic theme word (`arabic(19)` `accentColor`) right-aligned. Wire `RamadanJourneyManager`/`MuharramJourneyManager`/`HajjJourneyManager`. **Verify + Commit.**

---

## Final verification

1. **Full Sapphire sweep (simulator):** visit Today, Quran→Surah→Verse→(Gems, Commentary), Quiz intro, Explore→(Life Moments, Q&A), Progress, Journey→Season. Compare each against `Royal Sapphire.html`. Confirm: navy gradient + gold glow everywhere, gilt cards, gold CTAs, serif titles, Amiri Arabic RTL, floating tab bar, dark status bar/keyboard, no stray white surfaces, content clears the tab bar.
2. **Light-theme regression:** switch to Warm and Rosewater in Settings — every screen looks exactly as before; native tab bar returns; light status bar.
3. **Default:** delete app from sim, reinstall → launches in Royal Sapphire. Existing-user upgrade (pre-set theme) keeps their choice.
4. **Parity:** every action (audio, bookmarks, language toggle, search, deep links, quiz, journeys) works under Sapphire.

**Definition of done:** all phases committed (by the author), final verification passes, design matches the handoff frames within the agreed fidelity, light themes unchanged.

---

## Notes & decisions carried from design

- Keep the app's **5-tab IA** (not the handoff's 4 tabs).
- **Progress** stays Apple-style (recolor only).
- Icons via **SF Symbols**; emoji dropped on Sapphire screens.
- **No auto-commit**; stage + pause for author. Execution: implementer + spec review only (no code-quality reviewer).
- Per-screen pixel detail is intentionally referenced to the handoff (DRY) rather than re-transcribed; the `Sp*` library + tokens carry the exactness.
