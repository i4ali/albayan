//
//  ProgressManager.swift
//  AlBayan
//
//  SwiftData-backed reading progress, streaks, and badges with CloudKit sync.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ProgressManager: ObservableObject {
    static let shared = ProgressManager()

    // MARK: - Published Properties

    @Published var verseProgress: [VerseProgress] = []
    @Published var streak: ReadingStreak = ReadingStreak()  // placeholder; replaced after bind()
    @Published var badges: [BadgeAward] = []
    @Published var stats: ProgressStats = ProgressStats()
    @Published var preferences: ProgressPreferences = ProgressPreferences()
    @Published var pendingBadge: BadgeAward? = nil // For showing badge celebration

    private var modelContext: ModelContext!
    private var hasBound = false

    // MARK: - Initialization

    private init() {}

    /// Called once at app launch from AlBayanApp before any UI accesses the manager.
    /// Idempotent — guarded so a `.task` re-fire doesn't double-register the remote-change observer.
    func bind(to context: ModelContext) {
        guard !hasBound else { return }
        hasBound = true
        self.modelContext = context
        ensureSingletons()
        refresh()
        observeRemoteChanges()

        // Update today's verse count and streak on load
        updateTodayVersesCount()
        updateStreakOnLoad()

        print("📊 ProgressManager: \(verseProgress.count) verses, \(badges.count) badges, streak=\(streak.currentStreak)")
    }

    // MARK: - Refresh / singletons

    private func refresh() {
        guard modelContext != nil else { return }
        do {
            verseProgress = try modelContext.fetch(FetchDescriptor<VerseProgress>())
            badges = try modelContext.fetch(FetchDescriptor<BadgeAward>())
            if let s = try modelContext.fetch(FetchDescriptor<ReadingStreak>()).first { streak = s }
            if let st = try modelContext.fetch(FetchDescriptor<ProgressStats>()).first { stats = st }
            if let p = try modelContext.fetch(FetchDescriptor<ProgressPreferences>()).first { preferences = p }
        } catch {
            print("⚠️ ProgressManager refresh failed: \(error)")
        }
    }

    private func ensureSingletons() {
        guard modelContext != nil else { return }
        consolidate(ReadingStreak.self) { ReadingStreak() }
        consolidate(ProgressStats.self) { ProgressStats() }
        consolidate(ProgressPreferences.self) { ProgressPreferences() }
        try? modelContext.save()
    }

    private func consolidate<T: PersistentModel>(_ type: T.Type, factory: () -> T) {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<T>())
            if existing.isEmpty {
                modelContext.insert(factory())
            } else if existing.count > 1 {
                // Keep first, delete rest. (For ReadingStreak/ProgressStats/Preferences,
                // a more sophisticated "keep latest updatedAt" can be added later if needed.)
                for instance in existing.dropFirst() { modelContext.delete(instance) }
            }
        } catch {
            print("⚠️ consolidate(\(type)) failed: \(error)")
        }
    }

    private func observeRemoteChanges() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func save() {
        try? modelContext.save()
    }

    // MARK: - Verse Progress Tracking

    @discardableResult
    func markVerseAsRead(surahNumber: Int, verseNumber: Int) -> Bool {
        guard surahNumber > 0 && surahNumber <= 114 else { return false }

        let verseKey = "\(surahNumber):\(verseNumber)"

        // Check if already marked
        var isNewRead = false
        if let existing = verseProgress.first(where: { $0.verseKey == verseKey }) {
            // Update existing
            existing.surahNumber = surahNumber
            existing.verseNumber = verseNumber
            existing.readDate = Date()
            existing.isRead = true
        } else {
            // Add new
            let progress = VerseProgress(
                surahNumber: surahNumber,
                verseNumber: verseNumber
            )
            modelContext.insert(progress)
            verseProgress.append(progress)
            isNewRead = true
        }

        // Update stats
        stats.totalVersesRead = verseProgress.filter { $0.isRead }.count
        updateTodayVersesCount()
        stats.lastReadDate = Date()
        stats.lastUpdated = Date()

        // Award sawab for verse reading (10 sawab per verse, based on hadith)
        if isNewRead {
            stats.totalSawab += 10
            print("✨ ProgressManager: +10 sawab earned! Total: \(stats.totalSawab)")
        }

        // Update streak
        updateStreak()

        // Check for surah completion and badges
        checkSurahCompletion(surahNumber: surahNumber)

        // Save changes
        save()
        refresh()

        // Re-arm motivational notifications around the new reading state
        rearmProgressNotifications(forSurah: surahNumber)

        print("✅ ProgressManager: Marked verse \(verseKey) as read")
        return true
    }

    /// Push the streak reminder and gentle nudge forward (each read replaces the
    /// pending request), and arm a near-completion encouragement when the user
    /// stops within a few verses of finishing a surah.
    private func rearmProgressNotifications(forSurah surahNumber: Int) {
        guard preferences.notificationsEnabled else { return }

        let completion = getSurahCompletion(surahNumber: surahNumber)
        let remaining = completion.total - completion.read
        let surahName = DataManager.shared.getSurah(number: surahNumber)?.surah.englishName

        Task {
            await NotificationManager.shared.scheduleStreakReminder()
            await NotificationManager.shared.scheduleGentleNudge()

            if remaining > 0, remaining <= 3, let surahName {
                await NotificationManager.shared.scheduleNearCompletionEncouragement(
                    surahNumber: surahNumber,
                    surahName: surahName,
                    versesRemaining: remaining
                )
            }
        }
    }

    @discardableResult
    func unmarkVerseAsRead(surahNumber: Int, verseNumber: Int) -> Bool {
        guard surahNumber > 0 && surahNumber <= 114 else { return false }

        let verseKey = "\(surahNumber):\(verseNumber)"

        if let existing = verseProgress.first(where: { $0.verseKey == verseKey }) {
            modelContext.delete(existing)

            // Update stats (re-fetch will refresh array; recompute eagerly)
            verseProgress.removeAll { $0.verseKey == verseKey }
            stats.totalVersesRead = verseProgress.filter { $0.isRead }.count
            updateTodayVersesCount()

            // Deduct sawab for unmarking verse
            stats.totalSawab = max(0, stats.totalSawab - 10)
            stats.lastUpdated = Date()

            save()
            refresh()

            print("✅ ProgressManager: Unmarked verse \(verseKey)")
            return true
        } else {
            return false
        }
    }

    func isVerseRead(surahNumber: Int, verseNumber: Int) -> Bool {
        let verseKey = "\(surahNumber):\(verseNumber)"
        return verseProgress.contains(where: { $0.verseKey == verseKey && $0.isRead })
    }

    func getVerseProgress(surahNumber: Int, verseNumber: Int) -> VerseProgress? {
        let verseKey = "\(surahNumber):\(verseNumber)"
        return verseProgress.first(where: { $0.verseKey == verseKey })
    }

    // MARK: - Sawab Management

    /// Add sawab points from external sources (quizzes, etc.)
    func addSawab(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        stats.totalSawab += amount
        stats.lastUpdated = Date()
        save()
        print("✨ ProgressManager: +\(amount) sawab earned (\(reason))! Total: \(stats.totalSawab)")
    }

    // MARK: - Surah Completion

    func getSurahCompletion(surahNumber: Int) -> (read: Int, total: Int) {
        let surahVerses = verseProgress.filter { $0.surahNumber == surahNumber && $0.isRead }
        let totalVerses = DataManager.shared.getSurah(number: surahNumber)?.surah.versesCount ?? 0
        return (read: surahVerses.count, total: totalVerses)
    }

    func isSurahCompleted(surahNumber: Int) -> Bool {
        let completion = getSurahCompletion(surahNumber: surahNumber)
        return completion.read == completion.total && completion.total > 0
    }

    private func checkSurahCompletion(surahNumber: Int) {
        guard isSurahCompleted(surahNumber: surahNumber) else { return }

        // Check if badge already awarded
        let alreadyAwarded = badges.contains(where: {
            $0.surahNumber == surahNumber && $0.badgeType == .surahCompletion
        })

        if !alreadyAwarded, let surah = DataManager.shared.getSurah(number: surahNumber)?.surah {
            // Award badge
            let badge = BadgeAward(
                surahNumber: surahNumber,
                surahName: surah.englishName,
                arabicName: surah.arabicName,
                badgeType: .surahCompletion
            )
            modelContext.insert(badge)
            badges.append(badge)
            stats.totalSurahsCompleted += 1

            // Award sawab for badge
            let badgeSawab = badge.badgeType.sawabValue
            stats.totalSawab += badgeSawab
            print("✨ ProgressManager: +\(badgeSawab) sawab earned from \(badge.badgeType.title)! Total: \(stats.totalSawab)")

            // Set pending badge for celebration
            if preferences.celebrationsEnabled {
                pendingBadge = badge
            }

            // The surah is done — the almost-done encouragement is now stale
            NotificationManager.shared.cancelNearCompletionReminder(surahNumber: surahNumber)

            // Celebrate via notification
            let surahName = surah.englishName
            Task {
                await NotificationManager.shared.scheduleMilestoneCelebration(
                    milestone: "You've completed Surah \(surahName)! Keep up the amazing work."
                )
            }

            // Check milestone badges
            checkMilestoneBadges()

            stats.lastUpdated = Date()
            save()

            print("🎉 ProgressManager: Surah \(surahNumber) completed! Badge awarded.")
        }
    }

    private func checkMilestoneBadges() {
        let completedSurahs = stats.totalSurahsCompleted

        // Check for milestone badges
        let milestones: [(count: Int, type: BadgeType)] = [
            (10, .milestone10),
            (25, .milestone25),
            (50, .milestone50),
            (114, .allSurahs)
        ]

        for milestone in milestones {
            if completedSurahs == milestone.count {
                let alreadyAwarded = badges.contains(where: { $0.badgeType == milestone.type })
                if !alreadyAwarded {
                    let badge = BadgeAward(
                        surahNumber: 0,
                        surahName: milestone.type.title,
                        arabicName: milestone.type.subtitle,
                        badgeType: milestone.type
                    )
                    modelContext.insert(badge)
                    badges.append(badge)

                    // Award sawab for milestone badge
                    let badgeSawab = badge.badgeType.sawabValue
                    stats.totalSawab += badgeSawab
                    print("✨ ProgressManager: +\(badgeSawab) sawab earned from \(milestone.type.title)! Total: \(stats.totalSawab)")

                    if preferences.celebrationsEnabled {
                        pendingBadge = badge
                    }

                    // Celebrate via notification
                    let message = milestone.count == 114
                        ? "You've completed the entire Quran! What an incredible achievement."
                        : "You've completed \(milestone.count) surahs! Keep up the amazing work."
                    Task {
                        await NotificationManager.shared.scheduleMilestoneCelebration(milestone: message)
                    }

                    print("🎉 ProgressManager: Milestone badge awarded: \(milestone.type.title)")
                }
            }
        }
    }

    // MARK: - Streak Management

    private func updateStreakOnLoad() {
        guard let lastRead = streak.lastReadDate else { return }

        let calendar = Calendar.current
        let now = Date()

        // Check if streak should be broken
        if let daysSince = calendar.dateComponents([.day], from: lastRead, to: now).day {
            if daysSince > 1 {
                // Streak broken
                streak.currentStreak = 0
                streak.streakStartDate = nil
                print("📉 ProgressManager: Streak broken (last read \(daysSince) days ago)")
            }
        }

        // Update stats
        stats.currentStreak = streak.currentStreak
        stats.longestStreak = streak.longestStreak

        streak.updatedAt = Date()
        stats.lastUpdated = Date()
        save()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let now = Date()

        if let lastRead = streak.lastReadDate {
            // Check if this is a new day
            if calendar.isDate(lastRead, inSameDayAs: now) {
                // Same day - no streak change
                return
            }

            // Check if this is the next day
            if let daysSince = calendar.dateComponents([.day], from: lastRead, to: now).day {
                if daysSince == 1 {
                    // Continue streak
                    streak.currentStreak += 1
                    if streak.currentStreak > streak.longestStreak {
                        streak.longestStreak = streak.currentStreak
                    }

                    // Check for streak badges
                    checkStreakBadges()

                    print("🔥 ProgressManager: Streak continued! Current: \(streak.currentStreak)")
                } else if daysSince > 1 {
                    // Streak broken - start new
                    streak.currentStreak = 1
                    streak.streakStartDate = now
                    print("📉 ProgressManager: Streak broken. Starting fresh.")
                }
            }
        } else {
            // First read ever
            streak.currentStreak = 1
            streak.longestStreak = 1
            streak.streakStartDate = now
            print("🎉 ProgressManager: First reading streak started!")
        }

        streak.lastReadDate = now
        streak.updatedAt = Date()

        // Update stats
        stats.currentStreak = streak.currentStreak
        stats.longestStreak = streak.longestStreak
        stats.lastReadDate = now
    }

    private func checkStreakBadges() {
        let streakMilestones: [(days: Int, type: BadgeType)] = [
            (7, .streak7),
            (30, .streak30),
            (100, .streak100)
        ]

        for milestone in streakMilestones {
            if streak.currentStreak == milestone.days {
                let alreadyAwarded = badges.contains(where: { $0.badgeType == milestone.type })
                if !alreadyAwarded {
                    let badge = BadgeAward(
                        surahNumber: 0,
                        surahName: milestone.type.title,
                        arabicName: milestone.type.subtitle,
                        badgeType: milestone.type
                    )
                    modelContext.insert(badge)
                    badges.append(badge)

                    // Award sawab for streak badge
                    let badgeSawab = badge.badgeType.sawabValue
                    stats.totalSawab += badgeSawab
                    print("✨ ProgressManager: +\(badgeSawab) sawab earned from \(milestone.type.title)! Total: \(stats.totalSawab)")

                    if preferences.celebrationsEnabled {
                        pendingBadge = badge
                    }

                    // Celebrate via notification
                    let days = milestone.days
                    Task {
                        await NotificationManager.shared.scheduleMilestoneCelebration(
                            milestone: "You've reached a \(days)-day reading streak! MashaAllah."
                        )
                    }

                    print("🔥 ProgressManager: Streak badge awarded: \(milestone.type.title)")
                }
            }
        }
    }

    // MARK: - Today's Verses Count

    private func updateTodayVersesCount() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayVerses = verseProgress.filter { progress in
            calendar.isDate(progress.readDate, inSameDayAs: today)
        }

        stats.versesReadToday = todayVerses.count
    }

    // MARK: - Progress Stats

    func getProgressStats() -> ProgressStats {
        return stats
    }

    func getWeeklyProgress() -> [Int] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [Int] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                weeklyData.append(0)
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let versesOnDay = verseProgress.filter { progress in
                calendar.isDate(progress.readDate, inSameDayAs: dayStart)
            }.count

            weeklyData.append(versesOnDay)
        }

        return weeklyData
    }

    func getMonthlyProgress() -> [Int] {
        let calendar = Calendar.current
        let today = Date()
        var monthlyData: [Int] = []

        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                monthlyData.append(0)
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let versesOnDay = verseProgress.filter { progress in
                calendar.isDate(progress.readDate, inSameDayAs: dayStart)
            }.count

            monthlyData.append(versesOnDay)
        }

        return monthlyData
    }

    func getRecentActivity(limit: Int = 10) -> [VerseProgress] {
        return verseProgress
            .sorted { $0.readDate > $1.readDate }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Badge Management

    func getBadges() -> [BadgeAward] {
        return badges.sorted { $0.awardedDate > $1.awardedDate }
    }

    func dismissPendingBadge() {
        pendingBadge = nil
    }

    /// Award Ramadan completion badge (called by RamadanJourneyManager)
    /// Only awards once per Islamic year
    func awardRamadanBadge(year: Int) {
        // Check if already awarded this year
        let alreadyAwarded = badges.contains(where: {
            $0.badgeType == .ramadanCompletion &&
            Calendar.current.component(.year, from: $0.awardedDate) == year
        })

        guard !alreadyAwarded else {
            print("ProgressManager: Ramadan badge already awarded for year \(year)")
            return
        }

        let badge = BadgeAward(
            surahNumber: 0,
            surahName: "Ramadan Champion",
            arabicName: "بطل رمضان",
            badgeType: .ramadanCompletion
        )
        modelContext.insert(badge)
        badges.append(badge)

        // Award sawab bonus
        stats.totalSawab += badge.badgeType.sawabValue
        print("ProgressManager: +\(badge.badgeType.sawabValue) sawab earned from Ramadan completion! Total: \(stats.totalSawab)")

        if preferences.celebrationsEnabled {
            pendingBadge = badge
        }

        stats.lastUpdated = Date()
        save()

        print("ProgressManager: Ramadan Champion badge awarded for year \(year)")
    }

    /// Award Hajj completion badge (called by HajjJourneyManager)
    /// Only awards once per Islamic year
    func awardHajjBadge(year: Int) {
        // Check if already awarded this year
        let alreadyAwarded = badges.contains(where: {
            $0.badgeType == .hajjCompletion &&
            Calendar.current.component(.year, from: $0.awardedDate) == year
        })

        guard !alreadyAwarded else {
            print("ProgressManager: Hajj badge already awarded for year \(year)")
            return
        }

        let badge = BadgeAward(
            surahNumber: 0,
            surahName: "Hajj Champion",
            arabicName: "بطل الحج",
            badgeType: .hajjCompletion
        )
        modelContext.insert(badge)
        badges.append(badge)

        // Award sawab bonus
        stats.totalSawab += badge.badgeType.sawabValue
        print("ProgressManager: +\(badge.badgeType.sawabValue) sawab earned from Hajj completion! Total: \(stats.totalSawab)")

        if preferences.celebrationsEnabled {
            pendingBadge = badge
        }

        stats.lastUpdated = Date()
        save()

        print("ProgressManager: Hajj Champion badge awarded for year \(year)")
    }

    // MARK: - Preferences

    func updatePreferences(_ newPreferences: ProgressPreferences) {
        // newPreferences may be the same instance as self.preferences (call sites that
        // do `var p = manager.preferences; p.x = y; manager.updatePreferences(p)` are
        // really mutating-in-place under @Model class semantics). Either way, persist.
        if newPreferences !== preferences {
            preferences.notificationsEnabled = newPreferences.notificationsEnabled
            preferences.celebrationsEnabled = newPreferences.celebrationsEnabled
            preferences.showStreakInHeader = newPreferences.showStreakInHeader
        }
        preferences.updatedAt = Date()
        save()

        // Arm or disarm motivational notifications to match the toggle
        if preferences.notificationsEnabled {
            Task {
                await NotificationManager.shared.scheduleStreakReminder()
                await NotificationManager.shared.scheduleGentleNudge()
            }
        } else {
            NotificationManager.shared.cancelProgressNotifications()
        }
    }

    // MARK: - Reset Progress

    func resetProgress() async {
        guard modelContext != nil else { return }

        // Delete every fetched VerseProgress and BadgeAward
        for vp in verseProgress { modelContext.delete(vp) }
        for badge in badges { modelContext.delete(badge) }

        // Delete singleton instances
        if let s = try? modelContext.fetch(FetchDescriptor<ReadingStreak>()).first {
            modelContext.delete(s)
        }
        if let st = try? modelContext.fetch(FetchDescriptor<ProgressStats>()).first {
            modelContext.delete(st)
        }
        // Keep ProgressPreferences (user's settings shouldn't reset on progress reset)

        // Clear local arrays
        verseProgress.removeAll()
        badges.removeAll()
        pendingBadge = nil

        save()

        // Re-create singletons (streak/stats); preferences is kept.
        ensureSingletons()
        refresh()

        print("🔄 ProgressManager: Progress reset (local + cloud)")
    }
}
