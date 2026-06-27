//
//  AlBayanApp.swift
//  AlBayan
//
//  Created by Imran Ali on 8/1/25.
//

import SwiftData
import SwiftUI
import UserNotifications

@main
struct AlBayanApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer = {
        let schema = Schema([
            Bookmark.self, BookmarkCollection.self, UserBookmarkPreferences.self,
            VerseProgress.self, ReadingStreak.self, BadgeAward.self,
            ProgressStats.self, ProgressPreferences.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.MAHR.Partner.AlBayan")
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    BookmarkManager.shared.bind(to: container.mainContext)
                    ProgressManager.shared.bind(to: container.mainContext)
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            // Re-derive premium status when the app returns to the foreground.
            // Catches the case where the user signs into their Apple Account
            // (or switches accounts) in Settings while the app is backgrounded.
            if newPhase == .active {
                Task { await PremiumManager.shared.refreshFromStoreKit() }
                Task {
                    await NotificationManager.shared.refreshOnActivation()
                    await NotificationHistoryStore.shared.syncDelivered()
                }
                DailyChallengeProvider.shared.refreshIfDayChanged()
                DailyCrosswordProvider.shared.refreshIfDayChanged()
                DailyCrosswordManager.shared.refreshForToday()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle verse deep link from notifications
        if url.scheme == "albayan" && url.host == "verse" {
            handleVerseDeepLink(url)
        }
    }

    private func handleVerseDeepLink(_ url: URL) {
        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        // Extract surah and verse numbers
        var surahNumber: Int?
        var verseNumber: Int?

        for item in queryItems {
            if item.name == "surah", let value = item.value, let number = Int(value) {
                surahNumber = number
            } else if item.name == "verse", let value = item.value, let number = Int(value) {
                verseNumber = number
            }
        }

        guard let surah = surahNumber, let verse = verseNumber else {
            return
        }

        // Stash for cold launches (views may not be subscribed yet)
        DeepLinkRouter.shared.pendingVerse = PendingVerse(surah: surah, verse: verse)

        // Post notification to trigger navigation
        NotificationCenter.default.post(
            name: .navigateToVerse,
            object: nil,
            userInfo: ["surah": surah, "verse": verse]
        )
    }
    
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Record into the inbox history
        let item = NotificationHistoryStore.item(from: notification)
        Task { @MainActor in
            NotificationHistoryStore.shared.record(item)
        }

        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Record into the inbox history as already read
        let item = NotificationHistoryStore.item(from: response.notification, isRead: true)

        // Extract verse information
        let surah = userInfo["surah"] as? Int
        let verse = userInfo["verse"] as? Int

        Task { @MainActor in
            NotificationHistoryStore.shared.record(item)

            if let surah, let verse {
                // Stash for cold launches (views may not be subscribed yet);
                // consumed by MainTabView/HomeView on appear.
                DeepLinkRouter.shared.pendingVerse = PendingVerse(surah: surah, verse: verse)

                // Live path for when the app is already running
                NotificationCenter.default.post(
                    name: .navigateToVerse,
                    object: nil,
                    userInfo: ["surah": surah, "verse": verse]
                )
            }
        }

        completionHandler()
    }
}
