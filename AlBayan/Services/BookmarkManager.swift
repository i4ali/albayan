//
//  BookmarkManager.swift
//  AlBayan
//
//  SwiftData-backed bookmark management with CloudKit sync.
//

import Foundation
import SwiftData

@MainActor
final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published var bookmarks: [Bookmark] = []
    @Published var collections: [BookmarkCollection] = []
    @Published var preferences: UserBookmarkPreferences?
    @Published var isLoading: Bool = false

    private var modelContext: ModelContext!
    private var hasBound = false

    private init() {}

    /// Called once at app launch from AlBayanApp before any UI accesses the manager.
    /// Idempotent — guarded so a `.task` re-fire doesn't double-register the remote-change observer.
    func bind(to context: ModelContext) {
        guard !hasBound else { return }
        hasBound = true
        self.modelContext = context
        ensurePreferences()
        refresh()
        observeRemoteChanges()
        print("📚 BookmarkManager: \(bookmarks.count) bookmarks, \(collections.count) collections, prefs=\(preferences != nil)")
    }

    // MARK: - Refresh from store

    private func refresh() {
        guard modelContext != nil else { return }
        do {
            bookmarks = try modelContext.fetch(FetchDescriptor<Bookmark>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            collections = try modelContext.fetch(FetchDescriptor<BookmarkCollection>())
            preferences = try modelContext.fetch(FetchDescriptor<UserBookmarkPreferences>()).first
        } catch {
            print("⚠️ BookmarkManager refresh failed: \(error)")
        }
    }

    private func ensurePreferences() {
        guard modelContext != nil else { return }
        do {
            let existing = try modelContext.fetch(FetchDescriptor<UserBookmarkPreferences>())
            if existing.isEmpty {
                let prefs = UserBookmarkPreferences()
                modelContext.insert(prefs)
                try? modelContext.save()
            } else if existing.count > 1 {
                // Singleton race: keep the first, delete the rest
                for prefs in existing.dropFirst() { modelContext.delete(prefs) }
                try? modelContext.save()
            }
        } catch {
            print("⚠️ ensurePreferences failed: \(error)")
        }
    }

    private func observeRemoteChanges() {
        // Refresh on remote sync events
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: - Bookmark mutations

    var bookmarkLimit: Int { preferences?.bookmarkLimit ?? 10 }

    func isAlreadyBookmarked(surahNumber: Int, verseNumber: Int) -> Bool {
        bookmarks.contains { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }
    }

    /// View-side compatibility helper.
    func isBookmarked(surahNumber: Int, verseNumber: Int) -> Bool {
        isAlreadyBookmarked(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// View-side compatibility helper.
    func getBookmark(surahNumber: Int, verseNumber: Int) -> Bookmark? {
        bookmarks.first { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }
    }

    @discardableResult
    func addBookmark(
        surahNumber: Int,
        verseNumber: Int,
        surahName: String,
        verseText: String,
        verseTranslation: String,
        notes: String? = nil,
        tags: [String] = []
    ) -> Bool {
        guard !isAlreadyBookmarked(surahNumber: surahNumber, verseNumber: verseNumber) else { return false }
        guard bookmarks.count < bookmarkLimit else { return false }
        let bookmark = Bookmark(
            surahNumber: surahNumber, verseNumber: verseNumber,
            surahName: surahName, verseText: verseText, verseTranslation: verseTranslation,
            notes: notes, tags: tags
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
        refresh()
        return true
    }

    func updateBookmark(_ bookmark: Bookmark, notes: String? = nil, tags: [String]? = nil) {
        if let notes = notes { bookmark.notes = notes }
        if let tags = tags { bookmark.tags = tags }
        bookmark.updatedAt = Date()
        try? modelContext.save()
        refresh()
    }

    /// View-side compatibility helper (id-based update).
    func updateBookmark(id: UUID, notes: String? = nil, tags: [String]? = nil) {
        guard let bookmark = bookmarks.first(where: { $0.id == id }) else { return }
        updateBookmark(bookmark, notes: notes, tags: tags)
    }

    func deleteBookmark(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
        try? modelContext.save()
        refresh()
    }

    /// View-side compatibility helper (id-based delete).
    func removeBookmark(id: UUID) {
        guard let bookmark = bookmarks.first(where: { $0.id == id }) else { return }
        deleteBookmark(bookmark)
    }

    func toggleBookmark(
        surahNumber: Int, verseNumber: Int,
        surahName: String, verseText: String, verseTranslation: String
    ) {
        if let existing = bookmarks.first(where: { $0.surahNumber == surahNumber && $0.verseNumber == verseNumber }) {
            deleteBookmark(existing)
        } else {
            addBookmark(
                surahNumber: surahNumber, verseNumber: verseNumber,
                surahName: surahName, verseText: verseText, verseTranslation: verseTranslation
            )
        }
    }

    // MARK: - Sorting and filtering (view-side compatibility)

    func getSortedBookmarks() -> [Bookmark] {
        let order = preferences?.sortOrder ?? .dateDescending
        switch order {
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
        getSortedBookmarks().filter { $0.tags.contains(tag) }
    }

    func getAllTags() -> [String] {
        Array(Set(bookmarks.flatMap { $0.tags })).sorted()
    }

    // MARK: - Collections

    @discardableResult
    func createCollection(name: String, descriptionText: String? = nil) -> BookmarkCollection {
        let collection = BookmarkCollection(name: name, descriptionText: descriptionText)
        modelContext.insert(collection)
        try? modelContext.save()
        refresh()
        return collection
    }

    func renameCollection(_ collection: BookmarkCollection, to newName: String) {
        collection.name = newName
        collection.updatedAt = Date()
        try? modelContext.save()
        refresh()
    }

    func deleteCollection(_ collection: BookmarkCollection) {
        modelContext.delete(collection)
        try? modelContext.save()
        refresh()
    }

    func addBookmarkToCollection(_ bookmark: Bookmark, collection: BookmarkCollection) {
        bookmark.collection = collection
        bookmark.updatedAt = Date()
        try? modelContext.save()
        refresh()
    }

    func removeBookmarkFromCollection(_ bookmark: Bookmark) {
        bookmark.collection = nil
        bookmark.updatedAt = Date()
        try? modelContext.save()
        refresh()
    }

    // MARK: - Debug & Reset

    #if DEBUG
    /// DEBUG-only: wipe all SwiftData-backed bookmark data. Used by SettingsView's
    /// "clear all local data" dev affordance. Does NOT touch CloudKit on its own —
    /// SwiftData will propagate the deletes through normal sync.
    func clearAllLocalData() {
        guard modelContext != nil else { return }
        for bookmark in bookmarks { modelContext.delete(bookmark) }
        for collection in collections { modelContext.delete(collection) }
        if let prefs = preferences { modelContext.delete(prefs) }
        try? modelContext.save()
        ensurePreferences()
        refresh()
        print("🧹 BookmarkManager: cleared all SwiftData bookmark data")
    }
    #endif
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
