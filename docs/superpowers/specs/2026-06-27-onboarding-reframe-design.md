# Onboarding Reframe - Tafakkur (AlBayan)

**Date:** 2026-06-27
**Status:** Approved design, ready to build
**Reference:** `tiktok_carousel_sapphire_gems/` (problem -> solution arc); rebrand positioning "Read. Reflect. Grow." (see memory `project_tafakkur_rebrand`)

## Goal
Reframe onboarding from an **authority + scholarship-credentials** pitch into a **reflection / growth** story that matches the Tafakkur rebrand. The current flow opens with a hadith about "the best guidance is the guidance of Muhammad" and a mission screen selling "authentic classical and contemporary Sunni scholarship" - it answers *"is this legit and comprehensive?"* but never *"what will this fix for me?"* The reframe makes the felt problem (you recite, but it never lands) and the reflect/grow promise the spine.

This is a **copy-only reframe** across the existing 13-screen flow. No screens added or removed, no flow logic changed.

## Positioning decisions (locked)
- **Spine:** hybrid - keep the existing screen set and order; re-point copy only.
- **Angle:** "Reciting to reflecting" (growth / identity shift). Pain = *plateau*: years of reciting, but it stays on the surface. Promise = understand it, reflect on it, let it change you.
- **Opener:** swap the "Best Guidance" hadith for **Qur'an 47:24** - the verse *is* the problem ("locks upon the hearts"). Sacred anchor retained; 47:24 is from Surah Muhammad, so the Prophetic thread stays without the authority framing.
- **Voice:** aspirational, quietly reverent, plain words, short lines, payoff-led. NOT academic; no "scholarship resume" register; no carousel-style "let's be honest" snark. **No em dashes in UI copy** (use a plain hyphen).
- **Throughline:** **Read - Reflect - Grow** becomes screen 2's skeleton; each later screen serves one pillar. The pillar is *writing logic*, not an on-screen tag (the flow does not march cleanly Read->Reflect->Grow, so visible pillar chips would look erratic).

## Scope - what does NOT change
- Screen count (13), screen order, navigation, `TabView` paging, Skip button, auto-advance behavior (except a suggested timing bump on screen 1, below).
- All animations, layout structure, fonts, and theme adaptivity. Every screen already branches on `themeManager.isSapphire`; new strings flow through the existing styling unchanged.
- Notification opt-in logic in `DailyVerseScreen` / `ProgressNotificationsScreen` and `completeOnboarding()` in `OnboardingFlowView`. Buttons, bindings, permission flow untouched.
- Profile setup fields (name + preferred language) and their bindings.
- The Gems concept-bubble reveal interaction and its "The Core Insight / Why it matters" structure and sample content.
- StoreKit, premium gating, data files.

This is a **string-level reframe** inside existing SwiftUI views.

---

## Screen-by-screen copy

Format: **screen N - file - pillar**; `current` -> **proposed** (exact target strings).

### 1 - HadithScreen.swift - OPENER
Rebuild the screen body around 47:24 (same structure as today: eyebrow + Arabic block + English block + attribution, plus one new kicker line). Keep all animations, the geometric background, and tap/swipe-to-continue.
- eyebrow `"The Best Guidance"` -> **`"The Qur'an asks"`**
- Arabic (verbatim from bundled `AlBayan/AlBayan/Data/quran_data.json` verse 47:24), set on two lines:
  **`أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ`**
  **`أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَآ`**
- English block (currently 4 lines) -> four lines, adapted from the app's canonical translation (drop "Then" and the "[their]" brackets for display):
  **`"Do they not reflect`** / **`upon the Qur'an,`** / **`or are there locks`** / **`upon the hearts?"`**
- attribution `"— Prophet Muhammad ﷺ"` -> **`"Qur'an 47:24 · Surah Muhammad"`**
- **NEW kicker line** below attribution (own fade-in, secondary/tertiary text): **`"You've recited it for years. When did it last reach your heart?"`**
- Suggested: bump the 5s auto-advance to ~6s to allow reading the added kicker (keep tap/swipe).
- **Rename** `HadithScreen` -> `OpeningVerseScreen` (struct, file -> `OpeningVerseScreen.swift`, the `.tag(0)` reference in `OnboardingFlowView`, the header comment, and the `AlBayan.xcodeproj/project.pbxproj` file reference). The name is otherwise stale and misleading.

### 2 - MissionScreen.swift - THE TURN
Keep the shimmering `تفكّر` mark and all animation. Replace the headline, sub, and feature list.
- headline `"This app brings those teachings to your fingertips"` -> **`"Time to do more than read it."`**
- sub `"Through authentic classical and contemporary Sunni scholarship, with balanced comparative perspectives"` -> **`"Understand it. Reflect on it. Let it change you."`**
- Replace the **four** `HighlightRow`s (Complete Quranic text / 4 layers / Daily verses / Save bookmarks) with **three** rows that are the Read-Reflect-Grow promise:
  1. icon `book.fill` - **`"Read it in words that finally click."`**
  2. icon `sparkles` - **`"Reflect on what each verse asks of you."`**
  3. icon `leaf.fill` - **`"Grow - carry one thing forward, daily."`**
- The dropped "authentic scholarship" reassurance is **not lost** - it relocates to screen 3 (Layers), reframed as clarity.

### 3 - LayersScreen.swift - READ
- title `"4 Layers of Wisdom"` -> **`"Understand it at your own depth."`**
- subtitle `"Tap each layer to explore"` -> **`"From plain-words simple to deep classical tafsir - real scholarship, in language you'll actually follow."`**
- Keep the four layer rows (Foundation / Classical Sunni / Contemporary / Comparative) and their expanded descriptions; they carry the scholar names (Tabari, Ibn Kathir, Qurtubi) and the trust function. No change to row content.

### 4 - QuickGemsScreen.swift - REFLECT (hero)
- eyebrow `"Precious insights unveiled"` -> **`"The one big idea"`**
- Keep title `"Gems"` (feature brand).
- Supporting line (set existing subtitle/tagline, or add one beneath the title): **`"The verse's heart in a sentence - and the one thing it asks of you today."`**
- Preserve the concept-bubble reveal, the `"The Core Insight:"` / `"Why it matters:"` labels, and the Ayat al-Kursi sample content.

### 5 - QuizFeatureScreen.swift - REFLECT
- title `"Test Your Knowledge"` -> **`"See what actually stayed with you."`**
- subtitle `"Quizzes for every surah"` -> **`"A short quiz for every surah - not to grade you, to help it stick."`**
- tagline `"Deepen your understanding through reflection"` -> **`"Not a test. A way to make it stick."`**
- Keep the sample question, options, and the `"🏛️ Foundation"` sample-category label.
- **Result-tier reframe (register leak):** the result screen currently crowns the user `"Scholar Level"` / `عالم` / `"Excellent understanding!"` - academic ranking. Reframe all result tiers in the file away from scholar ranks toward "it's landing" language. Known top tier:
  - `"Scholar Level"` -> **`"It's landing"`**
  - `"Excellent understanding!"` -> **`"It's starting to stay."`**
  - Arabic `عالم` -> **`رَسَخَ`** ("it took root"; same root as *ar-rasikhuna fil-'ilm*) - **confirm with the `arabic-quality-checker` agent before shipping.**
  - The plan must enumerate the full set of result tiers from the file and reframe each consistently (this spec only quotes the one tier visible in the copy inventory).

### 6 - DailyChallengeScreen.swift - GROW
- title `"Daily Challenge"` -> **`"A daily nudge to reflect."`**
- subtitle `"A new challenge every day"` -> **`"One question, one minute. A small reflection that adds up."`**
- tagline `"Learn something new every day in under a minute"` -> **`"Keep the streak. Keep growing."`**
- Keep sample question/options and the streak/"TODAY" sample labels.

### 7 - DailyCrosswordScreen.swift - REFLECT (light)
- title `"Daily Crossword"` -> **`"Make the words stick - the fun way."`**
- subtitle `"A new crossword every day"` -> **`"A quick daily crossword for your Qur'anic vocabulary."`**
- Drop or replace tagline `"A fun way to grow your Qur'anic vocabulary"` (now redundant with the subtitle) -> **`"Two minutes. Genuinely fun."`**
- Keep the `"SOLVED!"` sample-state label.

### 8 - SeasonalFeaturesScreen.swift - GROW
- title `"Special Seasons"` -> **`"Grow most when it matters most."`**
- subtitle `"Unique experiences for blessed months"` -> **`"When Ramadan and Dhul-Hijjah arrive, guided journeys appear - so the blessed days don't slip by."`** ("don't slip by" is a deliberate callback to the opener.)
- Keep both season cards (Ramadan Journey / Dhul-Hijjah Journey), their feature bullets, and the functional tagline about the seasonal tab appearing automatically.

### 9 - ProgressTrackingScreen.swift - GROW
- title `"Track Your Progress"` -> **`"See yourself grow, verse by verse."`**
- subtitle `"Master the Quran, verse by verse"` -> **`"Every verse you reflect on is counted - your journey, saved."`**
- Keep the sample verse and the `"Your progress syncs across all your devices"` trust line.

### 10 - ProfileSetupScreen.swift - SETUP (light touch)
- title `"Welcome 👋"` -> **`"Let's make this yours."`**
- subtitle `"Let's personalize your experience"` -> **`"Your name, your language - so every reflection feels like it's for you."`**
- Keep `YOUR NAME` / `PREFERRED LANGUAGE` labels, placeholder, and `Continue` button.

### 11 - DailyVerseScreen.swift - READ
- title `"Your Daily Companion"` -> **`"One verse to carry into your day."`**
- subtitle `"Start each day with a meaningful verse"` -> **`"A meaningful verse each morning - a small pause that sets the tone."`**
- section title `"Based on Islamic Calendar"` -> **`"Chosen for the Islamic season"`** (keep the section copy beneath it).
- Keep the `Enable Daily Verses` button, enabled-state text, and "enable later in Settings" note. **Notification logic unchanged.**

### 12 - ProgressNotificationsScreen.swift - GROW
- title `"Stay Motivated"` -> **`"Small steps, kept up, change you."`**
- subtitle `"Build your reading streak and earn badges"` -> **`"Gentle nudges to keep your streak alive."`**
- Keep cards 1 (Track Your Progress) and 2 (Build Streaks).
- **Card 3 (register leak):** `"Earn Badges"` / `"Complete surahs and hit milestones to unlock achievements"` -> **`"Reach milestones"`** / **`"Complete surahs and reach milestones along the way."`**
- Keep the `Enable Progress Reminders` button and "enable later" note. **Notification logic unchanged.**

### 13 - FinalScreen.swift - CLOSER
- title `"Begin Your Journey"` -> **`"Read. Reflect. Grow."`**
- subtitle `"Tap below to begin"` -> **`"This is where it stops slipping away."`** (closes the loop opened by 47:24 / "none of it stayed".)
- button `"Get Started"` -> **`"Start reflecting"`**

---

## Optional stretch (deferred, NOT in this build)
A light **reorder** so the flow walks Read -> Reflect -> Grow cleanly (e.g. move `DailyVerseScreen` up near Layers, cluster the reflect screens, end on the grow screens before setup). Out of the "keep the tour, re-point headlines" scope chosen for this pass. Default: no reorder.

## Files
Edit (copy only, preserve all animation/layout/binding/theme code):
- `AlBayan/Views/Onboarding/HadithScreen.swift` -> rebuild as the 47:24 opener **and rename to** `OpeningVerseScreen.swift`
- `AlBayan/Views/Onboarding/MissionScreen.swift` (headline/sub + 4 rows -> 3)
- `AlBayan/Views/Onboarding/LayersScreen.swift`
- `AlBayan/Views/Onboarding/QuickGemsScreen.swift`
- `AlBayan/Views/Onboarding/QuizFeatureScreen.swift` (+ result-tier reframe)
- `AlBayan/Views/Onboarding/DailyChallengeScreen.swift`
- `AlBayan/Views/Onboarding/DailyCrosswordScreen.swift`
- `AlBayan/Views/Onboarding/SeasonalFeaturesScreen.swift`
- `AlBayan/Views/Onboarding/ProgressTrackingScreen.swift`
- `AlBayan/Views/Onboarding/ProfileSetupScreen.swift`
- `AlBayan/Views/Onboarding/DailyVerseScreen.swift`
- `AlBayan/Views/Onboarding/ProgressNotificationsScreen.swift`
- `AlBayan/Views/Onboarding/FinalScreen.swift`
- `AlBayan/Views/Onboarding/OnboardingFlowView.swift` (update the `.tag(0)` struct reference + comment for the rename)
- `AlBayan.xcodeproj/project.pbxproj` (only for the file rename; do in Xcode or update the matching `PBXFileReference` / `PBXBuildFile` entries)

## Acceptance criteria
- Every `current` string above is replaced with its `proposed` target; no onboarding screen still reads "the guidance of Muhammad" (as a mission), "authentic ... Sunni scholarship" (as the pitch), "Test Your Knowledge", "Scholar Level", "Stay Motivated", or "Earn Badges".
- Screen 1 Arabic matches `quran_data.json` 47:24 verbatim; any changed Arabic (quiz result word) is confirmed by `arabic-quality-checker`.
- No em dashes in any new UI string; voice stays plain and short.
- Project compiles. Onboarding still advances through all 13 screens; notification opt-ins and profile setup still function; both Sapphire and default themes render the new copy (eyebrow casing, fonts) correctly.
