//
//  AhlulbaytEntryDetailView.swift
//  AlBayan
//
//  Detailed view showing Ahl al-Bayt entry with verses and perspectives
//

import SwiftUI

struct AhlulbaytEntryDetailView: View {
    let entry: AhlulbaytEntry
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var ahlulbaytManager = AhlulbaytQuranManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVerseForNav: (surah: Int, verse: Int)?
    @State private var navigateToVerse = false

    var relatedEntries: [AhlulbaytEntry] {
        ahlulbaytManager.relatedEntries(for: entry)
    }

    var body: some View {
        ZStack {
            // Adaptive background
            AdaptiveModernBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Entry header
                    VStack(spacing: 16) {
                        // Category badge
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: entry.categoryIcon)
                                    .font(.system(size: 14, weight: .semibold))

                                Text(entry.category.displayName)
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                                    .tracking(themeManager.isSapphire ? 2 : 0)
                            }
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if themeManager.isSapphire {
                                    Capsule()
                                        .fill(AnyShapeStyle(themeManager.goldChipFill))
                                        .overlay(
                                            Capsule()
                                                .stroke(themeManager.strokeColor, lineWidth: 1)
                                        )
                                } else {
                                    Capsule()
                                        .fill(themeManager.accentColor.opacity(0.15))
                                }
                            }

                            Spacer()
                        }

                        // Entry title
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.accentColor)

                                Text("AHL AL-BAYT IN THE QURAN")
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                    .tracking(themeManager.isSapphire ? 3 : 1.2)
                            }

                            Text(entry.title)
                                .font(themeManager.isSapphire ? SapphireFont.headline(26) : .system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.primaryText)
                                .lineSpacing(4)
                        }
                    }
                    .padding(24)
                    .background {
                        if themeManager.isSapphire {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AnyShapeStyle(themeManager.cardElevated))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        } else if themeManager.useWarmLayout {
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

                    // Ahl al-Bayt Members
                    if !entry.ahlulbaytMembers.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.accentColor)

                                Text("AHL AL-BAYT MEMBERS")
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                    .tracking(themeManager.isSapphire ? 3 : 1.2)
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(entry.ahlulbaytMembers, id: \.self) { member in
                                    Text(member)
                                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                                        .tracking(themeManager.isSapphire ? 2 : 0)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background {
                                            if themeManager.isSapphire {
                                                Capsule()
                                                    .fill(AnyShapeStyle(themeManager.goldChipFill))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                                    )
                                            } else {
                                                Capsule()
                                                    .fill(themeManager.accentColor.opacity(0.12))
                                            }
                                        }
                                }
                            }
                        }
                        .padding(20)
                        .background {
                            if themeManager.isSapphire {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AnyShapeStyle(themeManager.cardBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                    )
                            } else if themeManager.useWarmLayout {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.98, green: 0.98, blue: 0.95))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeManager.accentColor.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Verses header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "book.pages.fill")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.accentColor)

                            Text("QURANIC REFERENCE")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                .tracking(themeManager.isSapphire ? 3 : 1.2)
                        }

                        Text("This entry references \(entry.verseCount) verse\(entry.verseCount == 1 ? "" : "s"):")
                            .font(themeManager.isSapphire ? SapphireFont.body(16) : .system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.primaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Verses with context
                    ForEach(Array(entry.verses.enumerated()), id: \.element.verseNumber) { index, ahlulbaytVerse in
                        AhlulbaytVerseCard(
                            ahlulbaytVerse: ahlulbaytVerse,
                            index: index + 1,
                            totalVerses: entry.verseCount,
                            onNavigate: {
                                selectedVerseForNav = (ahlulbaytVerse.surahNumber, ahlulbaytVerse.verseNumber)
                                navigateToVerse = true
                            }
                        )
                    }

                    // Revelation Context
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.accentColor)

                            Text("REVELATION CONTEXT")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                .tracking(themeManager.isSapphire ? 3 : 1.2)
                        }

                        Text(entry.revelationContext)
                            .font(themeManager.isSapphire ? SapphireFont.serif(17 * readingSettings.scale, semibold: false) : .system(size: 16 * readingSettings.scale, weight: .medium))
                            .foregroundColor(themeManager.primaryText)
                            .lineSpacing(6 * readingSettings.scale)
                    }
                    .padding(20)
                    .background {
                        if themeManager.isSapphire {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AnyShapeStyle(themeManager.cardBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        } else if themeManager.useWarmLayout {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.98, green: 0.98, blue: 0.95))
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.accentColor.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Related entries
                    if !relatedEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.accentColor)

                                Text("RELATED ENTRIES")
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                    .tracking(themeManager.isSapphire ? 3 : 1.2)
                            }

                            ForEach(relatedEntries) { relatedEntry in
                                RelatedEntryCard(entry: relatedEntry)
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
                        Text("Ahl al-Bayt")
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

struct AhlulbaytVerseCard: View {
    let ahlulbaytVerse: AhlulbaytVerse
    let index: Int
    let totalVerses: Int
    let onNavigate: () -> Void
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared

    var verseData: (arabic: String, translation: String)? {
        guard let verses = dataManager.quranData?.verses["\(ahlulbaytVerse.surahNumber)"],
              let verse = verses["\(ahlulbaytVerse.verseNumber)"] else {
            return nil
        }
        return (verse.arabicText, verse.translation(for: languageManager.selectedLanguage))
    }

    var surahName: String {
        dataManager.quranData?.surahs.first { $0.number == ahlulbaytVerse.surahNumber }?.englishName ?? "Surah \(ahlulbaytVerse.surahNumber)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Verse header
            HStack(spacing: 12) {
                // Verse number badge
                ZStack {
                    Circle()
                        .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldGradient) : AnyShapeStyle(themeManager.accentGradient))
                        .frame(width: 40, height: 40)

                    Text("\(index)")
                        .font(themeManager.isSapphire ? SapphireFont.numeral(18) : .system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Verse \(index) of \(totalVerses)")
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.secondaryText)
                        .tracking(themeManager.isSapphire ? 2 : 0)

                    Text("\(surahName) (\(ahlulbaytVerse.surahNumber):\(ahlulbaytVerse.verseNumber))")
                        .font(themeManager.isSapphire ? SapphireFont.headline(16) : .system(size: 15, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                }

                Spacer()

                if ahlulbaytVerse.isPrimary {
                    Text("PRIMARY")
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            if themeManager.isSapphire {
                                Capsule()
                                    .fill(AnyShapeStyle(themeManager.goldChipFill))
                                    .overlay(
                                        Capsule()
                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                    )
                            } else {
                                Capsule()
                                    .fill(themeManager.accentColor.opacity(0.15))
                            }
                        }
                        .tracking(themeManager.isSapphire ? 2 : 0)
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
                        .font(themeManager.isSapphire ? SapphireFont.arabicVerse(26 * readingSettings.scale) : .custom("AmiriQuran-Regular", size: 24 * readingSettings.scale))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(8 * readingSettings.scale)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    // Translation
                    Text(verse.translation)
                        .font(themeManager.isSapphire ? SapphireFont.serif(16 * readingSettings.scale, semibold: false) : .system(size: 16 * readingSettings.scale, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(4 * readingSettings.scale)
                        .translationLayout(languageManager.selectedLanguage)
                }
                .padding(20)

                Divider()
                    .background(themeManager.strokeColor)
            }

            // Verse context
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.accentColor)

                    Text("Verse Context")
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .bold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                        .tracking(themeManager.isSapphire ? 2 : 0)
                }

                Text(ahlulbaytVerse.context)
                    .font(themeManager.isSapphire ? SapphireFont.serif(15 * readingSettings.scale, semibold: false) : .system(size: 15 * readingSettings.scale, weight: .medium))
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing(4 * readingSettings.scale)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background {
                if themeManager.isSapphire {
                    Rectangle()
                        .fill(AnyShapeStyle(themeManager.cardBackground))
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
                            .font(themeManager.isSapphire ? SapphireFont.headline(15) : .system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background {
                        if themeManager.isSapphire {
                            Capsule()
                                .fill(AnyShapeStyle(themeManager.goldGradient))
                                .shadow(color: themeManager.accentColor.opacity(0.35), radius: 8)
                        } else {
                            Capsule()
                                .fill(themeManager.accentGradient)
                                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8)
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .background {
            if themeManager.isSapphire {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AnyShapeStyle(themeManager.cardElevated))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            } else if themeManager.useWarmLayout {
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

struct RelatedEntryCard: View {
    let entry: AhlulbaytEntry
    @StateObject private var themeManager = ThemeManager.shared
    @State private var navigateToEntry = false

    var body: some View {
        NavigationLink(destination: AhlulbaytEntryDetailView(entry: entry), isActive: $navigateToEntry) {
            HStack(spacing: 12) {
                Image(systemName: entry.categoryIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                    .frame(width: 32, height: 32)
                    .background {
                        if themeManager.isSapphire {
                            Circle()
                                .fill(AnyShapeStyle(themeManager.goldChipFill))
                                .overlay(
                                    Circle()
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        } else {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.15))
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.category.displayName)
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .bold))
                        .foregroundColor(themeManager.accentColor)
                        .tracking(themeManager.isSapphire ? 2 : 0)

                    Text(entry.title)
                        .font(themeManager.isSapphire ? SapphireFont.headline(16) : .system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.tertiaryText)
            }
            .padding(16)
            .background {
                if themeManager.isSapphire {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AnyShapeStyle(themeManager.cardBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.strokeColor, lineWidth: 1)
                        )
                } else if themeManager.useWarmLayout {
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

// FlowLayout for wrapping member tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    NavigationView {
        AhlulbaytEntryDetailView(
            entry: AhlulbaytEntry(
                id: "ab1",
                title: "Verse of Purification (Ayat al-Tathir)",
                shortTitle: "Al-Tathir",
                category: .purity,
                verses: [
                    AhlulbaytVerse(
                        surahNumber: 33,
                        verseNumber: 33,
                        context: "Allah's declaration of the purity of the Prophet's family",
                        isPrimary: true
                    )
                ],
                ahlulbaytMembers: ["Prophet Muhammad (ﷺ)", "Imam Ali (ع)", "Lady Fatimah (ع)", "Imam Hasan (ع)", "Imam Husayn (ع)"],
                revelationContext: "This verse was revealed specifically about the five members of the Prophet's family.",
                relatedEntries: []
            )
        )
    }
}
