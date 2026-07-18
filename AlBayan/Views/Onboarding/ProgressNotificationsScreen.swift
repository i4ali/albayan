//
//  ProgressNotificationsScreen.swift
//  AlBayan
//
//  Onboarding Screen 5: Reading Progress & Motivation
//

import SwiftUI

struct ProgressNotificationsScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var progressNotificationsEnabled: Bool
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        // Icon - Flame for streak
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .blur(radius: 10)

                            Text("🔥")
                                .font(.system(size: 48))
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(themeManager.glassEffect)
                                )
                                .shadow(color: Color.orange.opacity(0.4), radius: 12)
                        }
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isVisible)

                        Text("Small steps, kept up, change you.")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(28)
                                  : .system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.primaryText)
                            .onboardingTitle()
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : 20)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                        Text("Gentle nudges to keep your streak alive.")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(18, semibold: false)
                                  : .system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.secondaryText)
                            .onboardingSubtitle()
                            .opacity(isVisible ? 1 : 0)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.5), value: isVisible)
                    }

                    // Feature cards
                    VStack(spacing: 16) {
                        ProgressFeatureCard(
                            icon: "chart.bar.fill",
                            color: .blue,
                            title: "Track Your Progress",
                            description: "See your daily verse count and reading streaks"
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 30)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.7), value: isVisible)

                        ProgressFeatureCard(
                            icon: "flame.fill",
                            color: .orange,
                            title: "Build Streaks",
                            description: "Read daily to maintain your streak and reach new milestones"
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 30)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.8), value: isVisible)

                        ProgressFeatureCard(
                            icon: "trophy.fill",
                            color: .yellow,
                            title: "Reach milestones",
                            description: "Complete surahs and reach milestones along the way."
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 30)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.9), value: isVisible)
                    }
                    .padding(.horizontal, 24)

                    // Enable button
                    VStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                progressNotificationsEnabled.toggle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: progressNotificationsEnabled ? "checkmark.circle.fill" : "bell.badge.fill")
                                    .font(.system(size: 20, weight: .semibold))

                                Text(progressNotificationsEnabled ? "Reminders Enabled" : "Enable Progress Reminders")
                                    .font(themeManager.isSapphire
                                          ? SapphireFont.serif(20)
                                          : .system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(progressNotificationsEnabled ?
                                          AnyShapeStyle(LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          )) :
                                          AnyShapeStyle(themeManager.isSapphire ? themeManager.goldGradient : themeManager.purpleGradient))
                            )
                            .shadow(
                                color: (progressNotificationsEnabled ? Color.green : (themeManager.isSapphire ? themeManager.accentBright : Color(red: 0.39, green: 0.4, blue: 0.95))).opacity(0.4),
                                radius: 12
                            )
                        }

                        if !progressNotificationsEnabled {
                            Text("You can always enable this later in Settings")
                                .font(themeManager.isSapphire
                                      ? SapphireFont.serif(17, semibold: false)
                                      : .system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.secondaryText)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.6).delay(1.1), value: isVisible)
                }

                Spacer(minLength: 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
        }
    }
}

struct ProgressFeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.isSapphire ? themeManager.goldChipFill : color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : color)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(18)
                          : .system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)

                Text(description)
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(16, semibold: false)
                          : .system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.glassEffect)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.strokeColor, lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProgressNotificationsScreen(progressNotificationsEnabled: .constant(false))
}
