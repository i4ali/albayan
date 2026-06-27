//
//  ProfileSetupScreen.swift
//  AlBayan
//
//  Onboarding: collect the user's name + preferred reading language.
//  Shown right before the final "Get Started" screen.
//

import SwiftUI

struct ProfileSetupScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @Binding var currentPage: Int

    // Persisted live so the name sticks whether the user taps Continue or swipes the page.
    @AppStorage("userName") private var userName = ""

    @FocusState private var nameFocused: Bool
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                VStack(spacing: 36) {
                    header
                    nameField
                    languageSection
                    continueButton
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 60)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear { isVisible = true }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Text("Welcome 👋")
                .font(themeManager.isSapphire ? SapphireFont.serif(32) : .system(size: 32, weight: .bold))
                .foregroundColor(themeManager.primaryText)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(Animation.easeOut(duration: 0.6).delay(0.2), value: isVisible)

            Text("Let's personalize your experience")
                .font(themeManager.isSapphire ? SapphireFont.serif(18, semibold: false) : .system(size: 16, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .multilineTextAlignment(.center)
                .opacity(isVisible ? 1 : 0)
                .animation(Animation.easeOut(duration: 0.6).delay(0.3), value: isVisible)
        }
    }

    // MARK: - Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR NAME")
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 13, weight: .semibold))
                .tracking(themeManager.isSapphire ? 2 : 0.5)
                .foregroundColor(themeManager.secondaryText)

            TextField("Enter your name", text: $userName)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { nameFocused = false }
                .font(themeManager.isSapphire ? SapphireFont.body(17) : .system(size: 17, weight: .regular))
                .foregroundColor(themeManager.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.secondaryBackground.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(nameFocused ? themeManager.accentColor : themeManager.strokeColor, lineWidth: 1)
                )
        }
        .opacity(isVisible ? 1 : 0)
        .animation(Animation.easeOut(duration: 0.6).delay(0.4), value: isVisible)
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREFERRED LANGUAGE")
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 13, weight: .semibold))
                .tracking(themeManager.isSapphire ? 2 : 0.5)
                .foregroundColor(themeManager.secondaryText)

            HStack(spacing: 12) {
                ForEach(CommentaryLanguage.supportedTafsirLanguages, id: \.self) { language in
                    languageButton(language)
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(Animation.easeOut(duration: 0.6).delay(0.5), value: isVisible)
    }

    private func languageButton(_ language: CommentaryLanguage) -> some View {
        let isSelected = languageManager.selectedLanguage == language
        return Button(action: {
            withAnimation { languageManager.setLanguage(language) }
        }) {
            Text(language.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(
                    isSelected
                        ? (themeManager.isSapphire ? themeManager.onAccentText : .white)
                        : themeManager.tertiaryText
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldGradient) : AnyShapeStyle(themeManager.accentGradient))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldChipFill) : AnyShapeStyle(Color.clear))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            themeManager.isSapphire ? themeManager.accentColor : themeManager.strokeColor,
                            lineWidth: isSelected ? (themeManager.isSapphire ? 1 : 0) : 1
                        )
                )
        }
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button(action: {
            nameFocused = false
            withAnimation { currentPage += 1 }
        }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(themeManager.isSapphire ? SapphireFont.serif(20) : .system(size: 18, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldGradient) : AnyShapeStyle(themeManager.purpleGradient))
            )
            .shadow(color: themeManager.isSapphire ? themeManager.goldButtonShadow : Color(red: 0.39, green: 0.4, blue: 0.95).opacity(0.4), radius: 12)
        }
        .padding(.top, 8)
        .opacity(isVisible ? 1 : 0)
        .animation(Animation.easeOut(duration: 0.6).delay(0.6), value: isVisible)
    }
}

#Preview {
    ProfileSetupScreen(currentPage: .constant(9))
}
