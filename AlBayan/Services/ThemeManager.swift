//
//  ThemeManager.swift
//  AlBayan
//
//  Theme state + palette resolver. Views consume colors/gradients exclusively
//  through `ThemeManager.shared.<getter>`, so adding a new theme only requires
//  a new `ThemeVariant` case + its color mapping here.
//

import SwiftUI

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

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private static let storageKey = "selectedTheme"

    @Published var selectedTheme: ThemeVariant {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.storageKey)
        }
    }

    var isDarkMode: Bool { selectedTheme == .royalSapphire }
    var isSapphire: Bool { selectedTheme == .royalSapphire }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let stored = ThemeVariant(rawValue: raw) {
            self.selectedTheme = stored
        } else {
            self.selectedTheme = .royalSapphire
        }
    }

    func setTheme(_ theme: ThemeVariant) {
        selectedTheme = theme
    }

    // MARK: - Color Scheme

    var colorScheme: ColorScheme { selectedTheme == .royalSapphire ? .dark : .light }

    /// Whether this theme uses the "warm" visual layout (rounded pill buttons, card-muted back chip,
    /// SF Pro Rounded type scale, centered hero card with large Arabic title).
    /// Both `warmInviting` and `rosewater` share this structure; only their color tokens differ.
    var useWarmLayout: Bool {
        switch selectedTheme {
        case .warmInviting, .rosewater: return true
        case .royalSapphire:            return false
        }
    }

    // MARK: - Backgrounds

    var primaryBackground: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.973, green: 0.961, blue: 1.0)   // #F8F5FF Soft Lavender
        case .rosewater:
            return Color(red: 0.992, green: 0.953, blue: 0.949) // #FDF3F2 Blush
        case .royalSapphire:
            return Color(hex: "#0A1124")
        }
    }

    var secondaryBackground: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.987, green: 0.969, blue: 0.980) // #FBF8FA
        case .rosewater:
            return Color(red: 1.000, green: 0.988, blue: 0.988) // #FFFCFC warm-tinted white
        case .royalSapphire:
            return Color(hex: "#070C1C")
        }
    }

    var tertiaryBackground: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 1.0, green: 0.976, blue: 0.961)   // #FFF9F5 Warm White
        case .rosewater:
            return Color(red: 0.969, green: 0.902, blue: 0.894) // #F7E6E4 card-muted
        case .royalSapphire:
            return Color(hex: "#101E40")
        }
    }

    // MARK: - Text

    var primaryText: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.176, green: 0.145, blue: 0.125) // #2D2520
        case .rosewater:
            return Color(red: 0.227, green: 0.165, blue: 0.165) // #3A2A2A
        case .royalSapphire:
            return Color(hex: "#EAEFFB")
        }
    }

    var secondaryText: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.42, green: 0.365, blue: 0.329)  // #6B5D54
        case .rosewater:
            return Color(red: 0.486, green: 0.369, blue: 0.361) // #7C5E5C
        case .royalSapphire:
            return Color(hex: "#EAEFFB").opacity(0.92)  // lifted from 0.62 for legibility on dark navy
        }
    }

    var tertiaryText: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.69, green: 0.64, blue: 0.6)     // #B0A399
        case .rosewater:
            return Color(red: 0.761, green: 0.663, blue: 0.655) // #C2A9A7
        case .royalSapphire:
            return Color(hex: "#EAEFFB").opacity(0.74)  // lifted from 0.40 for legibility on dark navy
        }
    }

    /// Card surface (pure white in Warm, warm-tinted white in Rosewater).
    var cardBackground: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color.white
        case .rosewater:
            return Color(red: 1.000, green: 0.988, blue: 0.988) // #FFFCFC
        case .royalSapphire:
            return Color.white.opacity(0.05)
        }
    }

    // MARK: - Accents

    /// Primary accent color (text-safe). Peaceful purple (Warm) / Dusty Rose purple (Rosewater).
    var accentColor: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.608, green: 0.561, blue: 0.749) // #9B8FBF
        case .rosewater:
            return Color(red: 0.663, green: 0.549, blue: 0.710) // #A98CB5
        case .royalSapphire:
            return Color(hex: "#D9C079")
        }
    }

    /// Deep variant of the primary accent (gradient endpoint / pressed states).
    var accentColorDark: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.545, green: 0.498, blue: 0.659) // #8B7FA8
        case .rosewater:
            return Color(red: 0.576, green: 0.471, blue: 0.631) // #9378A1
        case .royalSapphire:
            return Color(hex: "#B5963F")
        }
    }

    /// Secondary accent color. Sunset orange (Warm) / Rose clay (Rosewater).
    var accentSecondary: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.91, green: 0.604, blue: 0.435)  // #E89A6F
        case .rosewater:
            return Color(red: 0.847, green: 0.514, blue: 0.502) // #D88380
        case .royalSapphire:
            return Color(hex: "#5B9BE0")
        }
    }

    /// Deep variant of the secondary accent.
    var accentSecondaryDark: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.847, green: 0.541, blue: 0.373) // #D88A5F
        case .rosewater:
            return Color(red: 0.749, green: 0.420, blue: 0.408) // #BF6B68
        case .royalSapphire:
            return Color(hex: "#3F7BC0")
        }
    }

    // MARK: - Premium-art surface tokens
    // Always-dark art surfaces (Today hero, reader, glass over art). Not theme-switched:
    // these render only on the flagship dark theme or on always-dark surfaces.

    /// Near-black navy base under Today hero art (matches Sapphire bg2).
    var heroBase: Color { Color(hex: "#070C1C") }

    /// Darkest navy; immersive reader threshold background.
    var thresholdBase: Color { Color(hex: "#040918") }

    /// Dark glass fill (~0.45 alpha) for cards laid over bright cover art.
    var cardBacking: Color { Color(hex: "#0A1124").opacity(0.45) }

    /// Primary accent gradient (purple family).
    var purpleGradient: LinearGradient {
        switch selectedTheme {
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.608, green: 0.561, blue: 0.749), // #9B8FBF
                    Color(red: 0.545, green: 0.498, blue: 0.659)  // #8B7FA8
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.663, green: 0.549, blue: 0.710), // #A98CB5
                    Color(red: 0.576, green: 0.471, blue: 0.631)  // #9378A1
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .royalSapphire:
            return goldGradient
        }
    }

    /// Secondary accent gradient (orange family in Warm / rose-clay in Rosewater).
    var accentGradient: LinearGradient {
        switch selectedTheme {
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.604, blue: 0.435),  // #E89A6F
                    Color(red: 0.847, green: 0.541, blue: 0.373)  // #D88A5F
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.847, green: 0.514, blue: 0.502), // #D88380 rose clay
                    Color(red: 0.749, green: 0.420, blue: 0.408)  // #BF6B68
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .royalSapphire:
            return goldGradient
        }
    }

    /// Premium hero gradient for the Today "reminder" card. A deeper start plus a
    /// hue-shifted rose endpoint give real value contrast and a duotone richness
    /// that the flatter `purpleGradient` lacks. White text stays legible across it.
    var reminderGradient: LinearGradient {
        switch selectedTheme {
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.322, green: 0.255, blue: 0.569), // #524191 deep violet
                    Color(red: 0.627, green: 0.424, blue: 0.573)  // #A06C92 orchid-rose
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.361, green: 0.239, blue: 0.439), // #5C3D70 royal plum
                    Color(red: 0.659, green: 0.373, blue: 0.486)  // #A85F7C rose-mauve
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .royalSapphire:
            return LinearGradient(
                colors: [Color(hex: "#101E40"), Color(hex: "#070C1C")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Material / Stroke

    /// Card-surface fill used in `.fill(themeManager.glassEffect)` call sites.
    /// Was `.ultraThin` Material, which renders as generic grayish translucency and fights
    /// the theme's primaryBackground (produced a visible gray strip when used on headers).
    /// The Warm/Rosewater design handoffs both specify solid card surfaces, so this returns
    /// a solid, theme-tinted card color.
    var glassEffect: Color { cardBackground }

    var strokeColor: Color {
        switch selectedTheme {
        case .warmInviting:
            return Color(red: 0.176, green: 0.145, blue: 0.125).opacity(0.1)
        case .rosewater:
            return Color(red: 120/255, green: 60/255, blue: 60/255).opacity(0.10)
        case .royalSapphire:
            return Color(hex: "#D9C079").opacity(0.18)
        }
    }

    var floatingOrbColors: [Color] {
        switch selectedTheme {
        case .warmInviting:
            return [
                Color(red: 0.608, green: 0.561, blue: 0.749).opacity(0.06),
                Color(red: 0.91,  green: 0.604, blue: 0.435).opacity(0.05),
                Color(red: 0.498, green: 0.722, blue: 0.604).opacity(0.04)
            ]
        case .rosewater:
            return [
                Color(red: 0.663, green: 0.549, blue: 0.710).opacity(0.06), // dusty rose purple
                Color(red: 0.847, green: 0.514, blue: 0.502).opacity(0.05), // rose clay
                Color(red: 0.624, green: 0.725, blue: 0.596).opacity(0.04)  // sage
            ]
        case .royalSapphire:
            return [
                Color(hex: "#D9C079").opacity(0.10),
                Color(hex: "#5B9BE0").opacity(0.07),
                Color(hex: "#F2E2A8").opacity(0.06)
            ]
        }
    }

    // MARK: - Royal Sapphire premium tokens

    var goldGradient: LinearGradient {
        switch selectedTheme {
        case .royalSapphire:
            return LinearGradient(
                colors: [Color(hex: "#F2E2A8"), Color(hex: "#B5963F")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.604, blue: 0.435),
                    Color(red: 0.847, green: 0.541, blue: 0.373)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.847, green: 0.514, blue: 0.502),
                    Color(red: 0.749, green: 0.420, blue: 0.408)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var accentBright: Color { selectedTheme == .royalSapphire ? Color(hex: "#F2E2A8") : accentColor }
    var cardElevated: Color { selectedTheme == .royalSapphire ? Color.white.opacity(0.075) : cardBackground }
    var strokeSoft: Color { selectedTheme == .royalSapphire ? Color(hex: "#D9C079").opacity(0.10) : strokeColor }
    var goldChipFill: Color { selectedTheme == .royalSapphire ? Color(hex: "#D9C079").opacity(0.15) : accentColor.opacity(0.12) }
    var semanticAzure: Color { selectedTheme == .royalSapphire ? Color(hex: "#5B9BE0") : accentSecondary }
    var semanticAzureChip: Color { selectedTheme == .royalSapphire ? Color(hex: "#5B9BE0").opacity(0.18) : accentSecondary.opacity(0.15) }
    var onAccentText: Color { selectedTheme == .royalSapphire ? Color(hex: "#1B1606") : .white }
    var cardShadow: Color { Color(hex: "#040918").opacity(selectedTheme == .royalSapphire ? 0.35 : 0.06) }
    var cardShadowElevated: Color { Color(hex: "#040918").opacity(selectedTheme == .royalSapphire ? 0.55 : 0.10) }
    var goldButtonShadow: Color { Color(hex: "#D9C079").opacity(selectedTheme == .royalSapphire ? 0.24 : 0.0) }

    /// Full-bleed background: radial navy gradient + soft gold top glow (Sapphire), else flat primaryBackground.
    @ViewBuilder var backgroundLayer: some View {
        if selectedTheme == .royalSapphire {
            ZStack {
                Color(hex: "#0A1124")
                RadialGradient(
                    colors: [Color(hex: "#101E40"), Color(hex: "#0A1124"), Color(hex: "#070C1C")],
                    center: .top, startRadius: 0, endRadius: 700
                )
                RadialGradient(
                    colors: [Color(hex: "#D9C079").opacity(0.14), .clear],
                    center: UnitPoint(x: 0.5, y: -0.02), startRadius: 0, endRadius: 240
                )
                .frame(height: 320).allowsHitTesting(false)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea()
        } else {
            primaryBackground.ignoresSafeArea()
        }
    }
}
