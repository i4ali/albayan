//
//  MainTabView.swift
//  AlBayan
//
//  Main tab container: Today, Quran, Explore, Progress, and the Journey hub.
//
//  Sapphire renders a fully custom tab container (no native `TabView`), so there is
//  no native tab bar that a dismissed sheet / fullScreenCover could resurrect beneath
//  the floating `SpTabBar` - the "double tab bar" bug. Other themes use the native bar.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    /// Tabs visited at least once. Each tab's content is built lazily on first visit
    /// and then kept alive, so its NavigationStack path, scroll position, and view
    /// state survive tab switches - matching native `TabView` behaviour.
    @State private var loadedTabs: Set<Int> = [0]

    private let tabCount = 5

    var body: some View {
        container
            .tint(themeManager.accentColor)
            .onChange(of: selectedTab) { _, newValue in
                loadedTabs.insert(newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToJourney)) { note in
                guard let journeyId = note.userInfo?["journey"] as? String else { return }
                DeepLinkRouter.shared.pendingJourneyId = journeyId
                selectedTab = 4
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToVerse)) { _ in
                // Verse deep-links (Today reminder/resume, notification inbox) route into
                // the Quran tab, where HomeView performs the actual in-stack navigation.
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

    // MARK: - Container

    @ViewBuilder
    private var container: some View {
        if themeManager.isSapphire {
            // Custom container: the selected tab is the only interactive/visible layer,
            // and `SpTabBar` is the one and only tab bar on screen.
            ZStack(alignment: .bottom) {
                ZStack {
                    ForEach(0..<tabCount, id: \.self) { index in
                        if index == selectedTab || loadedTabs.contains(index) {
                            tabContent(index)
                                .opacity(index == selectedTab ? 1 : 0)
                                .allowsHitTesting(index == selectedTab)
                                .zIndex(index == selectedTab ? 1 : 0)
                        }
                    }
                }
                SpTabBar(selection: $selectedTab)
            }
        } else {
            TabView(selection: $selectedTab) {
                TodayTab()
                    .tabItem { Label { Text("Today") } icon: { Image(systemName: "sun.max") } }
                    .tag(0)

                HomeTab()
                    .tabItem { Label { Text("Quran") } icon: { Image(systemName: "book") } }
                    .tag(1)

                ExploreTab()
                    .tabItem { Label { Text("Explore") } icon: { Image(systemName: "sparkles") } }
                    .tag(2)

                ProgressTab()
                    .tabItem { Label { Text("Progress") } icon: { Image(systemName: "chart.bar.fill") } }
                    .tag(3)

                // Permanent Journey hub (lists every journey with live Hijri status).
                JourneyTab()
                    .tabItem { Label { Text("Journey") } icon: { Image(systemName: "map") } }
                    .tag(4)
            }
        }
    }

    @ViewBuilder
    private func tabContent(_ index: Int) -> some View {
        switch index {
        case 0: TodayTab()
        case 1: HomeTab()
        case 2: ExploreTab()
        case 3: ProgressTab()
        default: JourneyTab()
        }
    }
}

/// NavigationStack wrapper so JourneyHubView (which has no navigation container of its
/// own) participates in tab navigation the same way the other tabs do.
struct JourneyTab: View {
    var body: some View {
        NavigationStack {
            JourneyHubView()
                .navigationBarHidden(true)
        }
    }
}

#Preview {
    MainTabView()
}
