# Dhul-Hijjah (Hajj) Journey — Design

**Date:** 2026-05-17
**Status:** Approved
**Source spec:** `dhul-hijjah-journey-export.md` (port guide from the Shia sibling app, commit `3147740`)

## Goal

Re-implement the "First Ten Days of Dhul-Hijjah" Journey as a seasonal tab in the
Sunni AlBayan app, mirroring the existing Ramadan Journey 1:1. Full spec scope.
Sunni du'a content authored now per §12 of the export, flagged for scholar review
before ship.

## Architecture

A self-contained seasonal feature. The Swift engine is a near-verbatim structural
copy of the Ramadan Journey code (Ramadan→Hajj, 30→10 days); only content and a
few wiring points differ.

Hajj season (Dhul-Qa'dah ≥25, Dhul-Hijjah ≤13) and Ramadan season are mutually
exclusive, so they **share the conditional tab slot**. The real app uses `tag(3)`
for the conditional Ramadan tab (the export's `tag(5)` assumption is wrong for
this codebase). Wiring: `if isRamadanSeason {…} else if isHajjSeason {…}` at
`tag(3)`.

Journey progress is device-local and separate from `ProgressManager`; only the
completion badge routes through `ProgressManager` (joining the existing badge
wall, sawab total, and celebration overlay).

## Components

### New files

| File | Basis |
|---|---|
| `AlBayan/Services/HajjJourneyManager.swift` | Structural copy of `RamadanJourneyManager` |
| `AlBayan/Views/HajjJourneyView.swift` | Copy of `RamadanJourneyView` |
| `AlBayan/Views/HajjDayDetailView.swift` | Copy of `RamadanDayDetailView` |
| `AlBayan/Data/hajj_journey.json` | 10 days, Sunni-sourced (§12), scholar-review flagged |

- `HajjJourneyManager`: `@MainActor ObservableObject` singleton. Publishes
  `days`, `progress`, `isLoading`, `errorMessage`. `init()` → `loadProgress()` →
  `loadDays()` → `checkYearReset()`. UserDefaults key `"hajjJourneyProgress"`.
  `checkYearReset()` compares stored `year` vs `IslamicCalendarManager.shared
  .currentIslamicYear()`. `markDayCompleted`/`unmarkDayCompleted`/`isDayCompleted`
  (guard 1...10). `checkForCompletionBadge()` → `ProgressManager.shared
  .awardHajjBadge(year:)` when all 10 complete. No-fallback: sets `errorMessage`
  if `hajj_journey.json` fails to load (no default content).
- `HajjJourneyView`: `AdaptiveModernBackground`, header with
  `hajjSeasonStatus()`, progress bar "X of 10 days" + percent, completion banner,
  `LazyVStack` of 10 `HajjDayCard`s (today / locked / completed states), premium
  lock → `PaywallView`, error section mirroring `RamadanErrorSection`.
- `HajjDayDetailView`: scrollable sections — header, du'a (Arabic
  `AmiriQuran-Regular` `.trailing`, transliteration, English, source), verses
  (per `HajjVerse`: `Quran S:V` header + "Full Tafsir" deep-link via
  `.navigateToVerse`, Arabic + translation from `DataManager.shared.getVerse`,
  relevanceNote), tafsirFocus, reflection, mark-complete toggle.

### Modified files (additive)

- `Models/QuranModels.swift` — add `HajjJourneyData`, `HajjDay`, `HajjDua`,
  `HajjVerse`, `HajjJourneyProgress` (`completionPercentage` = count/10.0,
  `isCompleted` = count ≥ 10). Add `BadgeType.hajjCompletion = "hajj_completion"`
  and its switch arms: title `"Hajj Champion"`, subtitle `"بطل الحج"`, icon
  `"building.columns.fill"`, color `"gold"`, description `"Completed the entire
  10-day Dhul-Hijjah Journey"`, sawabValue `500`, hadith `"There are no days in
  which righteous deeds are more beloved to Allah than these ten days. - Prophet
  Muhammad (PBUH)"` (Bukhari — verbatim).
- `Services/IslamicCalendarManager.swift` — add `isHajjSeason()`,
  `currentHajjDay()`, `daysUntilHajj()`, `hajjSeasonStatus()` per export §5.
  Leave existing `isDhulHijjah()` untouched (potential other callers).
- `Services/NotificationManager.swift` — add `scheduleArafahReminder()`: local
  notification on 9 Dhul-Hijjah at the user's existing preferred time, only if
  already `.authorized` (never prompts), `userInfo = ["surah": 2, "verse": 198]`,
  `categoryIdentifier = "ARAFAH_REMINDER"`, title `"Day of Arafah 🤲"`, Sunni
  body: `"Today is the Day of Arafah — the best day of the year for du'a and
  seeking forgiveness. Tap to continue your Dhul-Hijjah Journey."` Resolves 9
  Dhul-Hijjah of `currentIslamicYear()` to a Gregorian fire date; skips if
  already passed. Call it at the end of `scheduleNotifications()` guarded by
  `if IslamicCalendarManager.shared.isHajjSeason()`.
- `Services/PremiumManager.swift` — add `canAccessHajjDay(_:)` (day 1 free,
  2–10 require `isPremium`), mirroring `canAccessRamadanDay`.
- `Services/ProgressManager.swift` — add `awardHajjBadge(year:)` mirroring
  `awardRamadanBadge` **exactly**: dedupe by `.hajjCompletion` + awarded year,
  `BadgeAward(surahNumber: 0, surahName: "Hajj Champion", arabicName: "بطل الحج",
  badgeType: .hajjCompletion)`, `modelContext.insert` + `badges.append`,
  `stats.totalSawab += sawabValue`, `pendingBadge` if celebrations enabled,
  `save()`. (Real `awardRamadanBadge` uses `save()`, not the export's
  `saveProgress()/scheduleSync()`.)
- `Views/MainTabView.swift` — conditional Hajj tab sharing the Ramadan slot at
  `tag(3)`.
- `ContentView.swift` — on launch (`.onAppear` path), `if
  IslamicCalendarManager.shared.isHajjSeason() { Task { await
  NotificationManager.shared.scheduleArafahReminder() } }`.
- `Views/ProgressRingsView.swift` — when `isHajjSeason()`, render the seasonal
  ring from `HajjJourneyManager.shared.completionPercentage`, labeled "Hajj"
  (Ramadan/Hajj share the seasonal ring slot in `ProgressRingsStack`).
- `Views/Onboarding/SeasonalFeaturesScreen.swift` — promote the existing
  "Dhul-Hijjah & Hajj season" placeholder bullet into a real "Dhul-Hijjah
  Journey" feature card with Sunni copy: "Daily du'a & dhikr for the ten blessed
  days", "Curated verses for the best ten days of the year", "Day of Arafah
  reminder", "Track your 10-day journey".

No asset catalog entries — SF Symbols only.

## Content: `hajj_journey.json` (10 days, Sunni-sourced)

Schema identical to `ramadan_journey.json`: `{ "days": [ … ] }`, exactly 10
entries, each `{ id, dayNumber, theme, themeArabic, icon, dua{arabic,
transliteration, english, source}, verses[2], tafsirFocus, reflection }`.

Theme/icon map (kept from export §4; doctrinally neutral):

| Day | Theme | Arabic | Icon | Verses |
|---|---|---|---|---|
| 1 | The Blessed Ten | العَشْرُ المُبارَكَة | `calendar.badge.exclamationmark` | 89:2, 22:28 |
| 2 | Remembrance | الذِّكْر | `sparkles` | (2 fitting dhikr verses, e.g. 33:41, 13:28) |
| 3 | Repentance | التَّوْبَة | `arrow.counterclockwise` | (2 fitting tawba verses, e.g. 39:53, 66:8) |
| 4 | Pure Monotheism | التَّوْحِيد | `circle.hexagongrid.fill` | 112:1, + a second tawhid ayah |
| 5 | Sacrifice & Charity | الإيثار | `hands.and.sparkles.fill` | 22:37, + second |
| 6 | The Submission of Ibrahim | تَسْلِيمُ إِبْرَاهِيم | `flame.fill` | 37:102, 37:107 |
| 7 | The Call of Hajj | نِدَاءُ الحَجّ | `figure.walk.circle.fill` | 22:27, + second |
| 8 | Day of Tarwiyah | يَوْمُ التَّرْوِيَة | `drop.fill` | 2:197, + second |
| 9 | The Day of Arafah | يَوْمُ عَرَفَة | `mountain.2.fill` | 2:198, 7:55 |
| 10 | Eid al-Adha | عِيدُ الأَضْحَى | `moon.stars.fill` | 108:2, + second |

Two verses per day for all 10 (approved). Day 6 uses two representative ayat
from the 37:102–107 range (37:102, 37:107).

Sunni adaptation (export §12) applied to du'a texts/sources:
- No Imam `(AS)`; Prophet → `ﷺ`/"(peace be upon him)", Companions → "(RA)".
- Sources from Hisn al-Muslim, Sahih al-Bukhari/Muslim, Riyad as-Salihin,
  al-Adhkar (al-Nawawi), Tirmidhi/Muwatta.
- Day 3 → Sayyid al-Istighfar (Bukhari).
- Day 4 → `Lā ilāha illā Allāhu waḥdahū lā sharīka lah…` (Bukhari/Muslim).
- Day 9 → Prophet's ﷺ best du'a of Arafah (`Lā ilāha illā Allāhu waḥdahū lā
  sharīka lah, lahu-l-mulku wa lahu-l-ḥamd, wa huwa ʿalā kulli shayʾin qadīr`,
  Tirmidhi / Muwatta Malik); `tafsirFocus` references this hadith.
- Days 1/2/5/8/10 shared dhikr/Takbir/Talbiyah texts — re-attribute `source`
  only.

**Top of file or accompanying note:** flag the JSON for Sunni scholar review
(esp. Days 3, 4, 9 du'a texts, all `source` strings, `tafsirFocus`) before ship.

## Data flow

`init()` → `loadProgress()` (UserDefaults) → `loadDays()` (bundle JSON) →
`checkYearReset()`. Mark day → mutate `Set<Int>` → save → all 10 →
`ProgressManager.awardHajjBadge` → badge wall + sawab + celebration overlay. Tab
visibility & seasonal ring driven live by `isHajjSeason()`. Arafah notification
tap → `.navigateToVerse` receiver in `SurahListView` → Quran 2:198.

## Error handling

No-fallback rule preserved: JSON decode/load failure → `errorMessage` surfaced
via an error section in the list view; no default/placeholder content. Arafah
notification only schedules if already `.authorized`.

## Testing

Temporarily force `isHajjSeason()` / `currentHajjDay()` to validate:
- Conditional tab appears at `tag(3)`; not shown alongside Ramadan.
- Day cards: today / future-locked / completed / premium-locked states.
- Premium gating: day 1 free, days 2–10 → `PaywallView`.
- Detail sections render (du'a RTL, verses with tafsir deep-link, reflection).
- Mark all 10 → `awardHajjBadge` once: badge wall + sawab +500 + celebration.
- Year-reset clears progress when Hijri year changes.
- Arafah notification fires on 9 Dhul-Hijjah, deep-links to 2:198.
- `hajj_journey.json` decode error surfaces (no silent fallback).

## Deltas from the export spec (codebase reality)

1. Conditional tab is `tag(3)` (shared with Ramadan), not `tag(5)`.
2. No "daily-verse reschedule routine" — Arafah reminder re-armed in
   `scheduleNotifications()` + once at launch in `ContentView`.
3. `ProgressManager` is SwiftData-backed; `awardHajjBadge` mirrors
   `awardRamadanBadge` (`modelContext.insert` + `save()`), not the export's
   `saveProgress()/scheduleSync()`.
4. `.navigateToVerse` receiver lives in `SurahListView`, not `MainTabView`
   (already present — verify only).
5. Existing `isDhulHijjah()` left intact; new `isHajjSeason()` added alongside.
