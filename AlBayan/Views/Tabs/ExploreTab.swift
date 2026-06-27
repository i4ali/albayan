//
//  ExploreTab.swift
//  AlBayan
//
//  NavigationStack wrapper for ExploreView
//

import SwiftUI

struct ExploreTab: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background with floating elements
                AdaptiveModernBackground()

                ExploreView()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ExploreTab()
}
