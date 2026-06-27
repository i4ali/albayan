//
//  TodayTab.swift
//  AlBayan
//
//  NavigationStack wrapper for TodayView.
//

import SwiftUI

struct TodayTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveModernBackground()
                TodayView()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    TodayTab()
}
