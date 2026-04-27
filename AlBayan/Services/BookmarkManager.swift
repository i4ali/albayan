//
//  BookmarkManager.swift
//  AlBayan
//
//  Manages bookmarks with local-only persistence (UserDefaults).
//

import Foundation
import UIKit
import Combine

@MainActor
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published var bookmarks: [Bookmark] = []
    @Published var preferences: UserBookmarkPreferences?
    @Published var collections: [BookmarkCollection] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var syncStatus: String?
    @Published var isAuthenticated = false

    private let localStorageKey = "AlBayanBookmarks"
    private let preferencesKey = "AlBayanBookmarkPreferences"
    private let collectionsKey = "AlBayanBookmarkCollections"
    private let pendingDeletesKey = "AlBayanPendingDeletes"

    private var pendingDeletes: Set<UUID> = []

    private var currentUserId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "guest"
    }

    private init() {
        loadLocalBookmarks()
        loadLocalPreferences()
        loadLocalCollections()
        loadPendingDeletes()
    }

    // MARK: - Local Storage

    private func loadLocalBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: localStorageKey),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) else {
            print("💾 No local bookmarks found")
            return
        }

        bookmarks = decoded
        print("💾 Loaded \(bookmarks.count) bookmarks from local storage")
    }

    private func saveLocalBookmarks() {
        guard let encoded = try? JSONEncoder().encode(bookmarks) else {
            print("❌ Failed to encode bookmarks")
            return
        }

        UserDefaults.standard.set(encoded, forKey: localStorageKey)
        print("💾 Saved \(bookmarks.count) bookmarks to local storage")
    }

    private func loadLocalPreferences() {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey),
              let decoded = try? JSONDecoder().decode(UserBookmarkPreferences.self, from: data) else {
            // Create default preferences
            preferences = UserBookmarkPreferences(userId: currentUserId)
            saveLocalPreferences()
            return
        }

        preferences = decoded
        print("💾 Loaded bookmark preferences from local storage")
    }

    private func saveLocalPreferences() {
        guard let prefs = preferences,
              let encoded = try? JSONEncoder().encode(prefs) else {
            print("❌ Failed to encode preferences")
            return
        }

        UserDefaults.standard.set(encoded, forKey: preferencesKey)
        print("💾 Saved bookmark preferences to local storage")
    }

    private func loadLocalCollections() {
        guard let data = UserDefaults.standard.data(forKey: collectionsKey),
              let decoded = try? JSONDecoder().decode([BookmarkCollection].self, from: data) else {
            print("💾 No local bookmark collections found")
            return
        }

        collections = decoded
        print("💾 Loaded \(collections.count) bookmark collections from local storage")
    }

    private func saveLocalCollections() {
        guard let encoded = try? JSONEncoder().encode(collections) else {
            print("❌ Failed to encode collections")
            return
        }

        UserDefaults.standard.set(encoded, forKey: collectionsKey)
        print("💾 Saved \(collections.count) bookmark collections to local storage")
    }

    private func loadPendingDeletes() {
        guard let data = UserDefaults.standard.data(forKey: pendingDeletesKey),
              let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            print("💾 No pending deletes found")
            return
        }

        pendingDeletes = decoded
        print("💾 Loaded \(pendingDeletes.count) pending deletes from local storage")
    }

    private func savePendingDeletes() {
        guard let encoded = try? JSONEncoder().encode(pendingDeletes) else {
            print("❌ Failed to encode pending deletes")
            return
        }

        UserDefaults.standard.set(encoded, forKey: pendingDeletesKey)
        print("💾 Saved \(pendingDeletes.count) pending deletes to local storage")
    }

    // MARK: - Bookmark Management

    func addBookmark(
        surahNumber: Int,
        verseNumber: Int,
        surahName: String,
        verseText: String,
        verseTranslation: String,
        notes: String? = nil,
        tags: [String] = []
    ) -> Bool {
        // Check if bookmark already exists
        if bookmarks.contains(where: { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }) {
            errorMessage = "This verse is already bookmarked"
            return false
        }

        // Check bookmark limit - 10 bookmarks for all users
        let bookmarkLimit = 10

        if bookmarks.count >= bookmarkLimit {
            errorMessage = "You've reached your bookmark limit (\(bookmarkLimit) bookmarks)."
            return false
        }

        let bookmark = Bookmark(
            userId: currentUserId,
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            surahName: surahName,
            verseText: verseText,
            verseTranslation: verseTranslation,
            notes: notes,
            tags: tags,
            syncStatus: .pendingSync
        )

        bookmarks.append(bookmark)
        saveLocalBookmarks()

        print("✅ Added bookmark for \(surahName) \(verseNumber)")
        return true
    }

    func removeBookmark(id: UUID) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else {
            return
        }

        bookmarks.remove(at: index)
        saveLocalBookmarks()

        print("🗑️ Removed bookmark from local storage")
    }

    func updateBookmark(
        id: UUID,
        notes: String? = nil,
        tags: [String]? = nil
    ) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else {
            return
        }

        let existingBookmark = bookmarks[index]
        bookmarks[index] = Bookmark(
            id: existingBookmark.id,
            userId: existingBookmark.userId,
            surahNumber: existingBookmark.surahNumber,
            verseNumber: existingBookmark.verseNumber,
            surahName: existingBookmark.surahName,
            verseText: existingBookmark.verseText,
            verseTranslation: existingBookmark.verseTranslation,
            notes: notes ?? existingBookmark.notes,
            tags: tags ?? existingBookmark.tags,
            createdAt: existingBookmark.createdAt,
            updatedAt: Date(),
            syncStatus: .pendingSync
        )

        saveLocalBookmarks()

        print("✏️ Updated bookmark")
    }

    func isBookmarked(surahNumber: Int, verseNumber: Int) -> Bool {
        return bookmarks.contains { bookmark in
            bookmark.surahNumber == surahNumber &&
            bookmark.verseNumber == verseNumber
        }
    }

    func getBookmark(surahNumber: Int, verseNumber: Int) -> Bookmark? {
        return bookmarks.first { bookmark in
            bookmark.surahNumber == surahNumber &&
            bookmark.verseNumber == verseNumber
        }
    }

    // MARK: - Sorting and Filtering

    func getSortedBookmarks() -> [Bookmark] {
        guard let prefs = preferences else {
            return bookmarks.sorted { $0.createdAt > $1.createdAt }
        }

        switch prefs.sortOrder {
        case .dateAscending:
            return bookmarks.sorted { $0.createdAt < $1.createdAt }
        case .dateDescending:
            return bookmarks.sorted { $0.createdAt > $1.createdAt }
        case .surahOrder:
            return bookmarks.sorted {
                if $0.surahNumber == $1.surahNumber {
                    return $0.verseNumber < $1.verseNumber
                }
                return $0.surahNumber < $1.surahNumber
            }
        case .alphabetical:
            return bookmarks.sorted { $0.surahName < $1.surahName }
        }
    }

    func getBookmarksByTag(_ tag: String) -> [Bookmark] {
        return getSortedBookmarks().filter { $0.tags.contains(tag) }
    }

    func getAllTags() -> [String] {
        let allTags = Set(bookmarks.flatMap { $0.tags })
        return Array(allTags).sorted()
    }


    // MARK: - Debug & Reset Methods

    func clearAllLocalData() {
        // Clear all local bookmarks
        bookmarks.removeAll()

        // Clear all local collections
        collections.removeAll()

        // Reset preferences
        preferences = UserBookmarkPreferences(userId: currentUserId)

        // Clear pending deletes
        pendingDeletes.removeAll()

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: localStorageKey)
        UserDefaults.standard.removeObject(forKey: preferencesKey)
        UserDefaults.standard.removeObject(forKey: collectionsKey)
        UserDefaults.standard.removeObject(forKey: pendingDeletesKey)

        // Clear error state
        errorMessage = nil
        syncStatus = nil

        print("🧹 BookmarkManager: Cleared all local data")
    }
}

// MARK: - Errors

enum BookmarkError: LocalizedError {
    case limitReached
    case alreadyBookmarked
    case notFound
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "Bookmark limit reached"
        case .alreadyBookmarked:
            return "Verse already bookmarked"
        case .notFound:
            return "Bookmark not found"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
