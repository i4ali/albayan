//
//  QuickOverviewView.swift
//  AlBayan
//
//  Interactive quick overview ("Gems") — Arabic verse + concept bubbles.
//
//  Large-text redesign (handoff Appendix A): the sheet is a pinned top region
//  (header + height-capped, internally-scrollable verse + gold hairline) plus a
//  swappable lower region that cross-fades between the concept-bubble grid and the
//  gem-detail pane. The verse is pinned in BOTH states, so the highlighted fragment
//  can never be covered by the explanation — at any reading-text size. This replaces
//  the old ZStack(alignment: .bottom) + padding(.bottom, 280) overlay hack.
//

import SwiftUI

// MARK: - Highlighted Arabic Text Component

struct HighlightedArabicText: View {
    let text: String
    let highlightText: String?
    let highlightColor: Color
    let isHighlighting: Bool
    var scale: CGFloat = 1.0   // reading-text-size multiplier (defaults to 1×)

    @StateObject private var themeManager = ThemeManager.shared

    private var arabicFontSize: CGFloat { 28 * scale }
    private var arabicLineSpacing: CGFloat { 12 * scale }

    // Sapphire: Amiri 30 base size (scaled)
    private var sapphireArabicFontSize: CGFloat { 30 * scale }
    private var sapphireArabicLineSpacing: CGFloat { 14 * scale }

    var body: some View {
        if let highlightText = highlightText, !highlightText.isEmpty, isHighlighting {
            // Build attributed text with highlight
            highlightedTextView(fullText: text, highlight: highlightText)
        } else {
            // Regular Arabic text
            if themeManager.isSapphire {
                Text(text)
                    .font(SapphireFont.arabic(sapphireArabicFontSize))
                    .foregroundColor(themeManager.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(sapphireArabicLineSpacing)
                    .environment(\.layoutDirection, .rightToLeft)
            } else {
                Text(text)
                    .font(.system(size: arabicFontSize, weight: .medium))
                    .foregroundColor(themeManager.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(arabicLineSpacing)
                    .environment(\.layoutDirection, .rightToLeft)
            }
        }
    }

    @ViewBuilder
    private func highlightedTextView(fullText: String, highlight: String) -> some View {
        // Split the text to find and highlight the matching portion
        let components = splitText(fullText: fullText, highlight: highlight)

        if themeManager.isSapphire {
            // Sapphire: Amiri font; highlighted keyword in accentBright
            components.reduce(Text("")) { result, component in
                if component.isHighlighted {
                    return result + Text(component.text)
                        .font(SapphireFont.arabic(sapphireArabicFontSize, bold: true))
                        .foregroundColor(themeManager.accentBright)
                } else {
                    return result + Text(component.text)
                        .font(SapphireFont.arabic(sapphireArabicFontSize))
                        .foregroundColor(themeManager.primaryText)
                }
            }
            .multilineTextAlignment(.center)
            .lineSpacing(sapphireArabicLineSpacing)
            .environment(\.layoutDirection, .rightToLeft)
        } else {
            // Use Text concatenation to preserve natural RTL text flow
            components.reduce(Text("")) { result, component in
                if component.isHighlighted {
                    return result + Text(component.text)
                        .font(.system(size: arabicFontSize, weight: .bold))
                        .foregroundColor(highlightColor)
                } else {
                    return result + Text(component.text)
                        .font(.system(size: arabicFontSize, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                }
            }
            .multilineTextAlignment(.center)
            .lineSpacing(arabicLineSpacing)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private struct TextComponent: Equatable {
        let text: String
        let isHighlighted: Bool
    }

    private func splitText(fullText: String, highlight: String) -> [TextComponent] {
        // Try to find the highlight text in the full text
        guard let range = fullText.range(of: highlight) else {
            // If not found, return the whole text unhighlighted
            return [TextComponent(text: fullText, isHighlighted: false)]
        }

        var components: [TextComponent] = []

        // Text before highlight
        let beforeText = String(fullText[..<range.lowerBound])
        if !beforeText.isEmpty {
            components.append(TextComponent(text: beforeText, isHighlighted: false))
        }

        // Highlighted text
        components.append(TextComponent(text: highlight, isHighlighted: true))

        // Text after highlight
        let afterText = String(fullText[range.upperBound...])
        if !afterText.isEmpty {
            components.append(TextComponent(text: afterText, isHighlighted: false))
        }

        return components
    }
}

struct QuickOverviewView: View {
    let verse: VerseWithTafsir
    let surah: Surah
    let quickOverview: QuickOverviewData
    let onViewFullCommentary: () -> Void

    @State private var selectedConcept: VerseConcept? = nil
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    /// The one global language — verse translation + commentary + Gems stay in lockstep.
    private var selectedLanguage: CommentaryLanguage { languageManager.selectedLanguage }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(themeManager.tertiaryText.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Pinned header
            headerView
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Pinned verse — height-capped, scrolls internally if very long.
            // Pinned in BOTH states, so a highlighted fragment is never covered.
            PinnedVerseView(
                surah: surah,
                verse: verse,
                selectedConcept: selectedConcept,
                scale: readingSettings.scale
            )
            .padding(.bottom, 4)

            // Swap area: only the region below the hairline changes.
            if let concept = selectedConcept {
                gemDetailPane(concept)
                    .transition(.opacity)
            } else {
                browseScroll
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: isIPad ? 600 : .infinity)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .animation(.easeInOut(duration: 0.2), value: readingSettings.stepIndex)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            if themeManager.isSapphire {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(themeManager.goldGradient)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(themeManager.accentGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                if themeManager.isSapphire {
                    Text("Quick Gems")
                        .font(SapphireFont.headline(26))
                        .foregroundColor(themeManager.primaryText)

                    Text("Precious insights, unveiled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                } else {
                    Text("Gems")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(themeManager.primaryText)

                    Text("Precious insights unveiled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                }
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.tertiaryText)
            }
        }
    }

    // MARK: - Browse region (bubble grid + language selector + CTA)

    private var browseScroll: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                conceptBubblesGrid
                fullTafsirButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
    }

    private var conceptBubblesGrid: some View {
        let concepts = quickOverview.concepts

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(concepts) { concept in
                ConceptBubbleView(
                    concept: concept,
                    language: selectedLanguage,
                    isSelected: selectedConcept?.id == concept.id
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selectedConcept = concept
                    }
                }
            }
        }
    }

    // MARK: - Gem detail pane (back-chip + fade-masked scroll + pinned CTA)

    private func gemDetailPane(_ concept: VerseConcept) -> some View {
        let rtl = selectedLanguage.isRTL
        let color = Color(hex: concept.colorHex)
        return VStack(spacing: 0) {
            HStack {
                BackToGemsChip {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { selectedConcept = nil }
                }
                Spacer()
            }
            .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 10) {
                        Image(systemName: concept.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : color)
                        if themeManager.isSapphire {
                            Text(concept.getTitle(language: selectedLanguage).uppercased())
                                .font(SapphireFont.eyebrow).tracking(1.5)
                                .foregroundColor(themeManager.accentColor)
                        } else {
                            Text(concept.getTitle(language: selectedLanguage).uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded)).tracking(1)
                                .foregroundColor(themeManager.primaryText)
                        }
                    }
                    detailSection(color, "The Core Insight:", concept.getCoreInsight(language: selectedLanguage), rtl: rtl)
                    detailSection(color, "Why it matters:", concept.getWhyItMatters(language: selectedLanguage), rtl: rtl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 24)
            }
            .scrollEdgeFade()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(color.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: color.opacity(0.12), radius: 10, y: 4)
            )
            .padding(.horizontal, 18)

            // The SAME "Read Full Tafsir" CTA, pinned at the bottom of the detail pane.
            fullTafsirButton
                .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func detailSection(_ color: Color, _ title: String, _ text: String, rtl: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if themeManager.isSapphire {
                Text(title.uppercased())
                    .font(SapphireFont.eyebrow).tracking(1.5)
                    .foregroundColor(themeManager.accentColor)
            } else {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            if themeManager.isSapphire {
                Text(text)
                    // Cormorant is Latin-only; for RTL languages (Urdu/Arabic) fall back to the
                    // native system font at a larger size + looser line-spacing so it reads cleanly.
                    .font(
                        rtl
                            ? .system(size: 18 * readingSettings.scale, weight: .regular)
                            : SapphireFont.serif(19 * readingSettings.scale, semibold: false)
                    )
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing((rtl ? 11 : 7) * readingSettings.scale)
                    .multilineTextAlignment(rtl ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: rtl ? .trailing : .leading)
                    .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            } else {
                Text(text)
                    .font(.system(size: 15 * readingSettings.scale, weight: .regular, design: .serif))   // scales
                    .foregroundColor(themeManager.primaryText)
                    .lineSpacing(7 * readingSettings.scale)
                    .multilineTextAlignment(rtl ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: rtl ? .trailing : .leading)
                    .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            }
        }
    }

    // MARK: - Full Tafsir Button

    private var fullTafsirButton: some View {
        Button(action: {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onViewFullCommentary()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text("Read Full Tafsir")
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                themeManager.isSapphire
                ? RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.goldGradient)
                    .shadow(color: themeManager.goldButtonShadow, radius: 12)
                : RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.purpleGradient)
                    .shadow(color: themeManager.accentColor.opacity(0.3), radius: 12)
            )
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        themeManager.primaryBackground
        .ignoresSafeArea()
    }
}

// MARK: - Pinned Verse (height-capped, internally scrollable)

private struct VerseHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct PinnedVerseView: View {
    let surah: Surah
    let verse: VerseWithTafsir
    let selectedConcept: VerseConcept?
    let scale: CGFloat

    @StateObject private var themeManager = ThemeManager.shared
    @State private var verseHeight: CGFloat = 0
    private let maxVerseHeight: CGFloat = 230

    private var highlightColor: Color {
        selectedConcept.map { Color(hex: $0.colorHex) } ?? themeManager.accentColor
    }

    var body: some View {
        VStack(spacing: 12) {
            if themeManager.isSapphire {
                Text("\(surah.englishName.uppercased()) · \(verse.number)")
                    .font(SapphireFont.eyebrow).tracking(3)
                    .foregroundColor(themeManager.accentColor)
            } else {
                Text("\(surah.englishName.uppercased()) · \(verse.number)")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundColor(themeManager.accentColor)
            }

            ScrollView(.vertical, showsIndicators: false) {
                HighlightedArabicText(
                    text: verse.arabicText,
                    highlightText: selectedConcept?.arabicHighlight,
                    highlightColor: highlightColor,
                    isHighlighting: selectedConcept != nil,
                    scale: scale
                )
                .frame(maxWidth: .infinity).padding(.vertical, 2)
                .background(GeometryReader { g in
                    Color.clear.preference(key: VerseHeightKey.self, value: g.size.height)
                })
            }
            .frame(height: min(max(verseHeight, 1), maxVerseHeight))   // hug content, cap at 230
            .onPreferenceChange(VerseHeightKey.self) { verseHeight = $0 }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeManager.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(highlightColor.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: highlightColor.opacity(0.1), radius: 8, y: 3)
        )
        .padding(.horizontal, 18).padding(.top, 2)
    }
}

// MARK: - Concept Bubble View

struct ConceptBubbleView: View {
    let concept: VerseConcept
    let language: CommentaryLanguage
    let isSelected: Bool
    let onTap: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    private var bubbleColor: Color {
        Color(hex: concept.colorHex)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: concept.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.isSapphire
                        ? (isSelected ? themeManager.accentBright : themeManager.secondaryText)
                        : bubbleColor)

                Text(concept.getTitle(language: language))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.isSapphire
                        ? (isSelected ? themeManager.accentBright : themeManager.secondaryText)
                        : themeManager.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                themeManager.isSapphire
                ? Capsule()
                    .fill(isSelected ? themeManager.goldChipFill : themeManager.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? themeManager.accentColor : themeManager.strokeColor,
                                    lineWidth: isSelected ? 1.5 : 1)
                    )
                : Capsule()
                    .fill(themeManager.glassEffect)
                    .overlay(
                        Capsule()
                            .stroke(bubbleColor.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: themeManager.isSapphire
                ? (isSelected ? themeManager.accentColor.opacity(0.2) : Color.clear)
                : bubbleColor.opacity(0.2),
                    radius: isSelected ? 8 : 4)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Back-to-gems chip

private struct BackToGemsChip: View {
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.accentColor)
                Text("Back to gems")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
            }
            .padding(.leading, 12).padding(.trailing, 15).padding(.vertical, 9)
            .background(
                Capsule().fill(themeManager.glassEffect)
                    .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scroll edge fade

private extension View {
    /// Softly fades the top & bottom edges of a scroll region (masks to transparent,
    /// revealing the background) so content dissolves instead of hard-clipping.
    func scrollEdgeFade(top: CGFloat = 14, bottom: CGFloat = 30) -> some View {
        self.mask(
            GeometryReader { geo in
                let h = max(geo.size.height, 1)
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: min(top / h, 0.5)),
                    .init(color: .black, location: 1 - min(bottom / h, 0.5)),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
        )
    }
}
