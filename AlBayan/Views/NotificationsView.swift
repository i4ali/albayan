//
//  NotificationsView.swift
//  AlBayan
//
//  Notification inbox showing recent notifications
//

import SwiftUI

struct NotificationItem: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    let surahNumber: Int?
    let verseNumber: Int?

    enum NotificationType: String, Codable {
        case dailyVerse
        case streak
        case milestone
        case nudge
        case nearCompletion

        var icon: String {
            switch self {
            case .dailyVerse: return "book.fill"
            case .streak: return "flame.fill"
            case .milestone: return "star.fill"
            case .nudge: return "heart.fill"
            case .nearCompletion: return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .dailyVerse: return Color(red: 0.39, green: 0.4, blue: 0.95)
            case .streak: return .orange
            case .milestone: return .green
            case .nudge: return Color(red: 0.93, green: 0.28, blue: 0.6)
            case .nearCompletion: return .purple
            }
        }
    }
}

struct NotificationsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [NotificationItem] = []
    @State private var navigateToVerse: (surah: Int, verse: Int)?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.primaryBackground
                .ignoresSafeArea()

                if notifications.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 64))
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)

                        Text("No Notifications")
                            .font(themeManager.isSapphire ? SapphireFont.serif(24) : .system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.primaryText)

                        Text(themeManager.isSapphire ? "ALL CAUGHT UP" : "You're all caught up!\nNotifications will appear here when you receive them.")
                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 16, weight: .medium))
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                            .tracking(themeManager.isSapphire ? 2.5 : 0)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        if themeManager.isSapphire {
                            Text("Notifications will appear here\nwhen you receive them.")
                                .font(SapphireFont.body(15))
                                .foregroundColor(themeManager.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notifications) { notification in
                                NotificationCard(notification: notification) {
                                    // Mark as read
                                    if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                                        notifications[index].isRead = true
                                        saveNotifications()
                                    }

                                    // Navigate if it has verse info
                                    if let surah = notification.surahNumber,
                                       let verse = notification.verseNumber {
                                        dismiss()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            NotificationCenter.default.post(
                                                name: .navigateToVerse,
                                                object: nil,
                                                userInfo: ["surah": surah, "verse": verse]
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbarBackground(themeManager.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if themeManager.isSapphire {
                    ToolbarItem(placement: .principal) {
                        Text("Notifications")
                            .font(SapphireFont.screenTitle)
                            .foregroundColor(themeManager.primaryText)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !notifications.isEmpty {
                        Button("Clear All") {
                            notifications.removeAll()
                            saveNotifications()
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : Color(red: 0.39, green: 0.4, blue: 0.95))
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            notifications = NotificationHistoryStore.shared.load()

            // Pull in anything delivered while the app wasn't running
            Task {
                await NotificationHistoryStore.shared.syncDelivered()
                notifications = NotificationHistoryStore.shared.load()
            }
        }
    }

    private func saveNotifications() {
        NotificationHistoryStore.shared.replaceAll(notifications)
    }
}

struct NotificationCard: View {
    let notification: NotificationItem
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    if themeManager.isSapphire {
                        Circle()
                            .fill(themeManager.goldChipFill)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(notification.type.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                    }

                    Image(systemName: notification.type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : notification.type.color)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(themeManager.isSapphire ? SapphireFont.serif(17) : .system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.primaryText)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(themeManager.isSapphire ? themeManager.accentColor : Color(red: 0.39, green: 0.4, blue: 0.95))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.message)
                        .font(themeManager.isSapphire ? SapphireFont.body(15) : .system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Text(themeManager.isSapphire ? formatTimestamp(notification.timestamp).uppercased() : formatTimestamp(notification.timestamp))
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
                        .tracking(themeManager.isSapphire ? 2.5 : 0)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.glassEffect)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                notification.isRead
                                    ? themeManager.strokeColor
                                    : (themeManager.isSapphire ? themeManager.accentColor.opacity(0.3) : Color(red: 0.39, green: 0.4, blue: 0.95).opacity(0.3)),
                                lineWidth: notification.isRead ? 1 : 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    NotificationsView()
}
