//
//  MissionScreen.swift
//  AlBayan
//
//  Onboarding Screen 2: App Mission
//

import SwiftUI

struct MissionScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isVisible = false
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 50) {
                // App icon with glow
                ZStack {
                    // Glow effect
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(themeManager.accentGradient.opacity(0.3))
                            .frame(width: 140 - CGFloat(index * 20), height: 140 - CGFloat(index * 20))
                            .blur(radius: 10)
                            .scaleEffect(isVisible ? 1 : 0.5)
                            .opacity(isVisible ? 1 : 0)
                            .animation(
                                Animation.easeOut(duration: 1.0).delay(Double(index) * 0.2),
                                value: isVisible
                            )
                    }

                    // App icon representation with shimmer
                    Text("تفكّر")
                        .font(.system(size: 48, weight: .light, design: .default))
                        .foregroundColor(themeManager.primaryText)
                        .overlay(
                            GeometryReader { geometry in
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.6),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.5)
                                .offset(x: shimmerOffset * geometry.size.width * 1.5)
                                .blendMode(.overlay)
                            }
                            .mask(
                                Text("تفكّر")
                                    .font(.system(size: 48, weight: .light, design: .default))
                            )
                        )
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: isVisible)
                }
                .frame(height: 150)

                // Mission statement
                VStack(spacing: 24) {
                    Text("Time to do more than read it.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(26)
                              : .system(size: 26, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(6)
                        .onboardingTitle()
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(Animation.easeOut(duration: 0.8).delay(0.8), value: isVisible)

                    Text("Understand it. Reflect on it. Let it change you.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(19, semibold: false)
                              : .system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .lineSpacing(5)
                        .onboardingSubtitle()
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(Animation.easeOut(duration: 0.8).delay(1.1), value: isVisible)
                }

                // Feature highlights
                VStack(spacing: 16) {
                    HighlightRow(
                        icon: "book.fill",
                        text: "Read it in words that finally click.",
                        isVisible: isVisible,
                        delay: 1.4
                    )

                    HighlightRow(
                        icon: "sparkles",
                        text: "Reflect on what each verse asks of you.",
                        isVisible: isVisible,
                        delay: 1.6
                    )

                    HighlightRow(
                        icon: "leaf.fill",
                        text: "Grow - carry one thing forward, daily.",
                        isVisible: isVisible,
                        delay: 1.8
                    )
                }
                .padding(.horizontal, 30)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
            startShimmerAnimation()
        }
    }

    private func startShimmerAnimation() {
        // Start shimmer after initial animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.0
            }
        }
    }
}

// MARK: - Highlight Row

struct HighlightRow: View {
    @StateObject private var themeManager = ThemeManager.shared
    let icon: String
    let text: String
    let isVisible: Bool
    let delay: Double

    var body: some View {
        HStack(spacing: 14) {
            if themeManager.isSapphire {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AnyShapeStyle(themeManager.goldGradient))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.goldChipFill)
                    )
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.accentGradient)
                    )
                    .shadow(color: Color(red: 0.39, green: 0.4, blue: 0.95).opacity(0.3), radius: 8)
            }

            Text(text)
                .font(themeManager.isSapphire
                      ? SapphireFont.serif(17)
                      : .system(size: 15, weight: .medium))
                .foregroundColor(themeManager.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
        .animation(Animation.easeOut(duration: 0.6).delay(delay), value: isVisible)
    }
}

#Preview {
    MissionScreen()
}
