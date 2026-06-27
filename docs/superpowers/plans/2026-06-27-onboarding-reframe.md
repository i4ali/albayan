# Onboarding Reframe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reframe the 13-screen onboarding from an authority/scholarship pitch into a "reciting -> reflecting" growth story (Tafakkur rebrand), copy-only.

**Architecture:** String-level edits inside the existing SwiftUI onboarding views. No new screens, no reorder, no flow/logic/notification/StoreKit changes. The opener screen is rebuilt around Qur'an 47:24 and renamed; every other screen keeps its layout/animation and only swaps user-facing copy. Verification is a compile build plus `grep` assertions (old strings gone, new strings present) - there are no unit tests for static SwiftUI copy and none should be invented.

**Tech Stack:** Swift / SwiftUI, Xcode 16 (file-system-synchronized project group), `xcodebuild`.

**Spec:** `docs/superpowers/specs/2026-06-27-onboarding-reframe-design.md` (exact `current -> proposed` strings for all 13 screens live there).

## Global Constraints

- **Copy-only.** Preserve all animation, layout, font, binding, and theme (`themeManager.isSapphire`) code. Do not change flow, navigation, notification opt-in logic, profile fields, or StoreKit.
- **No em dashes** in any UI string. Use a plain hyphen `-`.
- **Voice:** aspirational, quietly reverent, plain words, short lines, payoff-led. Not academic.
- **47:24 Arabic must be verbatim** from `AlBayan/AlBayan/Data/quran_data.json` (verse 47:24): `أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَآ`.
- **No screens added, removed, or reordered.** Count stays 13.
- **No auto-commit (user preference, overrides this skill's commit steps).** Each task ends with a compile + grep verification, then STOP and report the diff to the user for review. Do **not** run `git commit`; the user commits manually.
- **Compile check (compile-only; signing disabled is fine for this per project memory):**
  ```bash
  xcodebuild -project AlBayan.xcodeproj -scheme AlBayan -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
  ```
  Expected last line: `** BUILD SUCCEEDED **`
- **File rename is clean:** the project uses `PBXFileSystemSynchronizedRootGroup`, so renaming a `.swift` file needs only `git mv` + code edits - **no `project.pbxproj` edit.**

---

### Task 1: Opener - rebuild as Qur'an 47:24 and rename `HadithScreen` -> `OpeningVerseScreen`

**Files:**
- Rename: `AlBayan/Views/Onboarding/HadithScreen.swift` -> `AlBayan/Views/Onboarding/OpeningVerseScreen.swift`
- Modify: the renamed file (struct name, strings, kicker, timings)
- Modify: `AlBayan/Views/Onboarding/OnboardingFlowView.swift` (`.tag(0)` reference + comment)

**Interfaces:**
- Produces: `struct OpeningVerseScreen` with the same public shape as today - `OpeningVerseScreen(currentPage: Binding<Int>)`. `OnboardingFlowView` consumes it at `.tag(0)`.

- [ ] **Step 1: Rename the file (preserves git history)**

```bash
git mv AlBayan/Views/Onboarding/HadithScreen.swift AlBayan/Views/Onboarding/OpeningVerseScreen.swift
```

- [ ] **Step 2: Rename the struct, preview, and header comment**

In `OpeningVerseScreen.swift`:
- Header comment `//  HadithScreen.swift` -> `//  OpeningVerseScreen.swift`; the description line `//  Onboarding Screen 1: The Best Guidance (Sahih Muslim 867 / Sahih al-Bukhari 7277).` -> `//  Onboarding Screen 1: The opening verse - Qur'an 47:24 (Surah Muhammad).`
- `struct HadithScreen: View {` -> `struct OpeningVerseScreen: View {`
- `#Preview { HadithScreen(currentPage: .constant(0)) }` -> `#Preview { OpeningVerseScreen(currentPage: .constant(0)) }`

- [ ] **Step 3: Replace the eyebrow text (two occurrences - visible label + shimmer mask)**

Replace **both** `Text("The Best Guidance")` occurrences with `Text("The Qur'an asks")`.

- [ ] **Step 4: Replace the Arabic block with verse 47:24**

```swift
Text("أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ\nأَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَآ")
```
(replaces `Text("خيرُ الحديثِ\nكتابُ الله\nوخيرُ الهدْيِ\nهدْيُ محمدٍ ﷺ")`)

- [ ] **Step 5: Replace the four English-line strings (keep the four-`Text` VStack structure)**

- `Text("\"The best speech")` -> `Text("\"Do they not reflect")`
- `Text("is the Book of Allah,")` -> `Text("upon the Qur'an,")`
- `Text("and the best guidance")` -> `Text("or are there locks")`
- `Text("is the guidance of Muhammad ﷺ.\"")` -> `Text("upon the hearts?\"")`

- [ ] **Step 6: Replace the attribution (also drops the em dash)**

`Text("— Prophet Muhammad ﷺ")` -> `Text("Qur'an 47:24 · Surah Muhammad")`

- [ ] **Step 7: Add the kicker line immediately after the attribution `Text` (inside the same `VStack(spacing: 40)`)**

```swift
// Personal kicker - turns the verse on the reader
Text("You've recited it for years. When did it last reach your heart?")
    .font(themeManager.isSapphire
          ? SapphireFont.serif(16, semibold: false, italic: true)
          : .system(size: 14, weight: .medium))
    .foregroundColor(themeManager.secondaryText)
    .multilineTextAlignment(.center)
    .lineSpacing(4)
    .padding(.horizontal, 36)
    .padding(.top, 4)
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 20)
    .animation(Animation.easeOut(duration: 0.8).delay(1.7), value: isVisible)
```

- [ ] **Step 8: Re-time the continue hint and auto-advance to allow reading the kicker**

- The "Swipe or tap to continue" hint `.animation(... .delay(1.7) ...)` -> `.delay(2.0)`
- Auto-advance `DispatchQueue.main.asyncAfter(deadline: .now() + 5.0)` -> `.now() + 6.0`

- [ ] **Step 9: Update the reference in `OnboardingFlowView.swift`**

- `// Screen 1: Hadith` -> `// Screen 1: Opening verse (47:24)`
- `HadithScreen(currentPage: $currentPage)` -> `OpeningVerseScreen(currentPage: $currentPage)`

- [ ] **Step 10: Compile**

Run the Global-Constraints compile command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 11: Verify strings**

```bash
grep -rn "HadithScreen" AlBayan/                          # expect: no matches
grep -rn "أَفَلَا يَتَدَبَّرُونَ" AlBayan/Views/Onboarding/OpeningVerseScreen.swift   # expect: 1 match
grep -rn "When did it last reach your heart" AlBayan/Views/Onboarding/OpeningVerseScreen.swift  # expect: 1 match
grep -rn "best guidance is the guidance of Muhammad\|The Best Guidance" AlBayan/Views/Onboarding/   # expect: no matches
```

- [ ] **Step 12: STOP - report the diff to the user for review. Do not commit.**

---

### Task 2: The Turn - `MissionScreen` headline/sub + 4 feature rows -> 3 Read/Reflect/Grow rows

**Files:**
- Modify: `AlBayan/Views/Onboarding/MissionScreen.swift`

**Interfaces:**
- Consumes: existing `HighlightRow(icon:text:isVisible:delay:)` (unchanged).

- [ ] **Step 1: Replace the headline**

`Text("This app brings those teachings to your fingertips")` -> `Text("Time to do more than read it.")`

- [ ] **Step 2: Replace the sub-headline**

`Text("Through authentic classical and contemporary Sunni scholarship, with balanced comparative perspectives")` -> `Text("Understand it. Reflect on it. Let it change you.")`

- [ ] **Step 3: Replace the four `HighlightRow`s with three**

Delete the four existing `HighlightRow(...)` calls (Complete Quranic text / 4 layers / Daily verses / Save bookmarks) and replace with:

```swift
HighlightRow(
    icon: "book.fill",
    text: "Read it in words that finally click.",
    isVisible: isVisible,
    delay: 1.4
)

HighlightRow(
    icon: "sparkles",
    text: "Reflect on what each verse asks of you.",
    isVisible: isVisible,
    delay: 1.6
)

HighlightRow(
    icon: "leaf.fill",
    text: "Grow - carry one thing forward, daily.",
    isVisible: isVisible,
    delay: 1.8
)
```

- [ ] **Step 4: Compile** - Global-Constraints command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Verify strings**

```bash
grep -rn "Time to do more than read it" AlBayan/Views/Onboarding/MissionScreen.swift    # expect: 1
grep -rn "Read it in words that finally click" AlBayan/Views/Onboarding/MissionScreen.swift  # expect: 1
grep -rn "Sunni scholarship\|brings those teachings" AlBayan/Views/Onboarding/MissionScreen.swift  # expect: no matches
```

- [ ] **Step 6: STOP - report the diff to the user for review. Do not commit.**

---

### Task 3: Quiz screen - `QuizFeatureScreen` headline/sub/tagline + result-tier reframe (with Arabic check)

**Files:**
- Modify: `AlBayan/Views/Onboarding/QuizFeatureScreen.swift`

- [ ] **Step 1: Read the whole file first** to locate the result-tier strings. The copy inventory only surfaced the top tier (`"Scholar Level"` / `عالم` / `"Excellent understanding!"`); there may be additional lower tiers. Enumerate every result-tier label/message in the file before editing.

- [ ] **Step 2: Replace the heading copy**

- `Text("Test Your Knowledge")` -> `Text("See what actually stayed with you.")`
- `Text("Quizzes for every surah")` -> `Text("A short quiz for every surah - not to grade you, to help it stick.")`
- tagline `Text("Deepen your understanding through reflection")` -> `Text("Not a test. A way to make it stick.")`

- [ ] **Step 3: Reframe the result tier(s) away from academic ranks**

Top tier (known):
- `"Scholar Level"` -> `"It's landing"`
- `"Excellent understanding!"` -> `"It's starting to stay."`

For any additional tiers found in Step 1, rewrite their label + message in the same "is it landing / is it staying" register (no "scholar", "expert", "master", "knowledge level" wording). Keep score thresholds and logic unchanged.

- [ ] **Step 4: Confirm the Arabic result word before changing it**

Proposed: Arabic `عالم` -> `رَسَخَ` ("it took root"). Dispatch the `arabic-quality-checker` agent: ask it to validate `رَسَخَ` as a 1-word quiz-result label meaning "it took root / it stayed" in this reflection context, and to suggest a better single word if not ideal. Apply its verdict (use its recommended word). Do **not** finalize the Arabic without this check.

- [ ] **Step 5: Compile** - Global-Constraints command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Verify strings**

```bash
grep -rn "See what actually stayed with you" AlBayan/Views/Onboarding/QuizFeatureScreen.swift   # expect: 1
grep -rn "Test Your Knowledge\|Scholar Level" AlBayan/Views/Onboarding/QuizFeatureScreen.swift  # expect: no matches
```

- [ ] **Step 7: STOP - report the diff (note the Arabic checker's verdict) to the user for review. Do not commit.**

---

### Task 4: Feature screens - straight copy swaps (Layers, Gems, Daily Challenge, Crossword, Seasonal, Progress Tracking)

**Files (modify, copy only):**
- `LayersScreen.swift`, `QuickGemsScreen.swift`, `DailyChallengeScreen.swift`, `DailyCrosswordScreen.swift`, `SeasonalFeaturesScreen.swift`, `ProgressTrackingScreen.swift` (all under `AlBayan/Views/Onboarding/`)

- [ ] **Step 1: LayersScreen.swift**

- `Text("4 Layers of Wisdom")` -> `Text("Understand it at your own depth.")`
- `Text("Tap each layer to explore")` -> `Text("From plain-words simple to deep classical tafsir - real scholarship, in language you'll actually follow.")`
- Leave the four layer rows and their expanded descriptions unchanged.

- [ ] **Step 2: QuickGemsScreen.swift** (read the file to find the eyebrow + where the title sits)

- eyebrow `Text("Precious insights unveiled")` -> `Text("The one big idea")`
- Keep the title `Text("Gems")`.
- Supporting line beneath the title: set the existing subtitle string to `"The verse's heart in a sentence - and the one thing it asks of you today."`. If no subtitle `Text` exists beneath the title, add one in the same style/placement the screen already uses for secondary text.
- Do **not** touch the concept-bubble reveal, the `"The Core Insight:"` / `"Why it matters:"` labels, or the Ayat al-Kursi sample content.

- [ ] **Step 3: DailyChallengeScreen.swift**

- `Text("Daily Challenge")` -> `Text("A daily nudge to reflect.")`
- `Text("A new challenge every day")` -> `Text("One question, one minute. A small reflection that adds up.")`
- `Text("Learn something new every day in under a minute")` -> `Text("Keep the streak. Keep growing.")`
- Leave the sample question/options and streak/"TODAY" labels unchanged.

- [ ] **Step 4: DailyCrosswordScreen.swift**

- `Text("Daily Crossword")` -> `Text("Make the words stick - the fun way.")`
- `Text("A new crossword every day")` -> `Text("A quick daily crossword for your Qur'anic vocabulary.")`
- `Text("A fun way to grow your Qur'anic vocabulary")` -> `Text("Two minutes. Genuinely fun.")`
- Leave the `"SOLVED!"` sample label unchanged.

- [ ] **Step 5: SeasonalFeaturesScreen.swift**

- `Text("Special Seasons")` -> `Text("Grow most when it matters most.")`
- `Text("Unique experiences for blessed months")` -> `Text("When Ramadan and Dhul-Hijjah arrive, guided journeys appear - so the blessed days don't slip by.")`
- Leave both season cards, their bullets, and the "seasonal tab appears automatically" tagline unchanged.

- [ ] **Step 6: ProgressTrackingScreen.swift**

- `Text("Track Your Progress")` -> `Text("See yourself grow, verse by verse.")`
- `Text("Master the Quran, verse by verse")` -> `Text("Every verse you reflect on is counted - your journey, saved.")`
- Leave the sample verse and the "syncs across all your devices" line unchanged.

- [ ] **Step 7: Compile** - Global-Constraints command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Verify strings**

```bash
cd AlBayan/Views/Onboarding
grep -rn "Understand it at your own depth\|The one big idea\|A daily nudge to reflect\|Make the words stick\|Grow most when it matters most\|See yourself grow, verse by verse" .  # expect: 6 matches (one per screen)
grep -rn "4 Layers of Wisdom\|Precious insights unveiled\|Special Seasons\|Track Your Progress\|Master the Quran" .  # expect: no matches
```

- [ ] **Step 9: STOP - report the diff to the user for review. Do not commit.**

---

### Task 5: Setup, notifications, and closer - copy swaps (Profile, Daily Verse, Progress Notifications, Final)

**Files (modify, copy only):**
- `ProfileSetupScreen.swift`, `DailyVerseScreen.swift`, `ProgressNotificationsScreen.swift`, `FinalScreen.swift` (all under `AlBayan/Views/Onboarding/`)

- [ ] **Step 1: ProfileSetupScreen.swift**

- `Text("Welcome 👋")` -> `Text("Let's make this yours.")`
- `Text("Let's personalize your experience")` -> `Text("Your name, your language - so every reflection feels like it's for you.")`
- Leave `YOUR NAME` / `PREFERRED LANGUAGE` labels, placeholder, and `Continue` button unchanged.

- [ ] **Step 2: DailyVerseScreen.swift**

- `Text("Your Daily Companion")` -> `Text("One verse to carry into your day.")`
- `Text("Start each day with a meaningful verse")` -> `Text("A meaningful verse each morning - a small pause that sets the tone.")`
- section title `Text("Based on Islamic Calendar")` -> `Text("Chosen for the Islamic season")`
- Leave the section copy beneath it, the `Enable Daily Verses` button, the enabled-state text, and the "enable later in Settings" note unchanged. **Do not touch notification logic.**

- [ ] **Step 3: ProgressNotificationsScreen.swift**

- `Text("Stay Motivated")` -> `Text("Small steps, kept up, change you.")`
- `Text("Build your reading streak and earn badges")` -> `Text("Gentle nudges to keep your streak alive.")`
- Card 3: `"Earn Badges"` -> `"Reach milestones"`; `"Complete surahs and hit milestones to unlock achievements"` -> `"Complete surahs and reach milestones along the way."`
- Leave cards 1 & 2, the `Enable Progress Reminders` button, and the "enable later" note unchanged. **Do not touch notification logic.**

- [ ] **Step 4: FinalScreen.swift**

- `Text("Begin Your Journey")` -> `Text("Read. Reflect. Grow.")`
- `Text("Tap below to begin")` -> `Text("This is where it stops slipping away.")`
- button `Text("Get Started")` -> `Text("Start reflecting")`

- [ ] **Step 5: Compile** - Global-Constraints command. Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Verify strings**

```bash
cd AlBayan/Views/Onboarding
grep -rn "Let's make this yours\|One verse to carry into your day\|Small steps, kept up, change you\|Read. Reflect. Grow.\|Start reflecting" .  # expect: 5 matches
grep -rn "Welcome 👋\|Your Daily Companion\|Stay Motivated\|Earn Badges\|Begin Your Journey\|Get Started" .  # expect: no matches
```

- [ ] **Step 7: Final full-flow sanity check**

Confirm `OnboardingFlowView` still wires 13 tags (0-12) and `totalPages = 13`. No screen added/removed/reordered.

```bash
grep -rn "em dash check" /dev/null; grep -rn "—" AlBayan/Views/Onboarding/   # expect: no matches (no em dashes anywhere in onboarding)
```

- [ ] **Step 8: STOP - report the diff to the user for review. Do not commit.**

---

## Self-Review

**1. Spec coverage:** All 13 screens from the spec are covered - Task 1 (screen 1 opener + rename), Task 2 (screen 2 turn), Task 3 (screen 5 quiz + result-tier leak fix + Arabic check), Task 4 (screens 3, 4, 6, 7, 8, 9), Task 5 (screens 10, 11, 12 incl. the "Earn Badges" leak fix, 13 closer). The optional reorder is correctly excluded (spec marks it deferred). The "scholarship reassurance moves to Layers" handoff is realized in Task 4 Step 1's new subtitle.

**2. Placeholder scan:** No "TBD/TODO". The two "read the file first" instructions (Task 3 Step 1 result tiers; Task 4 Step 2 Gems subtitle slot) are deliberate discovery steps with explicit fallback actions, not placeholders - they exist because the copy inventory could not see full layout/state for those two screens.

**3. Type/name consistency:** The only renamed symbol is `HadithScreen` -> `OpeningVerseScreen`, updated in the file, its `#Preview`, and `OnboardingFlowView` (Task 1 Steps 2 & 9). `HighlightRow`'s signature is reused unchanged (Task 2). No other symbols change.

## Notes for execution
- Per user preference: **review is implementer + spec-compliance only; skip the code-quality reviewer.** (This is copy, gated by compile + grep + spec match.)
- Per user preference: **no auto-commit** - stop after each task for the user to review and commit.
