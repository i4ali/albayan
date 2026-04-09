# Modern Light Theme UI Style Guide — AlBayan App

## Overview

This document ensures UI consistency for the "Modern Light" theme across all screens.

**Theme Philosophy:** Refined minimalist light — serenity through breathable white space. Cool-neutral off-white backgrounds, pure white floating cards, a single muted-blue accent, and soft multi-pastel ambience. Modern Light is the clarity-first counterpart to `modernDark` and sits alongside `warmInviting` as a second light option with a distinctly less-warm, more-minimalist personality.

---

## 1. Color Palette

### Backgrounds
| Purpose | Hex | RGB | Usage |
|---------|-----|-----|-------|
| Primary Background | `#F8F9FB` | `(0.973, 0.976, 0.984)` | Main screen backgrounds |
| Secondary Background | `#FFFFFF` | `(1.0, 1.0, 1.0)` | Cards, sections |
| Tertiary Background | `#F1F3F7` | `(0.945, 0.953, 0.969)` | Accent areas, dividers |
| Card White | `#FFFFFF` | `(1.0, 1.0, 1.0)` | Card surfaces |

### Text Colors
| Purpose | Hex | RGB | Usage |
|---------|-----|-----|-------|
| Primary Text | `#1A1A1A` | `(0.102, 0.102, 0.102)` | Headings, body text |
| Secondary Text | `#757575` | `(0.459, 0.459, 0.459)` | Subtitles, metadata |
| Tertiary Text | `#A8A8A8` | `(0.659, 0.659, 0.659)` | Captions, hints |

### Primary Accent
| Purpose | Hex | RGB | Usage |
|---------|-----|-----|-------|
| Muted Blue | `#90BCE1` | `(0.565, 0.737, 0.882)` | Primary accent, buttons, selection |
| Deep Muted Blue | `#6FA3CE` | `(0.435, 0.639, 0.808)` | Gradient end, button shadow tint |

### Supporting Pastels — Ambient + Category Use
These pastels appear as (a) `floatingOrbColors` background ambience in Modern Light, AND (b) category-specific colors for progress rings, stat card icons, and ring legend across ALL themes. They are NOT used as primary buttons, selected states, or interactive accents — muted blue owns those roles.

| Purpose | Hex | RGB | Ambient Opacity | Category Mapping |
|---------|-----|-----|-----------------|------------------|
| Sage Green | `#89C9B4` | `(0.537, 0.788, 0.706)` | `0.08` | **Quran** (reading progress) |
| Dusty Rose | `#D995A1` | `(0.851, 0.584, 0.631)` | `0.06` | **Surahs** (completion progress) |
| Muted Blue | `#90BCE1` | `(0.565, 0.737, 0.882)` | n/a (primary accent) | **Quizzes** (quiz progress) |
| Soft Amber | `#EBC078` | `(0.922, 0.753, 0.471)` | `0.07` | **Ramadan** (seasonal progress) |

**Deeper companions (for gradient ends):**

| Pastel | Deeper Hex | Used For |
|--------|------------|----------|
| Sage | `#6FB89E` | Quran ring gradient end |
| Rose | `#C87A89` | Surah ring gradient end |
| Muted Blue | `#6FA3CE` | Quiz ring gradient end + primary accent gradient end |
| Amber | `#D9A85C` | Ramadan ring gradient end |

### Gradients

```swift
// Muted blue gradient (primary buttons, highlights, surah number badges)
LinearGradient(
    colors: [
        Color(red: 0.565, green: 0.737, blue: 0.882),  // #90BCE1
        Color(red: 0.435, green: 0.639, blue: 0.808)   // #6FA3CE
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Stroke
```swift
Color(red: 0.102, green: 0.102, blue: 0.102).opacity(0.08)  // Charcoal hairline
```

---

## 2. Typography

**Font Family:** System with `.rounded` design (SF Pro Rounded) — identical to `warmInviting`

| Element | Size | Weight | Code |
|---------|------|--------|------|
| Large Title | 34pt | Bold | `.font(.system(size: 34, weight: .bold, design: .rounded))` |
| Headline | 20pt | SemiBold | `.font(.system(size: 20, weight: .semibold, design: .rounded))` |
| Subheadline | 18pt | Medium | `.font(.system(size: 18, weight: .medium, design: .rounded))` |
| Body | 17pt | Regular | `.font(.system(size: 17, weight: .regular, design: .rounded))` |
| Caption | 14pt | Medium | `.font(.system(size: 14, weight: .medium, design: .rounded))` |
| Small Caption | 12pt | Medium | `.font(.system(size: 12, weight: .medium, design: .rounded))` |
| Arabic | 24-32pt | Medium | `.font(.system(size: 28, weight: .medium))` |

### Using Font Extensions
```swift
Text("Title").font(.warmTitle())
Text("Body").font(.warmBody())
Text("Caption").font(.warmCaption())
```
(The `.warm*` font extensions are generic across themes despite the name.)

---

## 3. Spacing

Reuses the existing `WarmSpacing` enum unchanged:

```swift
enum WarmSpacing {
    static let tiny: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let regular: CGFloat = 16
    static let large: CGFloat = 20
    static let generous: CGFloat = 24    // Default padding
    static let extraGenerous: CGFloat = 28
    static let huge: CGFloat = 32
}
```

**Standard Usage:**
- Screen padding: 24pt (generous)
- Card internal padding: 16pt (regular)
- Section spacing: 20-24pt
- Element gaps: 8-12pt

---

## 4. Corner Radii

Reuses the existing `WarmRadius` enum unchanged:

```swift
enum WarmRadius {
    static let small: CGFloat = 12      // Buttons, small elements
    static let medium: CGFloat = 16     // Search bars, inputs
    static let large: CGFloat = 20      // Cards
    static let pill: CGFloat = 24       // Pill buttons
}
```

> **Note:** The source style guide ("Spiritual Companion") calls for 24-32pt card radii. Modern Light intentionally keeps the 20pt standard to preserve cross-theme component consistency. If you later decide to build a theme-aware radius variant, this is the place to update.

---

## 5. Shadows

**Softness directive:** "Very light, blurred" per the source style guide. Use feather-light opacity values.

### Card Shadow (default)
```swift
.shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
```

### Button Shadow (blue-tinted)
```swift
.shadow(
    color: Color(red: 0.565, green: 0.737, blue: 0.882).opacity(0.25),
    radius: 8,
    x: 0,
    y: 4
)
```

### Badge Shadow
```swift
.shadow(
    color: Color(red: 0.565, green: 0.737, blue: 0.882).opacity(0.3),
    radius: 8
)
```

### Stat Card Shadow (blue-tinted)
```swift
.shadow(
    color: Color(red: 0.565, green: 0.737, blue: 0.882).opacity(0.12),
    radius: 12,
    x: 0,
    y: 4
)
```

---

## 6. Component Patterns

### Standard Card
```swift
VStack {
    // Content
}
.padding(WarmSpacing.regular)
.background(Color.white)
.cornerRadius(WarmRadius.large)
.shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
```

### Primary Button
```swift
Button(action: {}) {
    Text("Action")
        .font(.warmBody())
        .foregroundColor(.white)
        .padding(.horizontal, WarmSpacing.generous)
        .padding(.vertical, WarmSpacing.medium)
}
.background(themeManager.accentGradient)   // Muted blue gradient
.cornerRadius(WarmRadius.pill)
.shadow(
    color: themeManager.accentColor.opacity(0.25),
    radius: 8,
    x: 0,
    y: 4
)
```

### Search Bar
```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundColor(themeManager.secondaryText)
    TextField("Search surahs...", text: $searchText)
}
.padding(WarmSpacing.regular)
.background(Color.white)
.cornerRadius(WarmRadius.medium)
.shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
```

### Section Header
```swift
Text("Section Title")
    .font(.warmHeadline())
    .foregroundColor(themeManager.primaryText)
```

### Progress Ring (single accent)
```swift
Circle()
    .trim(from: 0, to: progress)
    .stroke(themeManager.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .background(
        Circle()
            .stroke(themeManager.accentColor.opacity(0.15), lineWidth: 6)
    )
```

### Circular Badge
```swift
Circle()
    .fill(themeManager.accentGradient)
    .frame(width: 56, height: 56)
    .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8)
```

---

## 7. Navigation Bar (Glassmorphism)

```swift
.background(
    themeManager.glassEffect   // .ultraThin
)
```

Glassmorphism on Modern Light reads as a frosted layer over the off-white background with a 2pt-stroke minimalist icon set. Active tab icons use `themeManager.accentColor` (muted blue); inactive tabs use `themeManager.secondaryText` (medium grey).

---

## 8. Screen Structure Template

```swift
struct NewScreenView: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            themeManager.primaryBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: WarmSpacing.large) {
                    headerSection
                    contentSection
                }
                .padding(.horizontal, WarmSpacing.generous)
                .padding(.top, WarmSpacing.large)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: WarmSpacing.small) {
            Text("Screen Title")
                .font(.warmTitle())
                .foregroundColor(themeManager.primaryText)

            Text("Subtitle or description")
                .font(.warmSubheadline())
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

---

## 9. Animation Guidelines

Identical to existing themes:

- **Theme transitions:** `easeInOut`, 0.5s duration
- **Selection feedback:** Scale 1.02x, 0.2s duration
- **Haptic feedback:** Light impact on selections
- **Color transitions:** Always animate with theme changes

---

## 10. Differences from Other Themes

| Aspect | warmInviting | modernLight | modernDark |
|--------|-------------|-------------|------------|
| Primary BG | Soft lavender `#F8F5FF` | Off-white `#F8F9FB` | Dark slate `#0F172A` |
| Primary text | Warm charcoal `#2D2520` | True charcoal `#1A1A1A` | White |
| Primary accent | Peaceful purple `#9B8FBF` | Muted blue `#90BCE1` | Indigo `#6366F1` |
| Secondary accent | Sunset orange `#E89A6F` | — (ambient pastels only) | Pink `#EC4899` |
| Shadow opacity | `0.04` | `0.05` | (glass blur) |
| Text undertone | Brown-warm | Cool-neutral | Cool-dark |
| Overall feel | Lavender sanctuary | Breathable minimalism | Vibrant glassmorphism |

---

## 11. Pastel Usage Rules (IMPORTANT)

The supporting pastels (sage, rose, blue, amber) have **two legitimate roles**:

1. **Ambient background decoration** (Modern Light only) — via `floatingOrbColors` at 6–8% opacity. Subtle shimmer, never competing with content.
2. **Category indicators** (all themes) — progress rings, stat card icons, and ring legend dots tied to fixed content categories (Quran, Surahs, Quizzes, Ramadan). These live in `ProgressRingsStack.swift` and `ProgressRingsView.swift` and intentionally bypass `ThemeManager` so categories read consistently regardless of theme.

**Pastels must NOT be used as:**
- Primary call-to-action buttons (muted blue owns this)
- Selection highlights (muted blue)
- Navigation active states (muted blue)
- Text colors (charcoal + grey scale)
- Border colors on generic containers (use `strokeColor`)
- Shadow colors on non-category elements (use `accentColor` with opacity)

If a future screen needs a new category pastel (e.g. "Dua", "Hadith"), either extend the `ProgressRingsStack` category set or add a dedicated `categoryAccent(for:)` helper on `ThemeManager`. Do NOT hardcode new pastels in random view files.

---

## 12. Light-Theme-Specific Rendering Rules

Because Modern Light uses a pure off-white aesthetic, certain SwiftUI `Material` effects (`.ultraThin`, `.thin`) render as a dirty translucent overlay that reads darker than expected. Prefer **solid color fills** over Material for these elements on Modern Light:

- **Split buttons** (e.g. Gems / In-Depth in Surah Detail) — use `themeManager.secondaryBackground` + `strokeColor` border instead of `glassEffect`. Pattern:
  ```swift
  @ViewBuilder
  private var splitButtonBackground: some View {
      if themeManager.selectedTheme == .modernLight {
          RoundedRectangle(cornerRadius: 12)
              .fill(themeManager.secondaryBackground)
              .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.strokeColor, lineWidth: 1))
      } else {
          RoundedRectangle(cornerRadius: 12)
              .fill(themeManager.glassEffect)
              .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.strokeColor, lineWidth: 1))
      }
  }
  ```

- **Home header** — uses a flat background on both `warmInviting` and `modernLight`; skip the glass overlay entirely for light themes. See `HomeView.swift` lines ~89-110.

Navigation bar / tab bar still use `themeManager.glassEffect` because system chrome is drawn by UIKit which handles Material correctly in both modes.

## 13. Shadow Rules

**Never hardcode shadow colors.** Always derive from `themeManager.accentColor` (or the primary/secondary/tertiary text colors) with an opacity modifier. Hardcoded indigo shadows from the `modernDark` era (`Color(red: 0.39, green: 0.4, blue: 0.95)`) render as a purple halo on Modern Light — always use `themeManager.accentColor.opacity(0.3)` or similar instead.

## 14. Checklist for New Screens (Modern Light Mode)

- [ ] Use `themeManager.primaryBackground` for screen background
- [ ] Apply `.rounded` design to all fonts
- [ ] Use charcoal text (`themeManager.primaryText`), no pure black
- [ ] Cards have 20pt radius + `Color.black.opacity(0.05)` shadow
- [ ] Buttons use `themeManager.accentGradient` + pill radius + blue-tinted shadow
- [ ] Standard 24pt horizontal padding
- [ ] Consistent spacing using `WarmSpacing` enum
- [ ] Muted blue (`themeManager.accentColor`) for ALL primary actions and selection states
- [ ] Category pastels used only in `ProgressRings*` files, following the §1 mapping
- [ ] Split-button patterns use solid fill, not `glassEffect` (see §12)
- [ ] Shadow colors derived from `themeManager.accentColor`, never hardcoded (see §13)
- [ ] Navigation uses glassmorphism via `themeManager.glassEffect` (`.ultraThin`)
