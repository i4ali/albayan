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

    // MARK: Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                hijriPill
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assalāmu 'alaykum 👋")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                    Text("Today")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                }
                reminderCard
                continueReadingSection
                duaSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
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
            .font(.system(size: 12, weight: .bold)).tracking(1)
            .foregroundColor(themeManager.secondaryText)
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
                        .font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(.white.opacity(0.85))
                    Text("\u{201C}\(verse.translation(for: languageManager.selectedLanguage))\u{201D}")
                        .font(.system(size: 19 * readingSettings.scale, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .lineSpacing(6 * readingSettings.scale)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(dataManager.getSurah(number: entry.surah)?.surah.englishName ?? "") · \(entry.surah):\(entry.verse)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(
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
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: Continue reading

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTINUE READING")
                .font(.system(size: 12, weight: .bold)).tracking(1)
                .foregroundColor(themeManager.tertiaryText)

            VStack(alignment: .leading, spacing: 14) {
                Text(hasResume ? "Continue reading" : "Start your journey")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.primaryText)
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(themeManager.purpleGradient)
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10, y: 4)
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
                    .font(.system(size: 12, weight: .bold)).tracking(1)
                    .foregroundColor(themeManager.tertiaryText)

                Button { presentedDua = dua } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(themeManager.accentColor.opacity(0.15)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dua.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeManager.primaryText)
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
