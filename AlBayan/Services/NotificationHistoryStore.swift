//
//  NotificationHistoryStore.swift
//  AlBayan
//
//  Persists delivered/tapped local notifications so the inbox
//  (NotificationsView) shows real history instead of sample data.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationHistoryStore {
    static let shared = NotificationHistoryStore()

    private let storageKey = "notificationHistory"
    private let maxEntries = 50

    private init() {}

    // MARK: - Persistence

    func load() -> [NotificationItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) else {
            return []
        }
        // Drop legacy demo entries (plain-UUID ids); real entries are "identifier|timestamp"
        return decoded
            .filter { $0.id.contains("|") }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func replaceAll(_ items: [NotificationItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Recording

    /// Record a delivered or tapped notification, deduplicating by delivery
    /// (request identifier + delivery date). A tap upgrades the entry to read.
    func record(_ item: NotificationItem) {
        var items = load()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if item.isRead && !items[index].isRead {
                items[index].isRead = true
            }
        } else {
            items.insert(item, at: 0)
            items.sort { $0.timestamp > $1.timestamp }
            if items.count > maxEntries {
                items = Array(items.prefix(maxEntries))
            }
        }
        replaceAll(items)
    }

    /// Merge notifications that were delivered while the app wasn't running
    /// and are still sitting in Notification Center.
    func syncDelivered() async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        for notification in delivered {
            record(Self.item(from: notification))
        }
    }

    // MARK: - Mapping

    /// Build an inbox entry from a UNNotification. Nonisolated so delegate
    /// callbacks can map before hopping to the main actor.
    nonisolated static func item(from notification: UNNotification, isRead: Bool = false) -> NotificationItem {
        let content = notification.request.content
        return NotificationItem(
            id: "\(notification.request.identifier)|\(Int(notification.date.timeIntervalSince1970))",
            title: content.title,
            message: content.body,
            type: type(forCategory: content.categoryIdentifier),
            timestamp: notification.date,
            isRead: isRead,
            surahNumber: content.userInfo["surah"] as? Int,
            verseNumber: content.userInfo["verse"] as? Int
        )
    }

    private nonisolated static func type(forCategory category: String) -> NotificationItem.NotificationType {
        switch category {
        case "STREAK_REMINDER": return .streak
        case "MILESTONE": return .milestone
        case "GENTLE_NUDGE": return .nudge
        case "NEAR_COMPLETION": return .nearCompletion
        default: return .dailyVerse // DAILY_VERSE, ARAFAH_REMINDER
        }
    }
}
