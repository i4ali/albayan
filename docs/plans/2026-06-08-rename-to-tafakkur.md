# Rename AlBayan → Tafakkur — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> **Commits:** Per the repo owner's standing preference, do **not** auto-commit. Make the edits, run the verification, and **stop before `git commit`** — the owner commits on review. The `git commit` lines below are the *intended* messages, not a license to commit automatically.

**Goal:** Rebrand the app to **Tafakkur: Quran Reflection** via a display-name + App Store listing change, with **zero** change to bundle ID, CloudKit container, deep-link scheme, or user settings — so all installs, reviews, purchases, and synced data are preserved.

**Architecture:** Add `CFBundleDisplayName` (the only thing that changes the home-screen name) while leaving `PRODUCT_NAME`/`TARGET_NAME` = `AlBayan` untouched. Change the two user-facing in-app strings. Everything else (icon, ASC listing, screenshots, privacy page) is content/listing work outside the build.

**Tech Stack:** Xcode (SwiftUI), `Info.plist`, App Store Connect, Assets.xcassets, GitHub Pages (privacy hosting), the `aso-appstore-screenshots` skill.

---

## ⛔ GUARDRAILS — DO **NOT** rename any of these (rename = breakage)

| Thing | Where | Why it must stay `AlBayan` |
|-------|-------|----------------------------|
| Bundle ID `MAHR.Partner.AlBayan` | project build settings | Renaming orphans the App Store record → loses **all** installs/reviews |
| CloudKit container `iCloud.MAHR.Partner.AlBayan` | `AlBayanApp.swift:26` | Renaming wipes every user's synced bookmarks/notes |
| UserDefaults key `AlBayanAudioConfiguration` | `AudioManager.swift:97,105` | Renaming silently resets saved audio settings on update |
| URL scheme `albayan://` + `CFBundleURLName` | `Info.plist` | Renaming breaks existing deep links / push routing (Journeys hub) |
| Xcode target / scheme / folder `AlBayan` | project | Cosmetic only, invisible to users, high churn — explicitly out of scope |
| Asset name `AppIcon` | `Assets.xcassets/AppIcon.appiconset` | Keep the asset name; only replace the *art* |

**The only user-visible "AlBayan" strings to change are in Task 2.** Everything in this table stays.

---

## Task 1: Set the home-screen display name to "Tafakkur"

**Files:**
- Modify: `AlBayan/Info.plist`

**Step 1 — Add the display-name key.** Inside the top-level `<dict>` (e.g. after the `ITSAppUsesNonExemptEncryption` entry), add:

```xml
	<key>CFBundleDisplayName</key>
	<string>Tafakkur</string>
```

**Step 2 — Verify it compiles** (compile-only; the signing flag is safe here):

```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build CODE_SIGNING_ALLOWED=NO
```
Expected: `BUILD SUCCEEDED`.

**Step 3 — Verify the name on the home screen.** Run in the simulator **without** `CODE_SIGNING_ALLOWED=NO` (that flag makes it trap in CloudKit on launch). Confirm the icon label under the app reads **Tafakkur**.

**Step 4 — Commit (on owner review):**
```bash
git add AlBayan/Info.plist
git commit -m "feat(brand): set display name to Tafakkur"
```

---

## Task 2: Update the two user-facing in-app strings

**Files:**
- Modify: `AlBayan/Views/WelcomeView.swift:76`
- Modify: `AlBayan/Views/Onboarding/LayersScreen.swift:186`

**Step 1 — Welcome screen.** Change:
```swift
Text("Welcome to AlBayan")
```
to:
```swift
Text("Welcome to Tafakkur")
```

**Step 2 — Layers onboarding string.** Line 186 currently reads:
```swift
return "Unique to AlBayan: Balanced analysis comparing Sunni and Shia scholarly interpretations with academic integrity."
```
⚠️ **This copy is stale** — it describes the *old* Sunni-vs-Shia comparative model, but the app migrated to the **Sunni 3-layer tafsir** (v1.1). Renaming alone would ship an inaccurate claim. **Get owner sign-off on new copy.** Suggested replacement (aligned to the 3-layer + Reflect/Grow positioning):
```swift
return "Unique to Tafakkur: three layers for every verse — plain meaning, classical tafsir, and a reflection to carry into your day."
```

**Step 3 — Verify no user-facing "AlBayan" literals remain.** This should return **only** the three guardrail lines (`AlBayanApp.swift:26`, `AudioManager.swift:97`, `AudioManager.swift:105`):
```bash
grep -rnE '"[^"]*AlBayan[^"]*"' AlBayan --include="*.swift"
```
Expected: exactly those 3 lines, none from a `Views/` file.

**Step 4 — Rebuild** (same command as Task 1, Step 2). Expected: `BUILD SUCCEEDED`.

**Step 5 — Commit (on owner review):**
```bash
git add AlBayan/Views/WelcomeView.swift AlBayan/Views/Onboarding/LayersScreen.swift
git commit -m "feat(brand): rebrand in-app copy AlBayan → Tafakkur"
```

---

## Task 3: New app icon / wordmark  *(design task — not code-automatable)*

**Files:**
- Replace art in: `AlBayan/Assets.xcassets/AppIcon.appiconset/` (keep the asset **named** `AppIcon`)

**Steps:**
1. Produce a **Tafakkur** icon — title-case wordmark and/or the Arabic **تفكّر** mark (never all-caps `TAFAKKUR`). Reuse the brand palette; the `aso-appstore-screenshots` skill / Nano Banana tooling can generate candidates.
2. Drop the rendered PNGs into the existing `AppIcon.appiconset`, replacing the AlBayan art (keep `Contents.json` slot names).
3. Verify the new icon renders in the simulator.
4. Commit (on review): `chore(brand): new Tafakkur app icon`.

---

## Task 4: App Store Connect listing  *(manual — ASC web UI checklist)*

**Pre-req:** In ASC, confirm the exact name **`Tafakkur: Quran Reflection`** is available (App Store enforces name uniqueness at submission). If taken, fall back to `Tafakkur — Quran Reflection` or `Tafakkur: Reflect on Quran`.

Set, in **App Information / the next version's listing**:
- **Name:** `Tafakkur: Quran Reflection`
- **Subtitle:** `Deep tafsir, duas & journeys`
- **Keywords:** `tafseer,commentary,ayah,surah,islam,muslim,urdu,dhikr,tadabbur,contemplation,journal,mushaf,recite`
- **Promotional text:** *3-layer tafsir that finally makes every verse click — plus daily reflections, du'as, and guided journeys. Read. Reflect. Grow, with the Quran every day.*
- **Description:** rewrite the opening paragraph to lead with **Tafakkur** + **Read. Reflect. Grow.**, and scrub any remaining "AlBayan" / "Sunni and Shia comparison" language.

No repo change. Done in App Store Connect.

---

## Task 5: Regenerate ASO screenshots  *(design/tooling task)*

**Files:**
- `screenshots/appstore/aso/iphone/*.png`, `screenshots/appstore/aso/ipad/*.png`

The current set has **"AlBayan" baked into the captions**. Regenerate via the `aso-appstore-screenshots` skill (+ `scripts/aso_composite.py`, `scripts/aso_nano_banana.py`) with the new name and the **Read. Reflect. Grow.** voice. New filenames may use a `Tafakkur_` prefix (cosmetic). Commit (on review): `chore(brand): regenerate ASO screenshots for Tafakkur`.

---

## Task 6: Privacy page + listing docs

**Files:**
- Modify: `docs/PRIVACY_POLICY.md` (text `AlBayan` → `Tafakkur`; **leave** bundle/container IDs unchanged)
- Modify: `docs/APP_STORE_PUBLISHING_GUIDE.md`, `docs/APP_STORE_CONNECT_FORMS.md`, `docs/BUILD_FOR_APPSTORE.md` (these also still say **"Shia"** in places — fix to match the Sunni 3-layer positioning)

**Steps:**
1. Update the privacy text and **re-publish** to the hosted page (`https://i4ali.github.io/thaqalyn/privacy-policy.html`). Keep the URL/path the same so the ASC Privacy Policy URL still resolves.
2. Leave historical `docs/plans/*` design docs as-is (they're a record).
3. Commit (on review): `docs(brand): update privacy + store docs for Tafakkur`.

---

## Task 7: Final verification & release (v1.3, build 5)

1. `MARKETING_VERSION` is already `1.3`, `CURRENT_PROJECT_VERSION` `5` — the rename rides this release. (Use `@bump-version` if a fresh build number is needed.)
2. Run in simulator: home-screen label = **Tafakkur**; Welcome screen = **"Welcome to Tafakkur"**; onboarding Layers copy updated.
3. **Guardrail check** — confirm these are still `AlBayan` (must match the table above):
   ```bash
   grep -rn "MAHR.Partner.AlBayan\|AlBayanAudioConfiguration\|albayan" AlBayan/Info.plist AlBayan/AlBayanApp.swift AlBayan/Services/AudioManager.swift
   ```
4. Archive and submit alongside the new App Store Connect listing (Task 4).

---

## Out of scope (YAGNI)
- Renaming the Xcode target/scheme/folder, bundle ID, CloudKit container, URL scheme, or UserDefaults keys (see guardrails).
- A new `tafakkur://` deep-link scheme (could be *added* later as an alias; not needed now).

## Due diligence before submit
- ASC name-availability confirmation (Task 4 pre-req).
- Light trademark sanity check on "Tafakkur" as an app brand.
- Owner sign-off on the `LayersScreen` copy rewrite (Task 2, Step 2).
