//
//  SurahExperienceCatalog.swift
//  AlBayan
//
//  Static registry of the immersive "Inside the Surah" experiences, shown in the
//  Journeys hub and surfaced as a Read | Journey strip on the matching surah's card
//  in the Quran tab. Mirrors JourneyCatalog's shape; an experience is available or
//  coming soon. All are premium-gated except al-Fatiha, the free flagship teaser
//  (PremiumManager.canAccessSurahExperience). English-first; ur/ar come later.
//

import SwiftUI

/// One surah experience in the hub. Static registry - see `SurahExperienceDescriptor.all`.
struct SurahExperienceDescriptor: Identifiable {
    /// Stable id - also the deep-link id (DeepLinkRouter.pendingSurahExperienceId).
    let id: String
    /// The surah this experience belongs to - drives the list-row strip lookup.
    let surahNumber: Int
    let title: LocalizedText
    let titleAr: String
    let sfSymbol: String
    let subtitle: LocalizedText
    /// True when the experience is built and openable. False = "coming soon".
    let available: Bool
    /// The experience content, present only when `available`.
    let dive: DeepDive?
    /// Cover art (Assets.xcassets, `CoverSurah%03d`); nil = SF Symbol fallback.
    var coverAssetName: String? = nil

    static let all: [SurahExperienceDescriptor] = [
        SurahExperienceDescriptor(
            id: "surah-fatiha",
            surahNumber: 1,
            title: "Surah al-Fatiha",
            titleAr: "الْفَاتِحَة",
            sfSymbol: "book.closed",
            subtitle: "The Opening - the prayer beneath every prayer",
            available: true, dive: .surahFatiha,
            coverAssetName: "CoverSurah001"
        ),
        SurahExperienceDescriptor(
            id: "surah-baqara",
            surahNumber: 2,
            title: "Surah al-Baqara",
            titleAr: "الْبَقَرَة",
            sfSymbol: "hands.sparkles.fill",
            subtitle: "The Cow - a mirror inside the mightiest surah",
            available: true, dive: .surahBaqara,
            coverAssetName: "CoverSurah002"
        ),
        SurahExperienceDescriptor(
            id: "surah-ali-imran",
            surahNumber: 3,
            title: "Surah Al Imran",
            titleAr: "آلِ عِمْرَان",
            sfSymbol: "person.3.sequence.fill",
            subtitle: "The Family of Imran - a chosen house and the covenant it carried",
            available: false, dive: nil,
            coverAssetName: "CoverSurah003"
        ),
        SurahExperienceDescriptor(
            id: "surah-nisa",
            surahNumber: 4,
            title: "Surah al-Nisa",
            titleAr: "النِّسَاء",
            sfSymbol: "figure.2.and.child.holdinghands",
            subtitle: "The Women - one trust, from the orphan's coin to the seat of justice",
            available: false, dive: nil,
            coverAssetName: "CoverSurah004"
        ),
        SurahExperienceDescriptor(
            id: "surah-yusuf",
            surahNumber: 12,
            title: "Surah Yusuf",
            titleAr: "يُوسُف",
            sfSymbol: "moon.stars",
            subtitle: "The most beautiful of stories - loss, patience, reunion",
            available: false, dive: nil,
            coverAssetName: "CoverSurah012"
        ),
        SurahExperienceDescriptor(
            id: "surah-rahman",
            surahNumber: 55,
            title: "Surah al-Rahman",
            titleAr: "الرَّحْمَٰن",
            sfSymbol: "water.waves",
            subtitle: "One question, asked again and again",
            available: false, dive: nil,
            coverAssetName: "CoverSurah055"
        ),
    ]

    static func byId(_ id: String) -> SurahExperienceDescriptor? { all.first { $0.id == id } }
    static func bySurahNumber(_ n: Int) -> SurahExperienceDescriptor? { all.first { $0.surahNumber == n } }
}
