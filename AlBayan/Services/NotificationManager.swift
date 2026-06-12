//
//  NotificationManager.swift
//  AlBayan
//
//  Service for managing daily verse notifications
//  Handles permissions, scheduling, and verse selection based on Islamic calendar
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var preferences: NotificationPreferences {
        didSet {
            savePreferences()
            if preferences.enabled {
                Task {
                    await scheduleNotifications()
                }
            } else {
                cancelDailyVerseNotifications()
            }
        }
    }

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let islamicCalendar = IslamicCalendarManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private var verseData: IslamicMonthVerseData?
    private let progressManager = ProgressManager.shared

    // UserDefaults keys
    private let preferencesKey = "notificationPreferences"

    private init() {
        // Load preferences
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = NotificationPreferences()
        }

        // Load verse data
        loadVerseData()

        // Check permission status
        Task {
            await checkPermissionStatus()
        }
    }

    // MARK: - Data Loading

    private func loadVerseData() {
        guard let url = Bundle.main.url(forResource: "islamic_month_verses", withExtension: "json") else {
            print("❌ NotificationManager: Could not find islamic_month_verses.json in bundle")
            print("📁 Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.verseData = try decoder.decode(IslamicMonthVerseData.self, from: data)
        } catch {
            print("❌ NotificationManager: Error loading verse data - \(error)")
        }
    }

    // MARK: - Preferences

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkPermissionStatus()
            return granted
        } catch {
            print("❌ NotificationManager: Error requesting permission - \(error)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.permissionStatus = settings.authorizationStatus
    }

    /// Whether iOS will currently deliver our notifications
    private func isAuthorized() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Verse Selection

    /// Select today's verse based on Islamic calendar
    func selectTodayVerse() -> DailyVerseEntry? {
        guard let verseData = verseData else {
            print("❌ NotificationManager: Verse data not loaded")
            return nil
        }

        let monthNumber = islamicCalendar.currentIslamicMonth()
        let dayOfMonth = islamicCalendar.currentIslamicDay()

        guard let monthData = verseData.months.first(where: { $0.month == monthNumber }) else {
            print("❌ NotificationManager: Could not find month \(monthNumber)")
            return nil
        }

        // Rotate through verses using day of month
        let verseIndex = (dayOfMonth - 1) % monthData.verses.count
        let selectedVerse = monthData.verses[verseIndex]

        return selectedVerse
    }

    /// Get Islamic month data for current month
    func currentMonthData() -> IslamicMonth? {
        guard let verseData = verseData else { return nil }
        let monthNumber = islamicCalendar.currentIslamicMonth()
        return verseData.months.first(where: { $0.month == monthNumber })
    }

    // MARK: - Notification Content

    /// Build notification content for a verse
    private func buildNotificationContent(for verseEntry: DailyVerseEntry) async -> UNMutableNotificationContent? {
        let content = UNMutableNotificationContent()

        guard let verse = DataManager.shared.getVerse(surah: verseEntry.surah, verse: verseEntry.verse) else {
            print("❌ NotificationManager: Could not load verse \(verseEntry.surah):\(verseEntry.verse)")
            return nil
        }

        // Get month name
        let monthData = currentMonthData()
        let monthName = monthData?.name ?? islamicCalendar.monthName(for: islamicCalendar.currentIslamicMonth())

        // Title
        content.title = "Verse of the Day - \(monthName)"

        // Body
        var body = ""

        // Arabic text
        body += verse.arabicText + "\n\n"

        // Translation
        body += verse.translation

        // Optional: Add brief tafsir snippet if enabled
        if preferences.includeTafsir {
            if let tafsir = verse.tafsir {
                let tafsirText = tafsir.content(for: TafsirLayer.foundation, language: preferences.language)
                let snippet = String(tafsirText.prefix(150))
                body += "\n\n💡 \(snippet)..."
            }
        }

        body += "\n\n📚 Tap to explore the 4-layer tafsir"

        content.body = body

        // Sound
        content.sound = .default

        // Badge
        content.badge = 1

        // Category
        content.categoryIdentifier = "DAILY_VERSE"

        // User info for deep linking
        content.userInfo = [
            "surah": verseEntry.surah,
            "verse": verseEntry.verse,
            "type": "daily_verse"
        ]

        return content
    }

    // MARK: - Notification Scheduling

    /// Re-sync everything that depends on app activation: permission status, icon
    /// badge, and the rolling 7-day daily-verse window. Called on every launch and
    /// foreground so the one-shot schedule never silently runs dry.
    func refreshOnActivation() async {
        await checkPermissionStatus()

        // Clear the icon badge left behind by delivered notifications
        try? await notificationCenter.setBadgeCount(0)

        if preferences.enabled {
            await scheduleNotifications() // also re-arms Arafah during Hajj season
        } else if IslamicCalendarManager.shared.isHajjSeason() {
            await scheduleArafahReminder()
        }
    }

    /// Schedule notifications for the next 7 days
    func scheduleNotifications() async {
        guard await isAuthorized() else {
            print("⚠️ NotificationManager: Not authorized to schedule notifications")
            return
        }

        // Replace the existing daily-verse window without touching other types
        cancelDailyVerseNotifications()

        // Schedule for next 7 days
        for dayOffset in 0..<7 {
            await scheduleNotification(for: dayOffset)
        }

        // Re-arm the Day of Arafah reminder so it survives daily reschedules
        if IslamicCalendarManager.shared.isHajjSeason() {
            await scheduleArafahReminder()
        }
    }

    /// Schedule a notification for a specific day offset
    private func scheduleNotification(for dayOffset: Int) async {
        // Calculate target date (add dayOffset days to today)
        let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()

        // Get hour and minute from user preferences
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferences.time)

        // Extract all components from target date and override time
        var targetComponents = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        targetComponents.hour = timeComponents.hour
        targetComponents.minute = timeComponents.minute

        // For today, only schedule if time hasn't passed
        if dayOffset == 0 {
            let now = Date()
            if let notificationTime = Calendar.current.date(from: targetComponents),
               notificationTime <= now {
                return
            }
        }

        // Get verse for that day (simulate by using dayOffset to select verse)
        guard let verse = selectVerseForDay(dayOffset: dayOffset) else {
            print("❌ NotificationManager: Could not select verse for day \(dayOffset)")
            return
        }

        // Build content
        guard let content = await buildNotificationContent(for: verse) else {
            print("❌ NotificationManager: Could not build content for day \(dayOffset)")
            return
        }

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: targetComponents, repeats: false)

        // Create request
        let identifier = "daily_verse_\(dayOffset)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule
        do {
            try await notificationCenter.add(request)
        } catch {
            print("❌ NotificationManager: Error scheduling notification - \(error)")
        }
    }

    /// Select verse for a specific day offset (used for scheduling future notifications)
    private func selectVerseForDay(dayOffset: Int) -> DailyVerseEntry? {
        guard let verseData = verseData else { return nil }

        // Calculate Islamic date for target day
        let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        let islamicComponents = islamicCalendar.islamicCalendar.dateComponents([.month, .day], from: targetDate)

        guard let monthNumber = islamicComponents.month,
              let dayOfMonth = islamicComponents.day else {
            return nil
        }

        guard let monthData = verseData.months.first(where: { $0.month == monthNumber }) else {
            return nil
        }

        let verseIndex = (dayOfMonth - 1) % monthData.verses.count
        return monthData.verses[verseIndex]
    }

    /// Cancel only the rolling daily-verse notifications
    func cancelDailyVerseNotifications() {
        let identifiers = (0..<7).map { "daily_verse_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Testing

    /// Send a test notification immediately (for testing purposes)
    func sendTestNotification() async {
        guard let verse = selectTodayVerse() else {
            return
        }

        guard let content = await buildNotificationContent(for: verse) else {
            return
        }

        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("❌ NotificationManager: Error scheduling test notification - \(error)")
        }
    }

    // MARK: - Pending Notifications

    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }

    /// Print all pending notifications (for debugging)
    func printPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        for request in requests {
            print("NotificationManager: \(request.identifier)")
        }
    }

    // MARK: - Progress Notifications

    /// Schedule a streak reminder notification. Re-armed after every reading
    /// session (same identifier replaces the pending request), so it only fires
    /// if the user hasn't read by their preferred time tomorrow.
    func scheduleStreakReminder() async {
        // Only schedule if progress notifications are enabled
        guard progressManager.preferences.notificationsEnabled else { return }

        // Check if user has a current streak
        let currentStreak = progressManager.streak.currentStreak
        guard currentStreak > 0 else { return }

        guard await isAuthorized() else { return }

        // Schedule for tomorrow at the user's preferred notification time
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferences.time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Going! 🔥"
        content.body = "You're on a \(currentStreak)-day reading streak. Don't break it today!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "STREAK_REMINDER"

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Streak reminder scheduled")
        } catch {
            print("❌ NotificationManager: Error scheduling streak reminder - \(error)")
        }
    }

    /// Schedule a single local notification for the Day of Arafah (9 Dhul-Hijjah)
    /// at the user's preferred time. Does NOT request permission — only schedules
    /// if already authorized. Deep-links to Quran 2:198 via the .navigateToVerse path.
    func scheduleArafahReminder() async {
        // Only if already authorized — never prompt from here
        guard await isAuthorized() else { return }

        let calendar = IslamicCalendarManager.shared
        let hijriYear = calendar.currentIslamicYear()

        // Resolve 9 Dhul-Hijjah of the current Hijri year to a Gregorian date
        var comps = DateComponents()
        comps.year = hijriYear
        comps.month = 12
        comps.day = 9
        guard let arafahDay = calendar.islamicCalendar.date(from: comps) else { return }

        // Apply the user's preferred notification time
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferences.time)
        var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: arafahDay)
        fireComponents.hour = timeComponents.hour
        fireComponents.minute = timeComponents.minute

        // Skip if it has already passed this year
        if let fireDate = Calendar.current.date(from: fireComponents), fireDate <= Date() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Day of Arafah 🤲"
        content.body = "Today is the Day of Arafah — the best day of the year for du'a and seeking forgiveness. Tap to continue your Dhul-Hijjah Journey."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ARAFAH_REMINDER"
        content.userInfo = ["surah": 2, "verse": 198]

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "arafah_reminder_\(hijriYear)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Arafah reminder scheduled for \(fireComponents)")
        } catch {
            print("❌ NotificationManager: Error scheduling Arafah reminder - \(error)")
        }
    }

    /// Schedule a milestone celebration notification
    func scheduleMilestoneCelebration(milestone: String) async {
        // Only schedule if progress notifications are enabled
        guard progressManager.preferences.notificationsEnabled else { return }

        guard await isAuthorized() else { return }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Congratulations! 🎉"
        content.body = milestone
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MILESTONE"

        // Schedule for 5 seconds from now (immediate celebration)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "milestone_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Milestone notification scheduled")
        } catch {
            print("❌ NotificationManager: Error scheduling milestone notification - \(error)")
        }
    }

    /// Schedule a "come back" nudge 3 days out. Re-armed after every reading
    /// session (same identifier replaces the pending request), so it only fires
    /// if the user actually stays away for 3 days.
    func scheduleGentleNudge() async {
        // Only schedule if progress notifications are enabled
        guard progressManager.preferences.notificationsEnabled else { return }

        guard await isAuthorized() else { return }

        // Only nudge users who have read before
        guard progressManager.stats.lastReadDate != nil else { return }

        // Schedule 3 days from now at preferred time
        guard let nudgeDay = Calendar.current.date(byAdding: .day, value: 3, to: Date()) else { return }
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: nudgeDay)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferences.time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "We miss you! 📖"
        content.body = "It's been a few days since your last reading. Come back to continue your journey through the Quran."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "GENTLE_NUDGE"

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "gentle_nudge",
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Gentle nudge scheduled")
        } catch {
            print("❌ NotificationManager: Error scheduling gentle nudge - \(error)")
        }
    }

    /// Schedule encouragement for nearly completed surah. Fires 1 hour after the
    /// last read in the almost-done zone (same identifier replaces the pending
    /// request); cancelled when the surah is completed.
    func scheduleNearCompletionEncouragement(surahNumber: Int, surahName: String, versesRemaining: Int) async {
        // Only schedule if progress notifications are enabled
        guard progressManager.preferences.notificationsEnabled else { return }

        guard await isAuthorized() else { return }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Almost There! 🌟"
        content.body = "You're almost done with Surah \(surahName)! Only \(versesRemaining) verses remaining."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "NEAR_COMPLETION"

        // Schedule for 1 hour from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "near_completion_\(surahNumber)",
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Near completion encouragement scheduled")
        } catch {
            print("❌ NotificationManager: Error scheduling encouragement - \(error)")
        }
    }

    /// Cancel the near-completion reminder for a surah (e.g. once it's completed)
    func cancelNearCompletionReminder(surahNumber: Int) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["near_completion_\(surahNumber)"])
    }

    /// Cancel progress-related notifications
    func cancelProgressNotifications() {
        var identifiers = [
            "streak_reminder",
            "gentle_nudge"
        ]
        identifiers += (1...114).map { "near_completion_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ NotificationManager: Progress notifications cancelled")
    }
}

