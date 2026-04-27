//
//  RosewaterSurahDetailView.swift
//  AlBayan
//
//  Standalone mockup of the Surah Detail screen in the Rosewater theme
//  (design_handoff_rosewater_theme/). Hardcoded sample data — not wired
//  to ThemeManager or DataManager. For visual iteration only.
//

import SwiftUI

// MARK: - Palette (Rosewater)

private enum RW {
    static let bg         = Color(red: 0.992, green: 0.953, blue: 0.949) // #FDF3F2
    static let card       = Color(red: 1.000, green: 0.988, blue: 0.988) // #FFFCFC
    static let cardMuted  = Color(red: 0.969, green: 0.902, blue: 0.894) // #F7E6E4

    static let text1      = Color(red: 0.227, green: 0.165, blue: 0.165) // #3A2A2A
    static let text2      = Color(red: 0.486, green: 0.369, blue: 0.361) // #7C5E5C
    static let text3      = Color(red: 0.761, green: 0.663, blue: 0.655) // #C2A9A7

    static let purple     = Color(red: 0.663, green: 0.549, blue: 0.710) // #A98CB5 dusty rose
    static let purpleDeep = Color(red: 0.576, green: 0.471, blue: 0.631) // #9378A1
    static let purpleSoft = Color(red: 0.945, green: 0.910, blue: 0.945) // #F1E8F1

    static let rose       = Color(red: 0.847, green: 0.514, blue: 0.502) // #D88380 rose clay
    static let roseDeep   = Color(red: 0.749, green: 0.420, blue: 0.408) // #BF6B68
    static let roseSoft   = Color(red: 0.973, green: 0.871, blue: 0.863) // #F8DEDC

    static let sage       = Color(red: 0.624, green: 0.725, blue: 0.596) // #9FB998

    static let divider    = Color(red: 120/255, green: 60/255, blue: 60/255).opacity(0.10)

    static let purpleGradient = LinearGradient(
        colors: [purple, purpleDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let roseGradient = LinearGradient(
        colors: [rose, roseDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Sample data

struct RWVerse: Identifiable {
    let id: Int
    let arabic: String
    let english: String
}

private let sampleVerses: [RWVerse] = [
    RWVerse(id: 1,
            arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
            english: "In the name of Allah, the Entirely Merciful, the Especially Merciful."),
    RWVerse(id: 2,
            arabic: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
            english: "[All] praise is [due] to Allah, Lord of the worlds."),
    RWVerse(id: 3,
            arabic: "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
            english: "The Entirely Merciful, the Especially Merciful."),
    RWVerse(id: 4,
            arabic: "مَٰلِكِ يَوْمِ ٱلدِّينِ",
            english: "Sovereign of the Day of Recompense."),
    RWVerse(id: 5,
            arabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
            english: "It is You we worship and You we ask for help."),
    RWVerse(id: 6,
            arabic: "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
            english: "Guide us to the straight path."),
    RWVerse(id: 7,
            arabic: "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
            english: "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.")
]

// MARK: - Main view

struct RosewaterSurahDetailView: View {
    var body: some View {
        ZStack {
            RW.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    backChip
                    heroCard
                    versesList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: Back chip

    private var backChip: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(RW.text1)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(RW.cardMuted)
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: Hero card

    private var heroCard: some View {
        VStack(spacing: 0) {
            Text("سُورَةُ ٱلْفَاتِحَةِ")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(RW.text1)
                .lineSpacing(4)
                .multilineTextAlignment(.center)

            Text("The Opening")
                .font(.system(size: 18, weight: .regular, design: .rounded).italic())
                .foregroundColor(RW.text2)
                .padding(.top, 10)

            HStack(spacing: 18) {
                Label("7 verses", systemImage: "book")
                Label("Meccan", systemImage: "mappin.and.ellipse")
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(RW.purple)
            .padding(.top, 14)

            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Play Sequence")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(RW.roseGradient)
                .clipShape(Capsule())
                .shadow(color: RW.rose.opacity(0.38), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(RW.card)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: Verses

    private var versesList: some View {
        VStack(spacing: 14) {
            ForEach(sampleVerses) { verse in
                RWVerseCard(verse: verse)
            }
        }
    }
}

// MARK: - Verse card

private struct RWVerseCard: View {
    let verse: RWVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text("\(verse.id)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(RW.purple)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle().stroke(RW.purple, lineWidth: 2)
                    )

                Spacer()

                HStack(spacing: 10) {
                    RWIconCircle(bg: RW.purpleSoft, tint: RW.purple, systemName: "play.fill")
                    RWIconCircle(bg: RW.roseSoft, tint: RW.rose, systemName: "heart")
                }
            }

            // Arabic
            Text(verse.arabic)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(RW.text1)
                .lineSpacing(14)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.top, 14)

            // English
            Text(verse.english)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(RW.text1)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            // Commentary pill
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("View Commentary")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(RW.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RW.purpleSoft)
            )
            .padding(.top, 14)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(RW.card)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Small icon circle

private struct RWIconCircle: View {
    let bg: Color
    let tint: Color
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 30, height: 30)
            .background(Circle().fill(bg))
    }
}

// MARK: - Preview

#Preview {
    RosewaterSurahDetailView()
}
