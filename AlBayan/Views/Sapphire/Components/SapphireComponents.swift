//
//  SapphireComponents.swift
//  AlBayan
//
//  Royal Sapphire component library (Sp* prefix).
//  All color and typography tokens come exclusively from ThemeManager / SapphireFont —
//  no hardcoded hex values here.
//

import SwiftUI

// MARK: - SpShell

/// Page wrapper: navy gradient + gold glow behind content.
struct SpShell<Content: View>: View {
    @StateObject private var themeManager = ThemeManager.shared
    @ViewBuilder var content: Content
    var body: some View {
        ZStack { themeManager.backgroundLayer; content }
    }
}

// MARK: - SpHeading

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
            if let sub {
                Text(sub).font(.system(size: 13.5))
                    .foregroundColor(themeManager.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: center ? .center : .leading)
    }
}

// MARK: - SpCard

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

// MARK: - SpNumeral

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

// MARK: - SpGoldCTA

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

// MARK: - SpDivider

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

// MARK: - SpIconChip

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
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(active ? AnyShapeStyle(themeManager.goldGradient) : AnyShapeStyle(themeManager.goldChipFill))
            )
            .overlay(
                active ? nil : RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1)
            )
    }
}

// MARK: - SpPressStyle

/// Subtle press feedback (scale + opacity), consistent across Sapphire.
struct SpPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ThemeManager.shared.backgroundLayer
        VStack(spacing: 18) {
            SpHeading(eyebrow: "The Noble Qur'an", title: "Read & Reflect")
            SpCard(glow: true) { Text("Card").padding(40) }
            HStack { SpNumeral(n: "1", size: 46); SpIconChip(systemIcon: "play.fill"); SpIconChip(systemIcon: "star.fill", active: true) }
            SpGoldCTA(title: "Begin Quiz", systemIcon: "brain") {}
            SpDivider(label: "114 Surahs")
        }.padding()
    }
}
