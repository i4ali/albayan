# Offline Authentication & Premium Status Testing Guide

This guide documents how to test the offline-first authentication and premium status persistence features in AlBayan.

## Overview

The app implements a fully offline-first architecture for both authentication and premium status:
- **Sessions** are cached in Keychain and persist indefinitely when offline
- **Premium status** is cached alongside sessions and restored when offline
- **Network reconnection** automatically syncs and updates cached data

---

## Test 1: Offline Session Persistence

### Objective
Verify that users remain authenticated when the app is relaunched offline.

### Steps
1. Sign in to the app using any method:
   - Email/password (e.g., `ali.muhammadimran@gmail.com`)
   - Apple Sign In
   - Anonymous sign-in
2. Verify you are signed in (check profile menu)
3. Enable **Airplane Mode** on the simulator (`Device > Features > Toggle Airplane Mode`)
4. **Force quit** the app (swipe up from bottom, swipe app away)
5. **Relaunch** the app from the home screen

### Expected Results
- ✅ User remains signed in (no "Guest Mode")
- ✅ User email/ID is displayed in profile menu
- ✅ All local bookmarks are accessible
- ✅ No network error messages

### Console Logs to Watch For
```
🌐 Network monitoring started
✅ Auth check: Using valid cached session (offline mode)
✅ Premium status restored from cache: true
```

### Failure Indicators
- ❌ App shows "Guest Mode" when offline
- ❌ User is signed out
- ❌ Console shows "No cached session available"

---

## Test 2: Offline Premium Status Persistence (Premium User)

### Objective
Verify that premium users maintain their premium status when offline.

### Steps
1. Sign in as a premium user (e.g., `ali.muhammadimran@gmail.com`)
2. Verify UI shows **"Premium Member"** (green text) in profile menu
3. Navigate to any surah (2-114) and verify tafsir is accessible
4. Enable **Airplane Mode**
5. **Force quit** and **relaunch** the app
6. Check profile menu premium status
7. Try accessing tafsir for Surahs 2-114

### Expected Results
- ✅ Profile menu shows **"Premium Member"** (not "Free Tier")
- ✅ Premium status text is **green** (not orange)
- ✅ Tafsir for Surahs 2-114 is accessible
- ✅ All premium features work offline

### Console Logs to Watch For
```
✅ Auth check: Using valid cached session (offline mode)
✅ Premium status restored from cache: true
ℹ️ Offline mode - skipping premium status network check
```

### Failure Indicators
- ❌ Profile menu shows "Free Tier" (orange text)
- ❌ Premium features locked when offline
- ❌ Console shows "Premium status loaded: false"

---

## Test 3: Offline Premium Status Persistence (Free User)

### Objective
Verify that free tier users remain free tier when offline.

### Steps
1. Sign in as a free tier user or anonymously
2. Verify UI shows **"Free Tier"** (orange text) in profile menu
3. Verify Surah 1 (Al-Fatiha) is accessible
4. Verify Surahs 2-114 show "Premium Required" for tafsir
5. Enable **Airplane Mode**
6. **Force quit** and **relaunch** the app
7. Check premium status and feature access

### Expected Results
- ✅ Profile menu shows **"Free Tier"** (orange text)
- ✅ Surah 1 (Al-Fatiha) tafsir accessible
- ✅ Surahs 2-114 tafsir shows "Premium Required"
- ✅ No accidental premium access granted

### Console Logs to Watch For
```
✅ Auth check: Using valid cached session (offline mode)
✅ Premium status restored from cache: false
ℹ️ Offline mode - skipping premium status network check
```

---

## Test 4: Offline Bookmark Operations

### Objective
Verify that bookmark operations work seamlessly when offline.

### Steps
1. Sign in to the app (online)
2. Create 2-3 bookmarks
3. Verify bookmarks sync to cloud (green checkmark)
4. Enable **Airplane Mode**
5. Add a new bookmark (should work immediately)
6. Edit an existing bookmark
7. Delete a bookmark
8. **Force quit** and **relaunch** the app offline
9. Verify all bookmark changes persisted

### Expected Results
- ✅ All CRUD operations work offline
- ✅ Bookmarks persist after app relaunch
- ✅ No sync errors displayed to user
- ✅ Changes queued for sync when online

### Console Logs to Watch For
```
✅ Added bookmark for [Surah Name] [Verse]
💾 Saved [N] bookmarks to local storage
ℹ️ Offline mode - sync will retry when network available
```

---

## Test 5: Network Reconnection & Auto-Sync

### Objective
Verify that the app automatically syncs when network is restored.

### Steps
1. Sign in as premium user (online)
2. Create a bookmark
3. Enable **Airplane Mode**
4. Add another bookmark while offline
5. **Disable Airplane Mode**
6. Watch console logs for 5-10 seconds

### Expected Results
- ✅ Network restored detected automatically
- ✅ Session refreshed with Supabase
- ✅ Premium status re-validated from server
- ✅ Pending bookmarks synced to cloud
- ✅ No user intervention required

### Console Logs to Watch For
```
🌐 Network restored - refreshing auth state
✅ Auth check: Online session validated and cached with premium status: true
✅ Premium status loaded from Supabase: true
🌐 Network restored - retrying pending syncs
✅ Synced [N] bookmarks to Supabase
```

---

## Test 6: Session Expiration Handling

### Objective
Verify behavior when cached session expires.

### Steps
1. Sign in to the app
2. Wait for session to expire (default: ~1 hour for access token)
   - *To speed up testing, you can manually edit the cached session expiration in Keychain*
3. Enable **Airplane Mode**
4. **Force quit** and **relaunch** the app

### Expected Results
- ✅ App detects expired session
- ✅ User is signed out gracefully
- ✅ App shows sign-in screen
- ✅ No crash or data corruption

### Console Logs to Watch For
```
⚠️ Auth check: Cached session expired - user needs to sign in
✅ Session cleared from Keychain
```

---

## Test 7: Sign-Out While Offline

### Objective
Verify that sign-out clears cached session even when offline.

### Steps
1. Sign in to the app (online)
2. Enable **Airplane Mode**
3. Tap profile menu → **Sign Out**
4. Verify sign-out confirmation
5. **Relaunch** the app while still offline

### Expected Results
- ✅ User is signed out immediately
- ✅ Cached session cleared from Keychain
- ✅ Premium status reset to free
- ✅ App shows guest mode on relaunch
- ✅ Local bookmarks cleared (if configured)

### Console Logs to Watch For
```
✅ Premium status cleared
✅ Signed out successfully - cache cleared
✅ Session cleared from Keychain
```

---

## Test 8: Multi-User Session Isolation

### Objective
Verify that switching users properly isolates cached sessions and premium status.

### Steps
1. Sign in as User A (premium)
2. Create a bookmark
3. Verify premium status displayed
4. Sign out (online or offline)
5. Sign in as User B (free tier)
6. Enable **Airplane Mode**
7. **Force quit** and **relaunch**
8. Verify User B's data displayed

### Expected Results
- ✅ User A's bookmarks not visible to User B
- ✅ User B shows free tier status (not User A's premium)
- ✅ Cached session matches User B
- ✅ No data bleed between accounts

### Console Logs to Watch For
```
🔄 User changed from [User A ID] to [User B ID] - clearing local data
✅ Premium status restored from cache: false
```

---

## Troubleshooting

### Issue: User Signed Out When Offline
**Possible Causes:**
- Session expired (tokens only last ~1 hour)
- Keychain cache was manually cleared
- App updated and cache format changed

**Solution:**
- Sign in again when online
- Check console for "Cached session expired" message

---

### Issue: Premium Status Shows "Free Tier" When Offline
**Possible Causes:**
- Premium status wasn't fetched/cached before going offline
- Cache was corrupted or cleared
- Sign-in happened while offline (no premium status fetched)

**Solution:**
1. Sign out
2. Connect to network
3. Sign in again
4. Wait for "Premium status loaded: true" in console
5. Go offline and test again

---

### Issue: Bookmarks Not Syncing After Reconnection
**Possible Causes:**
- Authentication expired
- Network observer not detecting connectivity
- Sync already in progress

**Solution:**
- Check console for "Network restored" message
- Manually pull to refresh in bookmarks view
- Sign out and sign in again

---

## Expected Console Log Examples

### Successful Offline Session Restore (Premium User)
```
🌐 Network monitoring started
ℹ️ Auth check: No cached session available
✅ Auth check: Using valid cached session (offline mode)
✅ Premium status restored from cache: true
ℹ️ Offline mode - skipping premium status network check
💾 Loaded 5 bookmarks from local storage
```

### Successful Network Reconnection
```
🌐 Network restored - refreshing auth state
✅ Auth check: Online session validated and cached with premium status: true
✅ Premium status loaded from Supabase: true
✅ Auth state: Token refreshed - cache updated with premium status: true
🌐 Network restored - retrying pending syncs
✅ Synced 3 bookmarks to Supabase
```

### Successful Sign-In (Caching Premium Status)
```
✅ Signed in successfully: [USER-ID] - session cached with premium status: true
✅ Premium status loaded from Supabase: true
✅ Session saved to Keychain
```

---

## Architecture Summary

### Cached Data (Keychain Storage)
- **Access Token** - Used for API authentication
- **Refresh Token** - Used to get new access tokens
- **Expiration Date** - When access token expires (~1 hour)
- **User ID** - Unique user identifier
- **User Email** - Email address (if available)
- **Premium Status** - Boolean flag (true/false) ⭐ **NEW**

### Network Monitoring
- **NWPathMonitor** - Detects online/offline status changes
- **Auto-Retry** - Syncs pending operations when network returns
- **Debounced** - Prevents excessive sync attempts

### Offline-First Principles
1. **Local operations always succeed** - No network required for CRUD
2. **Network is enhancement** - Sync happens in background
3. **Zero data loss** - All changes persist locally first
4. **Graceful degradation** - Premium features work with cached status

---

## Related Files

- `/AlBayan/Services/AuthSessionStorage.swift` - Keychain session caching
- `/AlBayan/Services/SupabaseService.swift` - Authentication & network monitoring
- `/AlBayan/Services/PremiumManager.swift` - Premium status management
- `/AlBayan/Services/BookmarkManager.swift` - Offline-first bookmark sync
- `/BOOKMARK_SYNC_ARCHITECTURE.md` - Detailed sync architecture documentation

---

**Last Updated**: 2025-11-29
**Version**: 3.5 (Build 17+)
