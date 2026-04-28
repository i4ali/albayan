# CloudKit (Phase 2) Design

**Date:** 2026-04-27
**Status:** Approved (design only — implementation plan to follow)
**Phase:** 2 of 2 (Phase 1, Supabase removal, completed in commit `8cd9395`)

## Context

Phase 1 stripped Supabase entirely and left the app as a fully-functional, device-local-only experience using `UserDefaults` for bookmarks and reading progress. Phase 2 adds cross-device sync via SwiftData + CloudKit.

After Phase 2, a user signed into the same iCloud account on multiple iOS devices will see their bookmarks, verse progress, streak, badges, stats, and preferences sync automatically across devices with no UI affordance — silent, invisible sync.

## Goal & Non-Goals

### Goal
Add cross-device sync for the same data Phase 1 retained locally, using SwiftData with `cloudKitDatabase: .private`. Apple's runtime handles sync, conflict resolution, push, and retries.

### In scope
- New SwiftData `@Model` classes for the 6 entity types (replacing the existing Codable structs)
- A single shared `ModelContainer` configured with `.cloudKitDatabase(.private("iCloud.MAHR.Partner.AlBayan"))` in `AlBayanApp`
- Rewritten `BookmarkManager` and `ProgressManager` (SwiftData-backed, business logic preserved, dead Phase-1 code removed)
- Final removal of Phase 1's deferred dead code (inert `@Published` flags, `pendingDeletes` apparatus, `SyncStatusToast` UI, `BookmarkSyncStatus` enum, the `Bookmark.syncStatus` field)
- Collapse the duplicate `Transaction.updates` listener (Phase 1 reviewer item #7)
- Silent fallback when iCloud is unavailable

### Non-goals
- Migrating any existing `UserDefaults` bookmarks/progress (fresh start — Phase 2 starts SwiftData empty; UserDefaults keys abandoned in place)
- Syncing quiz results, Ramadan journey, theme/audio preferences, TTS voices, or rating-prompt state (Phase 1 scope only)
- Any sync-state UI (no banners, no "synced/not signed in" indicator, no toast)
- Public CloudKit DB or shared records / collaboration features
- Web or non-Apple-platform access
- A `@Query`-in-views idiomatic refactor (manager singletons preserved)

## Approach

**Bottom-up SwiftData migration with manager rewrites.**

1. Define 6 `@Model` classes mirroring the existing struct types
2. Configure `ModelContainer` with `.cloudKitDatabase(.private)` in `AlBayanApp`
3. Add CloudKit entitlement + container ID in `AlBayan.entitlements` (already done — Xcode UI step performed manually)
4. Rewrite `BookmarkManager` and `ProgressManager` to use `ModelContext` for CRUD; preserve their public business-logic API; drop inert sync flags and dead code paths
5. Remove the final tranche of Phase 1 deferred dead code from views
6. Verify on simulator (single-device tests + optional two-device sync test)

Apple's SwiftData runtime handles the actual sync, conflict resolution, push subscriptions, and retries. No custom sync engine code from us.

### Alternatives ruled out

- **CloudKit raw CKRecord + custom sync engine** — significant code surface (~500-800 LOC); SwiftData removes that work entirely.
- **Core Data + `NSPersistentCloudKitContainer`** — older, more boilerplate; SwiftData is the modern equivalent and the project already targets iOS 18.2 (no compatibility concern).
- **`@Query`-in-views idiomatic refactor** — every consuming view changes; too much blast radius for unclear gain.
- **Migration of existing UserDefaults data** — explicit user choice: AlBayan is pre-launch, fresh start is acceptable.

## SwiftData Schema

Six `@Model` classes replace the existing structs. Constraints imposed by SwiftData + CloudKit: every property has a default value or is optional; no `@Attribute(.unique)`; relationships must be optional with explicit inverses; no `userId` field (no auth).

### `Bookmark` (replaces `struct Bookmark` at `QuranModels.swift:399`)
- Drop: `userId`, `syncStatus`
- Keep: `id: UUID = UUID()`, `surahNumber: Int = 0`, `verseNumber: Int = 0`, `surahName: String = ""`, `verseText: String = ""`, `verseTranslation: String = ""`, `notes: String? = nil`, `tags: [String] = []`, `createdAt: Date = .now`, `updatedAt: Date = .now`
- Add relationship: `collection: BookmarkCollection? = nil` (with inverse on the collection side)

### `BookmarkCollection`
- Drop: `userId`, `bookmarkIds: [UUID]` (replaced by relationship)
- Keep: `id: UUID = UUID()`, `name: String = ""`, `descriptionText: String? = nil` (renamed from `description` to avoid `Identifiable.description` collision), `createdAt: Date = .now`, `updatedAt: Date = .now`
- Add: `@Relationship(deleteRule: .nullify, inverse: \Bookmark.collection) var bookmarks: [Bookmark] = []`

### `UserBookmarkPreferences` (singleton — one per iCloud account)
- Drop: `userId`, `isPremium` (StoreKit-derived, not user data)
- Keep: `bookmarkLimit: Int = 10`, `defaultTags: [String] = []`, `sortOrderRaw: String = "date_desc"`, `groupByRaw: String = "none"`
- Computed accessors: `var sortOrder: BookmarkSortOrder { get/set }` and `var groupBy: BookmarkGroupBy { get/set }` map raw strings ↔ enum

### `VerseProgress`
- Mirrors current struct field-for-field with all properties given defaults
- One instance per verse the user has touched (likely hundreds over time)

### `ReadingStreak` (singleton)
- All current fields with defaults: `currentStreak: Int = 0`, `longestStreak: Int = 0`, `lastReadDate: Date? = nil`, etc.

### `BadgeAward`
- All current fields with defaults
- One instance per earned badge

### `ProgressStats` (singleton)
- All current fields with defaults

### `ProgressPreferences` (singleton)
- `notificationsEnabled: Bool = true`, `celebrationsEnabled: Bool = true`, `showStreakInHeader: Bool = true`

### Singleton handling
For the four singletons (`UserBookmarkPreferences`, `ReadingStreak`, `ProgressStats`, `ProgressPreferences`), the manager fetches all instances on init. If zero, creates one. If 2+ (race between two devices initializing simultaneously before sync), keeps the one with the latest `updatedAt`/`lastUpdated` and deletes the rest. Implemented as a `consolidateSingleton<T>()` helper. Idempotent.

## ModelContainer & CloudKit Configuration

A single shared `ModelContainer` is configured at app launch in `AlBayanApp.swift`:

```swift
@main
struct AlBayanApp: App {
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

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
    }
}
```

### Key behaviors
- **Private database only.** No public/shared DBs.
- **Silent fallback.** If iCloud is unavailable (not signed in, restricted, network down), SwiftData runs the local store and queues changes for later sync. No errors surfaced to the user.
- **Schema initialization.** SwiftData creates the development CloudKit schema on first launch. Production schema must be promoted manually via the CloudKit Console before App Store / TestFlight submission (one-time per schema change).
- **`try!` on container init.** Failure here is fatal — without persistence, nothing else works.

### Manager-context binding
Manager singletons (`BookmarkManager.shared`, `ProgressManager.shared`) acquire a `ModelContext` from the container directly. They hold a reference to the container at init time (set during app startup) and access its `mainContext` on the main actor. Avoids threading the container through SwiftUI environment when both managers and the container need to be reachable as singletons.

## Manager Rewrites

### `BookmarkManager`

**Public API kept (signatures unchanged):**
- `@Published var bookmarks: [Bookmark]`, `collections: [BookmarkCollection]`, `preferences: UserBookmarkPreferences?`, `isLoading: Bool`
- `addBookmark(...)`, `updateBookmark(...)`, `deleteBookmark(...)`, `toggleBookmark(...)`
- `createCollection(...)`, `renameCollection(...)`, `deleteCollection(...)`, `addBookmarkToCollection(...)`, `removeBookmarkFromCollection(...)`
- `isAlreadyBookmarked(surahNumber:verseNumber:)` — preserved
- Free-tier limit enforcement (`bookmarkLimit = 10`) — preserved

**Deleted:**
- `@Published var isSyncing`, `errorMessage`, `syncStatus`, `isAuthenticated`
- `pendingDeletes: Set<UUID>`, `pendingDeletesKey`, `loadPendingDeletes()`, `savePendingDeletes()`
- All `UserDefaults`-based `loadLocal*()` / `saveLocal*()` functions and their `*Key` constants
- `currentUserId` computed property

**Added:**
- `private var modelContext: ModelContext` (assigned in init from the shared container)
- `private func refresh()` — re-fetches `Bookmark` and `BookmarkCollection`; updates `@Published` properties
- Listener for SwiftData remote-change notifications to refresh when sync brings in changes from another device

**Mutation pattern:**

```swift
func addBookmark(surahNumber: Int, verseNumber: Int, ...) {
    guard !isAlreadyBookmarked(...), bookmarks.count < bookmarkLimit else { return }
    let bookmark = Bookmark(surahNumber: surahNumber, ...)
    modelContext.insert(bookmark)
    try? modelContext.save()
    refresh()
}
```

### `ProgressManager`

**Public API kept:**
- `@Published var verseProgress`, `streak`, `badges`, `stats`, `preferences`, `pendingBadge`
- All business-logic methods: `markVerseAsRead(...)`, `addSawab(...)`, `markSurahCompleted(...)`, `updateStreak()`, `awardBadge(...)`, `getTodaysVersesCount()`, full Progress Stats / Badge Management sections
- `resetProgress()` — now deletes every `@Model` instance and recreates the four singletons fresh

**Deleted:**
- `@Published var isSyncing`, `syncStatus`, `errorMessage`, `isAuthenticated`, `hasConflict`, `conflictMessage`
- All `*Key` constants and `loadLocalData()` / individual `save*()` functions
- `clearAllLocalData()` (private, unused)

**Added:**
- `private var modelContext: ModelContext`
- `private func refresh()` — re-fetches all four singleton entities + the `verseProgress` and `badges` collections
- `private func ensureSingletons()` — fetches each singleton type at init; creates if zero results, consolidates if 2+ results, idempotent

**Streak / badge / sawab logic — fully preserved.** The only change is mutating a `@Model` class property automatically schedules a CloudKit upload, where before it wrote to `UserDefaults`.

## Entitlements & Project Config

### Entitlements (`AlBayan/AlBayan.entitlements`)
Already populated by Xcode UI step:

```xml
<key>aps-environment</key>
<string>development</string>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.MAHR.Partner.AlBayan</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

The `aps-environment` key was added automatically by Xcode for CloudKit silent push notifications.

### Apple Developer Portal (already done by user)
- iCloud capability enabled on the `MAHR.Partner.AlBayan` App ID
- Container `iCloud.MAHR.Partner.AlBayan` created
- iCloud capability added to the Xcode project's Signing & Capabilities pane with the container checked

### Xcode project (`project.pbxproj`)
No file additions needed — Xcode 16 file-system-synchronized groups pick up new Swift files automatically. The `CODE_SIGN_ENTITLEMENTS = AlBayan/AlBayan.entitlements` build setting already exists.

## Phase 1 Dead-Code Cleanup (final tranche)

Items the Phase 1 code review flagged as deferred-to-Phase-2 NITs, removed as part of this work:

- **`SyncStatusToast` struct** — `ContentView.swift:643-681` (post-cleanup line numbers). No longer instantiated since `bookmarkManager.syncStatus` is gone.
- **Toast call sites** — `ContentView.swift:279-283` and `HomeView.swift:114-118`. The `if let syncStatus = bookmarkManager.syncStatus { SyncStatusToast(...) }` blocks.
- **`BookmarkSyncStatus` enum** — `QuranModels.swift:446-451`. Unreferenced once `Bookmark.syncStatus` field is gone.
- **Stale comments** flagged by the reviewer: `WelcomeView.swift:5`, `FinalScreen.swift:5,30`, `ContentView.swift:65`.

### Duplicate `Transaction.updates` listener (Phase 1 reviewer item #7)
`PremiumManager` and `PurchaseManager` both listen. Phase 2 collapses this:
- Keep only `PurchaseManager`'s listener (it calls `transaction.finish()`)
- Have `PurchaseManager` call `await PremiumManager.shared.refreshFromStoreKit()` after each verified transaction (already does)
- Delete `PremiumManager`'s `updatesTask` and the `init`-side subscription
- `PremiumManager` becomes pure read-derived-state with one explicit `refresh` method

## Verification

### Build-time gates
- `xcodebuild ... clean build` → `** BUILD SUCCEEDED **`, zero new warnings
- `grep -rn "UserDefaults.standard.*\(verseProgressKey\|streakKey\|badgesKey\|statsKey\|preferencesKey\|localStorageKey\|collectionsKey\|pendingDeletesKey\)" AlBayan/` → empty
- `grep -rn "syncStatus\|isSyncing\|hasConflict\|conflictMessage\|pendingDeletes\|SyncStatusToast\|BookmarkSyncStatus" AlBayan/ --include="*.swift"` → empty
- `grep -n "import SwiftData" AlBayan/Models/QuranModels.swift AlBayan/Services/BookmarkManager.swift AlBayan/Services/ProgressManager.swift AlBayan/AlBayanApp.swift` → matches in all four

### Single-device smoke tests (manual on simulator)
1. Fresh install on simulator signed into iCloud → onboarding completes → app lands cleanly, no console errors
2. Add 3 bookmarks, mark 5 verses read, accumulate a streak. Kill app. Relaunch. All data present.
3. Delete a bookmark. Relaunch. Stays deleted.
4. Hit bookmark limit (10) → 11th add rejected per existing free-tier rule
5. Sign out of iCloud in Simulator → Settings → Apple ID. Open app. Existing bookmarks still readable (cached locally). Add a new bookmark — it persists locally. Sign back into iCloud. Bookmark uploads.
6. Airplane mode + add bookmark → relaunch with network back → bookmark eventually appears in CloudKit

### Two-device sync test (optional but recommended)
1. Sign device A and device B into the same iCloud account (two simulator instances, or simulator + real device)
2. On device A: add a bookmark, mark a verse read, earn a badge
3. Wait ~10–30 seconds (CloudKit push latency); open device B → all three changes appear without manual refresh
4. On device B: edit the bookmark's notes, change a preference toggle
5. Wait, check device A → changes appear

### CloudKit Console verification
- https://icloud.developer.apple.com/dashboard → containers → `iCloud.MAHR.Partner.AlBayan` → Private DB → Development → Records
- After single-device smoke tests: records visible under `CD_Bookmark`, `CD_VerseProgress`, etc. (SwiftData prefixes record types with `CD_`)

### App Store / TestFlight gate (manual user step)
- CloudKit Console → Schema tab → "Deploy Schema Changes…" → Production. One-time per schema change.

## Risks & Rollback

### Risks

1. **Schema is permanent once shipped to production.** SwiftData+CloudKit allows adding optional properties later, but not removing or renaming them without a new container. Mitigation: Section 2 mirrors existing struct shapes 1:1; field set is reviewed at implementation time.

2. **Singleton race condition.** Two fresh devices signed into the same iCloud account simultaneously could create duplicate `ReadingStreak`/`ProgressStats`/etc. records before first sync. Mitigation: `consolidateSingleton<T>()` helper keeps the latest-`updatedAt` record and deletes the rest. Worst case: a few minutes of progress on the losing device discarded on first sync. Acceptable.

3. **CloudKit per-zone request rate.** `markVerseAsRead` fires one CKRecord write per verse. A power user reading 100 verses in a session generates 100 writes. SwiftData batches automatically; should be fine. Worth monitoring during smoke tests.

4. **iCloud account switching.** Apple's standard behavior: SwiftData clears local store of account A's records and starts fresh with account B's. Data appears to "vanish" from the user's perspective. Matches every other CloudKit app. No special handling needed.

### Rollback

- **Pre-launch**: `git revert <merge-commit>` returns to Phase 1 local-only state. No data loss because Phase 2 explicitly chose "no migration"; existing UserDefaults data is still on disk and would be re-read by reverted Phase 1 managers.
- **Post-launch**: targeted patch release with `cloudKitDatabase: .none` in `ModelConfiguration` drops to local-only. SwiftData store stays intact; sync just stops. No code revert needed.

## Manual Steps Summary

Items the user performs (called out in the implementation plan as USER tasks, not Claude tasks):

1. **Done before implementation:**
   - Apple Developer Portal: enable iCloud capability on App ID, create container `iCloud.MAHR.Partner.AlBayan`
   - Xcode: add iCloud capability via Signing & Capabilities pane, check CloudKit + the container
2. **During implementation:**
   - Sign the simulator into iCloud (Settings → Apple ID)
3. **After implementation:**
   - Run single-device smoke tests (6 scenarios, ~10 min)
   - Optional: run two-device sync test
   - CloudKit Console spot-check: confirm records appear in `private/development`
   - Commit Phase 2 (user-driven, like Phase 1)
4. **Before App Store / TestFlight submission:**
   - CloudKit Console → "Deploy Schema Changes" → Production (one-time per schema change)
