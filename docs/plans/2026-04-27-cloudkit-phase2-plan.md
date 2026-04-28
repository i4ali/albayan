# CloudKit (Phase 2) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add cross-device sync for bookmarks and reading progress via SwiftData + CloudKit, replacing the local-only `UserDefaults` persistence introduced in Phase 1.

**Architecture:** Replace the 6 entity Codable structs (`Bookmark`, `BookmarkCollection`, `UserBookmarkPreferences`, `VerseProgress`, `ReadingStreak`, `BadgeAward`, `ProgressStats`, `ProgressPreferences`) with `@Model` classes. Configure a single shared `ModelContainer` in `AlBayanApp` with `cloudKitDatabase: .private("iCloud.MAHR.Partner.AlBayan")`. Rewrite `BookmarkManager` and `ProgressManager` to use `ModelContext` for CRUD while preserving their public business-logic API. Apple's SwiftData runtime handles sync, conflict resolution, push, and retries.

**Tech Stack:** Swift 5.9 / SwiftUI / SwiftData / CloudKit / iOS 18.2 / Xcode 26 / StoreKit 2. No XCTest target — verification is `xcodebuild` build success per task plus a manual simulator smoke pass at the end.

**Companion design doc:** `docs/plans/2026-04-27-cloudkit-phase2-design.md`

**Standing user instruction:** Per `~/.claude/.../memory/feedback_no_auto_commit.md`, the executing engineer writes files and stops before `git commit`. Suggested commit messages are included; the user runs them. (Phase 1 user explicitly approved per-task commits during execution; check current preference before assuming.)

**Build verification command** (used after every task):

```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "error:|BUILD " | tail -20
```

Required: ends with `** BUILD SUCCEEDED **` and zero `error:` lines.

---

## Task ordering rationale

This work has a fundamental constraint: converting any of the 6 entity structs to `@Model` classes immediately breaks every consumer (managers, views, etc.). The two managers MUST be rewritten in the same task as the entity conversions, otherwise the build breaks mid-bundle.

Tasks therefore bundle each entity group with its consuming manager:

1. **Prerequisites** (Task 1) — manual, user-verified. Already partially done.
2. **Empty container** (Task 2) — wire up `ModelContainer` in `AlBayanApp` with empty schema so SwiftData runtime is available.
3. **Bookmark layer** (Task 3) — convert 3 bookmark-related structs to `@Model`, register in schema, rewrite `BookmarkManager`. Atomic.
4. **Progress layer** (Task 4) — convert 5 progress-related structs to `@Model`, register in schema, rewrite `ProgressManager`. Atomic.
5. **Phase 1 dead code cleanup** (Task 5) — `SyncStatusToast`, `BookmarkSyncStatus` enum, stale comments.
6. **Premium listener consolidation** (Task 6) — drop the duplicate `Transaction.updates` listener in `PremiumManager`.
7. **Final verification** (Task 7) — clean build, all grep gates clean, ready for manual smoke tests.
8. **Manual user steps** (Task 8) — smoke tests, CloudKit Console verification, optional two-device sync test.
9. **Pre-submission user step** (Task 9) — deploy schema to production via CloudKit Console (one-time before App Store).

---

## Task 1: Prerequisites verification (USER, not Claude)

**Files:** none — verification only.

**Why:** SwiftData with `cloudKitDatabase` requires the iCloud entitlements to be wired up correctly, otherwise the app crashes at first model-container init.

**Step 1: Confirm Apple Developer Portal state** (already done)

The user has confirmed:
- iCloud capability enabled on App ID `MAHR.Partner.AlBayan`
- Container `iCloud.MAHR.Partner.AlBayan` created
- iCloud capability added in Xcode's Signing & Capabilities pane with the container checked

**Step 2: Verify entitlements were written**

Run:

```bash
cat AlBayan/AlBayan.entitlements
```

Expected output contains all three of:

- `<key>com.apple.developer.icloud-services</key>` followed by `<array><string>CloudKit</string></array>`
- `<key>com.apple.developer.icloud-container-identifiers</key>` followed by `<array><string>iCloud.MAHR.Partner.AlBayan</string></array>`
- `<key>aps-environment</key><string>development</string>` (Xcode adds this automatically for CloudKit silent push)

**Step 3: Confirm baseline build**

Run the build verification command. Expected: `** BUILD SUCCEEDED **`. If signing fails here with "Provisioning profile doesn't include the com.apple.developer.icloud-services entitlement", the App ID portal step needs revisiting.

**Step 4: Sign the simulator into iCloud** (recommended now to avoid stalling at smoke test time)

Boot the simulator, open the Settings app → "Sign in to your iPhone" with any real Apple ID. ~30 seconds.

---

## Task 2: Empty `ModelContainer` in `AlBayanApp`

**Files:**
- Modify: `AlBayan/AlBayanApp.swift`

**Why:** Establish the SwiftData runtime with an empty schema first. Subsequent tasks will register entity types into this container as they're created. Build stays green.

**Step 1: Add SwiftData import and container property**

In `AlBayan/AlBayanApp.swift`, add `import SwiftData` near the top (alongside `import SwiftUI`).

Inside `struct AlBayanApp: App`, add a `let container: ModelContainer` property with an empty schema:

```swift
let container: ModelContainer = {
    let schema = Schema([])  // entities added in tasks 3 and 4
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private("iCloud.MAHR.Partner.AlBayan")
    )
    return try! ModelContainer(for: schema, configurations: [config])
}()
```

Note: an empty `Schema([])` may fail at runtime, but compiles. If `Schema([])` is rejected at compile time too, defer the property addition to Task 3 when the first entity exists.

**Step 2: Inject into the SwiftUI scene**

In the `var body: some Scene { WindowGroup { ContentView() } }` block, add `.modelContainer(container)` modifier on `ContentView()`:

```swift
WindowGroup {
    ContentView()
}
.modelContainer(container)
```

**Step 3: Build**

Run the build verification command. Expected: `BUILD SUCCEEDED`.

If `Schema([])` is rejected at compile time, defer the `container` property to Task 3 — Task 2 then becomes just adding `import SwiftData`. Document this branch in the implementer's task notes.

**Step 4: Suggested commit**

```
feat(swiftdata): add empty ModelContainer with private CloudKit DB
```

---

## Task 3: Bookmark layer — `@Model` entities + `BookmarkManager` rewrite

**Files:**
- Modify: `AlBayan/Models/QuranModels.swift` (replace `struct Bookmark`, `struct BookmarkCollection`, `struct UserBookmarkPreferences`)
- Modify: `AlBayan/AlBayanApp.swift` (register entities in schema)
- Modify: `AlBayan/Services/BookmarkManager.swift` (full rewrite)

**Why:** This is the first big atomic bundle. Converting any of the 3 structs to `@Model` will break `BookmarkManager`, so they must be done in lockstep.

**Step 1: Convert `Bookmark` struct to `@Model` class**

In `AlBayan/Models/QuranModels.swift` around line 399, replace:

```swift
struct Bookmark: Codable, Identifiable {
    let id: UUID
    let userId: String
    let surahNumber: Int
    let verseNumber: Int
    let surahName: String
    let verseText: String
    let verseTranslation: String
    let notes: String?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: BookmarkSyncStatus
    // ... computed property and init
}
```

With:

```swift
@Model
final class Bookmark {
    @Attribute(.unique) var id: UUID = UUID()
    var surahNumber: Int = 0
    var verseNumber: Int = 0
    var surahName: String = ""
    var verseText: String = ""
    var verseTranslation: String = ""
    var notes: String? = nil
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var collection: BookmarkCollection? = nil

    var verseReference: String { "\(surahNumber):\(verseNumber)" }

    init(
        id: UUID = UUID(),
        surahNumber: Int = 0,
        verseNumber: Int = 0,
        surahName: String = "",
        verseText: String = "",
        verseTranslation: String = "",
        notes: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        collection: BookmarkCollection? = nil
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.surahName = surahName
        self.verseText = verseText
        self.verseTranslation = verseTranslation
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.collection = collection
    }
}
```

**Important:** SwiftData with CloudKit does NOT support `@Attribute(.unique)`. If the build complains about `.unique` being incompatible with CloudKit, remove the `@Attribute(.unique)` annotation — leave just `var id: UUID = UUID()`. The UUID itself is stable and unique-by-construction; SwiftData will handle deduplication via the auto-injected primary key.

Add `import SwiftData` at the top of `QuranModels.swift`.

**Step 2: Convert `BookmarkCollection` struct to `@Model` class**

Around line 453, replace the struct with:

```swift
@Model
final class BookmarkCollection {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionText: String? = nil  // renamed from `description` to avoid Identifiable.description collision
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    @Relationship(deleteRule: .nullify, inverse: \Bookmark.collection) var bookmarks: [Bookmark] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        descriptionText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

**Step 3: Convert `UserBookmarkPreferences` struct to `@Model` class**

Around line 481, replace with:

```swift
@Model
final class UserBookmarkPreferences {
    var id: UUID = UUID()
    var bookmarkLimit: Int = 10
    var defaultTags: [String] = []
    var sortOrderRaw: String = BookmarkSortOrder.dateDescending.rawValue
    var groupByRaw: String = BookmarkGroupBy.none.rawValue

    var sortOrder: BookmarkSortOrder {
        get { BookmarkSortOrder(rawValue: sortOrderRaw) ?? .dateDescending }
        set { sortOrderRaw = newValue.rawValue }
    }

    var groupBy: BookmarkGroupBy {
        get { BookmarkGroupBy(rawValue: groupByRaw) ?? .none }
        set { groupByRaw = newValue.rawValue }
    }

    init() {}
}
```

The `BookmarkSortOrder` and `BookmarkGroupBy` enums (defined just below) stay as plain Swift `enum` types — leave them untouched.

**Step 4: Register the three entities in the container schema**

In `AlBayan/AlBayanApp.swift`, update the `Schema([])` line to:

```swift
let schema = Schema([Bookmark.self, BookmarkCollection.self, UserBookmarkPreferences.self])
```

(More entities added in Task 4.)

**Step 5: Rewrite `BookmarkManager.swift`**

Replace the entire contents of `AlBayan/Services/BookmarkManager.swift` with the rewrite below. This drops the inert sync flags, `pendingDeletes` apparatus, and all `UserDefaults`-based persistence; replaces with `ModelContext` CRUD.

```swift
//
//  BookmarkManager.swift
//  AlBayan
//
//  SwiftData-backed bookmark management with CloudKit sync.
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()

    @Published var bookmarks: [Bookmark] = []
    @Published var collections: [BookmarkCollection] = []
    @Published var preferences: UserBookmarkPreferences?
    @Published var isLoading: Bool = false

    private var modelContext: ModelContext!

    private init() {}

    /// Called once at app launch from AlBayanApp before any UI accesses the manager.
    func bind(to context: ModelContext) {
        self.modelContext = context
        ensurePreferences()
        refresh()
        observeRemoteChanges()
    }

    // MARK: - Refresh from store

    private func refresh() {
        do {
            bookmarks = try modelContext.fetch(FetchDescriptor<Bookmark>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            collections = try modelContext.fetch(FetchDescriptor<BookmarkCollection>())
            preferences = try modelContext.fetch(FetchDescriptor<UserBookmarkPreferences>()).first
        } catch {
            print("⚠️ BookmarkManager refresh failed: \(error)")
        }
    }

    private func ensurePreferences() {
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

    func deleteBookmark(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
        try? modelContext.save()
        refresh()
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
}
```

**Step 6: Wire up `bind(to:)` in `AlBayanApp.swift`**

In the `WindowGroup`'s root view, after `.modelContainer(container)`, add a `.task` that binds the manager to the main context:

```swift
WindowGroup {
    ContentView()
        .task {
            BookmarkManager.shared.bind(to: container.mainContext)
        }
}
.modelContainer(container)
```

(`ProgressManager.shared.bind(to: container.mainContext)` will be added in the same `.task` in Task 4.)

**Step 7: Fix any view-side breakages**

Build the project. Expected breakages (each is a quick fix):

- Anywhere a view constructs a `Bookmark` directly via the old struct init (e.g., for previews) — update to use the `@Model` init signature
- Any code that does `bookmark.userId` — remove the access (field is gone)
- Any code that does `bookmark.syncStatus` — remove the access (field is gone). This should already be zero matches per Phase 1's `SyncStatusToast` removal in Task 5 of THIS plan; if grep finds matches, defer the fix to Task 5.
- Any code that does `BookmarkManager.shared.forceSyncWithSupabase()` — already removed in Phase 1, should be zero matches

For each breakage: read the surrounding context, make the minimal fix to compile.

**Step 8: Verify build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 9: Verify entities are visible to SwiftData**

Add a print statement in `BookmarkManager.bind(to:)` after `refresh()`:

```swift
print("📚 BookmarkManager: \(bookmarks.count) bookmarks, \(collections.count) collections, prefs=\(preferences != nil)")
```

This will show in the simulator log on next run. (Remove the print after Task 7's smoke test passes, or leave it — it's informational.)

**Step 10: Suggested commit**

```
feat(swiftdata): bookmark layer (Bookmark/Collection/Preferences) on SwiftData
```

---

## Task 4: Progress layer — `@Model` entities + `ProgressManager` rewrite

**Files:**
- Modify: `AlBayan/Models/QuranModels.swift` (replace 5 progress structs)
- Modify: `AlBayan/AlBayanApp.swift` (extend schema)
- Modify: `AlBayan/Services/ProgressManager.swift` (full rewrite)

**Why:** Same atomic-bundle pattern as Task 3, for the 5 progress entities.

**Step 1: Convert `VerseProgress` struct to `@Model` class**

Inspect the current struct first:

```bash
sed -n '669,700p' AlBayan/Models/QuranModels.swift
```

Replace with a `@Model final class VerseProgress` mirroring the field set (all fields with defaults, no `userId`, no sync-related fields). Pattern:

```swift
@Model
final class VerseProgress {
    var id: UUID = UUID()
    var surahNumber: Int = 0
    var verseNumber: Int = 0
    // ... all other current struct fields, each with a default
    var readAt: Date = Date()

    init(/* same params, all with defaults */) {
        // assignments
    }
}
```

**Step 2: Convert `ReadingStreak` struct to `@Model` class** (singleton)

```bash
sed -n '695,720p' AlBayan/Models/QuranModels.swift
```

Replace mirroring the field set:

```swift
@Model
final class ReadingStreak {
    var id: UUID = UUID()
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastReadDate: Date? = nil
    // ... any other current fields with defaults
    var updatedAt: Date = Date()

    init(/* defaults */) { /* assignments */ }
}
```

**Step 3: Convert `BadgeAward` struct to `@Model` class**

```bash
sed -n '714,730p' AlBayan/Models/QuranModels.swift
```

Replace mirroring the field set, all defaults.

**Step 4: Convert `ProgressStats` struct to `@Model` class** (singleton)

```bash
sed -n '859,895p' AlBayan/Models/QuranModels.swift
```

Replace mirroring, all defaults. Add `var lastUpdated: Date = Date()` if not already present (used for singleton consolidation).

**Step 5: Convert `ProgressPreferences` struct to `@Model` class** (singleton)

```bash
sed -n '890,905p' AlBayan/Models/QuranModels.swift
```

Replace:

```swift
@Model
final class ProgressPreferences {
    var id: UUID = UUID()
    var notificationsEnabled: Bool = true
    var celebrationsEnabled: Bool = true
    var showStreakInHeader: Bool = true
    var updatedAt: Date = Date()

    init() {}
}
```

**Step 6: Extend the schema in `AlBayanApp.swift`**

Update the schema line to:

```swift
let schema = Schema([
    Bookmark.self, BookmarkCollection.self, UserBookmarkPreferences.self,
    VerseProgress.self, ReadingStreak.self, BadgeAward.self,
    ProgressStats.self, ProgressPreferences.self,
])
```

**Step 7: Rewrite `ProgressManager.swift`**

Replace the entire file. The rewrite preserves ALL business logic methods (`markVerseAsRead`, `addSawab`, `markSurahCompleted`, `updateStreak`, `awardBadge`, `getTodaysVersesCount`, `checkForBadgeAwards`, etc.) while swapping persistence from UserDefaults to ModelContext.

Outline:

```swift
import Foundation
import SwiftData
import Combine

@MainActor
final class ProgressManager: ObservableObject {
    static let shared = ProgressManager()

    @Published var verseProgress: [VerseProgress] = []
    @Published var streak: ReadingStreak = ReadingStreak()  // placeholder; replaced after bind()
    @Published var badges: [BadgeAward] = []
    @Published var stats: ProgressStats = ProgressStats()
    @Published var preferences: ProgressPreferences = ProgressPreferences()
    @Published var pendingBadge: BadgeAward? = nil

    private var modelContext: ModelContext!

    private init() {}

    func bind(to context: ModelContext) {
        self.modelContext = context
        ensureSingletons()
        refresh()
        observeRemoteChanges()
    }

    private func refresh() {
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

    // MARK: - Business logic
    // PORT EVERY existing public method from the old ProgressManager:
    //   markVerseAsRead(surahNumber:verseNumber:)
    //   addSawab(amount:)
    //   markSurahCompleted(surahNumber:)
    //   updateStreak()
    //   awardBadge(_:)
    //   getTodaysVersesCount()
    //   isSurahCompleted(surahNumber:)
    //   completionPercentage(forSurahNumber:totalVerses:)
    //   checkForBadgeAwards()
    //   resetProgress()
    //   ... etc.
    //
    // For each method:
    //   1. Replace `UserDefaults.standard.set(encoded, forKey: ...)` calls with `try? modelContext.save()`
    //   2. Replace direct array mutations on `@Published` props with insert/delete on the modelContext
    //   3. Mutating `streak.currentStreak = N` works directly because streak is now a `@Model class` (reference type)
    //   4. Call `refresh()` at the end of each mutator
    //
    // resetProgress() implementation:
    //   - Delete every fetched VerseProgress and BadgeAward
    //   - Delete the singleton instances and re-create
    //   - Save and refresh
}
```

The implementer should read the existing `ProgressManager.swift` end-to-end before rewriting — there is significant business logic that must be preserved verbatim. The skeleton above is a guide; expand each section by porting the existing code with persistence calls swapped.

**Step 8: Wire up `bind(to:)` in `AlBayanApp.swift`**

Extend the `.task` block:

```swift
.task {
    BookmarkManager.shared.bind(to: container.mainContext)
    ProgressManager.shared.bind(to: container.mainContext)
}
```

**Step 9: Fix view-side breakages**

Same pattern as Task 3. Likely none if the public API was preserved.

**Step 10: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 11: Suggested commit**

```
feat(swiftdata): progress layer (verses/streak/badges/stats/prefs) on SwiftData
```

---

## Task 5: Phase 1 dead-code cleanup

**Files:**
- Modify: `AlBayan/ContentView.swift`
- Modify: `AlBayan/Views/HomeView.swift`
- Modify: `AlBayan/Models/QuranModels.swift`
- Modify: `AlBayan/Views/WelcomeView.swift`, `AlBayan/Views/Onboarding/FinalScreen.swift`

**Why:** Items deferred from Phase 1's code review now that the inert flags they observed are gone.

**Step 1: Delete `SyncStatusToast` struct and its call sites**

In `AlBayan/ContentView.swift`, locate the `SyncStatusToast` struct (search for `struct SyncStatusToast`). Delete the entire struct definition.

Then locate every call site:

```bash
grep -n "SyncStatusToast\|bookmarkManager.syncStatus" AlBayan/ContentView.swift AlBayan/Views/HomeView.swift
```

For each match, delete the surrounding `if let syncStatus = ... { SyncStatusToast(...) }` block.

**Step 2: Delete `BookmarkSyncStatus` enum**

In `AlBayan/Models/QuranModels.swift`, locate the enum:

```bash
grep -n "enum BookmarkSyncStatus" AlBayan/Models/QuranModels.swift
```

Delete the entire enum definition (~6 lines).

**Step 3: Update stale comments**

- `AlBayan/Views/WelcomeView.swift:5` — remove "with authentication options" from the file header comment
- `AlBayan/Views/Onboarding/FinalScreen.swift:5` — change "Onboarding Screen 10: Account Setup" to something like "Onboarding Screen 10: Final Screen"
- `AlBayan/Views/Onboarding/FinalScreen.swift:30` — change UI label "Choose how you'd like to start" to "Tap below to begin" (or similar — single-button context)
- `AlBayan/ContentView.swift:65` — remove "not for authentication" from the comment if still present

**Step 4: Verify nothing broke**

```bash
grep -rn "syncStatus\|SyncStatusToast\|BookmarkSyncStatus\|isSyncing\|hasConflict\|conflictMessage\|pendingDeletes" AlBayan/ --include="*.swift"
```

Expected: no output. If anything remains, it's a missed reference — fix before proceeding.

**Step 5: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 6: Suggested commit**

```
chore: remove Phase 1 deferred dead code (SyncStatusToast, BookmarkSyncStatus, stale comments)
```

---

## Task 6: Consolidate `Transaction.updates` listener

**Files:**
- Modify: `AlBayan/Services/PremiumManager.swift`

**Why:** Phase 1's reviewer flagged that both `PremiumManager` and `PurchaseManager` listen to `Transaction.updates`. `PurchaseManager` is the proper owner (calls `transaction.finish()`); collapse `PremiumManager` to a passive read-only state derived on demand.

**Step 1: Edit `PremiumManager.swift`**

Remove the `Transaction.updates` subscription:
- Delete `private var updatesTask: Task<Void, Never>?` property
- Delete the `init` body's `updatesTask = Task { ... for await ... Transaction.updates ... }` block
- Delete `deinit { updatesTask?.cancel() }`

Keep `refreshFromStoreKit()` exactly as-is (called by `PurchaseManager` after each verified transaction).

In `init`, only call `Task { await refreshFromStoreKit() }` so the initial state is hydrated:

```swift
init() {
    Task { await refreshFromStoreKit() }
}
```

**Step 2: Verify `PurchaseManager` already calls `refreshFromStoreKit()` after each transaction**

```bash
grep -n "refreshFromStoreKit" AlBayan/Services/PurchaseManager.swift
```

Expected: at least 3 matches (after the three call sites that previously called `syncPremiumStatusToSupabase`). If any are missing, add `await PremiumManager.shared.refreshFromStoreKit()` to those code paths.

**Step 3: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 4: Suggested commit**

```
refactor(premium): single Transaction.updates listener (in PurchaseManager)
```

---

## Task 7: Final verification gates

**Files:** none modified.

**Step 1: Run all build-time gate commands**

```bash
echo "=== UserDefaults storage keys (should be empty) ==="
grep -rn "UserDefaults.standard.*\(verseProgressKey\|streakKey\|badgesKey\|statsKey\|preferencesKey\|localStorageKey\|collectionsKey\|pendingDeletesKey\)" AlBayan/ --include="*.swift" || echo "(clean)"

echo "=== Phase 1 inert flags (should be empty) ==="
grep -rn "syncStatus\|isSyncing\|hasConflict\|conflictMessage\|pendingDeletes\|SyncStatusToast\|BookmarkSyncStatus" AlBayan/ --include="*.swift" || echo "(clean)"

echo "=== SwiftData imports (should be 4 matches) ==="
grep -n "import SwiftData" AlBayan/Models/QuranModels.swift AlBayan/Services/BookmarkManager.swift AlBayan/Services/ProgressManager.swift AlBayan/AlBayanApp.swift

echo "=== CloudKit container ID (should be 1+ matches) ==="
grep -rn "iCloud.MAHR.Partner.AlBayan" AlBayan/ --include="*.swift" --include="*.entitlements"

echo "=== ModelContainer in AlBayanApp ==="
grep -n "ModelContainer\|cloudKitDatabase\|modelContainer(" AlBayan/AlBayanApp.swift
```

All "clean" gates must print `(clean)`. SwiftData imports must show all 4. CloudKit container ID must show in entitlements + AlBayanApp.

**Step 2: Clean build from scratch**

```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' clean build 2>&1 | grep -E "error:|warning:|BUILD " | tail -30
```

Required: `** BUILD SUCCEEDED **` with zero new errors. Pre-existing deprecation warnings (SKStoreReviewController, NavigationLink iOS 16) are acceptable.

**Step 3: Suggested commit (if any tweaks needed)**

Only if step 1 surfaced anything to fix.

---

## Task 8: Manual user smoke tests (USER, not Claude)

**Files:** none — verification only.

**Step 1: Boot simulator with iCloud signed in**

If not already done in Task 1: open simulator → Settings → "Sign in to your iPhone" with your Apple ID. ~30 seconds.

**Step 2: Run single-device smoke tests**

Build and run on simulator from Xcode. Exercise:

1. Fresh install → onboarding completes → app lands cleanly. Watch the Xcode console for `📚 BookmarkManager: 0 bookmarks...` log line confirming bind succeeded.
2. Add 3 bookmarks across different surahs. Mark 5 verses read. Watch the streak counter increment.
3. Kill the app (swipe up from app switcher). Relaunch. All data should persist.
4. Delete a bookmark from the bookmarks list. Relaunch — stays deleted.
5. Add bookmarks until limit (10). Try to add an 11th — should be rejected per `bookmarkLimit`.
6. Settings app → sign out of iCloud. Open AlBayan — existing bookmarks still readable. Add a new bookmark (this stays local). Sign back into iCloud → after a few seconds the local bookmark should upload (verify in CloudKit Console, step 4 below).
7. Toggle airplane mode on. Add a bookmark. Toggle airplane mode off. After ~30 seconds the bookmark appears in CloudKit Console.

If any scenario fails, do not proceed. Report the failure with reproduction steps.

**Step 3: CloudKit Console verification**

1. Visit https://icloud.developer.apple.com/dashboard
2. Select container: `iCloud.MAHR.Partner.AlBayan`
3. Database: Private; Environment: Development
4. Click Records tab. Should see record types `CD_Bookmark`, `CD_VerseProgress`, `CD_ReadingStreak`, `CD_BadgeAward`, `CD_ProgressStats`, `CD_ProgressPreferences`, `CD_BookmarkCollection`, `CD_UserBookmarkPreferences` (the `CD_` prefix is auto-added by SwiftData)
5. Click into `CD_Bookmark` → see the records you added in step 2 above

**Step 4 (optional): Two-device sync test**

Either:
- Boot a second simulator (e.g., iPhone 17 Pro) and sign it into the same iCloud account
- OR install on a real device signed into the same iCloud account

Then:
1. On device A: add a bookmark, mark a verse read, earn a badge
2. Wait 10–30 seconds for CloudKit push
3. Open device B → all three changes appear in the app without manual refresh
4. On device B: edit the bookmark's notes, change a preference toggle
5. Wait, check device A → changes appear

If two-device test fails but single-device test passes, file as a follow-up; sync correctness is hard to debug and may need iteration. Single-device passing is the minimum bar.

**Step 5: Commit Phase 2**

```bash
git status
git add <each-modified-file-explicitly>
git commit -m "feat: add CloudKit sync via SwiftData (Phase 2)"
```

(Per standing memory, the user runs the commit; the assistant does not.)

---

## Task 9: Pre-submission step (USER, not Claude)

**Run this only before submitting to TestFlight or the App Store.** Not needed for development builds on simulator/device.

**Step 1: Deploy CloudKit schema to Production**

1. Visit https://icloud.developer.apple.com/dashboard
2. Select container `iCloud.MAHR.Partner.AlBayan`
3. Click Schema tab
4. Click "Deploy Schema Changes…" → confirm deployment to Production
5. Verify in Production environment that the same record types exist as in Development

This is one-time per schema change. If you later add fields to a `@Model` class, repeat this step.

---

## Done

- App syncs bookmarks + reading progress automatically across iOS devices via SwiftData + CloudKit
- All Phase 1 dead code finally removed
- Single source of truth for premium status (PurchaseManager owns the StoreKit listener)
- Schema deployed to production once you ship to the App Store

If anything goes wrong post-merge, see the design doc's "Risks & Rollback" section for emergency procedures.
