//
//  QuestionDetailView.swift
//  AlBayan
//
//  Detailed view showing question with verse answers and relevance notes
//

import SwiftUI

struct QuestionDetailView: View {
    let question: Question
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var questionsManager = QuestionsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVerseForNav: (surah: Int, verse: Int)?
    @State private var navigateToVerse = false

    var relatedQuestions: [Question] {
        question.relatedQuestions.compactMap { id in
            questionsManager.question(byId: id)
        }
    }

    var body: some View {
        ZStack {
            // Adaptive background
            AdaptiveModernBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Question header
                    VStack(spacing: 16) {
                        // Category badge
                        HStack {
                            if themeManager.isSapphire {
                                HStack(spacing: 8) {
                                    Image(systemName: question.categoryIcon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.accentColor)

                                    Text(question.category.displayName.uppercased())
                                        .font(SapphireFont.eyebrow)
                                        .foregroundColor(themeManager.accentColor)
                                        .kerning(2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule()
                                        .fill(themeManager.goldChipFill)
                                        .overlay(
                                            Capsule()
                                                .stroke(themeManager.strokeColor, lineWidth: 1)
                                        )
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: question.categoryIcon)
                                        .font(.system(size: 14, weight: .semibold))

                                    Text(question.category.displayName)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(themeManager.accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule()
                                        .fill(themeManager.accentColor.opacity(0.15))
                                }
                            }

                            Spacer()
                        }

                        // Question text
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.accentColor)

                                if themeManager.isSapphire {
                                    Text("THE QUESTION")
                                        .font(SapphireFont.eyebrow)
                                        .foregroundColor(themeManager.accentColor)
                                        .kerning(2)
                                } else {
                                    Text("THE QUESTION")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(themeManager.secondaryText)
                                        .tracking(1.2)
                                }
                            }

                            if themeManager.isSapphire {
                                Text(question.question)
                                    .font(SapphireFont.serif(26))
                                    .foregroundColor(themeManager.primaryText)
                                    .lineSpacing(4)
                            } else {
                                Text(question.question)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(themeManager.primaryText)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(24)
                    .background {
                        if themeManager.useWarmLayout {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(themeManager.glassEffect)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Quranic answer header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.accentColor)

                            if themeManager.isSapphire {
                                Text("QURANIC ANSWER")
                                    .font(SapphireFont.eyebrow)
                                    .foregroundColor(themeManager.accentColor)
                                    .kerning(2)
                            } else {
                                Text("QURANIC ANSWER")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(themeManager.secondaryText)
                                    .tracking(1.2)
                            }
                        }

                        if themeManager.isSapphire {
                            HStack(spacing: 8) {
                                // Azure verified badge
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(themeManager.semanticAzure)
                                    Text("\(question.verseCount) verse\(question.verseCount == 1 ? "" : "s")")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(themeManager.semanticAzure)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.semanticAzureChip)
                                .clipShape(Capsule())

                                Text("The Quran answers this question:")
                                    .font(SapphireFont.serif(17, semibold: false))
                                    .foregroundColor(themeManager.secondaryText)
                            }
                        } else {
                            Text("The Quran answers this question in \(question.verseCount) verse\(question.verseCount == 1 ? "" : "s"):")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.primaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Verses with answers
                    ForEach(Array(question.verses.enumerated()), id: \.element.verseNumber) { index, questionVerse in
                        VerseAnswerCard(
                            questionVerse: questionVerse,
                            index: index + 1,
                            totalVerses: question.verseCount,
                            onNavigate: {
                                selectedVerseForNav = (questionVerse.surahNumber, questionVerse.verseNumber)
                                navigateToVerse = true
                            }
                        )
                    }

                    // Related questions
                    if !relatedQuestions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.accentColor)

                                if themeManager.isSapphire {
                                    Text("RELATED QUESTIONS")
                                        .font(SapphireFont.eyebrow)
                                        .foregroundColor(themeManager.accentColor)
                                        .kerning(2)
                                } else {
                                    Text("RELATED QUESTIONS")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(themeManager.secondaryText)
                                        .tracking(1.2)
                                }
                            }

                            ForEach(relatedQuestions) { relatedQ in
                                RelatedQuestionCard(question: relatedQ)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }

            // Hidden NavigationLink for verse navigation
            if let verseNav = selectedVerseForNav,
               let surahData = dataManager.availableSurahs.first(where: { $0.surah.number == verseNav.surah }) {
                NavigationLink(
                    destination: SurahDetailView(surahWithTafsir: surahData, targetVerse: verseNav.verse),
                    isActive: $navigateToVerse
                ) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .hidden()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Questions")
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

struct VerseAnswerCard: View {
    let questionVerse: QuestionVerse
    let index: Int
    let totalVerses: Int
    let onNavigate: () -> Void
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared

    var verseData: (arabic: String, translation: String)? {
        guard let verses = dataManager.quranData?.verses["\(questionVerse.surahNumber)"],
              let verse = verses["\(questionVerse.verseNumber)"] else {
            return nil
        }
        return (verse.arabicText, verse.translation(for: languageManager.selectedLanguage))
    }

    var surahName: String {
        dataManager.quranData?.surahs.first { $0.number == questionVerse.surahNumber }?.englishName ?? "Surah \(questionVerse.surahNumber)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Verse header
            HStack(spacing: 12) {
                // Verse number badge
                if themeManager.isSapphire {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.goldChipFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                            .frame(width: 40, height: 40)

                        Text("\(index)")
                            .font(SapphireFont.numeral(20))
                            .foregroundColor(themeManager.accentColor)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentGradient)
                            .frame(width: 40, height: 40)

                        Text("\(index)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    if themeManager.isSapphire {
                        Text("VERSE \(index) OF \(totalVerses)")
                            .font(SapphireFont.eyebrow)
                            .foregroundColor(themeManager.accentColor)
                            .kerning(2)

                        Text("\(surahName) (\(questionVerse.surahNumber):\(questionVerse.verseNumber))")
                            .font(SapphireFont.serif(16))
                            .foregroundColor(themeManager.primaryText)
                    } else {
                        Text("Verse \(index) of \(totalVerses)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.secondaryText)

                        Text("\(surahName) (\(questionVerse.surahNumber):\(questionVerse.verseNumber))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.primaryText)
                    }
                }

                Spacer()

                if questionVerse.isPrimary {
                    if themeManager.isSapphire {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(themeManager.semanticAzure)
                            Text("PRIMARY")
                                .font(SapphireFont.eyebrow)
                                .foregroundColor(themeManager.semanticAzure)
                                .kerning(1.5)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.semanticAzureChip)
                        .clipShape(Capsule())
                    } else {
                        Text("PRIMARY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule()
                                    .fill(themeManager.accentColor.opacity(0.15))
                            }
                    }
                }
            }
            .padding(20)

            Divider()
                .background(themeManager.strokeColor)

            // Verse text
            if let verse = verseData {
                VStack(alignment: .leading, spacing: 16) {
                    // Arabic text
                    Text(verse.arabic)
                        .font(themeManager.isSapphire ? SapphireFont.arabicVerse(28 * readingSettings.scale) : .custom("AmiriQuran-Regular", size: 24 * readingSettings.scale))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing((themeManager.isSapphire ? 14 : 8) * readingSettings.scale)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    // Translation
                    Text(verse.translation)
                        .font(themeManager.isSapphire ? SapphireFont.serif(17 * readingSettings.scale, semibold: false) : .system(size: 16 * readingSettings.scale, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(4 * readingSettings.scale)
                        .translationLayout(languageManager.selectedLanguage)
                }
                .padding(20)

                Divider()
                    .background(themeManager.strokeColor)
            }

            // Relevance note
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.accentColor)

                    if themeManager.isSapphire {
                        Text("WHY THIS ANSWERS")
                            .font(SapphireFont.eyebrow)
                            .foregroundColor(themeManager.accentColor)
                            .kerning(2)
                    } else {
                        Text("Why This Answers")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeManager.secondaryText)
                    }
                }

                Text(questionVerse.relevanceNote)
                    .font(themeManager.isSapphire ? SapphireFont.serif(16 * readingSettings.scale, semibold: false) : .system(size: 15 * readingSettings.scale, weight: .medium))
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing(4 * readingSettings.scale)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background {
                if themeManager.isSapphire {
                    Rectangle()
                        .fill(themeManager.cardElevated)
                } else if themeManager.useWarmLayout {
                    Rectangle()
                        .fill(Color(red: 0.98, green: 0.98, blue: 0.95))
                } else {
                    Rectangle()
                        .fill(themeManager.accentColor.opacity(0.05))
                }
            }

            Divider()
                .background(themeManager.strokeColor)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onNavigate) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))

                        Text("Read Full Tafsir")
                            .font(themeManager.isSapphire ? SapphireFont.serif(16) : .system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background {
                        if themeManager.isSapphire {
                            Capsule()
                                .fill(AnyShapeStyle(themeManager.goldGradient))
                                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8)
                        } else {
                            Capsule()
                                .fill(AnyShapeStyle(themeManager.accentGradient))
                                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .background {
            if themeManager.useWarmLayout {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.glassEffect)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct RelatedQuestionCard: View {
    let question: Question
    @StateObject private var themeManager = ThemeManager.shared
    @State private var navigateToQuestion = false

    var body: some View {
        NavigationLink(destination: QuestionDetailView(question: question), isActive: $navigateToQuestion) {
            HStack(spacing: 12) {
                // Icon chip
                if themeManager.isSapphire {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.goldChipFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: question.categoryIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                    }
                } else {
                    Image(systemName: question.categoryIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.15))
                        }
                }

                Text(question.question)
                    .font(themeManager.isSapphire ? SapphireFont.serif(17) : .system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
                    .lineLimit(2)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.tertiaryText)
            }
            .padding(16)
            .background {
                if themeManager.useWarmLayout {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.glassEffect)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.strokeColor, lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        QuestionDetailView(
            question: Question(
                id: "q1",
                question: "What is the purpose of life?",
                shortQuestion: "Life's purpose?",
                category: .faith,
                verses: [
                    QuestionVerse(
                        surahNumber: 51,
                        verseNumber: 56,
                        relevanceNote: "This verse directly states the purpose: to worship and know Allah.",
                        isPrimary: true
                    )
                ],
                relatedQuestions: []
            )
        )
    }
}
