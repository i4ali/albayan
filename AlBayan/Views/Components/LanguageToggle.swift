import SwiftUI

// MARK: - Global verse-translation language toggle (shared)

/// Compact globe + language-code chip that cycles the ONE global language
/// (EN → UR → AR) via `CommentaryLanguageManager`. Self-observing — drop it
/// anywhere; every verse-translation view follows the same singleton, so the
/// chip and the verses stay in lockstep.
struct VerseLanguageToggle: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { languageManager.toggleLanguage() }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .semibold))
                Text(languageManager.selectedLanguage.rawValue.uppercased())
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(themeManager.accentColor)
            .frame(height: 40)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(themeManager.accentColor.opacity(0.12))
                    .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Translation language")
        .accessibilityValue(languageManager.selectedLanguage.displayName)
    }
}

extension View {
    /// Aligns a verse-translation line for the given language — RTL (trailing) for
    /// Urdu/Arabic, LTR (leading) otherwise. Apply after the text's font/spacing.
    func translationLayout(_ language: CommentaryLanguage) -> some View {
        self
            .multilineTextAlignment(language.isRTL ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: language.isRTL ? .trailing : .leading)
            .environment(\.layoutDirection, language.isRTL ? .rightToLeft : .leftToRight)
    }
}
