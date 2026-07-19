//
//  PremiumBadgeView.swift
//  AlBayan
//
//  Premium indicator chip (premium-art-sunni: "PREMIUM chip - accent capsule, never a lock").
//  An accent-tinted capsule reading PREMIUM, no lock glyph. Theme-aware (uses the accent color).
//

import SwiftUI

struct PremiumBadgeView: View {
    @StateObject private var themeManager = ThemeManager.shared

    var size: BadgeSize = .medium

    var body: some View {
        Text("PREMIUM")
            .font(.system(size: textSize, weight: .heavy))
            .tracking(1.2)
            .foregroundColor(themeManager.accentColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(themeManager.accentColor.opacity(0.14))
                    .overlay(Capsule().stroke(themeManager.accentColor.opacity(0.42), lineWidth: 1))
            )
    }

    // MARK: - Size Configuration

    enum BadgeSize {
        case small, medium, large
    }

    private var textSize: CGFloat {
        switch size {
        case .small: return 9
        case .medium: return 10.5
        case .large: return 12
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 5
        case .large: return 6
        }
    }
}

// MARK: - Variant with Custom Text (e.g. "Unlock Commentary")

struct PremiumBadgeWithText: View {
    @StateObject private var themeManager = ThemeManager.shared

    let text: String
    let size: PremiumBadgeView.BadgeSize

    init(text: String = "Unlock", size: PremiumBadgeView.BadgeSize = .medium) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: textSize, weight: .heavy))
            .tracking(1.0)
            .foregroundColor(themeManager.accentColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(themeManager.accentColor.opacity(0.14))
                    .overlay(Capsule().stroke(themeManager.accentColor.opacity(0.42), lineWidth: 1))
            )
    }

    private var textSize: CGFloat {
        switch size {
        case .small: return 9
        case .medium: return 10.5
        case .large: return 12
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 5
        case .large: return 6
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PremiumBadgeView(size: .small)
        PremiumBadgeView(size: .medium)
        PremiumBadgeView(size: .large)

        PremiumBadgeWithText(text: "Unlock Commentary", size: .large)
    }
    .padding()
    .background(Color.black)
}
