//
//  FinalScreen.swift
//  AlBayan
//
//  Onboarding Screen 10: Final Screen
//

import SwiftUI

struct FinalScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    let onComplete: () -> Void
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Read. Reflect. Grow.")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(32)
                                  : .system(size: 32, weight: .bold))
                            .foregroundColor(themeManager.primaryText)
                            .onboardingTitle()
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : -20)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                        Text("This is where it stops slipping away.")
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(18, semibold: false)
                                  : .system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.secondaryText)
                            .onboardingSubtitle()
                            .opacity(isVisible ? 1 : 0)
                            .animation(Animation.easeOut(duration: 0.6).delay(0.3), value: isVisible)
                    }

                    // Get started button
                    VStack(spacing: 16) {
                        Button(action: onComplete) {
                            HStack {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start reflecting")
                                    .font(themeManager.isSapphire
                                          ? SapphireFont.serif(20)
                                          : .system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(themeManager.isSapphire
                                          ? AnyShapeStyle(themeManager.goldGradient)
                                          : AnyShapeStyle(themeManager.purpleGradient))
                            )
                            .shadow(color: themeManager.isSapphire
                                    ? themeManager.goldButtonShadow
                                    : Color(red: 0.39, green: 0.4, blue: 0.95).opacity(0.4), radius: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.6).delay(0.5), value: isVisible)
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

#Preview {
    FinalScreen(onComplete: {})
}
