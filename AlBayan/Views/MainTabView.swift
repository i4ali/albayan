//
//  MainTabView.swift
//  AlBayan
//
//  Main TabView container with Home, Explore, Progress, and a permanent Journeys hub tab
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tabItem {
                    Label {
                        Text("Home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(0)

            ExploreTab()
                .tabItem {
                    Label {
                        Text("Explore")
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                }
                .tag(1)

            ProgressTab()
                .tabItem {
                    Label {
                        Text("Progress")
                    } icon: {
                        Image(systemName: "chart.pie.fill")
                    }
                }
                .tag(2)

            // Permanent Journeys hub (lists every journey with live Hijri status).
            JourneyHubView()
                .tabItem {
                    Label {
                        Text("Journeys")
                    } icon: {
                        Image(systemName: "map.fill")
                    }
                }
                .tag(3)
        }
        .tint(themeManager.accentColor)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToJourney)) { note in
            guard let journeyId = note.userInfo?["journey"] as? String else { return }
            DeepLinkRouter.shared.pendingJourneyId = journeyId
            selectedTab = 3
        }
    }
}

#Preview {
    MainTabView()
}
