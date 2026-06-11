//
//  ExploreSectionHeader.swift
//  AlBayan
//
//  Section header component for Explore tab
//

import SwiftUI

struct ExploreSectionHeader: View {
    let title: String

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Text(title.uppercased())
            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 13, weight: .semibold))
            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
            .tracking(themeManager.isSapphire ? 2.5 : 0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        ExploreSectionHeader(title: "Life & Guidance")
        ExploreSectionHeader(title: "Stories & Figures")
    }
}
