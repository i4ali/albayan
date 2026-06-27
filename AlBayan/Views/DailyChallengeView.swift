//
//  DailyChallengeView.swift
//  AlBayan
//
//  Full-screen play sheet for today's Daily Challenge. Shell matches StoryDetailView
//  (AdaptiveModernBackground + ScrollView/VStack + dismiss). Renders by format:
//  multipleChoice / fillInBlank → option buttons; trueFalse → True/False; flashcard →
//  reveal → "Got it" / "Review again". Reading content (prompt / options / answer /
//  explanation / arabicText) scales with ReadingSettingsManager; chrome stays fixed.
//  RTL is applied for Urdu/Arabic on the reading text + answer stacks.
//

import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @StateObject private var manager = DailyChallengeManager.shared
    @StateObject private var provider = DailyChallengeProvider.shared
    @Environment(\.dismiss) private var dismiss

    /// Index of the option the user tapped (MC / fillInBlank / trueFalse). nil until answered.
    @State private var selectedIndex: Int? = nil
    /// Flashcard: whether the back has been revealed.
    @State private var flashcardRevealed = false
    /// Set once we've recorded this day's completion, so it counts only once.
    @State private var didRecord = false

    private var challenge: DailyChallenge { provider.today }
    private var lang: CommentaryLanguage { languageManager.selectedLanguage }
    private var scale: CGFloat { readingSettings.scale }
    private var answered: Bool { selectedIndex != nil || (challenge.format == .flashcard && flashcardRevealed) }

    var body: some View {
        ZStack {
            AdaptiveModernBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    promptBlock

                    answerArea

                    if answered, let explanation = challenge.explanation {
                        explanationBlock(explanation)
                    }

                    if answered {
                        SpGoldCTA(title: DailyChallengeStrings.doneButton(lang), systemIcon: "checkmark") {
                            Haptics.impact(.light)
                            dismiss()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    // MARK: - Header (chrome — fixed size)

    private var header: some View {
        HStack(alignment: .top) {
            Text(DailyChallengeStrings.dailyChallenge(lang).uppercased())
                .font(SapphireFont.eyebrow)
                .tracking(themeManager.isSapphire ? 3 : 1.2)
                .foregroundColor(themeManager.accentColor)

            Spacer()

            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeManager.secondaryText)
                    .frame(width: 34, height: 34)
                    .background {
                        if themeManager.isSapphire {
                            Circle().fill(themeManager.goldChipFill)
                                .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
                        } else {
                            Circle().fill(themeManager.accentColor.opacity(0.1))
                        }
                    }
            }
            .buttonStyle(SpPressStyle())
        }
        .environment(\.layoutDirection, .leftToRight) // keep close button at top-right
    }

    // MARK: - Prompt + optional Arabic (reading content — scales + RTL)

    private var promptBlock: some View {
        VStack(alignment: lang.isRTL ? .trailing : .leading, spacing: 16) {
            Text(challenge.prompt.text(for: lang))
                .font(themeManager.isSapphire
                      ? SapphireFont.headline(24 * scale)
                      : .system(size: 22 * scale, weight: .semibold))
                .foregroundColor(themeManager.primaryText)
                .lineSpacing(5 * scale)
                .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: lang.isRTL ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let arabic = challenge.arabicText, !arabic.isEmpty {
                Text(arabic)
                    .font(themeManager.isSapphire
                          ? SapphireFont.arabicVerse(28 * scale)
                          : .custom("Amiri-Regular", size: 26 * scale))
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing(8 * scale)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeManager.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(themeManager.strokeColor, lineWidth: 1))
                    }
            }

            if let source = challenge.source, !source.isEmpty {
                Text(source)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: lang.isRTL ? .trailing : .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
    }

    // MARK: - Answer area (by format)

    @ViewBuilder
    private var answerArea: some View {
        switch challenge.format {
        case .multipleChoice, .fillInBlank:
            optionButtons
        case .trueFalse:
            trueFalseButtons
        case .flashcard:
            flashcardArea
        }
    }

    // MARK: Multiple-choice / fill-in-the-blank

    private var optionButtons: some View {
        VStack(spacing: 12) {
            if let options = challenge.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    optionButton(text: option.text(for: lang), index: index)
                }
            }
        }
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
    }

    private func optionButton(text: String, index: Int) -> some View {
        let isChosen = selectedIndex == index
        let isCorrect = challenge.correctIndex == index
        let revealCorrect = answered && isCorrect
        let revealWrong = answered && isChosen && !isCorrect

        let border: Color = revealCorrect ? .green : (revealWrong ? .red : themeManager.strokeColor)
        let fill: Color = revealCorrect ? Color.green.opacity(0.16)
            : (revealWrong ? Color.red.opacity(0.16) : themeManager.cardBackground)

        return Button {
            chooseOption(index)
        } label: {
            HStack(spacing: 12) {
                Text(text)
                    .font(themeManager.isSapphire
                          ? SapphireFont.body(17 * scale)
                          : .system(size: 16 * scale, weight: .medium))
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing(3 * scale)
                    .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: lang.isRTL ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if revealCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if revealWrong {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(border, lineWidth: revealCorrect || revealWrong ? 2 : 1))
            }
        }
        .buttonStyle(SpPressStyle())
        .disabled(answered)
    }

    // MARK: True / False

    private var trueFalseButtons: some View {
        // Convention: correctIndex 1 = true, 0 = false. Map True→index 1, False→index 0.
        HStack(spacing: 12) {
            trueFalseButton(label: DailyChallengeStrings.trueLabel(lang), index: 1, icon: "checkmark")
            trueFalseButton(label: DailyChallengeStrings.falseLabel(lang), index: 0, icon: "xmark")
        }
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
    }

    private func trueFalseButton(label: String, index: Int, icon: String) -> some View {
        let isChosen = selectedIndex == index
        let isCorrect = challenge.correctIndex == index
        let revealCorrect = answered && isCorrect
        let revealWrong = answered && isChosen && !isCorrect

        let border: Color = revealCorrect ? .green : (revealWrong ? .red : themeManager.strokeColor)
        let fill: Color = revealCorrect ? Color.green.opacity(0.16)
            : (revealWrong ? Color.red.opacity(0.16) : themeManager.cardBackground)

        return Button {
            chooseOption(index)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(revealCorrect ? .green : (revealWrong ? .red : themeManager.accentColor))
                Text(label)
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(18 * scale)
                          : .system(size: 17 * scale, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(border, lineWidth: revealCorrect || revealWrong ? 2 : 1))
            }
        }
        .buttonStyle(SpPressStyle())
        .disabled(answered)
    }

    // MARK: Flashcard

    @ViewBuilder
    private var flashcardArea: some View {
        if !flashcardRevealed {
            Button {
                Haptics.impact(.light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    flashcardRevealed = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.rotate")
                        .font(.system(size: 16, weight: .semibold))
                    Text(DailyChallengeStrings.flipCard(lang))
                        .font(.system(size: 15.5, weight: .bold))
                        .tracking(0.3)
                }
                .foregroundColor(themeManager.onAccentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(themeManager.goldGradient))
                .shadow(color: themeManager.goldButtonShadow, radius: 14, x: 0, y: 10)
            }
            .buttonStyle(SpPressStyle())
        } else {
            VStack(alignment: lang.isRTL ? .trailing : .leading, spacing: 16) {
                if let answer = challenge.answer {
                    Text(answer.text(for: lang))
                        .font(themeManager.isSapphire
                              ? SapphireFont.body(19 * scale)
                              : .system(size: 18 * scale, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(5 * scale)
                        .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                        .frame(maxWidth: .infinity, alignment: lang.isRTL ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeManager.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(themeManager.strokeColor, lineWidth: 1))
                        }
                }

                HStack(spacing: 12) {
                    flashcardChoice(label: DailyChallengeStrings.gotIt(lang), gotIt: true)
                    flashcardChoice(label: DailyChallengeStrings.reviewAgain(lang), gotIt: false)
                }
            }
            .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
        }
    }

    private func flashcardChoice(label: String, gotIt: Bool) -> some View {
        Button {
            recordFlashcard(gotIt: gotIt)
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(gotIt ? themeManager.onAccentText : themeManager.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    if gotIt {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(themeManager.goldGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(themeManager.goldChipFill)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(themeManager.strokeColor, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(SpPressStyle())
    }

    // MARK: - Explanation (reading content — scales + RTL)

    private func explanationBlock(_ explanation: LocalizedText) -> some View {
        let wasCorrect = selectedIndex != nil && selectedIndex == challenge.correctIndex
        let isScoring = challenge.format != .flashcard

        return VStack(alignment: lang.isRTL ? .trailing : .leading, spacing: 10) {
            if isScoring {
                HStack(spacing: 8) {
                    Image(systemName: wasCorrect ? "checkmark.seal.fill" : "info.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(wasCorrect ? .green : themeManager.accentColor)
                    Text(wasCorrect ? DailyChallengeStrings.correct(lang) : DailyChallengeStrings.notQuite(lang))
                        .font(SapphireFont.eyebrow)
                        .tracking(themeManager.isSapphire ? 2 : 1)
                        .foregroundColor(wasCorrect ? .green : themeManager.accentColor)
                }
            }

            Text(explanation.text(for: lang))
                .font(themeManager.isSapphire
                      ? SapphireFont.serif(16 * scale, semibold: false)
                      : .system(size: 15 * scale, weight: .medium))
                .foregroundColor(themeManager.primaryText)
                .lineSpacing(5 * scale)
                .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: lang.isRTL ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeManager.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
    }

    // MARK: - Scoring (guarded once per day)

    private func chooseOption(_ index: Int) {
        guard selectedIndex == nil else { return }
        Haptics.impact(.light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedIndex = index
        }
        let wasCorrect = (index == challenge.correctIndex)
        if !didRecord {
            manager.complete(challenge: challenge, wasCorrect: wasCorrect)
            didRecord = true
        }
    }

    private func recordFlashcard(gotIt: Bool) {
        Haptics.impact(.light)
        if !didRecord {
            manager.completeFlashcard(challenge: challenge, gotIt: gotIt)
            didRecord = true
        }
        dismiss()
    }
}

#Preview {
    DailyChallengeView()
}
