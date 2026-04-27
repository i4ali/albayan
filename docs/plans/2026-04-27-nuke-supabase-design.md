# Nuke Supabase — Phase 1 Design

**Date:** 2026-04-27
**Status:** Approved (design only — implementation plan to follow)
**Phase:** 1 of 2 (Phase 2 is CloudKit, separate design)

## Context

The AlBayan source code was forked from a similar app (Thaqalayn) which is live and uses Supabase as its cloud backend. AlBayan will not use Supabase at all. This design covers Phase 1: complete removal of Supabase, leaving the app as a fully-functional, device-local-only experience. Phase 2 (a separate design) will introduce CloudKit for cross-device sync.

Today, Supabase touches 13 Swift files across 116 references and powers:
- Email/password auth, Sign in with Apple, anonymous auth, password reset, account deletion
- Bookmark sync (offline-first with three-step sync)
- Reading-progress sync (verse progress, streak, badges, stats, preferences)
- Premium status fetch/write

## Goal & Non-Goals

### Goal
Remove every trace of Supabase from the codebase. The app remains fully usable: bookmarks and reading progress continue to work, but only on the device they were created on.

### In scope
- Delete the `supabase-swift` SwiftPM dependency
- Delete `SupabaseService.swift`, `AuthenticationView.swift`, `AccountDeletionView.swift`
- Strip Supabase sync code from `BookmarkManager`, `ProgressManager`
- Convert `PremiumManager` to derive `isPremium` from StoreKit `Transaction.currentEntitlements`
- Remove all auth UI flows from `WelcomeView`, onboarding `FinalScreen`, `ContentView`, `SettingsView`
- Strip Supabase URL/anon key from `Config.swift` (delete the file if nothing else uses it)
- Delete the Supabase project server-side (manual step, called out in plan)

### Non-goals (deferred to Phase 2)
- Adding CloudKit
- Cleaning up `@Published` properties on the managers (`isSyncing`, `errorMessage`, `isAuthenticated`, `hasConflict`, `syncStatus`) — they stay for now to keep blast radius small; Phase 2 will revisit
- Cross-device sync of any data
- Removing the `Bookmark.syncStatus` model field

## Approach

**Surgical excision** (chosen over full manager rewrite or stub-then-cleanup).

Touch each affected file, remove only Supabase imports/observers/calls. Keep `BookmarkManager` and `ProgressManager` structurally intact — they already have full local `UserDefaults` persistence underneath the sync layer. We delete the sync layer, leaving the local persistence path intact. Public APIs and `@Published` surface stay the same so call sites don't break. Phase 2 will likely revisit the manager APIs anyway when CloudKit lands.

## What Gets Deleted

### Files removed entirely
- `AlBayan/Services/SupabaseService.swift` (~620 lines)
- `AlBayan/Views/AuthenticationView.swift`
- `AlBayan/Views/AccountDeletionView.swift`
- `AlBayan/Config.swift` — verify nothing else imports `Config.*` or `ProjectInfo`, then delete

### Xcode project changes (`AlBayan.xcodeproj/project.pbxproj`)
- Remove all entries referencing `supabase-swift`:
  - `XCRemoteSwiftPackageReference` (`73E0BC212E3D3ABB00E517DE`)
  - Package product (`73E0BC202E3D3ABB00E517DE`)
  - Frameworks build file (`73412EC52E42B89100AE42D0`)
  - Package products list entry
- Remove file references for the three deleted Swift files
- `Package.resolved` regenerates automatically on next build

### Symbols/types (defined in `SupabaseService.swift`, removed transitively)
- `SupabaseService` class
- `SupabaseError` enum
- Database row models (`BookmarkRow`, `ReadingProgressRow`, premium row, etc.) — only used for the wire format

### Entitlements
`AlBayan.entitlements` only contains `com.apple.developer.applesignin`. After SIWA goes away, this can be removed entirely (and the `CODE_SIGN_ENTITLEMENTS` build setting cleared) — flag in plan.

## Managers: Sync Layer Stripped

### `BookmarkManager.swift`
- Remove `import Supabase`, the `supabaseService` property, and `setupSupabaseObservers()`
- Remove `forceSyncWithSupabase()`, `signOutAndClearRemoteData()`, all calls to `supabaseService.syncBookmarks/fetchBookmarks/deleteBookmark/signInAnonymously`
- Keep `@Published` flags (`isSyncing`, `errorMessage`, `syncStatus`, `isAuthenticated`) as inert defaults. `isAuthenticated` becomes a constant `false`. Phase 2 cleans these up.
- `Bookmark.syncStatus` field on the model: keep the field (avoids touching every persistence path), it stays `.pendingSync` forever locally — harmless

### `ProgressManager.swift`
- Same pattern: remove `supabaseService`, `setupSupabaseObservers()`, `signOutAndClearRemoteData()`, the three-step sync block (~lines 208–365), and conflict-resolution code (`hasConflict`, `conflictMessage`)
- Keep local `UserDefaults` persistence (`saveVerseProgress`, `saveStreak`, `saveBadges`, `saveStats`, `savePreferences`) — that's what's been doing the actual heavy lifting offline-first
- `@Published` flags stay inert as in BookmarkManager

### `PremiumManager.swift`
- Drop `checkPremiumStatus()` (Supabase fetch) and `clearPremiumStatus()` (logout-driven)
- Replace with a StoreKit-driven update: on init, iterate `Transaction.currentEntitlements`, set `isPremium = true` if any unrevoked entitlement matches the product ID; subscribe to `Transaction.updates` for real-time changes
- `PurchaseManager` already has the `Transaction.updates` listener — `PremiumManager` listens independently to keep them decoupled
- Drop the `UserDefaults` cache (`premiumStatusKey`) — StoreKit's local entitlement cache is already the offline-safe source of truth; double-caching invites drift

## Auth UI Removal & Onboarding Rewire

### `WelcomeView.swift`
- Currently has a "Sign in / Create account" CTA that presents `AuthenticationView`, plus a "Continue without account" path
- Becomes single-CTA: "Continue" → `markWelcomeAsShown()` → into the app
- Remove the `.fullScreenCover` for `AuthenticationView` and any associated state

### `Views/Onboarding/FinalScreen.swift:132`
- Currently the onboarding's last step presents `AuthenticationView`
- Replace with a plain "Get started" button that dismisses onboarding

### `ContentView.swift`
- `:288` — auth presentation, remove
- `:678` — `AccountDeletionView` presentation, remove
- `:663–664` — calls to `bookmarkManager.signOutAndClearRemoteData()` / `progressManager.signOutAndClearRemoteData()`, remove (whole sign-out flow goes)
- Any `.task` / `.onAppear` blocks calling `SupabaseService.shared.checkAuthState()` or `PremiumManager.checkPremiumStatus()` — remove

### `SettingsView.swift`
- Remove the entire account section: sign-in row, sign-out row, "Delete account" row, the `icloud.fill` row at `:258`, the comment placeholder at `:369`
- Other settings (theme, audio, notifications, language) untouched

### Other Supabase-touching views
`PaywallView.swift`, `BadgeAwardView.swift`, `QuizResultsView.swift`, `HomeView.swift`, `VerseSummaryView.swift`, `SurahDetailView.swift`, `QuizView.swift`, `QuickOverviewView.swift`, `NotificationsView.swift`, `Components/DiscoveryCarousel.swift`, plus other onboarding screens.

For each: remove the `import Supabase`, replace `isAuthenticated` reads with `false` (or delete the conditional branch entirely if it's now dead). Implementation plan will enumerate each with a precise diff.

## Server-Side Cleanup & Secrets

`Config.swift:14–15` ships a hardcoded Supabase URL and anon key in source control. Anon keys are intended to be public (they're guarded by RLS on the server), but the underlying project still exists.

### Manual step (called out in plan, not done by code)
- Delete the Supabase project at dashboard reference `awiuswwmvlmmvkkfghvc` ("AlBayan", us-east-1, org `zijygqgebsdmibiwdxis`)
- One-way destructive action — performed manually in the Supabase web console
- After deletion, the anon key in git history points to nothing

### No git history rewrite
Standard practice for an exposed-but-revoked anon key. If history scrubbing is desired, that's a separate decision and follow-up.

## Verification & Acceptance Criteria

### Build-time gates (must all pass)
- `grep -ri "supabase" AlBayan/ --include="*.swift"` → zero matches
- `grep -i "supabase" AlBayan.xcodeproj/project.pbxproj` → zero matches
- `find . -name "Package.resolved" -exec grep -l supabase {} \;` → empty
- `import Supabase` appears in zero files
- Project builds clean with no warnings about missing types or unresolved references
- No file references `AuthenticationView`, `AccountDeletionView`, `SupabaseService`, `Config.supabase*`

### Runtime smoke tests (manual on simulator)
1. Fresh install → onboarding completes → lands in app, no auth prompts anywhere
2. Add a bookmark → kill app → relaunch → bookmark persists
3. Read verses → progress/streak/badges advance → kill app → relaunch → all preserved
4. Settings has no account section, no sign-in/sign-out/delete-account rows
5. Paywall: tap purchase → StoreKit sandbox completes → `isPremium` flips to true → premium content unlocks; relaunch → still premium
6. Restore Purchases works (sandbox)
7. Network off → app fully usable, no error banners about sync failing

### Negative checks
- Airplane mode on first launch — no crashes, no infinite spinners (since there's no network call to make)
- No background tasks attempting any network sync

## Phase 2 Hand-Off

### State at end of Phase 1
- App is local-only, fully functional, releasable
- `BookmarkManager` / `ProgressManager` keep their `@Published` sync flags inert
- `Bookmark.syncStatus` field still exists on the model

### What Phase 2 will need to do (separate design, separate plan)
- Add CloudKit entitlement (`com.apple.developer.icloud-services` + `com.apple.developer.icloud-container-identifiers`)
- Define CloudKit record types for `Bookmark` and the reading-progress entities (`VerseProgress`, `ReadingStreak`, `BadgeAward`, `ProgressStats`, `ProgressPreferences`)
- Wire push-based sync: `CKDatabaseSubscription` for the private database, `NSPersistentCloudKitContainer` if migrating to Core Data, or a custom sync engine on top of the existing `UserDefaults` storage (decision deferred)
- Re-purpose or remove the inert `@Published` flags
- Handle "user not signed into iCloud" gracefully — app stays local-only in that case

### Open questions for Phase 2 (do not resolve now)
- Storage: stay on `UserDefaults` + custom CloudKit sync, or migrate to Core Data + `NSPersistentCloudKitContainer`?
- Conflict resolution strategy (last-write-wins vs. merge)
- How to handle CloudKit quota on large progress histories
