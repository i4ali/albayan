//
//  OpeningVerseScreen.swift
//  AlBayan
//
//  Onboarding Screen 1: The opening verse - Qur'an 47:24 (Surah Muhammad).
//

import SwiftUI

struct OpeningVerseScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var currentPage: Int
    @State private var isVisible = false
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Subtle Islamic geometric pattern background
            GeometricPatternBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 40) {
                    // Title with glow
                    Text("The Qur'an asks")
                        .font(themeManager.isSapphire
                              ? SapphireFont.eyebrow
                              : .system(size: 20, weight: .semibold))
                        .tracking(themeManager.isSapphire ? 3 : 0)
                        .textCase(themeManager.isSapphire ? .uppercase : nil)
                        .foregroundColor(themeManager.isSapphire
                                         ? themeManager.accentColor
                                         : themeManager.secondaryText)
                        .overlay(
                            GeometryReader { geometry in
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.5),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: geometry.size.width * 0.4)
                                .offset(x: shimmerOffset * geometry.size.width * 1.5)
                                .blendMode(.overlay)
                            }
                            .mask(
                                Text("The Qur'an asks")
                                    .font(themeManager.isSapphire
                                          ? SapphireFont.eyebrow
                                          : .system(size: 20, weight: .semibold))
                            )
                        )
                        .background(
                            Ellipse()
                                .fill(themeManager.accentGradient.opacity(0.3))
                                .frame(width: 200, height: 70)
                                .blur(radius: 20)
                                .scaleEffect(glowPulse ? 1.1 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                                    value: glowPulse
                                )
                        )
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.3), value: isVisible)

                    // Arabic verse 47:24
                    Text("أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ\nأَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَآ")
                        .font(themeManager.isSapphire
                              ? SapphireFont.arabic(26)
                              : .system(size: 26, weight: .medium, design: .serif))
                        .foregroundColor(themeManager.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 30)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 30)
                        .animation(Animation.easeOut(duration: 0.8).delay(0.6), value: isVisible)

                    // Divider
                    Capsule()
                        .fill(themeManager.accentGradient)
                        .frame(width: 60, height: 3)
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(x: isVisible ? 1 : 0, y: 1)
                        .animation(Animation.easeOut(duration: 0.5).delay(0.9), value: isVisible)

                    // English Translation
                    VStack(spacing: 12) {
                        Text("\"Do they not reflect")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(20, semibold: false)
                                  : .system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.primaryText)

                        Text("upon the Qur'an,")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(20, semibold: false)
                                  : .system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.primaryText)

                        Text("or are there locks")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(20, semibold: false)
                                  : .system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.primaryText)

                        Text("upon the hearts?\"")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(20, semibold: false)
                                  : .system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.primaryText)
                    }
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 30)
                    .animation(Animation.easeOut(duration: 0.8).delay(1.1), value: isVisible)

                    // Attribution
                    Text("Qur'an 47:24 · Surah Muhammad")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(16, semibold: true, italic: true)
                              : .system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .opacity(isVisible ? 1 : 0)
                        .animation(Animation.easeOut(duration: 0.6).delay(1.4), value: isVisible)

                    // Personal kicker - turns the verse on the reader
                    Text("You've recited it for years. When did it last reach your heart?")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(18, semibold: true, italic: false)
                              : .system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 36)
                        .padding(.top, 4)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(Animation.easeOut(duration: 0.8).delay(1.7), value: isVisible)
                }

                Spacer()

                // Tap to continue hint
                VStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryText)

                    Text("Swipe or tap to continue")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(15, semibold: false)
                              : .system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                }
                .opacity(isVisible ? 0.9 : 0)
                .animation(Animation.easeOut(duration: 0.6).delay(2.0), value: isVisible)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isVisible = true
            startTitleAnimations()

            // Auto-advance after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentPage = 1
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentPage = 1
            }
        }
    }

    private func startTitleAnimations() {
        // Start glow pulse after initial fade-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            glowPulse = true
        }
        // Start shimmer after initial animation
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

// MARK: - Geometric Pattern Background

struct GeometricPatternBackground: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Subtle gradient
            themeManager.primaryBackground

            // Very subtle geometric pattern overlay
            Canvas { context, size in
                let spacing: CGFloat = 40
                let lineWidth: CGFloat = 0.5

                for x in stride(from: 0, through: size.width, by: spacing) {
                    for y in stride(from: 0, through: size.height, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + spacing, y: y + spacing))

                        context.stroke(
                            path,
                            with: .color(themeManager.strokeColor.opacity(0.1)),
                            lineWidth: lineWidth
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OpeningVerseScreen(currentPage: .constant(0))
}
