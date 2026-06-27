# Daily Features (Sunni) — Engine + UI Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or subagent-driven-development) to implement task-by-task.

**Goal:** Bring the two daily features (Daily Challenge, Daily Crossword) to life in AlBayan — copy the sect-agnostic engine verbatim, rebuild the UI in AlBayan's Sapphire theme, wire the cards into the Today tab + premium gate + onboarding, and verify a clean build. The trilingual content (`daily_challenges.json`, `daily_crosswords.json`) is already authored and bundled.

**Architecture:** 3 layers from the handoff (`daily-features-sunni/`). Engine = copy-verbatim Swift (models/managers/providers) — pure logic + UserDefaults + JSON, no theme/sect coupling. UI = rebuild from the handoff UX specs using AlBayan's `Sp*`/`ThemeManager` design system. Wiring = two premium-gated cards on `TodayView`, foreground refresh in `AlBayanApp`, two onboarding slides. **No `.pbxproj` edits** — the project uses Xcode-16 synchronized folders (files on disk in `Models/`/`Services/`/`Views/`/`Data/` are auto-included).

**Tech Stack:** SwiftUI, `ThemeManager`/`SapphireComponents`/`SapphireFont`, `CommentaryLanguageManager`, `ReadingSettingsManager`, `PremiumManager`. Build: `xcodebuild`.

---

## ⚠️ Read before executing

1. **No auto-commit (project rule).** Each "Checkpoint" = stop, show diff, user commits. Never `git commit`.
2. **Spec-review only** between tasks (skip the code-quality reviewer), per standing preference.
3. **Source of truth for behavior/UX:** `daily-features-sunni/README.md`, `01-daily-challenge.md`, `02-daily-crossword.md`. The engine files to copy live in `daily-features-sunni/src/`.
4. **No `.pbxproj` surgery.** Synchronized folders auto-include files. Just place files in the correct dirs. (Verified: `objectVersion=77`, 6 `PBXFileSystemSynchronizedRootGroup`, 0 individual refs for existing Data JSON / Views.)
5. **Build gate after each phase:**
   ```
   xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator \
     -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO | tail -5
   ```
   Expected: `** BUILD SUCCEEDED **`. (Compile-only flags are fine here; do NOT use them if later running in the simulator — CloudKit traps on launch otherwise.)
6. **Content is done & bundled.** `AlBayan/AlBayan/Data/daily_challenges.json` (72) and `daily_crosswords.json` (365) already exist and validate. Do not regenerate.

---

## File destinations (AlBayan dirs — synchronized, auto-included)

| Source (`daily-features-sunni/src/`) | → Destination | Layer |
|---|---|---|
| `DailyChallengeModels.swift` | `AlBayan/Models/DailyChallengeModels.swift` | Engine (defines `LocalizedText`) |
| `DailyChallengeManager.swift` | `AlBayan/Services/DailyChallengeManager.swift` | Engine |
| `DailyChallengeProvider.swift` | `AlBayan/Services/DailyChallengeProvider.swift` | Engine |
| `DailyCrosswordModels.swift` | `AlBayan/Models/DailyCrosswordModels.swift` | Engine (reuses `LocalizedText`) |
| `DailyCrosswordManager.swift` | `AlBayan/Services/DailyCrosswordManager.swift` | Engine |
| `DailyCrosswordProvider.swift` | `AlBayan/Services/DailyCrosswordProvider.swift` | Engine |
| `DailyChallengeStrings.swift` | `AlBayan/Views/DailyChallengeStrings.swift` | Chrome strings (sect-neutral) |
| `DailyCrosswordStrings.swift` | `AlBayan/Views/DailyCrosswordStrings.swift` | Chrome strings |
| — (new) | `AlBayan/Views/DailyChallengeCard.swift` | UI (rebuild) |
| — (new) | `AlBayan/Views/DailyChallengeView.swift` | UI (rebuild) |
| — (new) | `AlBayan/Views/DailyCrosswordCard.swift` | UI (rebuild) |
| — (new) | `AlBayan/Views/DailyCrosswordView.swift` | UI (rebuild) |
| — (new) | `AlBayan/Views/Onboarding/DailyChallengeScreen.swift` | UI (rebuild) |
| — (new) | `AlBayan/Views/Onboarding/DailyCrosswordScreen.swift` | UI (rebuild) |
| — (new) | `AlBayan/Services/Haptics.swift` | small helper (no equivalent exists) |

Modified existing files: `AlBayan/Services/PremiumManager.swift`, `AlBayan/Views/TodayView.swift`, `AlBayanApp.swift`, `AlBayan/Views/Onboarding/OnboardingFlowView.swift`.

---

## Theme-token mapping (handoff `Em*`/Thaqalayn → AlBayan)

Rebuild UI with these. Inject `@StateObject private var themeManager = ThemeManager.shared` (+ `languageManager`, `readingSettings`, `premiumManager` as needed). Follow the existing dual-branch idiom (`themeManager.isSapphire ? Sapphire : warm`) like `QuizFeatureScreen`/`SurahDetailView`.

| Handoff token | AlBayan |
|---|---|
| `isMidnightEmerald` | `themeManager.isSapphire` |
| `primaryText / secondaryText / tertiaryText` | `themeManager.primaryText / .secondaryText / .tertiaryText` |
| `accentColor / accentBright / accentChip` | `themeManager.accentColor / .accentBright / .goldChipFill` |
| `accentGradient` | `themeManager.goldGradient` (a.k.a. `accentGradient`) |
| `strokeColor` | `themeManager.strokeColor` (soft: `.strokeSoft`) |
| `glassSurface` / `EmCard{}` | `themeManager.cardBackground` / wrap in `SpCard(elev:glow:radius:) { … }` |
| `onAccentText` | `themeManager.onAccentText` |
| `primaryBackground` / `EmeraldBackground` / `AdaptiveModernBackground` | `SpShell { … }` or `ZStack { themeManager.backgroundLayer; … }`; full-screen detail views match `StoryDetailView` (`AdaptiveModernBackground()` base) |
| hero/Today-card fill | `themeManager.reminderGradient` |
| `EmGoldCTA(title:sfSymbol:)` | `SpGoldCTA(title:systemIcon:) { … }` |
| `EmIconChip(sfSymbol:size:)` | `SpIconChip(systemIcon:size:active:)` |
| `EmType.serif(size,weight)` | `SapphireFont.serif(size, semibold:)` / `.screenTitle` / `.headline(_)` |
| `EmType.arabic(size)` | `SapphireFont.arabic(size, bold:)` / `.arabicVerse(_)` (Amiri) |
| `emEyebrow(...)` | `SapphireFont.eyebrow` + `.uppercased().tracking(2.5)`, color `accentColor` (or `SpHeading(eyebrow:)`) |
| `EmPressStyle` | `.buttonStyle(SpPressStyle())` |
| `Haptics.press()` | **new** `Haptics.impact(.light)` (see Phase P0) |
| `CommentaryLanguageManager.shared.selectedLanguage` / `.isRTL` | same — `CommentaryLanguageManager.shared` exists; apply RTL via `.environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)` + `.multilineTextAlignment(lang.isRTL ? .trailing : .leading)` |
| `ReadingSettingsManager.shared.scale` | same (`ReadingSettingsManager.shared.scale`) — **Daily Challenge reading content only** |

`LocalizedText` does **not** exist in AlBayan — it is introduced by copying `DailyChallengeModels.swift` (its `text(for:)` maps `.english/.french→en, .urdu→ur, .arabic→ar`, matching `CommentaryLanguage`).

---

## Phases / Tasks

### Phase P0 — Engine + foundation (copy verbatim)

**Files:** copy the 8 engine/chrome files per the destination table; create `AlBayan/Services/Haptics.swift`.

**Step 1:** Copy the 6 engine files + 2 `*Strings.swift` from `daily-features-sunni/src/` to their destinations **verbatim**. They are pure logic/strings; `CommentaryLanguage` already exists, so `LocalizedText` and the models compile as-is. Do not modify content.

**Step 2:** Create `AlBayan/Services/Haptics.swift`:
```swift
import UIKit
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
```

**Step 3 (build gate):** run the build command. Expected `** BUILD SUCCEEDED **` (engine is additive; nothing references it yet). If a symbol clash appears (e.g. a duplicate type name), report it.

**Step 4: Checkpoint.**

### Phase P1 — Premium hook + foreground refresh

**Files:** Modify `AlBayan/Services/PremiumManager.swift`, `AlBayanApp.swift`.

**Step 1:** Add to `PremiumManager` (mirrors existing `canAccess*` methods):
```swift
func canAccessDailyChallenge() -> Bool { isPremium }
func canAccessDailyCrossword() -> Bool { isPremium }
```

**Step 2:** In `AlBayanApp.swift`, inside the existing `.onChange(of: scenePhase)` `.active` branch (~lines 48–58, next to `PremiumManager.shared.refreshFromStoreKit()`), add the day-rollover refresh:
```swift
DailyChallengeProvider.shared.refreshIfDayChanged()
DailyCrosswordProvider.shared.refreshIfDayChanged()
DailyCrosswordManager.shared.refreshForToday()
```

**Step 3 (build gate)** → **Step 4: Checkpoint.**

### Phase P2 — Daily Challenge UI (rebuild)

**Files (create):** `AlBayan/Views/DailyChallengeCard.swift`, `AlBayan/Views/DailyChallengeView.swift`.

Build from `01-daily-challenge.md` UX specs + the theme mapping:
- **Card** — 3-state button (README §4.6): `.locked` (free → "Premium" pill via `PremiumBadgeView`/`goldChipFill`; tap → paywall), `.pending` (premium, not done → title + teaser via `DailyChallengeStrings.teaser(for:)` + chevron; tap → present `DailyChallengeView`), `.done` (checkmark + `streak.currentStreak` "🔥 N"; not tappable). State from `PremiumManager.shared.canAccessDailyChallenge()` + `DailyChallengeManager.shared.isCompletedToday` + `.streak`. Wrap in `SpCard`. Haptic on tap.
- **Play view** — full-screen `.sheet` (match `StoryDetailView` shell). Header eyebrow (`DailyChallengeStrings.dailyChallenge`) + close. Prompt + optional `arabicText` (Amiri). Answer area per format (MC/fill: option buttons → lock + mark correct/wrong + reveal; trueFalse: True/False; flashcard: reveal → "Got it"/"Review again", both mark done). Explanation after answering. `SpGoldCTA` "Done" dismisses. On answer → `manager.complete(challenge:wasCorrect:)` / `completeFlashcard(challenge:gotIt:)` (guarded once/day).
- **Reading-size:** prompt/options/answer/explanation/arabicText scale by `ReadingSettingsManager.shared.scale` (and lineSpacing); chrome fixed. **RTL** for ur/ar.

**Step (build gate)** → **Checkpoint.** *(Suggest capable model — substantial SwiftUI.)*

### Phase P3 — Daily Crossword UI (rebuild)

**Files (create):** `AlBayan/Views/DailyCrosswordCard.swift`, `AlBayan/Views/DailyCrosswordView.swift`.

Build from `02-daily-crossword.md` UX specs:
- **Card** — same 3-state pattern; `.pending` teaser `DailyCrosswordStrings.teaser`; tap → present `DailyCrosswordView(puzzle: DailyCrosswordProvider.shared.today)`. State from `canAccessDailyCrossword()` + `DailyCrosswordManager.shared.isCompletedToday` + `.streak`.
- **Play view** — full-screen `.sheet`. Header: eyebrow + live timer (mm:ss) + hint button + close. **Sparse grid** (render only cells present in some entry; cell = optional small number from `cellNumbers` + entered letter; highlight selected cell + active entry; tap toggles across/down). **Clue bar** (active entry `clue.text(for:)`, prev/next; clue localizes + RTL, grid stays LTR Latin). **Custom A–Z keyboard** (taps type + auto-advance; backspace). **Hint** reveals selected cell's correct letter, sets `usedHint`. **Solved overlay** when all filled cells match `puzzle.solution` → seal + time + streak + `SpGoldCTA` Done → `DailyCrosswordManager.shared.complete(seconds:usedHint:)`.
- **All fixed-size chrome — do NOT wire `ReadingSettingsManager`.** Grid/keyboard Latin LTR even in ur/ar; only clues localize.

**Step (build gate)** → **Checkpoint.** *(Suggest capable model — the grid + keyboard is the most complex view.)*

### Phase P4 — Today-tab wiring

**Files:** Modify `AlBayan/Views/TodayView.swift`.

**Step 1:** Add `@StateObject private var premiumManager = PremiumManager.shared` and `@State private var showChallengePaywall = false` / `showCrosswordPaywall = false` (or one shared flag) to `TodayView`.

**Step 2:** Insert `DailyChallengeCard()` then `DailyCrosswordCard()` into the main `VStack` **after `duaSection`** (~line 76–80), before `.padding(.bottom, 120)`. Each card owns its own `.sheet`s (play sheet + paywall) per the cards' design, OR `TodayView` hosts the paywall sheet — keep consistent with the card design from P2/P3.

**Step 3 (build gate)** → **Step 4: Checkpoint.** Card cycles locked→pending→done with premium toggled.

### Phase P5 — Onboarding slides

**Files (create):** `AlBayan/Views/Onboarding/DailyChallengeScreen.swift`, `DailyCrosswordScreen.swift`; **modify** `OnboardingFlowView.swift`.

**Step 1:** Build the two screens from the `QuizFeatureScreen` template (self-contained, `ThemeManager`, looping mini-demo + one-line value prop + streak flame). Challenge: auto-cycle a format demo. Crossword: tiny grid auto-filling to "solved".

**Step 2:** Register in `OnboardingFlowView` `TabView` — insert before `FinalScreen`, shift `FinalScreen` tag, and **bump `totalPages`** (11 → 13) so the page dots are correct:
```swift
DailyChallengeScreen().tag(10)
DailyCrosswordScreen().tag(11)
FinalScreen(onComplete: { completeOnboarding() }).tag(12)
```

**Step 3 (build gate)** → **Step 4: Checkpoint.**

### Phase P6 — Final verification

**Step 1:** Clean build:
```
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' clean build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO | tail -8
```
Expected `** BUILD SUCCEEDED **`.

**Step 2:** Confirm both JSONs are in the built `.app` bundle Resources (synchronized folder ⇒ should be automatic). If the providers `fatalError` at runtime later, the file isn't bundled — but compile + synced-folder membership covers this.

**Step 3:** (Optional, if running in sim) build WITHOUT the signing flags and launch to smoke-test card states + a solve; per the project note, the signing flags must be omitted to actually run (CloudKit).

**Step 4: Checkpoint.**

---

## Acceptance criteria

- [ ] 8 engine/chrome files copied verbatim; `Haptics.swift` added; `LocalizedText` resolves; build succeeds.
- [ ] `PremiumManager` has `canAccessDailyChallenge()/canAccessDailyCrossword()`; `AlBayanApp` refreshes providers on foreground.
- [ ] Both cards render the 3 states and present play sheets / paywall correctly; styled with `Sp*`/`ThemeManager`.
- [ ] Challenge: 4 formats reveal correctly; `arabicText` verbatim (Amiri); explanation after answering; reading-size scales reading content only; RTL for ur/ar.
- [ ] Crossword: grid solves (type/hint/solved overlay); fixed-size chrome; clues localize while grid stays LTR.
- [ ] Two onboarding slides registered; `totalPages` bumped.
- [ ] `** BUILD SUCCEEDED **` on a clean build; JSONs bundled.
- [ ] Nothing committed automatically.
