# Nuke Supabase — Phase 1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove every trace of Supabase from the AlBayan iOS app, leaving it fully functional as a device-local-only experience.

**Architecture:** Surgical excision. Strip the sync layer out of each service-layer manager (preserving their public API and `@Published` surface so call sites don't break), remove auth UI, delete `SupabaseService`/auth views/`Config.swift`, drop the `supabase-swift` SwiftPM dependency. Premium status becomes pure StoreKit. App stays buildable and releasable at every commit.

**Tech Stack:** Swift 5.9 / SwiftUI / iOS 17+ / Xcode 26 / StoreKit 2. No XCTest target exists in this project — verification is `xcodebuild` build success per task plus a manual simulator smoke pass at the end.

**Companion design doc:** `docs/plans/2026-04-27-nuke-supabase-design.md`

**Standing user instruction:** Per `~/.claude/.../memory/feedback_no_auto_commit.md`, the executing engineer (Claude) writes files and stops before `git commit`. Suggested commit messages are included with each task but the user runs the commit.

**Build verification command** (used after every task):

```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -20
```

Expected: exit 0, ends with `** BUILD SUCCEEDED **`.

---

## Task ordering rationale

Touchpoints are ordered leaf → root so the build stays green at every step:

1. **Service-layer sync stripping (Tasks 1–4)** — strip Supabase out of `PremiumManager`, `PurchaseManager`, `BookmarkManager`, `ProgressManager` while keeping their `@Published` props inert. Public API unchanged → no caller breakage.
2. **View-layer auth stripping (Tasks 5–9)** — remove direct `SupabaseService.shared` references from views (`WelcomeView`, `FinalScreen`, `ContentView`, `SettingsView`, `AlBayanApp`).
3. **File and dependency deletion (Tasks 10–14)** — delete the now-unreferenced files (`AuthenticationView`, `AccountDeletionView`, `SupabaseService`), strip the wire-format model in `QuranModels.swift`, drop the SwiftPM package, delete `Config.swift`, clean entitlements.
4. **Verification + manual server-side step (Tasks 15–16)** — final automated grep gates, manual simulator smoke test, manual Supabase project deletion.

---

## Task 1: Convert `PremiumManager` to StoreKit-only

**Files:**
- Modify: `AlBayan/Services/PremiumManager.swift`

**Why:** Premium status is currently fetched from Supabase. StoreKit's `Transaction.currentEntitlements` is the authoritative source and already cross-device-syncs via the App Store. Removing the Supabase dependency here unblocks `SupabaseService` deletion later.

**Step 1: Replace `PremiumManager.swift` with the StoreKit-driven version**

Replace the entire file with:

```swift
//
//  PremiumManager.swift
//  AlBayan
//
//  Manages premium status derived from StoreKit Transaction.currentEntitlements.
//  StoreKit's local entitlement cache is the offline-safe source of truth and
//  cross-device-syncs automatically via the App Store account.
//

import Foundation
import StoreKit
import Combine

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium: Bool = false

    private let productID = "com.albayan.premium"
    private var updatesTask: Task<Void, Never>?

    init() {
        Task { await refreshFromStoreKit() }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified = result else { continue }
                await self?.refreshFromStoreKit()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Re-derive `isPremium` from the current StoreKit entitlement set.
    func refreshFromStoreKit() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID, transaction.revocationDate == nil {
                found = true
                break
            }
        }
        isPremium = found
    }

    // MARK: - Access Control

    func canAccessTafsir(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessOverview(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessQuiz(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessLayer(_ layer: TafsirLayer, surahNumber: Int) -> Bool {
        if surahNumber == 1 {
            switch layer {
            case .foundation, .classical:
                return true
            case .contemporary, .comparative:
                return isPremium
            }
        }
        return isPremium
    }

    func canAccessPremiumReciter(_ reciter: Reciter) -> Bool { true }
    func getPremiumReciters() -> [Reciter] { [] }
    func getFreeReciters() -> [Reciter] { Reciter.popularReciters }

    func canAccessFastingCategory(_ categoryId: String) -> Bool {
        if categoryId == "obligation" { return true }
        return isPremium
    }

    func canAccessRamadanDay(_ dayNumber: Int) -> Bool {
        if dayNumber == 1 { return true }
        return isPremium
    }
}
```

**Verify productID matches:** before saving, confirm `com.albayan.premium` is the actual product ID by grepping:

```bash
grep -rn "productID\|product.id" AlBayan/Services/PurchaseManager.swift
```

If different, update the `productID` constant in the new file accordingly.

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(premium): derive isPremium from StoreKit entitlements (drop Supabase)
```

---

## Task 2: Strip Supabase sync from `PurchaseManager`

**Files:**
- Modify: `AlBayan/Services/PurchaseManager.swift`

**Why:** `PurchaseManager` writes premium status to Supabase after each purchase. With Task 1 done, this is dead — StoreKit `Transaction.updates` already pushes the new state into `PremiumManager`.

**Step 1: Remove the Supabase sync calls and helper**

In `AlBayan/Services/PurchaseManager.swift`:
- Delete the `syncPremiumStatusToSupabase()` private function (around lines 204–212)
- Delete the three call sites: lines 81–82, 127–128, 190 (search for `syncPremiumStatusToSupabase`)
- Replace each call site with a single line: `await PremiumManager.shared.refreshFromStoreKit()`
- Remove `import Supabase` if present at the top of the file

After edits, no Supabase references should remain in this file. Verify:

```bash
grep -in "supabase" AlBayan/Services/PurchaseManager.swift
```

Expected: no output.

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(purchase): drop Supabase premium-status sync, refresh from StoreKit
```

---

## Task 3: Strip Supabase sync from `BookmarkManager`

**Files:**
- Modify: `AlBayan/Services/BookmarkManager.swift`

**Why:** Remove all sync-layer code while preserving the `@Published` API surface so views observing `bookmarkManager.isAuthenticated` / `.isSyncing` / `.errorMessage` / `.syncStatus` still compile.

**Step 1: Edit `BookmarkManager.swift`**

Make these specific edits:

1. Remove `import Supabase` from the top of the file
2. Remove the `private var supabaseService = SupabaseService.shared` property (around line 30)
3. Initialize `@Published var isAuthenticated = false` and **make it a stored let-equivalent** by removing any code that assigns to it (it stays `false` forever)
4. Delete `setupSupabaseObservers()` entirely (around line 51)
5. Delete the `init()` body's call to `setupSupabaseObservers()` and any `if let user = supabaseService.currentUser` block
6. Delete `forceSyncWithSupabase()` entirely (around line 514)
7. Delete `signOutAndClearRemoteData()` if present
8. In the bookmark add/update/delete paths, remove all `if isAuthenticated { ... supabaseService.syncBookmarks/deleteBookmark ... }` blocks — bookmarks now persist locally only via the existing `UserDefaults`-based path
9. Remove any `await supabaseService.signInAnonymously()` calls
10. Remove the entire pull/three-step-sync code path that calls `supabaseService.fetchBookmarks()`

Verify Supabase is fully gone from this file:

```bash
grep -in "supabase" AlBayan/Services/BookmarkManager.swift
```

Expected: no output.

**Step 2: Confirm the `@Published` surface is still intact**

```bash
grep -n "@Published" AlBayan/Services/BookmarkManager.swift
```

Expected output should still include: `bookmarks`, `preferences`, `collections`, `isLoading`, `isSyncing`, `errorMessage`, `syncStatus`, `isAuthenticated`. (Inert flags stay so call sites don't break.)

**Step 3: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 4: Suggested commit**

```
refactor(bookmarks): strip Supabase sync layer (local-only persistence)
```

---

## Task 4: Strip Supabase sync from `ProgressManager`

**Files:**
- Modify: `AlBayan/Services/ProgressManager.swift`

**Why:** Same pattern as Task 3. Reading progress (verse progress, streak, badges, stats, preferences) already persists locally via `UserDefaults`; we just remove the sync layer.

**Step 1: Edit `ProgressManager.swift`**

1. Remove `import Supabase`
2. Remove `private var supabaseService = SupabaseService.shared` (around line 41)
3. Delete `setupSupabaseObservers()` entirely (around line 122) and remove its call from `init()`
4. Delete `signOutAndClearRemoteData()` (around line 184)
5. Delete the entire "Three-Step Sync Pattern" section (around lines 208–365): functions calling `supabaseService.syncReadingProgress`, `fetchReadingProgress`, `deleteReadingProgress`
6. Delete the conflict-resolution code path (`hasConflict`, `conflictMessage` setters — keep the `@Published` declarations themselves as inert)
7. In `init()` set `isAuthenticated = false` and leave it
8. Verify the local persistence functions stay intact: `saveVerseProgress`, `saveStreak`, `saveBadges`, `saveStats`, `savePreferences`

Verify Supabase is gone:

```bash
grep -in "supabase" AlBayan/Services/ProgressManager.swift
```

Expected: no output.

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(progress): strip Supabase sync layer (local-only persistence)
```

---

## Task 5: Strip auth from `WelcomeView`

**Files:**
- Modify: `AlBayan/Views/WelcomeView.swift`

**Why:** Remove the auth CTA and `AuthenticationView` presentation. Keep the welcome content; replace the auth path with a simple "Continue".

**Step 1: Edit `WelcomeView.swift`**

1. Remove the `@StateObject private var supabaseService = SupabaseService.shared` line (around line 12)
2. Remove `import Supabase` if present
3. Remove the `.fullScreenCover` / `.sheet` that presents `AuthenticationView` (around line 214)
4. Remove the `if supabaseService.isAuthenticated { ... }` block (around line 217); keep only the non-authenticated path
5. Collapse to a single primary CTA labeled "Continue" or "Get Started" that calls `markWelcomeAsShown()` and dismisses the view
6. Remove any "Sign in / Create account" button

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(welcome): drop auth CTA, single Continue button
```

---

## Task 6: Strip auth from onboarding `FinalScreen`

**Files:**
- Modify: `AlBayan/Views/Onboarding/FinalScreen.swift`

**Why:** Onboarding's last step currently presents `AuthenticationView`. Replace with a plain dismiss.

**Step 1: Edit `FinalScreen.swift`**

1. Remove `@StateObject private var supabaseService = SupabaseService.shared` (line 12)
2. Remove `import Supabase` if present
3. Remove the conditional block at line 134 (`if supabaseService.isAuthenticated { ... }`) — keep only the non-authenticated content
4. Remove the `AuthenticationView()` presentation at line 132 — replace with a "Get started" button that calls the existing onboarding-completion handler

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(onboarding): remove auth step from FinalScreen
```

---

## Task 7: Strip auth/account flows from `ContentView`

**Files:**
- Modify: `AlBayan/ContentView.swift`

**Why:** `ContentView` is the main router and has the largest surface of auth-related UI: sign-in/out flows, account deletion sheet, the cloud-sync status row, and three `SupabaseService.shared` references.

**Step 1: Edit `ContentView.swift`**

Locate and remove each of these blocks:

1. Line 470: `@StateObject private var supabaseService = SupabaseService.shared` — remove
2. Line 510: same — remove
3. Line 555: `if !supabaseService.isAuthenticated { ... }` block — delete the conditional and any "Sign in" CTA inside it
4. Lines 607–625: the `if supabaseService.isAuthenticated` cloud-sync settings rows — remove the entire block including the "Connected/Offline" status row, the `forceSyncWithSupabase()` button, and the second `if` block at line 621
5. Lines 663–664: remove the two calls `await bookmarkManager.signOutAndClearRemoteData()` / `await progressManager.signOutAndClearRemoteData()` and the surrounding sign-out flow
6. Line 678: remove the `AccountDeletionView()` presentation (likely `.sheet` or `.fullScreenCover` — remove it and its `@State` flag)
7. Line 1016: `@StateObject private var supabaseService = SupabaseService.shared` — remove
8. Remove `import Supabase` from the top

After edits, this should return zero results:

```bash
grep -in "supabase\|AccountDeletionView\|AuthenticationView" AlBayan/ContentView.swift
```

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(content-view): remove auth/account/sync UI flows
```

---

## Task 8: Strip account section from `SettingsView`

**Files:**
- Modify: `AlBayan/Views/SettingsView.swift`

**Why:** Settings has multiple sync-status rows, sign-in CTAs, and the "Delete account" link.

**Step 1: Edit `SettingsView.swift`**

Find and remove:

1. Line 247: `if bookmarkManager.isAuthenticated { ... }` block — remove the entire conditional row
2. Lines 258–261: the cloud sync status row (`icloud.fill` icon, "Cloud sync enabled" / "Not signed in" subtitle) — remove the whole row
3. Lines 670–687: the connected/offline indicator section — remove
4. Line 729: `if bookmarkManager.isAuthenticated { ... }` — remove the conditional
5. Line 871: `await bookmarkManager.forceSyncWithSupabase()` — remove the button that calls this
6. Line 369: remove the comment `// You can replace this with your actual AuthenticationView` and any associated placeholder
7. Remove any sign-in / sign-out / "Delete Account" rows that present `AuthenticationView` or `AccountDeletionView`
8. Remove `import Supabase` if present

After edits:

```bash
grep -in "supabase\|AuthenticationView\|AccountDeletionView\|forceSyncWith" AlBayan/Views/SettingsView.swift
```

Expected: no output.

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(settings): remove account section and cloud-sync status rows
```

---

## Task 9: Strip Supabase URL handling from `AlBayanApp`

**Files:**
- Modify: `AlBayan/AlBayanApp.swift`

**Why:** App entrypoint currently imports Supabase, holds a `SupabaseService.shared` reference, and has a URL-handling block for OAuth callbacks.

**Step 1: Edit `AlBayanApp.swift`**

1. Remove `import Supabase` (line 9)
2. Remove `@StateObject private var supabaseService = SupabaseService.shared` (line 14) and any `.environmentObject(supabaseService)` injection
3. Remove the `.onOpenURL` block / scene-phase URL handler at lines 32 and 77 that processes the Supabase auth callback. If the only `.onOpenURL` is for Supabase, remove the modifier entirely; if it handles other URL schemes too, only remove the Supabase branch.
4. Remove the `// Handle Supabase authentication callback` and `// Extract the URL components for Supabase auth` comments

After:

```bash
grep -in "supabase" AlBayan/AlBayanApp.swift
```

Expected: no output.

**Step 2: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 3: Suggested commit**

```
refactor(app): drop Supabase service injection and URL callback handling
```

---

## Task 10: Strip Supabase row models from `QuranModels.swift`

**Files:**
- Modify: `AlBayan/Models/QuranModels.swift`

**Why:** Wire-format database models (`ReadingProgressData` row, etc.) are no longer needed. The local in-memory shapes (`VerseProgress`, `ReadingStreak`, etc.) stay — only the Supabase DTOs go.

**Step 1: Inspect `QuranModels.swift` around line 943**

```bash
sed -n '935,1020p' AlBayan/Models/QuranModels.swift
```

Identify the `Codable` struct(s) used purely as Supabase wire models (likely `ReadingProgressData` and any `…Row` types). The block starts at the comment `/// Database model for Supabase reading_progress table`.

**Step 2: Delete those struct definitions**

Remove the comment and every Supabase-row struct that follows it, until you reach the next unrelated section. Do NOT remove the in-app domain models (`VerseProgress`, `ReadingStreak`, `BadgeAward`, `ProgressStats`, `ProgressPreferences`) — those are still used locally.

If unsure whether a struct is a wire-format DTO, grep for its name across the codebase: if it's only referenced inside (now-deleted) `SupabaseService.swift` and `ProgressManager`'s removed sync code, it's a DTO and can go.

**Step 3: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 4: Suggested commit**

```
refactor(models): drop Supabase wire-format row structs from QuranModels
```

---

## Task 11: Delete `AuthenticationView` and `AccountDeletionView`

**Files:**
- Delete: `AlBayan/Views/AuthenticationView.swift`
- Delete: `AlBayan/Views/AccountDeletionView.swift`
- Modify: `AlBayan.xcodeproj/project.pbxproj` (remove file references)

**Why:** Both files are now unreferenced (Tasks 5–8 removed every call site). Confirm and delete.

**Step 1: Confirm zero remaining references**

```bash
grep -rn "AuthenticationView\|AccountDeletionView" AlBayan/ --include="*.swift"
```

Expected: no output. If any references remain, fix them before proceeding.

**Step 2: Delete the two files**

```bash
rm AlBayan/Views/AuthenticationView.swift AlBayan/Views/AccountDeletionView.swift
```

**Step 3: Remove file references from the Xcode project**

In `AlBayan.xcodeproj/project.pbxproj`, search for `AuthenticationView.swift` and `AccountDeletionView.swift` and delete the lines containing them. There will be a few entries each (file reference, build file, group membership). Save.

```bash
grep -n "AuthenticationView\|AccountDeletionView" AlBayan.xcodeproj/project.pbxproj
```

Expected: no output.

**Step 4: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 5: Suggested commit**

```
chore: delete AuthenticationView and AccountDeletionView
```

---

## Task 12: Delete `SupabaseService.swift` and the SwiftPM dependency

**Files:**
- Delete: `AlBayan/Services/SupabaseService.swift`
- Modify: `AlBayan.xcodeproj/project.pbxproj`
- Modify: `AlBayan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

**Why:** With every call site removed in Tasks 1–10, the service file and its package dependency are now dead.

**Step 1: Confirm zero remaining `SupabaseService` references**

```bash
grep -rn "SupabaseService\|import Supabase" AlBayan/ --include="*.swift"
```

Expected: only matches inside `SupabaseService.swift` itself.

**Step 2: Delete `SupabaseService.swift`**

```bash
rm AlBayan/Services/SupabaseService.swift
```

**Step 3: Remove SwiftPM package references from `project.pbxproj`**

Open `AlBayan.xcodeproj/project.pbxproj`. Delete these lines (there are exactly four sites, IDs were captured during design):

- The `PBXBuildFile` entry referencing `Supabase in Frameworks` (`73412EC52E42B89100AE42D0`)
- The `PBXFrameworksBuildPhase` listing entry referencing the same ID
- The `packageProductDependencies` array entry referencing `73E0BC202E3D3ABB00E517DE /* Supabase */`
- The `packageReferences` array entry referencing `73E0BC212E3D3ABB00E517DE /* XCRemoteSwiftPackageReference "supabase-swift" */`
- The full `XCRemoteSwiftPackageReference "supabase-swift"` block (around line 359, 12 lines)
- The full `XCSwiftPackageProductDependency` block for `Supabase` (around line 370, 6 lines)
- The `SupabaseService.swift` file reference and group entries

After:

```bash
grep -in "supabase" AlBayan.xcodeproj/project.pbxproj
```

Expected: no output.

**Step 4: Regenerate `Package.resolved`**

```bash
rm AlBayan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

The next build will regenerate it without supabase-swift.

**Step 5: Resolve packages and build**

```bash
xcodebuild -project AlBayan.xcodeproj -resolvePackageDependencies 2>&1 | tail -5
```

Then run the build verification command. Expected: BUILD SUCCEEDED.

**Step 6: Confirm `Package.resolved` has no Supabase**

```bash
grep -i "supabase" AlBayan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

Expected: no output.

**Step 7: Suggested commit**

```
chore: delete SupabaseService and remove supabase-swift SwiftPM dependency
```

---

## Task 13: Delete `Config.swift`

**Files:**
- Delete: `AlBayan/Config.swift`
- Modify: `AlBayan.xcodeproj/project.pbxproj`

**Why:** `Config.swift` only holds the Supabase URL/anon key plus an unused `ProjectInfo` struct. With Supabase gone, the file is dead.

**Step 1: Confirm nothing else uses `Config` or `ProjectInfo`**

```bash
grep -rn "Config\.\|ProjectInfo" AlBayan/ --include="*.swift"
```

Expected: only matches inside `Config.swift` itself, plus possibly the (now-deleted) `SupabaseService.swift` location (if grep is picking up Xcode artifacts, ignore those). If any other file imports `Config.*`, stop and report — design assumed nothing else does.

**Step 2: Delete the file**

```bash
rm AlBayan/Config.swift
```

**Step 3: Remove `Config.swift` from `project.pbxproj`**

Search for `Config.swift` in `AlBayan.xcodeproj/project.pbxproj` and delete its file-reference and build-file entries.

```bash
grep -n "Config.swift" AlBayan.xcodeproj/project.pbxproj
```

Expected: no output.

**Step 4: Build**

Run the build verification command. Expected: BUILD SUCCEEDED.

**Step 5: Suggested commit**

```
chore: delete Config.swift (Supabase URL/anon key holder)
```

---

## Task 14: Clean up entitlements

**Files:**
- Modify: `AlBayan/AlBayan.entitlements`

**Why:** With Sign in with Apple removed (it was only used by `AuthenticationView`), the `com.apple.developer.applesignin` entitlement is dead. The file currently contains only that one entitlement.

**Step 1: Decide between two options**

Option A — leave the entitlements file with an empty `<dict/>` (preserves the build-setting wiring; harmless):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

Option B — delete the entitlements file entirely and clear the `CODE_SIGN_ENTITLEMENTS` build setting in `project.pbxproj`. Cleaner, but Phase 2 (CloudKit) will need to recreate it.

**Recommendation:** Option A. Phase 2 will re-add the file content with CloudKit entitlements, so leaving the empty plist in place avoids project.pbxproj surgery now.

**Step 2: Apply Option A**

Replace the contents of `AlBayan/AlBayan.entitlements` with the empty-`<dict/>` version above.

**Step 3: Build**

Run the build verification command. Expected: BUILD SUCCEEDED. (Xcode tolerates empty entitlements files.)

**Step 4: Suggested commit**

```
chore(entitlements): remove com.apple.developer.applesignin (auth dropped)
```

---

## Task 15: Final verification gates

**Files:** none modified — verification only.

**Step 1: Run all build-time gate commands**

```bash
echo "=== Swift source ==="
grep -ri "supabase" AlBayan/ --include="*.swift" || echo "(clean)"

echo "=== project.pbxproj ==="
grep -i "supabase" AlBayan.xcodeproj/project.pbxproj || echo "(clean)"

echo "=== Package.resolved ==="
grep -i "supabase" AlBayan.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved 2>/dev/null || echo "(clean)"

echo "=== AuthenticationView/AccountDeletionView ==="
grep -rn "AuthenticationView\|AccountDeletionView" AlBayan/ --include="*.swift" || echo "(clean)"

echo "=== Config references ==="
grep -rn "Config\.supabase" AlBayan/ --include="*.swift" || echo "(clean)"
```

All five must print `(clean)`.

**Step 2: Clean build from scratch**

```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' clean build 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **` with zero warnings about missing types or unresolved references.

**Step 3: Run the simulator smoke test**

Boot the simulator and exercise:

1. Fresh install (delete the app first) → onboarding completes → lands in app, **no auth prompts anywhere**
2. Add a bookmark → kill app (swipe up from app switcher) → relaunch → bookmark persists
3. Read verses across multiple sessions → progress/streak/badges advance → kill app → relaunch → all preserved
4. Settings: scroll the entire view → confirm **no account section, no sign-in/sign-out/delete-account rows, no cloud-sync status row**
5. Paywall: tap purchase → StoreKit sandbox completes → premium content unlocks → kill app → relaunch → still premium
6. Settings → "Restore Purchases" works (sandbox)
7. Toggle airplane mode → app still fully usable, no error banners about sync failing
8. Fresh install with airplane mode on from launch → no crashes, no infinite spinners

If any item fails, do not proceed to Task 16. Report the failure.

**Step 4: Suggested commit (if anything was tweaked during smoke test)**

Only if you needed follow-up fixes during smoke testing; otherwise no commit.

---

## Task 16: Manual server-side cleanup (USER, not Claude)

**This task is performed manually by the user in the Supabase web console. Claude does not run it.**

**Step 1: Delete the Supabase project**

1. Sign in to https://supabase.com/dashboard
2. Locate project: **AlBayan** (reference `awiuswwmvlmmvkkfghvc`, region us-east-1, org `zijygqgebsdmibiwdxis`)
3. Project Settings → General → Delete project
4. Confirm. This is irreversible.

After deletion, the anon key still present in git history points to a non-existent project and is fully inert.

**Step 2: (Optional) Confirm the URL is dead**

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://awiuswwmvlmmvkkfghvc.supabase.co/rest/v1/
```

Expected: a 4xx (project gone). If it still returns 200, the deletion may not have propagated yet — wait a few minutes.

---

## Done

- App is local-only, fully functional, zero Supabase footprint.
- Premium status flows through StoreKit only.
- Phase 2 (CloudKit) starts from this clean baseline. See `docs/plans/2026-04-27-nuke-supabase-design.md` § "Phase 2 Hand-Off" for what's deferred.
