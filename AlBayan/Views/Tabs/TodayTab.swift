//
//  TodayTab.swift
//  AlBayan
//
//  NavigationView wrapper for TodayView.
//

import SwiftUI

struct TodayTab: View {
    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveModernBackground()
                TodayView()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    TodayTab()
}
