//
//  SapphireHomeView.swift
//  AlBayan
//
//  Royal Sapphire Home / Read screen (Task F).
//  Mirrors SC01_Home from design_handoff_royal_sapphire/design-files/sapphire.jsx.
//  Data + navigation wired identically to HomeView.swift (DataManager, ProgressManager,
//  @AppStorage last-read, .navigateToVerse deep-link, SettingsView sheet).
//

import SwiftUI

// MARK: - SapphireHomeView

struct SapphireHomeView: View {

    // MARK: Dependencies
    @StateObject private var dataManager      = DataManager.shared
    @StateObject private var themeManager     = ThemeManager.shared
    @StateObject private var progressManager  = ProgressManager.shared

    // MARK: Last-read (same keys used by SurahDetailView and TodayView)
    @AppStorage("lastReadSurah") private var lastReadSurah = 0
    @AppStorage("lastReadVerse") private var lastReadVerse = 0

    // MARK: State
    @State private var searchText              = ""
    @State private var showingSettings         = false
    @State private var selectedSurahForDeepLink: SurahWithTafsir?
    @State private var targetVerseNumber: Int?

    // MARK: Derived: continue-reading

    private var hasResume: Bool { lastReadSurah > 0 }

    private var resumeSurah: SurahWithTafsir? {
        guard hasResume else { return nil }
        return dataManager.getSurah(number: lastReadSurah)
    }

    private var resumeSurahName: String {
        resumeSurah?.surah.englishName ?? "Al-Fātiḥah"
    }

    private var resumeSurahArabic: String {
        resumeSurah?.surah.arabicName ?? "الفاتحة"
    }

    private var resumeSurahNumber: Int {
        resumeSurah?.surah.number ?? 1
    }

    private var resumeTotalVerses: Int {
        resumeSurah?.surah.versesCount ?? 7
    }

    private var resumeProgressFraction: Double {
        guard resumeTotalVerses > 0 else { return 0 }
        let (read, total) = progressManager.getSurahCompletion(surahNumber: resumeSurahNumber)
        guard total > 0 else { return 0 }
        return Double(read) / Double(total)
    }

    private var resumeProgressPct: Int {
        Int(resumeProgressFraction * 100)
    }

    // MARK: Derived: filtered surah list

    private var filteredSurahs: [SurahWithTafsir] {
        guard !searchText.isEmpty else { return dataManager.availableSurahs }
        return dataManager.availableSurahs.filter { s in
            s.surah.englishName.localizedCaseInsensitiveContains(searchText) ||
            s.surah.englishNameTranslation.localizedCaseInsensitiveContains(searchText) ||
            s.surah.arabicName.contains(searchText)
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            SpShell {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBarRow
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 14)

                        SpHeading(eyebrow: "The Noble Qur'an", title: "Read & Reflect")
                            .padding(.horizontal, 20)

                        continueCard
                            .padding(.horizontal, 20)
                            .padding(.top, 18)

                        searchField
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        SpDivider(label: "114 Surahs")
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                            .padding(.bottom, 14)

                        surahList
                            .padding(.horizontal, 20)

                        // Floating tab-bar clearance
                        Color.clear.frame(height: 96)
                    }
                }
            }
            .navigationBarHidden(true)
            // Deep-link: push SurahDetailView programmatically
            .navigationDestination(isPresented: Binding(
                get: { selectedSurahForDeepLink != nil },
                set: { if !$0 { selectedSurahForDeepLink = nil; targetVerseNumber = nil } }
            )) {
                if let surah = selectedSurahForDeepLink {
                    SurahDetailView(surahWithTafsir: surah, targetVerse: targetVerseNumber)
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        // "showSettings" notification (same as HomeView)
        .onReceive(NotificationCenter.default.publisher(for: .init("showSettings"))) { _ in
            showingSettings = true
        }
        // Deep-link notification (same as HomeView)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVerse)) { notification in
            guard let userInfo = notification.userInfo,
                  let surahNum = userInfo["surah"] as? Int,
                  let verseNum = userInfo["verse"] as? Int else { return }
            showingSettings = false
            if let surahData = dataManager.availableSurahs.first(where: { $0.surah.number == surahNum }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    targetVerseNumber = verseNum
                    selectedSurahForDeepLink = surahData
                }
            }
        }
    }

    // MARK: - Top Bar Row

    // Greeting (avatar + "Assalāmu ʿalaykum" + name) intentionally lives only on the Today
    // tab; here we keep just the streak pill + Settings bell, right-aligned.
    private var topBarRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Spacer()
            // Streak pill
            streakPill
            // Bell / Settings button
            bellButton
        }
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.accentColor)
            Text("\(progressManager.stats.currentStreak)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(themeManager.primaryText)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(themeManager.cardBackground))
        .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
    }

    private var bellButton: some View {
        Button { showingSettings = true } label: {
            Image(systemName: "bell")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(themeManager.secondaryText)
                .frame(width: 36, height: 36)
                .background(Circle().fill(themeManager.cardBackground))
                .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .buttonStyle(SpPressStyle())
    }

    // MARK: - Continue Reading Card

    private var continueCard: some View {
        SpCard(glow: true) {
            ZStack(alignment: .topTrailing) {
                // Faint Arabic numeral watermark (nice-to-have)
                Text("\(resumeSurahNumber)")
                    .font(SapphireFont.arabic(96))
                    .foregroundColor(themeManager.accentColor.opacity(0.08))
                    .offset(x: 10, y: -30)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    // Eyebrow
                    Text("CONTINUE READING")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(themeManager.accentColor)

                    // Surah name
                    Text(hasResume ? resumeSurahName : "Al-Fātiḥah")
                        .font(SapphireFont.headline(27))
                        .foregroundColor(themeManager.primaryText)
                        .padding(.top, 8)
                        .lineLimit(1)

                    // Verse count + pct
                    Group {
                        if hasResume {
                            Text("Verse \(lastReadVerse) of \(resumeTotalVerses) · \(resumeProgressPct)% complete")
                        } else {
                            Text("Start your journey · Open Surah Al-Fātiḥah")
                        }
                    }
                    .font(.system(size: 12.5))
                    .foregroundColor(themeManager.secondaryText)
                    .padding(.top, 3)

                    // Gold progress track
                    progressTrack
                        .padding(.top, 14)

                    // Resume CTA
                    SpGoldCTA(
                        title: hasResume ? "Resume" : "Begin",
                        systemIcon: "play.fill",
                        small: true
                    ) {
                        let surah = hasResume ? lastReadSurah : 1
                        let verse = hasResume ? lastReadVerse : 1
                        NotificationCenter.default.post(
                            name: .navigateToVerse, object: nil,
                            userInfo: ["surah": surah, "verse": verse]
                        )
                    }
                    .padding(.top, 15)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipped()
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 4)
                // Fill
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(themeManager.goldGradient)
                    .frame(width: max(4, geo.size.width * resumeProgressFraction), height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(themeManager.accentColor)
            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search surahs, verses, themes…")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.tertiaryText)
                }
                .font(.system(size: 14))
                .foregroundColor(themeManager.primaryText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeManager.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(themeManager.strokeColor, lineWidth: 1)
        )
    }

    // MARK: - Surah List

    private var surahList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredSurahs) { surahWithTafsir in
                NavigationLink(destination: SurahDetailView(surahWithTafsir: surahWithTafsir, targetVerse: nil)) {
                    surahRow(surahWithTafsir)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func surahRow(_ item: SurahWithTafsir) -> some View {
        let surah = item.surah
        let (read, total) = progressManager.getSurahCompletion(surahNumber: surah.number)
        let pct = total > 0 ? Int(Double(read) / Double(total) * 100) : 0

        return SpCard {
            HStack(alignment: .center, spacing: 14) {
                // Numeral circle
                SpNumeral(n: "\(surah.number)", size: 42)

                // Middle column
                VStack(alignment: .leading, spacing: 2) {
                    // English name
                    Text(surah.englishName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                        .lineLimit(1)
                    // Transliteration (English name translation)
                    Text(surah.englishNameTranslation)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.tertiaryText)
                        .lineLimit(1)
                    // Meta row
                    HStack(spacing: 12) {
                        Text("\(surah.versesCount) verses")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.secondaryText)
                        Text(surah.revelationType.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.secondaryText)
                        if pct > 0 {
                            Text("\(pct)%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)

                // Arabic name (right-aligned)
                Text(surah.arabicName)
                    .font(SapphireFont.arabic(24))
                    .foregroundColor(themeManager.accentBright)
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - TextField placeholder helper

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

#Preview {
    SapphireHomeView()
}
