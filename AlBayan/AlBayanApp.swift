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

        // Post notification to trigger navigation
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToVerse"),
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

        // Extract verse information
        if let surah = userInfo["surah"] as? Int,
           let verse = userInfo["verse"] as? Int {
            // Create deep link URL
            if let url = URL(string: "albayan://verse?surah=\(surah)&verse=\(verse)") {
                // Post notification to app to handle navigation
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        }

        completionHandler()
    }
}
