//
//  MainTabView.swift
//  AlBayan
//
//  Main TabView container: Today, Quran, Explore, Progress, and the Journey hub.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayTab()
                .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label { Text("Today") } icon: { Image(systemName: "sun.max") }
                }
                .tag(0)

            HomeTab()
                .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label { Text("Quran") } icon: { Image(systemName: "book") }
                }
                .tag(1)

            ExploreTab()
                .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label { Text("Explore") } icon: { Image(systemName: "sparkles") }
                }
                .tag(2)

            ProgressTab()
                .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label { Text("Progress") } icon: { Image(systemName: "chart.bar.fill") }
                }
                .tag(3)

            // Permanent Journey hub (lists every journey with live Hijri status).
            JourneyHubView()
                .toolbar(themeManager.isSapphire ? .hidden : .visible, for: .tabBar)
                .tabItem {
                    Label { Text("Journey") } icon: { Image(systemName: "map") }
                }
                .tag(4)
        }
        .tint(themeManager.accentColor)
        .overlay(alignment: .bottom) {
            if themeManager.isSapphire {
                SpTabBar(selection: $selectedTab)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToJourney)) { note in
            guard let journeyId = note.userInfo?["journey"] as? String else { return }
            DeepLinkRouter.shared.pendingJourneyId = journeyId
            selectedTab = 4
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVerse)) { _ in
            // Verse deep-links (Today reminder/resume, notification inbox) route into the
            // Quran tab, where HomeView performs the actual in-stack navigation.
            selectedTab = 1
        }
        .onAppear {
            // Cold launch from a tapped notification: the .navigateToVerse post fired
            // before any view was subscribed, so route via the stashed deep link.
            if DeepLinkRouter.shared.pendingVerse != nil {
                selectedTab = 1
            }
        }
    }
}

#Preview {
    MainTabView()
}
