//
//  DuaDetailSheet.swift
//  AlBayan
//
//  Detail sheet for the Today tab's "Du'a of the Day" card.
//

import SwiftUI

struct DuaDetailSheet: View {
    let dua: DailyDua

    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(dua.category.uppercased())
                        .font(.system(size: 12, weight: .bold)).tracking(1.5)
                        .foregroundColor(themeManager.accentColor)

                    Text(dua.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(themeManager.primaryText)

                    Text(dua.arabic)
                        .font(.system(size: 26 * readingSettings.scale, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(12 * readingSettings.scale)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text(dua.transliteration)
                        .font(.system(size: 15 * readingSettings.scale, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(themeManager.secondaryText)
                        .lineSpacing(6 * readingSettings.scale)

                    Text(dua.english)
                        .font(.system(size: 16 * readingSettings.scale, weight: .regular, design: .serif))
                        .foregroundColor(themeManager.primaryText)
                        .lineSpacing(7 * readingSettings.scale)

                    Text(dua.source)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryText)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(themeManager.primaryBackground.ignoresSafeArea())
            .navigationTitle("Du'a of the Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

#Preview {
    DuaDetailSheet(dua: DailyDua(
        id: 1, title: "At iftar (breaking fast)", category: "Worship",
        arabic: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
        transliteration: "Dhahaba az-zama'u wabtallatil-'urooqu wa thabatal-ajru in sha Allah",
        english: "The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills.",
        source: "Abu Dawud 2357"))
}
