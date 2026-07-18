//
//  DailyChallengeScreen.swift
//  AlBayan
//
//  Onboarding Screen: Daily Challenge Highlight
//

import SwiftUI

struct DailyChallengeScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isVisible = false
    @State private var iconPulse = false
    @State private var showCard = false
    @State private var selectedOption: Int? = nil
    @State private var showCorrect = false
    @State private var streakCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with animated icon
                VStack(spacing: 20) {
                    // Animated icon
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .scaleEffect(iconPulse ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: iconPulse
                            )

                        // Icon background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.35), Color.red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        // Icon
                        if themeManager.isSapphire {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(AnyShapeStyle(themeManager.goldGradient))
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.5)
                    .animation(Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isVisible)

                    // Title
                    Text("A daily nudge to reflect.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(34)
                              : .system(size: 34, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                        .onboardingTitle()
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : -20)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                    // Subtitle
                    Text("One question, one minute. A small reflection that adds up.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(19, semibold: false)
                              : .system(size: 17, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .onboardingSubtitle()
                        .opacity(isVisible ? 1 : 0)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.5), value: isVisible)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Demo content
                VStack(spacing: 16) {
                    DailyChallengePreviewCard(
                        selectedOption: $selectedOption,
                        showCorrect: showCorrect,
                        streakCount: streakCount,
                        isVisible: showCard
                    )
                }
                .padding(.horizontal, 20)

                // Bottom tagline
                Text("Keep the streak. Keep growing.")
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(18, semibold: false)
                          : .system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    .opacity(isVisible ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.6).delay(0.8), value: isVisible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
            iconPulse = true
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) { showCard = true }
        }
        // Tap option A after 2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedOption = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showCorrect = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { streakCount = 5 }
                }
            }
        }
    }
}

// MARK: - Preview Card

private struct DailyChallengePreviewCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var selectedOption: Int?
    let showCorrect: Bool
    let streakCount: Int
    let isVisible: Bool

    private let options = ["Gratitude", "Patience", "Arrogance", "Wealth"]
    private let correctIndex = 0

    var body: some View {
        VStack(spacing: 16) {
            // Streak bar
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(streakCount > 0 ? .orange : themeManager.tertiaryText)
                    .scaleEffect(streakCount > 0 ? 1.15 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: streakCount)

                Text(streakCount > 0 ? "\(streakCount) day streak" : "Start your streak")
                    .font(themeManager.isSapphire
                          ? SapphireFont.eyebrow
                          : .system(size: 12, weight: .bold))
                    .tracking(themeManager.isSapphire ? 2 : 0.5)
                    .foregroundColor(streakCount > 0 ? .orange : themeManager.tertiaryText)

                Spacer()

                Text("TODAY")
                    .font(themeManager.isSapphire
                          ? SapphireFont.eyebrow
                          : .system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(themeManager.tertiaryText)
            }

            // Question
            Text("Which quality does Surah Al-Asr emphasize most?")
                .font(themeManager.isSapphire
                      ? SapphireFont.serif(17)
                      : .system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.primaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Options
            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.offset) { idx, text in
                    let isSelected = selectedOption == idx
                    let isCorrect = idx == correctIndex
                    let borderColor: Color = showCorrect && isCorrect
                        ? .green
                        : (isSelected && !showCorrect ? .orange : themeManager.strokeColor)
                    let bgColor: Color = showCorrect && isCorrect
                        ? .green.opacity(0.15)
                        : (isSelected && !showCorrect ? .orange.opacity(0.15) : themeManager.secondaryBackground)

                    HStack(spacing: 12) {
                        Text("\(["A","B","C","D"][idx])")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected || (showCorrect && isCorrect) ? borderColor : themeManager.secondaryText)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(borderColor.opacity(0.15)))

                        Text(text)
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(15, semibold: false)
                                  : .system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.primaryText)

                        Spacer()

                        if showCorrect && isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bgColor)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: isSelected || (showCorrect && isCorrect) ? 2 : 1))
                    )
                    .scaleEffect(isSelected && !showCorrect ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCorrect)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.secondaryBackground.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeManager.strokeColor, lineWidth: 1))
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 40)
        .animation(.easeOut(duration: 0.6), value: isVisible)
    }
}

#Preview {
    DailyChallengeScreen()
}
