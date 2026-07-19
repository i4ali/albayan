//
//  OnboardingFlowView.swift
//  AlBayan
//
//  Story-driven onboarding flow coordinator
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var notificationsEnabled = false
    @State private var progressNotificationsEnabled = false

    private let totalPages = 14

    var body: some View {
        ZStack {
            // Background
            themeManager.primaryBackground
                .ignoresSafeArea()

            // Main content
            TabView(selection: $currentPage) {
                // Screen 1: Opening verse (47:24)
                OpeningVerseScreen(currentPage: $currentPage)
                    .tag(0)

                // Screen 2: Mission
                MissionScreen()
                    .tag(1)

                // Screen 3: Four Layers
                LayersScreen()
                    .tag(2)

                // Screen 4: Inside the Surah (immersive experiences showcase)
                InsideSurahScreen(currentPage: $currentPage, pageIndex: 3)
                    .tag(3)

                // Screen 5: Quick Gems
                QuickGemsScreen()
                    .tag(4)

                // Screen 6: Quiz Feature
                QuizFeatureScreen()
                    .tag(5)

                // Screen 7: Daily Challenge
                DailyChallengeScreen()
                    .tag(6)

                // Screen 8: Daily Crossword
                DailyCrosswordScreen()
                    .tag(7)

                // Screen 9: Seasonal Features (Ramadan Journey)
                SeasonalFeaturesScreen()
                    .tag(8)

                // Screen 10: Progress Tracking
                ProgressTrackingScreen()
                    .tag(9)

                // Screen 11: Daily Verse
                DailyVerseScreen(notificationsEnabled: $notificationsEnabled)
                    .tag(10)

                // Screen 12: Progress Notifications
                ProgressNotificationsScreen(progressNotificationsEnabled: $progressNotificationsEnabled)
                    .tag(11)

                // Screen 13: Profile setup (name + preferred language)
                ProfileSetupScreen(currentPage: $currentPage)
                    .tag(12)

                // Screen 14: Final Setup
                FinalScreen(
                    onComplete: {
                        completeOnboarding()
                    }
                )
                .tag(13)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button (hidden on last page)
            if currentPage < totalPages - 1 {
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(themeManager.isSapphire
                                      ? SapphireFont.eyebrow
                                      : .system(size: 16, weight: .semibold))
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .foregroundColor(themeManager.secondaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(themeManager.glassEffect)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                    }

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(themeManager.colorScheme)
    }

    private func completeOnboarding() {
        let wantsDailyVerse = notificationsEnabled
        let wantsProgress = progressNotificationsEnabled

        Task { @MainActor in
            // Only flip preferences on if iOS actually granted permission,
            // otherwise Settings would show "Enabled" while nothing can fire.
            var granted = false
            if wantsDailyVerse || wantsProgress {
                granted = await NotificationManager.shared.requestPermission()
            }

            NotificationManager.shared.preferences.enabled = wantsDailyVerse && granted

            // Apply progress notification preferences (celebrations are in-app
            // overlays and don't need OS permission)
            let progressManager = ProgressManager.shared
            let prefs = progressManager.preferences
            prefs.notificationsEnabled = wantsProgress && granted
            prefs.celebrationsEnabled = wantsProgress
            progressManager.updatePreferences(prefs)
        }

        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasShownWelcome")

        // Dismiss
        dismiss()
    }
}

#Preview {
    OnboardingFlowView()
}
