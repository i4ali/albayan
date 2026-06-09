# Today Tab — Design

**Date:** 2026-06-08
**Status:** Approved (brainstorming)
**App version at design time:** v1.2 (build 4)

## Summary

Add a new **Today** dashboard tab as the app's landing tab, and rename the
existing **Home** tab to **Quran** (its content is already the full surah
browser). The Today tab is a light-themed dashboard — matching the app's
Warm/Rosewater themes — that surfaces a daily reminder verse, a resume-reading
card, and a daily du'a, plus the standard top-bar avatar and notification bell.

The dark mockup (`simulator_screenshot_FF45A5D5-…png`) defines the layout and
elements only; the visual treatment follows the app's existing **light** theme.

## Decisions (from brainstorming)

1. **Theme:** Light, matching the app (no standalone dark surface, no app-wide
   dark mode). The hero "Reminder" card uses the standard `purpleGradient`
   (purple in Warm / dusty-rose purple in Rosewater) with white text — the same
   treatment as the existing "Read Full Tafsir" CTA. **No gold anywhere.**
2. **Du'a of the day:** Build a small curated, rotating du'a dataset from
   authentic sources (with citations).
3. **Continue reading:** Deep-link straight into the last-read surah/verse
   (fallback Al-Fātiḥa), reusing the existing `.navigateToVerse` path.
4. **Tab bar:** Match the mockup exactly (labels + icons below).

## A. Tab bar restructure (`AlBayan/Views/MainTabView.swift`)

Five tabs:

| Tag | Label | View | SF Symbol | Change |
|-----|-------|------|-----------|--------|
| 0 | **Today** | `TodayTab` → `TodayView` | `sun.max` | **new** |
| 1 | **Quran** | `HomeTab` (content unchanged) | `book` | renamed from "Home" / `house.fill` |
| 2 | Explore | `ExploreTab` | `sparkles` | — |
| 3 | Progress | `ProgressTab` | `chart.bar.fill` | icon was `chart.pie.fill` |
| 4 | **Journey** | `JourneyHubView` | `map` | renamed from "Journeys" |

- `selectedTab` default stays `0` (now Today).
- Existing `.navigateToJourney` handler: update `selectedTab = 3` → `selectedTab = 4`.
- **Add** a `.navigateToVerse` handler in `MainTabView` that sets
  `selectedTab = 1` (Quran), so a resume triggered from the Today tab switches
  to the Quran tab where `HomeView` already routes the verse
  (`HomeView.swift:122`). `ContentView` continues to own its global overlays.

## B. `TodayView` layout (top → bottom)

A `ScrollView` over a `VStack`, on `themeManager.primaryBackground`. Order:

1. **Top bar** — reuse `ProfileAvatar` (left) + `Spacer` + `NotificationBell`
   (right). Both are top-level reusable views in `ContentView.swift`
   (`:822`, `:876`). (BookmarkBadge is omitted here — not in the mockup.)
2. **Hijri pill** — `22 DHUL-HIJJAH · MON`. `cardBackground` fill + `strokeColor`
   stroke, capsule. Source: `IslamicCalendarManager`.
3. **Greeting** — `Assalāmu 'alaykum 👋`, `secondaryText`.
4. **Title** — `Today`, large bold (`primaryText`).
5. **Reminder hero card** — filled `purpleGradient`, white text, soft accent
   shadow (mirrors `fullTafsirButton` in `QuickOverviewView.swift`). Contents:
   - eyebrow `✦ A REMINDER FOR TODAY`
   - verse English translation (serif, scales with `ReadingSettingsManager`)
   - citation `‹SurahName› · ‹surah›:‹verse›`
   - Tap → deep-link to that verse's full tafsir via `.navigateToVerse`.
6. **Continue-reading card** — eyebrow `CONTINUE READING` + a `cardBackground` +
   `strokeColor` card:
   - New user (no last-read): "Start your journey" / "Open Surah Al-Fātiḥa" /
     **▶ Begin**
   - Returning user: "Continue reading" / "Surah ‹name›, verse ‹n›" /
     **▶ Continue**
   - Button uses `purpleGradient` + white text. Tap → resume (see §E).
7. **Du'a-of-the-day card** — `cardBackground` + `strokeColor` card: bubble icon,
   title (e.g. "At iftar (breaking fast)"), category, trailing chevron. Tap →
   `DuaDetailSheet` (Arabic + transliteration + English + source).

All cards align to the same horizontal padding and corner radius used elsewhere
in the app (e.g. 20pt continuous corners, as in the Gems cards).

## C. Data sources & reuse map

No view-model layer — observe existing singletons via `@StateObject`, matching
the codebase (`ThemeManager`, `ReadingSettingsManager`, etc.).

| Element | Source | Symbol |
|---------|--------|--------|
| Reminder verse | `NotificationManager.selectTodayVerse()` → `DataManager.getVerse(surah:verse:)` | `NotificationManager.swift:114`, `DataManager.swift:148` |
| Verse translation (per language) | `VerseWithTafsir.translation(for:)` + `CommentaryLanguageManager` | `QuranModels.swift` |
| Hijri date / weekday | `IslamicCalendarManager` (`monthName`, `islamicDayOfWeek`, day) | `IslamicCalendarManager.swift` |
| Reading scale | `ReadingSettingsManager.shared.scale` | `ReadingSettingsManager.swift` |
| Avatar / bell | `ProfileAvatar`, `NotificationBell` | `ContentView.swift:822/876` |
| Theme tokens | `ThemeManager` (`primaryBackground`, `cardBackground`, `strokeColor`, `purpleGradient`, text colors) | `ThemeManager.swift` |

**Continue-reading source:** add two keys, `@AppStorage("lastReadSurah")` and
`@AppStorage("lastReadVerse")`, written when `SurahDetailView` opens (`.onAppear`
/ when a target verse is set). Absent ⇒ Al-Fātiḥa (surah 1, verse 1) empty state.
This is simpler and more reliable than inferring "most recent" from
`ProgressManager.verseProgress` (which has no per-verse timestamp ordering).

## D. Daily du'a dataset

- **Data file:** `AlBayan/AlBayan/Data/daily_duas.json` (the bundled-data dir —
  same location as `quran_data.json`). ~20 short, authentic daily du'as.
- **Model** (`QuranModels.swift`):
  ```swift
  struct DailyDua: Codable, Identifiable {
      let id: Int
      let title: String          // e.g. "At iftar (breaking fast)"
      let category: String       // e.g. "Worship"
      let arabic: String
      let transliteration: String
      let english: String
      let source: String         // e.g. "Abu Dawud 2357"
  }
  ```
- **Manager:** `DailyDuaManager` singleton, `selectTodayDua() -> DailyDua?`,
  rotating by Islamic day-of-month (mirrors `selectTodayVerse()`).
- **Sourcing:** content from authentic references (Hisnul Muslim / Qur'an, with
  citations). Kept small; **user reviews `daily_duas.json` before shipping.**
  No invented wording.

## E. Navigation wiring

- **Reminder card tap** and **Begin/Continue tap** both post
  `.navigateToVerse` with `userInfo: ["surah": Int, "verse": Int]`.
- `MainTabView` (new handler) sets `selectedTab = 1`; `HomeView` performs the
  in-tab navigation into `SurahDetailView` with the target verse highlighted.
- **Du'a card tap** presents `DuaDetailSheet` (local sheet state in `TodayView`).

## F. New / changed files

**New**
- `AlBayan/Views/Tabs/TodayTab.swift` — thin wrapper (matches `HomeTab` pattern)
- `AlBayan/Views/TodayView.swift` — dashboard content
- `AlBayan/Views/DuaDetailSheet.swift` — du'a detail sheet
- `AlBayan/Services/DailyDuaManager.swift` — daily du'a rotation
- `AlBayan/AlBayan/Data/daily_duas.json` — curated du'a data

**Changed**
- `AlBayan/Views/MainTabView.swift` — tab restructure + `.navigateToVerse` handler
- `AlBayan/Models/QuranModels.swift` — `DailyDua` model
- `AlBayan/Views/SurahDetailView.swift` — write `lastReadSurah` / `lastReadVerse`

## G. Out of scope (v1, YAGNI)

- Dynamic avatar initials (stays the existing "U")
- Notification badge count on the bell
- A full du'a library/browser screen
- App-wide dark mode

## H. Open items / review needed

- `daily_duas.json` content to be reviewed by the user for authenticity before
  release.
- Confirm `daily_duas.json` is added to the app target's bundle resources
  (same membership as `quran_data.json`).
- Verify the exact `Surah` name property used for the citation
  (`englishName`) and the empty-state surah lookup for Al-Fātiḥa.
