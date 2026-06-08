# Dhul-Hijjah (Hajj) Journey Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
>
> **User standing preference (memory `feedback_no_auto_commit`):** Do NOT run `git commit` automatically. The "Commit" steps below are manual checkpoints — write the files, run the build/validation, then STOP and let the user commit. Treat each "Commit" step as "report readiness, await user".

**Goal:** Add a seasonal "Dhul-Hijjah Journey" — a 10-day journey tab that appears during the Hajj window — mirroring the existing Ramadan Journey 1:1, with Sunni-sourced du'a content.

**Architecture:** Near-verbatim structural port of the Ramadan Journey engine (manager / models / two views) with `Ramadan→Hajj`, `30→10`. Hajj and Ramadan seasons are mutually exclusive and share one conditional tab slot (`tag(3)`). Journey progress is device-local (UserDefaults); only the completion badge routes through the existing SwiftData `ProgressManager`.

**Tech Stack:** Swift 5 / SwiftUI, Combine, SwiftData (ProgressManager), UserNotifications, `Calendar(identifier: .islamicUmmAlQura)`. Xcode project `AlBayan.xcodeproj` uses **PBXFileSystemSynchronizedRootGroup** — new files placed anywhere under `AlBayan/` are automatically compiled/bundled; **no `.pbxproj` edits required**.

**No test target exists.** Validation = compile (`xcodebuild … build`) + manual season-forcing. Each task ends with a build gate.

**Build/validate command (used throughout):**
```bash
xcodebuild -project AlBayan.xcodeproj -scheme AlBayan \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | tail -20
```
Expected on success: `** BUILD SUCCEEDED **`. (If the simulator name differs, run `xcrun simctl list devices available | grep iPhone` and substitute.)

---

## Task 1: Data models + completion badge

**Files:**
- Modify: `AlBayan/Models/QuranModels.swift` (Ramadan models block ends ~line 1303; `BadgeType` enum lines 731–849)

**Step 1: Add the Hajj model structs**

Immediately after the `RamadanJourneyProgress` struct's closing `}` (the Ramadan Journey Models block, ~line 1304), add:

```swift
// MARK: - Hajj (Dhul-Hijjah) Journey Models

struct HajjJourneyData: Codable {
    let days: [HajjDay]
}

struct HajjDay: Codable, Identifiable {
    let id: String
    let dayNumber: Int
    let theme: String
    let themeArabic: String
    let icon: String
    let dua: HajjDua
    let verses: [HajjVerse]
    let tafsirFocus: String
    let reflection: String
}

struct HajjDua: Codable {
    let arabic: String
    let transliteration: String
    let english: String
    let source: String?
}

struct HajjVerse: Codable, Identifiable {
    let id: String
    let surahNumber: Int
    let verseNumber: Int
    let relevanceNote: String

    var verseReference: String {
        "Quran \(surahNumber):\(verseNumber)"
    }
}

struct HajjJourneyProgress: Codable {
    var completedDays: Set<Int>
    var lastCompletedDate: Date?
    var year: Int

    init(
        completedDays: Set<Int> = [],
        lastCompletedDate: Date? = nil,
        year: Int = 0
    ) {
        self.completedDays = completedDays
        self.lastCompletedDate = lastCompletedDate
        self.year = year
    }

    var completionPercentage: Double {
        Double(completedDays.count) / 10.0
    }

    var isCompleted: Bool {
        completedDays.count >= 10
    }
}
```

**Step 2: Add the badge enum case**

In `enum BadgeType`, after `case ramadanCompletion = "ramadan_completion"` (line 740) add:

```swift
    case hajjCompletion = "hajj_completion"
```

**Step 3: Add the badge switch arms**

Add one arm to EACH of the six computed properties, immediately after the corresponding `.ramadanCompletion` arm:

- `title`: `case .hajjCompletion: return "Hajj Champion"`
- `subtitle`: `case .hajjCompletion: return "بطل الحج"`
- `icon`: `case .hajjCompletion: return "building.columns.fill"`
- `color`: `case .hajjCompletion: return "gold"`
- `description`: `case .hajjCompletion: return "Completed the entire 10-day Dhul-Hijjah Journey"`
- `sawabValue`: `case .hajjCompletion: return 500`
- `hadith`: add to the matched cases — change the line
  `case .ramadanCompletion:` (in the `hadith` switch, ~line 843) so it reads:
  ```swift
        case .ramadanCompletion:
            return "Whoever fasts Ramadan out of faith and seeking reward, his previous sins will be forgiven. - Prophet Muhammad (PBUH)"
        case .hajjCompletion:
            return "There are no days in which righteous deeds are more beloved to Allah than these ten days. - Prophet Muhammad (PBUH)"
  ```
  (The Bukhari "ten days" hadith — keep verbatim.)

**Step 4: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **` (models compile; `BadgeType` switches are exhaustive again).

**Step 5: Commit (manual checkpoint)**

```bash
git add AlBayan/Models/QuranModels.swift
git commit -m "feat(hajj): add Dhul-Hijjah journey models + hajjCompletion badge"
```
(Per user preference: do not auto-run. Report build success and stop for user to commit.)

---

## Task 2: Seasonality methods on IslamicCalendarManager

**Files:**
- Modify: `AlBayan/Services/IslamicCalendarManager.swift` (Ramadan Season Detection block ends ~line 201; leave existing `isDhulHijjah()` at line 132 untouched)

**Step 1: Add Hajj season methods**

After `ramadanSeasonStatus()`'s closing `}` (~line 201), before `// MARK: - Date Formatting`, add:

```swift
    // MARK: - Hajj (Dhul-Hijjah) Season Detection

    /// Hajj window: last 5 days of Dhul-Qa'dah (countdown) + Dhul-Hijjah days 1–13.
    /// Mutually exclusive with Ramadan season (months 8/9/10).
    func isHajjSeason() -> Bool {
        let month = currentIslamicMonth()
        let day = currentIslamicDay()
        switch month {
        case 11: return day >= 25   // Dhul-Qa'dah lead-in
        case 12: return day <= 13   // 10-day journey + Eid + Tashriq tail
        default: return false
        }
    }

    /// Current day of the 10-day journey (1–10), nil outside it.
    func currentHajjDay() -> Int? {
        guard currentIslamicMonth() == 12 else { return nil }
        let day = currentIslamicDay()
        return (1...10).contains(day) ? day : nil
    }

    /// Days until Dhul-Hijjah (only meaningful in Dhul-Qa'dah, month 11).
    func daysUntilHajj() -> Int? {
        guard currentIslamicMonth() == 11 else { return nil }
        return max(0, 30 - currentIslamicDay() + 1)
    }

    /// Status line shown in the Hajj Journey header.
    func hajjSeasonStatus() -> String {
        let month = currentIslamicMonth()
        let day = currentIslamicDay()
        switch month {
        case 11:
            if let d = daysUntilHajj(), d > 0 {
                return "\(d) day\(d == 1 ? "" : "s") until Dhul-Hijjah"
            }
            return "Dhul-Hijjah begins soon"
        case 12:
            if day == 9 { return "Day of Arafah" }
            if day == 10 { return "Eid al-Adha Mubarak!" }
            if day <= 10 { return "Day \(day) of Dhul-Hijjah" }
            if day <= 13 { return "Eid al-Adha Mubarak!" }
            return ""
        default:
            return ""
        }
    }
```

**Step 2: Build** — expected `** BUILD SUCCEEDED **`.

**Step 3: Commit (manual checkpoint)**

```bash
git add AlBayan/Services/IslamicCalendarManager.swift
git commit -m "feat(hajj): add Hajj season detection to IslamicCalendarManager"
```

---

## Task 3: Premium gating

**Files:**
- Modify: `AlBayan/Services/PremiumManager.swift` (after `canAccessRamadanDay`, line 85–88)

**Step 1: Add gating method**

After the `canAccessRamadanDay` method's closing `}` (line 88), add:

```swift

    func canAccessHajjDay(_ dayNumber: Int) -> Bool {
        if dayNumber == 1 { return true }
        return isPremium
    }
```

**Step 2: Build** — expected `** BUILD SUCCEEDED **`.

**Step 3: Commit (manual checkpoint)**

```bash
git add AlBayan/Services/PremiumManager.swift
git commit -m "feat(hajj): premium gating — day 1 free, 2–10 premium"
```

---

## Task 4: Award Hajj badge on ProgressManager

**Files:**
- Modify: `AlBayan/Services/ProgressManager.swift` (mirror `awardRamadanBadge`, lines 485–520)

**Step 1: Add `awardHajjBadge(year:)`**

Immediately after the `awardRamadanBadge(year:)` method's closing `}` (after line ~520), add — this mirrors `awardRamadanBadge` exactly (SwiftData `modelContext.insert` + `save()`; NOT the export's `saveProgress()/scheduleSync()`):

```swift

    /// Award Hajj completion badge (called by HajjJourneyManager)
    /// Only awards once per Islamic year
    func awardHajjBadge(year: Int) {
        let alreadyAwarded = badges.contains(where: {
            $0.badgeType == .hajjCompletion &&
            Calendar.current.component(.year, from: $0.awardedDate) == year
        })

        guard !alreadyAwarded else {
            print("ProgressManager: Hajj badge already awarded for year \(year)")
            return
        }

        let badge = BadgeAward(
            surahNumber: 0,
            surahName: "Hajj Champion",
            arabicName: "بطل الحج",
            badgeType: .hajjCompletion
        )
        modelContext.insert(badge)
        badges.append(badge)

        stats.totalSawab += badge.badgeType.sawabValue
        print("ProgressManager: +\(badge.badgeType.sawabValue) sawab earned from Hajj completion! Total: \(stats.totalSawab)")

        if preferences.celebrationsEnabled {
            pendingBadge = badge
        }

        stats.lastUpdated = Date()
        save()

        print("ProgressManager: Hajj Champion badge awarded for year \(year)")
    }
```

> If the `awardRamadanBadge` body has a closing `print(...)` then `}` differing from above, match its exact tail structure (it ends with the success print then `}`). Read lines 485–522 first to place the new method correctly.

**Step 2: Build** — expected `** BUILD SUCCEEDED **`.

**Step 3: Commit (manual checkpoint)**

```bash
git add AlBayan/Services/ProgressManager.swift
git commit -m "feat(hajj): awardHajjBadge — once per Hijri year, joins badge wall"
```

---

## Task 5: HajjJourneyManager service (verbatim adaptation)

**Files:**
- Create: `AlBayan/Services/HajjJourneyManager.swift`

**Step 1: Create the file** with this exact content (structural copy of `RamadanJourneyManager`, `30→10`, `ramadan→hajj`):

```swift
//
//  HajjJourneyManager.swift
//  AlBayan
//
//  Manager for 10-day Dhul-Hijjah (Hajj) Journey feature
//  Handles progress tracking, persistence, and badge awarding
//  Progress is SEPARATE from main ProgressManager (verse counts, streaks, sawab)
//

import Foundation
import Combine

@MainActor
class HajjJourneyManager: ObservableObject {
    static let shared = HajjJourneyManager()

    // MARK: - Published Properties

    @Published var days: [HajjDay] = []
    @Published var progress: HajjJourneyProgress = HajjJourneyProgress()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - UserDefaults Keys

    private let progressKey = "hajjJourneyProgress"

    // MARK: - Initialization

    private init() {
        loadProgress()
        loadDays()
        checkYearReset()
    }

    // MARK: - Data Loading

    func loadDays() {
        isLoading = true
        errorMessage = nil

        guard let url = Bundle.main.url(forResource: "hajj_journey", withExtension: "json") else {
            errorMessage = "Could not find hajj_journey.json"
            isLoading = false
            print("HajjJourneyManager: hajj_journey.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let journeyData = try decoder.decode(HajjJourneyData.self, from: data)

            self.days = journeyData.days
            self.isLoading = false
            print("HajjJourneyManager: Loaded \(self.days.count) journey days")
        } catch {
            self.errorMessage = "Failed to load journey: \(error.localizedDescription)"
            self.isLoading = false
            print("HajjJourneyManager: Failed to load - \(error.localizedDescription)")
        }
    }

    // MARK: - Progress Persistence

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(HajjJourneyProgress.self, from: data) {
            self.progress = decoded
            print("HajjJourneyManager: Loaded progress - \(progress.completedDays.count) days completed")
        }
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
            print("HajjJourneyManager: Saved progress")
        }
    }

    // MARK: - Year Reset Logic

    private func checkYearReset() {
        let currentYear = IslamicCalendarManager.shared.currentIslamicYear()

        if progress.year != currentYear {
            print("HajjJourneyManager: New Islamic year \(currentYear) - resetting progress")
            progress = HajjJourneyProgress(year: currentYear)
            saveProgress()
        }
    }

    // MARK: - Day Completion

    func markDayCompleted(_ dayNumber: Int) {
        guard dayNumber >= 1 && dayNumber <= 10 else { return }
        guard !isDayCompleted(dayNumber) else { return }

        progress.completedDays.insert(dayNumber)
        progress.lastCompletedDate = Date()

        if progress.year == 0 {
            progress.year = IslamicCalendarManager.shared.currentIslamicYear()
        }

        saveProgress()
        print("HajjJourneyManager: Day \(dayNumber) marked complete (\(progress.completedDays.count)/10)")

        checkForCompletionBadge()
    }

    func unmarkDayCompleted(_ dayNumber: Int) {
        guard dayNumber >= 1 && dayNumber <= 10 else { return }
        guard isDayCompleted(dayNumber) else { return }

        progress.completedDays.remove(dayNumber)
        saveProgress()
        print("HajjJourneyManager: Day \(dayNumber) unmarked (\(progress.completedDays.count)/10)")
    }

    func isDayCompleted(_ dayNumber: Int) -> Bool {
        return progress.completedDays.contains(dayNumber)
    }

    // MARK: - Badge Awarding

    private func checkForCompletionBadge() {
        guard progress.isCompleted else { return }

        let currentYear = IslamicCalendarManager.shared.currentIslamicYear()
        ProgressManager.shared.awardHajjBadge(year: currentYear)

        print("HajjJourneyManager: Journey complete! Badge awarded for year \(currentYear)")
    }

    // MARK: - Lookup Methods

    func day(byNumber dayNumber: Int) -> HajjDay? {
        return days.first { $0.dayNumber == dayNumber }
    }

    func day(byId id: String) -> HajjDay? {
        return days.first { $0.id == id }
    }

    // MARK: - Statistics

    var completedDaysCount: Int {
        return progress.completedDays.count
    }

    var completionPercentage: Double {
        return progress.completionPercentage
    }

    var isJourneyCompleted: Bool {
        return progress.isCompleted
    }

    var remainingDaysCount: Int {
        return max(0, 10 - progress.completedDays.count)
    }

    // MARK: - Reset

    func resetProgress() {
        let currentYear = IslamicCalendarManager.shared.currentIslamicYear()
        progress = HajjJourneyProgress(year: currentYear)
        saveProgress()
        print("HajjJourneyManager: Progress reset")
    }
}
```

**Step 2: Build** — expected `** BUILD SUCCEEDED **` (will still fail to find `hajj_journey.json` at runtime until Task 7; compiles fine).

**Step 3: Commit (manual checkpoint)**

```bash
git add AlBayan/Services/HajjJourneyManager.swift
git commit -m "feat(hajj): HajjJourneyManager — 10-day progress, year reset, badge hook"
```

---

## Task 6: Hajj Journey views (mechanical port of the two Ramadan views)

The two Ramadan views are pure UI over the manager; all wiring (DataManager verse lookup, `.navigateToVerse` deep-link, `AmiriQuran-Regular` font, ThemeManager, `AdaptiveModernBackground`, error section, `PaywallView`) is correct and carries over unchanged by a symbol rename. Port via copy + scripted identifier substitution.

**Files:**
- Create: `AlBayan/Views/HajjJourneyView.swift` (from `RamadanJourneyView.swift`)
- Create: `AlBayan/Views/HajjDayDetailView.swift` (from `RamadanDayDetailView.swift`)

**Step 1: Copy + rename identifiers**

```bash
cd /Users/muhammadimranali/Documents/development/albayan

sed -e 's/Ramadan/Hajj/g' -e 's/ramadan/hajj/g' -e 's/RAMADAN/HAJJ/g' \
  AlBayan/Views/RamadanJourneyView.swift > AlBayan/Views/HajjJourneyView.swift

sed -e 's/Ramadan/Hajj/g' -e 's/ramadan/hajj/g' -e 's/RAMADAN/HAJJ/g' \
  AlBayan/Views/RamadanDayDetailView.swift > AlBayan/Views/HajjDayDetailView.swift
```

This correctly maps every symbol: `RamadanJourneyView→HajjJourneyView`, `RamadanJourneyManager→HajjJourneyManager`, `RamadanDay→HajjDay`, `RamadanDayCard→HajjDayCard`, `RamadanJourneyHeader→HajjJourneyHeader`, `RamadanErrorSection→HajjErrorSection`, `canAccessRamadanDay→canAccessHajjDay`, `ramadanSeasonStatus()→hajjSeasonStatus()`, `currentRamadanDay()→currentHajjDay()`, `isRamadanSeason()→isHajjSeason()`, file-header comment text, and any user-facing "Ramadan"→"Hajj" strings.

**Step 2: Fix day-count literals (30 → 10)**

In BOTH new files, replace day-count occurrences. Inspect with:

```bash
grep -n "30\|1\.\.\.30\|/ 30\|>= 30\|of 30\|x of 30\|30 days\|0\.\.<30\|1\.\.30" \
  AlBayan/Views/HajjJourneyView.swift AlBayan/Views/HajjDayDetailView.swift
```

For each hit that means "number of journey days" (loops like `ForEach(1...30, …)`, `1..<31`, progress text `"of 30 days"`, `"30-Day"`, percentage `/ 30`, ring math), change `30→10` / `31→11`. **Do NOT change** unrelated numbers (font sizes, spacing, opacity, animation durations, corner radii, `0.3` delays, color literals). Review each `grep` line individually before editing.

> The header progress label, day-grid `ForEach`, and any "X of 30" copy are the expected hits. The detail view typically has no day-count loop (it renders one `HajjDay`); verify with the grep.

**Step 3: Sanity-check the rename**

```bash
grep -ni "ramadan" AlBayan/Views/HajjJourneyView.swift AlBayan/Views/HajjDayDetailView.swift
```
Expected: **no output**. (Any remaining "ramadan" is a missed rename — fix it.)

**Step 4: Build** — expected `** BUILD SUCCEEDED **`. Fix any compile errors (most likely a stray `30` in ring/percentage math or a symbol the sed over/under-matched).

**Step 5: Commit (manual checkpoint)**

```bash
git add AlBayan/Views/HajjJourneyView.swift AlBayan/Views/HajjDayDetailView.swift
git commit -m "feat(hajj): HajjJourneyView + HajjDayDetailView (ported from Ramadan)"
```

---

## Task 7: Sunni `hajj_journey.json` content (10 days)

**Files:**
- Create: `AlBayan/Data/hajj_journey.json`

Schema identical to `ramadan_journey.json`. Sunni-sourced per export §12. **The `_note` field at the top flags this file for Sunni scholar review before ship** (it is ignored by the `HajjJourneyData` decoder since that struct only decodes `days`).

**Step 1: Create the file** with this exact content:

```json
{
  "_note": "PENDING SUNNI SCHOLAR REVIEW before ship — verify all dua Arabic/transliteration/source (esp. Days 3, 4, 9) and tafsirFocus. Schema must match HajjJourneyData; only the `days` array is decoded.",
  "days": [
    {
      "id": "day1",
      "dayNumber": 1,
      "theme": "The Blessed Ten",
      "themeArabic": "العَشْرُ المُبارَكَة",
      "icon": "calendar.badge.exclamationmark",
      "dua": {
        "arabic": "اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ",
        "transliteration": "Allahu akbar, Allahu akbar, la ilaha illa-llah, wa-llahu akbar, Allahu akbar, wa lillahi-l-hamd",
        "english": "Allah is the Greatest, Allah is the Greatest. There is no god but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.",
        "source": "Sunnah — abundant takbir, tahlil and tahmid in these ten days (narrated from Ibn Umar & Abu Hurayrah RA; cf. Sahih al-Bukhari, Book of the Two Eids)"
      },
      "verses": [
        { "id": "h1v1", "surahNumber": 89, "verseNumber": 2, "relevanceNote": "\"And by the ten nights\" — Allah swears by these days, a sign of their immense rank." },
        { "id": "h1v2", "surahNumber": 22, "verseNumber": 28, "relevanceNote": "\"That they may witness benefits for themselves and mention the name of Allah on appointed days.\"" }
      ],
      "tafsirFocus": "Reflect on why Allah swears by 'the ten nights' (al-Qurtubi, Ibn Kathir: the ten days of Dhul-Hijjah). The Prophet ﷺ said no days are more beloved to Allah for righteous deeds than these — so front-load them with worship.",
      "reflection": "These ten days will pass quickly. What is the one act of worship you commit to increasing every day until Eid?"
    },
    {
      "id": "day2",
      "dayNumber": 2,
      "theme": "Remembrance",
      "themeArabic": "الذِّكْر",
      "icon": "sparkles",
      "dua": {
        "arabic": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
        "transliteration": "Subhana-llahi wa bihamdih, subhana-llahi-l-'azim",
        "english": "Glory be to Allah and praise Him; glory be to Allah the Magnificent.",
        "source": "Sahih al-Bukhari & Muslim (from Abu Hurayrah RA)"
      },
      "verses": [
        { "id": "h2v1", "surahNumber": 33, "verseNumber": 41, "relevanceNote": "\"O you who believe, remember Allah with much remembrance.\"" },
        { "id": "h2v2", "surahNumber": 13, "verseNumber": 28, "relevanceNote": "\"Verily, in the remembrance of Allah do hearts find rest.\"" }
      ],
      "tafsirFocus": "Dhikr is the lightest deed on the tongue yet heaviest on the scale. In these ten days the Sunnah is to multiply tasbih, tahmid, tahlil and takbir — connect this to the hearts-at-rest of 13:28.",
      "reflection": "Pick one dhikr and tie it to a daily trigger (after each prayer, every commute). Consistency over intensity."
    },
    {
      "id": "day3",
      "dayNumber": 3,
      "theme": "Repentance",
      "themeArabic": "التَّوْبَة",
      "icon": "arrow.counterclockwise",
      "dua": {
        "arabic": "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
        "transliteration": "Allahumma anta rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika ma-stata't, a'udhu bika min sharri ma sana't, abu'u laka bi-ni'matika 'alayya, wa abu'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfiru-dh-dhunuba illa anta",
        "english": "O Allah, You are my Lord, there is no god but You. You created me and I am Your servant; I keep Your covenant and promise as much as I can. I seek refuge in You from the evil I have done; I acknowledge Your favour upon me and I confess my sin, so forgive me, for none forgives sins but You.",
        "source": "Sayyid al-Istighfar — Sahih al-Bukhari (from Shaddad ibn Aws RA)"
      },
      "verses": [
        { "id": "h3v1", "surahNumber": 39, "verseNumber": 53, "relevanceNote": "\"Do not despair of the mercy of Allah; indeed Allah forgives all sins.\"" },
        { "id": "h3v2", "surahNumber": 66, "verseNumber": 8, "relevanceNote": "\"Turn to Allah in sincere repentance.\"" }
      ],
      "tafsirFocus": "Sayyid al-Istighfar is the master supplication of seeking forgiveness (Bukhari): whoever says it with conviction by day and dies that day enters Paradise. Pair its admission of sin with the open door of 39:53.",
      "reflection": "Name one sin you keep returning to. What concrete barrier will you put between yourself and it before Eid?"
    },
    {
      "id": "day4",
      "dayNumber": 4,
      "theme": "Pure Monotheism",
      "themeArabic": "التَّوْحِيد",
      "icon": "circle.hexagongrid.fill",
      "dua": {
        "arabic": "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        "transliteration": "La ilaha illa-llahu wahdahu la sharika lah, lahu-l-mulku wa lahu-l-hamd, wa huwa 'ala kulli shay'in qadir",
        "english": "There is no god but Allah alone, with no partner. His is the dominion and His is all praise, and He is over all things capable.",
        "source": "Sahih al-Bukhari & Muslim (from Abu Hurayrah RA — said one hundred times a day)"
      },
      "verses": [
        { "id": "h4v1", "surahNumber": 112, "verseNumber": 1, "relevanceNote": "\"Say: He is Allah, the One.\"" },
        { "id": "h4v2", "surahNumber": 2, "verseNumber": 163, "relevanceNote": "\"And your God is one God; there is no god but He, the Most Merciful, the Bestower of mercy.\"" }
      ],
      "tafsirFocus": "Tawhid is the substance of the talbiyah pilgrims raise (\"labbayk... la sharika lak\"). Whoever says this tahlil 100x has a reward like freeing ten slaves (Bukhari/Muslim) — make these days a season of pure tawhid.",
      "reflection": "Where in your life does something other than Allah quietly compete for your ultimate trust or fear?"
    },
    {
      "id": "day5",
      "dayNumber": 5,
      "theme": "Sacrifice & Charity",
      "themeArabic": "الإيثار",
      "icon": "hands.and.sparkles.fill",
      "dua": {
        "arabic": "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
        "transliteration": "Rabbana taqabbal minna innaka anta-s-Sami'u-l-'Alim",
        "english": "Our Lord, accept this from us. Indeed, You are the All-Hearing, the All-Knowing.",
        "source": "Quran 2:127 — the supplication of Ibrahim and Isma'il (peace be upon them) while raising the Ka'bah"
      },
      "verses": [
        { "id": "h5v1", "surahNumber": 22, "verseNumber": 37, "relevanceNote": "\"It is neither their flesh nor their blood that reaches Allah, but it is your piety that reaches Him.\"" },
        { "id": "h5v2", "surahNumber": 2, "verseNumber": 177, "relevanceNote": "True righteousness is to give wealth, despite love for it, to kin, orphans, the needy and the traveller." }
      ],
      "tafsirFocus": "22:37 reframes the udhiyah: the goal is taqwa, not the meat. Ibn Kathir notes Allah looks at sincerity, not quantity. Connect sacrifice to everyday charity in 2:177.",
      "reflection": "Beyond the Eid sacrifice, what is one thing you love that you can give away for Allah's sake this week?"
    },
    {
      "id": "day6",
      "dayNumber": 6,
      "theme": "The Submission of Ibrahim",
      "themeArabic": "تَسْلِيمُ إِبْرَاهِيم",
      "icon": "flame.fill",
      "dua": {
        "arabic": "رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ",
        "transliteration": "Rabbi hab li mina-s-salihin",
        "english": "My Lord, grant me a righteous offspring.",
        "source": "Quran 37:100 — the supplication of Prophet Ibrahim (peace be upon him)"
      },
      "verses": [
        { "id": "h6v1", "surahNumber": 37, "verseNumber": 102, "relevanceNote": "Ibrahim's dream to sacrifice his son, and Isma'il's reply: \"Do as you are commanded; you will find me patient.\"" },
        { "id": "h6v2", "surahNumber": 37, "verseNumber": 107, "relevanceNote": "\"And We ransomed him with a great sacrifice\" — the origin of the Eid udhiyah." }
      ],
      "tafsirFocus": "37:102–107 is the heart of Hajj's meaning: total submission. Ibn Kathir: Ibrahim and Isma'il submitted before the ransom came. Reflect on obeying first, understanding later.",
      "reflection": "What command of Allah do you delay because you do not yet 'feel' it? Where is your Ibrahim moment?"
    },
    {
      "id": "day7",
      "dayNumber": 7,
      "theme": "The Call of Hajj",
      "themeArabic": "نِدَاءُ الحَجّ",
      "icon": "figure.walk.circle.fill",
      "dua": {
        "arabic": "لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ",
        "transliteration": "Labbayka-llahumma labbayk, labbayka la sharika laka labbayk, inna-l-hamda wa-n-ni'mata laka wa-l-mulk, la sharika lak",
        "english": "Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Truly all praise, grace and dominion are Yours; You have no partner.",
        "source": "The Talbiyah — Sahih al-Bukhari & Muslim (from Ibn Umar RA)"
      },
      "verses": [
        { "id": "h7v1", "surahNumber": 22, "verseNumber": 27, "relevanceNote": "\"And proclaim to mankind the Hajj; they will come to you on foot and on every lean camel.\"" },
        { "id": "h7v2", "surahNumber": 3, "verseNumber": 97, "relevanceNote": "\"Pilgrimage to the House is a duty owed to Allah by all who can find a way to it.\"" }
      ],
      "tafsirFocus": "22:27: Ibrahim called and the answer still echoes in every talbiyah. Ibn Kathir relays that the talbiyah is the response to that ancient call. Even if not on Hajj, answer with longing.",
      "reflection": "Say the talbiyah aloud. What would it mean to live the rest of today as if you were truly answering a call?"
    },
    {
      "id": "day8",
      "dayNumber": 8,
      "theme": "Day of Tarwiyah",
      "themeArabic": "يَوْمُ التَّرْوِيَة",
      "icon": "drop.fill",
      "dua": {
        "arabic": "اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى",
        "transliteration": "Allahumma inna nas'aluka fi safarina hadha-l-birra wa-t-taqwa, wa mina-l-'amali ma tarda",
        "english": "O Allah, we ask You on this journey of ours for righteousness and piety, and for deeds that please You.",
        "source": "Sahih Muslim (the Prophet's ﷺ supplication for travel, from Ibn Umar RA)"
      },
      "verses": [
        { "id": "h8v1", "surahNumber": 2, "verseNumber": 197, "relevanceNote": "\"And take provision; but the best provision is taqwa (God-consciousness).\"" },
        { "id": "h8v2", "surahNumber": 2, "verseNumber": 196, "relevanceNote": "\"And complete the Hajj and 'Umrah for Allah.\"" }
      ],
      "tafsirFocus": "On 8 Dhul-Hijjah (Tarwiyah) pilgrims set out for Mina. 2:197 names the real luggage: taqwa. Whether travelling or not, prepare provisions for the greater journey to Allah.",
      "reflection": "If taqwa is the only provision that arrives with you, what did you pack today?"
    },
    {
      "id": "day9",
      "dayNumber": 9,
      "theme": "The Day of Arafah",
      "themeArabic": "يَوْمُ عَرَفَة",
      "icon": "mountain.2.fill",
      "dua": {
        "arabic": "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        "transliteration": "La ilaha illa-llahu wahdahu la sharika lah, lahu-l-mulku wa lahu-l-hamd, wa huwa 'ala kulli shay'in qadir",
        "english": "There is no god but Allah alone, with no partner. His is the dominion and His is all praise, and He is over all things capable.",
        "source": "Jami' at-Tirmidhi & Muwatta Malik — \"The best supplication is the supplication of the Day of Arafah\""
      },
      "verses": [
        { "id": "h9v1", "surahNumber": 2, "verseNumber": 198, "relevanceNote": "\"When you depart from Arafat, remember Allah at al-Mash'ar al-Haram.\"" },
        { "id": "h9v2", "surahNumber": 7, "verseNumber": 55, "relevanceNote": "\"Call upon your Lord humbly and in secret; He does not love the transgressors.\"" }
      ],
      "tafsirFocus": "The Prophet ﷺ said the best supplication is that of the Day of Arafah, and the best he and the Prophets said is this tahlil (Tirmidhi). Fasting Arafah expiates two years (Muslim). Devote this day to du'a and istighfar.",
      "reflection": "Arafah is the day of accepted du'a. Write down the three things you most need from Allah and ask Him with certainty."
    },
    {
      "id": "day10",
      "dayNumber": 10,
      "theme": "Eid al-Adha",
      "themeArabic": "عِيدُ الأَضْحَى",
      "icon": "moon.stars.fill",
      "dua": {
        "arabic": "اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ",
        "transliteration": "Allahu akbar Allahu akbar, la ilaha illa-llah, wa-llahu akbar Allahu akbar, wa lillahi-l-hamd",
        "english": "Allah is the Greatest, Allah is the Greatest. There is no god but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.",
        "source": "Sunnah — Takbir of Eid al-Adha and the days of Tashriq (reported from Ali & Ibn Mas'ud RA; cf. Sahih al-Bukhari, Book of the Two Eids)"
      },
      "verses": [
        { "id": "h10v1", "surahNumber": 108, "verseNumber": 2, "relevanceNote": "\"So pray to your Lord and sacrifice.\"" },
        { "id": "h10v2", "surahNumber": 22, "verseNumber": 34, "relevanceNote": "\"For every nation We appointed a rite of sacrifice, that they may mention the name of Allah.\"" }
      ],
      "tafsirFocus": "108:2 joins prayer and sacrifice as one act of devotion. Ibn Kathir: this is the Eid prayer and the udhiyah. Let the takbir fill these days of Tashriq with gratitude, not just celebration.",
      "reflection": "The journey ends with sacrifice and takbir. What did these ten days change in you that you will carry into the rest of the year?"
    }
  ]
}
```

**Step 2: Validate JSON + day count**

```bash
python3 -c "import json,sys; d=json.load(open('AlBayan/Data/hajj_journey.json')); ds=d['days']; assert len(ds)==10, len(ds); assert [x['dayNumber'] for x in ds]==list(range(1,11)); [ (x['dua']['arabic'], x['dua']['transliteration'], x['dua']['english'], len(x['verses'])==2) for x in ds ]; print('OK 10 days, 2 verses each')"
```
Expected: `OK 10 days, 2 verses each`.

**Step 3: Build + runtime check**

Build (`** BUILD SUCCEEDED **`). The synchronized group auto-bundles the JSON. Runtime decode is verified in Task 11.

**Step 4: Commit (manual checkpoint)**

```bash
git add AlBayan/Data/hajj_journey.json
git commit -m "feat(hajj): Sunni-sourced hajj_journey.json (10 days) — pending scholar review"
```

---

## Task 8: Conditional Hajj tab (shares the Ramadan slot)

**Files:**
- Modify: `AlBayan/Views/MainTabView.swift`

**Step 1: Add the season check** — after the `isRamadanSeason` computed property (line 17), add:

```swift

    private var isHajjSeason: Bool {
        IslamicCalendarManager.shared.isHajjSeason()
    }
```

**Step 2: Add the conditional tab** — after the closing `}` of the `if isRamadanSeason { … }` block (line 62), add (`else if` so the two seasons never both render at `tag(3)`):

```swift

            else if isHajjSeason {
                HajjJourneyView()
                    .tabItem {
                        Label {
                            Text("Hajj")
                        } icon: {
                            Image(systemName: "building.columns.fill")
                        }
                    }
                    .tag(3)
            }
```

> Swift requires `else if` to attach to the preceding `if`. If the existing `if isRamadanSeason {` block's closing brace is followed by other code, instead change it to a single `if isRamadanSeason { … } else if isHajjSeason { … }` chain — keep both branches at `.tag(3)`.

**Step 3: Update the file-header comment** line 5 — `Home, Explore, Progress, and conditional Ramadan tabs` → `…and a conditional seasonal (Ramadan / Hajj) tab`.

**Step 4: Build** — expected `** BUILD SUCCEEDED **`.

**Step 5: Commit (manual checkpoint)**

```bash
git add AlBayan/Views/MainTabView.swift
git commit -m "feat(hajj): conditional Hajj tab sharing the seasonal slot"
```

---

## Task 9: Arafah notification

**Files:**
- Modify: `AlBayan/Services/NotificationManager.swift` (add method near the seasonal notifications block ~line 388; add re-arm call inside `scheduleNotifications()` ~line 224)

**Step 1: Add `scheduleArafahReminder()`** — after `scheduleStreakReminder()`'s closing `}` (~line 388), add:

```swift

    /// Schedule a single local notification for the Day of Arafah (9 Dhul-Hijjah)
    /// at the user's preferred time. Does NOT request permission — only schedules
    /// if already authorized. Deep-links to Quran 2:198 via the .navigateToVerse path.
    @MainActor
    func scheduleArafahReminder() async {
        // Only if already authorized — never prompt from here
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let calendar = IslamicCalendarManager.shared
        let hijriYear = calendar.currentIslamicYear()

        // Resolve 9 Dhul-Hijjah of the current Hijri year to a Gregorian date
        var comps = DateComponents()
        comps.year = hijriYear
        comps.month = 12
        comps.day = 9
        guard let arafahDay = calendar.islamicCalendar.date(from: comps) else { return }

        // Apply the user's preferred notification time
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: preferences.time)
        var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: arafahDay)
        fireComponents.hour = timeComponents.hour
        fireComponents.minute = timeComponents.minute

        // Skip if it has already passed this year
        if let fireDate = Calendar.current.date(from: fireComponents), fireDate <= Date() {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Day of Arafah 🤲"
        content.body = "Today is the Day of Arafah — the best day of the year for du'a and seeking forgiveness. Tap to continue your Dhul-Hijjah Journey."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ARAFAH_REMINDER"
        content.userInfo = ["surah": 2, "verse": 198]

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "arafah_reminder_\(hijriYear)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("✅ NotificationManager: Arafah reminder scheduled for \(fireComponents)")
        } catch {
            print("❌ NotificationManager: Error scheduling Arafah reminder - \(error)")
        }
    }
```

**Step 2: Re-arm it on every reschedule** — at the END of `scheduleNotifications()`, immediately before its closing `}` (after the `for dayOffset in 0..<7 { … }` loop, ~line 223), add:

```swift

        // Re-arm the Day of Arafah reminder so it survives daily reschedules
        if IslamicCalendarManager.shared.isHajjSeason() {
            await scheduleArafahReminder()
        }
```

**Step 3: Build** — expected `** BUILD SUCCEEDED **`.

**Step 4: Commit (manual checkpoint)**

```bash
git add AlBayan/Services/NotificationManager.swift
git commit -m "feat(hajj): Day-of-Arafah local reminder, re-armed on reschedule"
```

---

## Task 10: Launch-time scheduling + seasonal progress ring + onboarding card

**Files:**
- Modify: `AlBayan/ContentView.swift`
- Modify: `AlBayan/Views/ProgressRingsView.swift`
- Modify: `AlBayan/Views/Onboarding/SeasonalFeaturesScreen.swift`

**Step 1: Schedule Arafah on launch (ContentView)**

Locate the launch path:
```bash
grep -n "checkFirstLaunch()\|\.onAppear\|recordAppLaunch" AlBayan/ContentView.swift
```
In the same `.onAppear { … }` closure that calls `checkFirstLaunch()` / `ratingManager.recordAppLaunch()`, add as the last statement inside it:

```swift
            if IslamicCalendarManager.shared.isHajjSeason() {
                Task { await NotificationManager.shared.scheduleArafahReminder() }
            }
```

**Step 2: Seasonal ring shows Hajj % in Hajj season (ProgressRingsView)**

The view passes `ramadanProgress:` / `showRamadanRing:` into `ProgressRingsStack` (line 90–95) and `RingLegend(showRamadanRing:)` (line 50). Make the seasonal ring source from whichever season is active, without renaming the shared component params.

- After the `isRamadanSeason` computed prop (line 19–21), add:
  ```swift
      private var isHajjSeason: Bool {
          IslamicCalendarManager.shared.isHajjSeason()
      }
  ```
- Replace the `ramadanProgress` computed prop (lines 36–38) with a seasonal selector:
  ```swift
      private var seasonalProgress: Double {
          if isHajjSeason { return HajjJourneyManager.shared.completionPercentage }
          return ramadanManager.completionPercentage
      }
      private var showSeasonalRing: Bool { isRamadanSeason || isHajjSeason }
  ```
  Add `@StateObject private var hajjManager = HajjJourneyManager.shared` next to the existing `ramadanManager` declaration (line 14) to drive view updates.
- Update the two call sites:
  - Line 50: `RingLegend(showRamadanRing: showSeasonalRing)`
  - Lines 94–95: `ramadanProgress: seasonalProgress,` and `showRamadanRing: showSeasonalRing`
- **Legend label** — `grep -n "Ramadan\|seasonalLabel\|label" AlBayan/Views/ProgressRingsView.swift` to find where `RingLegend` and `ProgressRingsStack` are *defined* and how the seasonal ring is labelled "Ramadan". Add an optional `seasonalLabel: String = "Ramadan"` parameter to those two component initializers, use it for the seasonal ring's text, and pass `seasonalLabel: isHajjSeason ? "Hajj" : "Ramadan"` from both call sites. (If the components live in another file, edit there; keep the default so other callers are unaffected.)

**Step 3: Onboarding — real Dhul-Hijjah card (SeasonalFeaturesScreen)**

Replace the "More Coming Soon" card (lines 122–136) with a real Dhul-Hijjah card placed right after the Ramadan card:

```swift
                // Dhul-Hijjah Journey card - expanded
                SeasonalFeatureExpandedCard(
                    icon: "building.columns.fill",
                    iconColors: [.green, .teal],
                    title: "Dhul-Hijjah Journey",
                    badge: "Seasonal",
                    badgeColor: .green,
                    features: [
                        ("hands.sparkles.fill", "Daily du'a & dhikr for the ten blessed days"),
                        ("book.pages.fill", "Curated verses for the best ten days of the year"),
                        ("mountain.2.fill", "Day of Arafah reminder"),
                        ("checkmark.circle.fill", "Track your 10-day journey")
                    ],
                    isVisible: showFeatureCards,
                    delay: 0.2
                )
```

(Drop the old "More Coming Soon" card entirely. Optionally update the bottom message line 143 to read `"The seasonal tab appears automatically\nduring Ramadan and Dhul-Hijjah"`.)

**Step 4: Build** — expected `** BUILD SUCCEEDED **`. Fix any `RingLegend`/`ProgressRingsStack` initializer mismatches.

**Step 5: Commit (manual checkpoint)**

```bash
git add AlBayan/ContentView.swift AlBayan/Views/ProgressRingsView.swift AlBayan/Views/Onboarding/SeasonalFeaturesScreen.swift
git commit -m "feat(hajj): launch Arafah scheduling, seasonal Hajj ring, onboarding card"
```

---

## Task 11: Manual integration validation (force the season)

**Files:**
- Temporary edit: `AlBayan/Services/IslamicCalendarManager.swift` (revert before final commit)

**Step 1: Force Hajj season + a specific day**

Temporarily hard-code for testing:
```swift
    func isHajjSeason() -> Bool { return true }
    func currentHajjDay() -> Int? { return 9 }   // exercise the Arafah path
```
(Keep `currentIslamicYear()` real.)

**Step 2: Run in the simulator** (Xcode ▶ or `xcodebuild … build` then launch). Validate the checklist:

- [ ] A **"Hajj"** tab appears at `tag(3)`; the Ramadan tab is NOT also present.
- [ ] List shows header "Dhul-Hijjah Journey" + `hajjSeasonStatus()` ("Day of Arafah" for day 9) + "X of 10 days" progress.
- [ ] 10 day cards render; today's day (9) highlighted; future days muted/locked.
- [ ] Day 1 opens detail (free). Days 2–10 hit `PaywallView` when not premium; with premium entitlement they open.
- [ ] Detail view: du'a Arabic renders RTL in `AmiriQuran-Regular`, transliteration/English/source present; each of the 2 verse cards shows Arabic + translation (via `DataManager`) and a working "Full Tafsir" deep-link into the Quran tab; tafsirFocus + reflection render.
- [ ] Mark all 10 days → "Hajj Champion" badge celebration appears once; badge shows on the Progress badge wall; `totalSawab` increases by 500; re-marking does not double-award.
- [ ] Progress tab seasonal ring shows Hajj % and is labelled **"Hajj"**.
- [ ] Onboarding seasonal screen shows the Dhul-Hijjah card.
- [ ] No-fallback: temporarily rename the bundled `hajj_journey.json` lookup (or set `forResource` to a bad name) → list view shows the error section, no placeholder content. Revert.
- [ ] Year reset: set a stale `year` in the persisted `hajjJourneyProgress` (or call `HajjJourneyManager.shared.resetProgress()`), relaunch → progress cleared.
- [ ] Arafah notification: with notifications authorized, trigger `NotificationManager.shared.scheduleArafahReminder()` (or set `preferences.time` to ~1 min ahead and force `currentIslamicYear`/date so 9 Dhul-Hijjah is imminent) → notification fires; tapping it deep-links to Quran 2:198.

**Step 3: Revert the temporary forcing**

Restore the real `isHajjSeason()` / `currentHajjDay()` bodies (from Task 2). Confirm:
```bash
grep -n "return true\|return 9" AlBayan/Services/IslamicCalendarManager.swift
```
Expected: no forced-test lines remain.

**Step 4: Final build** — expected `** BUILD SUCCEEDED **`.

**Step 5: Commit (manual checkpoint)** — only the revert, if anything changed:

```bash
git add AlBayan/Services/IslamicCalendarManager.swift
git commit -m "test(hajj): revert season-forcing after integration validation"
```

---

## Deltas from the export spec (codebase reality — already baked into this plan)

1. Conditional tab is `tag(3)` shared with Ramadan via `else if`, not the export's `tag(5)`.
2. No "daily-verse reschedule routine" — Arafah re-armed at the end of `scheduleNotifications()` + once at launch in `ContentView`'s existing `.onAppear`.
3. `ProgressManager` is SwiftData-backed; `awardHajjBadge` mirrors `awardRamadanBadge` (`modelContext.insert` + `save()`), not the export's `saveProgress()/scheduleSync()`.
4. `.navigateToVerse` receiver already lives in `SurahListView` — carried over unchanged by the view rename; verify only.
5. Existing `isDhulHijjah()` left intact; new `isHajjSeason()` added alongside.
6. Xcode uses file-system synchronized groups → no `.pbxproj` edits; new files auto-join the target.
7. No XCTest target → validation is compile + manual season-forcing (Task 11), not TDD.
```
