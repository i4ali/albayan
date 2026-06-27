//
//  ProgressTab.swift
//  AlBayan
//
//  NavigationStack wrapper for ProgressRingsView
//

import SwiftUI

struct ProgressTab: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveModernBackground()
                ProgressRingsView()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ProgressTab()
}
