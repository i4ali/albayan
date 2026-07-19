//
//  TodayView.swift
//  AlBayan
//
//  "Today" dashboard: Hijri date, daily reminder verse, resume-reading, daily du'a.
//  Light-themed; reuses ProfileAvatar / NotificationBell and existing managers.
//

import SwiftUI

struct TodayView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var readingSettings = ReadingSettingsManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var dataManager = DataManager.shared

    @AppStorage("lastReadSurah") private var lastReadSurah = 0
    @AppStorage("lastReadVerse") private var lastReadVerse = 0
    @AppStorage("userName") private var userName = ""

    @State private var showingNotifications = false
    @State private var todayDua: DailyDua?
    @State private var presentedDua: DailyDua?

    private let calendarManager = IslamicCalendarManager.shared
    private let duaManager = DailyDuaManager.shared

    // MARK: Derived data

    private var hijriPillText: String {
        let day = calendarManager.currentIslamicDay()
        let month = calendarManager.monthName(for: calendarManager.currentIslamicMonth()).uppercased()
        let weekday = String(calendarManager.islamicDayOfWeek().prefix(3)).uppercased()
        return "\(day) \(month) · \(weekday)"
    }

    private var verseEntry: DailyVerseEntry? { NotificationManager.shared.selectTodayVerse() }
    private var todayVerse: VerseWithTafsir? {
        guard let e = verseEntry else { return nil }
        return dataManager.getVerse(surah: e.surah, verse: e.verse)
    }

    private var hasResume: Bool { lastReadSurah > 0 }
    private var resumeSurahName: String {
        dataManager.getSurah(number: lastReadSurah)?.surah.englishName ?? "Al-Fātiḥa"
    }

    /// Greeting that appends the onboarding name when set (falls back cleanly when blank).
    private var greetingText: String {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = "Assalāmu 'alaykum"
        return name.isEmpty ? "\(base) 👋" : "\(base), \(name) 👋"
    }

    // MARK: Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                hijriPill
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                    if themeManager.isSapphire {
                        Text("Today")
                            .font(SapphireFont.screenTitle)
                            .foregroundColor(themeManager.primaryText)
                    } else {
                        Text("Today")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(themeManager.primaryText)
                    }
                }
                reminderCard
                continueReadingSection
                duaSection
                DailyChallengeCard()
                DailyCrosswordCard()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .onAppear { todayDua = duaManager.selectTodayDua() }
        .sheet(isPresented: $showingNotifications) { NotificationsView() }
        .sheet(item: $presentedDua) { DuaDetailSheet(dua: $0) }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            ProfileAvatar()
            Spacer()
            NotificationBell(showingNotifications: $showingNotifications)
        }
    }

    private var hijriPill: some View {
        Text(hijriPillText)
            .font(themeManager.isSapphire
                  ? SapphireFont.eyebrow
                  : .system(size: 12, weight: .bold))
            .tracking(themeManager.isSapphire ? 2.5 : 1)
            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                Capsule().fill(themeManager.cardBackground)
                    .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
            )
    }

    // MARK: Reminder hero card

    @ViewBuilder
    private var reminderCard: some View {
        if let entry = verseEntry, let verse = todayVerse {
            Button {
                NotificationCenter.default.post(name: .navigateToVerse, object: nil,
                                                userInfo: ["surah": entry.surah, "verse": entry.verse])
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("✦ A REMINDER FOR TODAY")
                        .font(themeManager.isSapphire
                              ? SapphireFont.eyebrow
                              : .system(size: 12, weight: .bold))
                        .tracking(themeManager.isSapphire ? 2.5 : 1)
                        .foregroundColor(themeManager.isSapphire
                                         ? themeManager.accentColor
                                         : .white.opacity(0.85))
                    Text("\u{201C}\(verse.translation(for: languageManager.selectedLanguage))\u{201D}")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(22, semibold: false)
                              : .system(size: 19 * readingSettings.scale, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .lineSpacing(6 * readingSettings.scale)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(dataManager.getSurah(number: entry.surah)?.surah.englishName ?? "") · \(entry.surah):\(entry.verse)")
                        .font(themeManager.isSapphire
                              ? SapphireFont.eyebrow
                              : .system(size: 13, weight: .medium))
                        .tracking(themeManager.isSapphire ? 2 : 0)
                        .foregroundColor(themeManager.isSapphire
                                         ? themeManager.accentColor
                                         : .white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                // Sapphire hero needs vertical room for the art even when the verse is short.
                .frame(minHeight: themeManager.isSapphire ? 136 : nil, alignment: .leading)
                .background(reminderCardBackground)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    /// Background for the reminder hero card. Sapphire gets the seasonal art band
    /// (premium-art doc 01-B): a full-bleed cover over `heroBase`, two scrims for
    /// legibility, and a hairline accent border. Legacy themes keep the flat gradient.
    @ViewBuilder
    private var reminderCardBackground: some View {
        if themeManager.isSapphire {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(themeManager.heroBase)
                .overlay {
                    Image(seasonalHeroAsset)
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    // Scrim 1: horizontal legibility wash, text side -> focal side.
                    LinearGradient(stops: [
                        .init(color: .black.opacity(0.88), location: 0.00),
                        .init(color: .black.opacity(0.60), location: 0.38),
                        .init(color: .black.opacity(0.16), location: 0.64),
                        .init(color: .clear,               location: 0.84),
                    ], startPoint: .leading, endPoint: .trailing)
                }
                .overlay {
                    // Scrim 2: bottom anchor back into heroBase.
                    LinearGradient(colors: [themeManager.heroBase.opacity(0.5), .clear],
                                   startPoint: .bottom, endPoint: .center)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(themeManager.accentColor.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.42), radius: 20, y: 10)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(themeManager.reminderGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.22), Color.clear],
                                center: .topTrailing, startRadius: 0, endRadius: 260
                            )
                        )
                        .blendMode(.softLight)
                )
                .shadow(color: themeManager.accentColorDark.opacity(0.35), radius: 16, y: 8)
        }
    }

    /// Seasonal Today hero (premium-art doc 01-B), selected from the Hijri month to
    /// mirror the app's journey windows: Ramadan (month 9), Dhul-Hijjah/Hajj (month 12),
    /// everyday otherwise.
    private var seasonalHeroAsset: String {
        if calendarManager.isRamadan() { return "TodayHeroRamadan" }
        if calendarManager.isDhulHijjah() { return "TodayHeroHajj" }
        return "TodayHeroEveryday"
    }

    // MARK: Continue reading

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTINUE READING")
                .font(themeManager.isSapphire
                      ? SapphireFont.eyebrow
                      : .system(size: 12, weight: .bold))
                .tracking(themeManager.isSapphire ? 2.5 : 1)
                .foregroundColor(themeManager.isSapphire
                                 ? themeManager.accentColor
                                 : themeManager.tertiaryText)

            VStack(alignment: .leading, spacing: 14) {
                if themeManager.isSapphire {
                    Text(hasResume ? "Continue reading" : "Start your journey")
                        .font(SapphireFont.headline(21))
                        .foregroundColor(themeManager.primaryText)
                } else {
                    Text(hasResume ? "Continue reading" : "Start your journey")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                }
                Text(hasResume ? "Surah \(resumeSurahName), verse \(lastReadVerse)" : "Open Surah Al-Fātiḥa")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)

                Button {
                    let surah = hasResume ? lastReadSurah : 1
                    let verse = hasResume ? lastReadVerse : 1
                    NotificationCenter.default.post(name: .navigateToVerse, object: nil,
                                                    userInfo: ["surah": surah, "verse": verse])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 14, weight: .semibold))
                        Text(hasResume ? "Continue" : "Begin").font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Group {
                            if themeManager.isSapphire {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(themeManager.goldGradient)
                                    .shadow(color: Color(red: 217/255, green: 192/255, blue: 121/255).opacity(0.24), radius: 14, y: 5)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(themeManager.reminderGradient)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color.white.opacity(0.22), Color.clear],
                                                    center: .topTrailing, startRadius: 0, endRadius: 180
                                                )
                                            )
                                            .blendMode(.softLight)
                                    )
                                    .shadow(color: themeManager.accentColorDark.opacity(0.35), radius: 12, y: 5)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeManager.strokeColor, lineWidth: 1))
            )
        }
    }

    // MARK: Du'a of the day

    @ViewBuilder
    private var duaSection: some View {
        if let dua = todayDua {
            VStack(alignment: .leading, spacing: 10) {
                Text("DU'A OF THE DAY")
                    .font(themeManager.isSapphire
                          ? SapphireFont.eyebrow
                          : .system(size: 12, weight: .bold))
                    .tracking(themeManager.isSapphire ? 2.5 : 1)
                    .foregroundColor(themeManager.isSapphire
                                     ? themeManager.accentColor
                                     : themeManager.tertiaryText)

                Button { presentedDua = dua } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.isSapphire
                                             ? themeManager.accentBright
                                             : themeManager.accentColor)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(themeManager.isSapphire
                                                      ? themeManager.goldChipFill
                                                      : themeManager.accentColor.opacity(0.15)))
                        VStack(alignment: .leading, spacing: 3) {
                            if themeManager.isSapphire {
                                Text(dua.title)
                                    .font(SapphireFont.headline(16))
                                    .foregroundColor(themeManager.primaryText)
                            } else {
                                Text(dua.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.primaryText)
                            }
                            Text(dua.category)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(themeManager.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.tertiaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(themeManager.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(themeManager.strokeColor, lineWidth: 1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    TodayView()
}
