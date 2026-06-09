# Journeys Hub Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace AlBayan's conditional in-season-only seasonal tab with a permanent
"Journeys" hub tab that lists every journey (Ramadan, Dhul-Hijjah) with live Hijri status
(Active / Coming soon / Ended), opens the active one full-screen, and explains locked ones.

**Architecture:** A static registry (`JourneyCatalog`) describes each journey; the existing
`IslamicCalendarManager` (extended with a debug-overridable `now` anchor) computes each
journey's status; `JourneyHubView` renders cards, presents the active journey's existing
view (`RamadanJourneyView`/`HajjJourneyView`, untouched) in a `.fullScreenCover`, and shows
a modal for locked taps. A lean `DeepLinkRouter` lets a tapped notification auto-open the
active journey. No backend, no new models, no change to journey progress/managers/JSON.

**Tech Stack:** Swift / SwiftUI, `Calendar(identifier: .islamicUmmAlQura)`, `ThemeManager`
design tokens, `UserDefaults` (already owned by the journey managers — untouched here).
iOS 18.2 target.

**Source design:** `docs/plans/2026-06-08-journeys-hub-design.md` ·
**Source spec:** `2026-06-08-albayan-journeys-tab-handoff.md` (root, untracked).

---

## Conventions for this plan (read first)

- **No XCTest target exists** (repo convention). The verification gate after each task is a
  clean **`xcodebuild build`**, plus **`#Preview`**/simulator checks where noted. Do **not**
  invent unit tests.
- **Build command** (generic destination = build-only; no specific booted device needed):
  ```bash
  xcodebuild -scheme AlBayan -destination 'generic/platform=iOS Simulator' build > /tmp/albayan_build.log 2>&1; echo "EXIT=$?"; tail -5 /tmp/albayan_build.log
  ```
  Expected: `EXIT=0` and `** BUILD SUCCEEDED **`. Capture `$?` from xcodebuild directly —
  piping straight to `tail` reports `tail`'s exit code, not the build's. NOTE: the
  iPhone 15-series sims have an incompatible runtime on this machine; named sims that
  resolve are iPhone 16e / 17 / Air (iOS 18.6 / 26.x) — `xcrun simctl list devices available | grep iPhone`.
- **Commits:** the user commits. Each task ends at a green build; do **not** auto-commit. A
  suggested final commit message is at the bottom.
- **New `.swift` files must be added to the Xcode target.** Xcode 16 uses synced folder
  groups, so files dropped into `AlBayan/Services/` and `AlBayan/Views/` are picked up
  automatically. If a new file isn't found by the build, add it to the `AlBayan` target in
  Xcode (or the `PBXFileSystemSynchronizedRootGroup` already covers these dirs — verify the
  build sees it).
- **Reuse, don't modify:** `RamadanJourneyView`, `HajjJourneyView`, their managers, JSON,
  models, badges, and premium gating are **not touched**.

---

## Task 1: Hijri `now` anchor + debug override in IslamicCalendarManager

Gives the calendar a single time source that `#Preview`s (and `JourneyCatalog.status`) can
drive. Purely additive; existing season methods keep working because they already read
through `currentIslamicDate()`.

**Files:**
- Modify: `AlBayan/Services/IslamicCalendarManager.swift`

**Step 1: Add the `debugNowOverride` static + `now` anchor.**
In `IslamicCalendarManager`, just after `private init() {}` (around line 14), insert:

```swift
    #if DEBUG
    /// Verification-only override for "now". Set from a #Preview to drive any Hijri date.
    static var debugNowOverride: Date? = nil
    #endif

    /// The instant all Hijri computations anchor to (overridable in DEBUG for previews).
    var now: Date {
        #if DEBUG
        return Self.debugNowOverride ?? Date()
        #else
        return Date()
        #endif
    }
```

**Step 2: Route `currentIslamicDate()` through `now`.**
Replace the body of `currentIslamicDate()` (around lines 26–30):

```swift
    func currentIslamicDate() -> DateComponents {
        let now = Date()
        let components = islamicCalendar.dateComponents([.year, .month, .day, .weekday], from: now)
        return components
    }
```
with:
```swift
    func currentIslamicDate() -> DateComponents {
        return islamicCalendar.dateComponents([.year, .month, .day, .weekday], from: now)
    }
```

**Step 3: Build.**
Run the build command. Expected: `** BUILD SUCCEEDED **`.
(Behavior is unchanged in Release; in DEBUG `debugNowOverride` is still `nil`, so `now` == `Date()`.)

---

## Task 2: DeepLinkRouter + `.navigateToJourney`

A tiny shared holder for "a notification asked to open journey X". Plain `ObservableObject`
(matching `IslamicCalendarManager`'s non-`@MainActor` style) so the `.onReceive` in Task 5
sets it without actor friction.

**Files:**
- Create: `AlBayan/Services/DeepLinkRouter.swift`

**Step 1: Create the file.**

```swift
//
//  DeepLinkRouter.swift
//  AlBayan
//
//  Routes a journey deep-link (from a tapped notification) to the Journeys hub.
//  Set by MainTabView on a `.navigateToJourney` notification; consumed (+cleared)
//  by JourneyHubView, which opens the journey only if it is currently active.
//

import Foundation

final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    /// Journey id ("ramadan" | "hajj") to auto-open once the hub appears.
    @Published var pendingJourneyId: String? = nil

    private init() {}
}

extension Notification.Name {
    /// Posted with `userInfo: ["journey": "<id>"]` to jump to the Journeys hub
    /// and auto-open the active journey.
    static let navigateToJourney = Notification.Name("navigateToJourney")
}
```

**Step 2: Build.** Expected: `** BUILD SUCCEEDED **`.

---

## Task 3: JourneyCatalog (status model + registry)

The registry + status bucketing. Reuses the existing season predicates/status strings; adds
no new calendar logic. Uses graceful fallbacks (no `preconditionFailure`).

**Files:**
- Create: `AlBayan/Services/JourneyCatalog.swift`

**Step 1: Create the file.**

```swift
//
//  JourneyCatalog.swift
//  AlBayan
//
//  Static registry of seasonal journeys + Hijri-date status bucketing.
//  Add a journey = append one JourneyDescriptor row (see the Muharram template below).
//

import SwiftUI

/// A journey's state relative to the current Hijri date.
enum JourneyStatus: Equatable {
    case active(line: String)
    case comingSoon(daysUntil: Int, startsLabel: String)
    case ended(daysUntil: Int, returnsLabel: String)   // daysUntil counts to NEXT year's return
    var isActive: Bool { if case .active = self { return true } else { return false } }
}

/// One journey in the hub. Static registry — see `JourneyDescriptor.all`.
struct JourneyDescriptor: Identifiable {
    let id: String                 // matches deep-link id + notification "journey" key
    let eyebrow: String            // e.g. "30-Day Journey"
    let title: String              // e.g. "Ramadan"
    let sfSymbol: String           // e.g. "moon.stars.fill"
    let contentStartMonth: Int     // Hijri month content begins (Ramadan=9, Dhul-Hijjah=12)
    let isActive: () -> Bool
    let statusLine: () -> String
    let destination: () -> AnyView // existing journey screen, reused in a full-screen cover
    /// For journeys whose schedule isn't a single content month (e.g. an evergreen journey
    /// that returns `.active` always). Not needed for the current roster.
    var statusOverride: ((IslamicCalendarManager) -> JourneyStatus)? = nil

    static let all: [JourneyDescriptor] = [
        JourneyDescriptor(
            id: "ramadan", eyebrow: "30-Day Journey", title: "Ramadan",
            sfSymbol: "moon.stars.fill", contentStartMonth: 9,
            isActive: { IslamicCalendarManager.shared.isRamadanSeason() },
            statusLine: { IslamicCalendarManager.shared.ramadanSeasonStatus() },
            destination: { AnyView(RamadanJourneyView()) }
        ),
        JourneyDescriptor(
            id: "hajj", eyebrow: "10-Day Journey", title: "Dhul-Hijjah",
            sfSymbol: "building.columns.fill", contentStartMonth: 12,
            isActive: { IslamicCalendarManager.shared.isHajjSeason() },
            statusLine: { IslamicCalendarManager.shared.hajjSeasonStatus() },
            destination: { AnyView(HajjJourneyView()) }
        ),
        // To add Muharram later (reframed for Sunni — Hijra / fast of ʿĀshūrāʾ / fresh start),
        // build its manager+view+JSON, add isMuharramSeason()/muharramSeasonStatus() to
        // IslamicCalendarManager, then append:
        // JourneyDescriptor(
        //   id: "muharram", eyebrow: "10-Day Journey", title: "Muharram",
        //   sfSymbol: "sunrise.fill", contentStartMonth: 1,
        //   isActive: { IslamicCalendarManager.shared.isMuharramSeason() },
        //   statusLine: { IslamicCalendarManager.shared.muharramSeasonStatus() },
        //   destination: { AnyView(MuharramJourneyView()) }
        // ),
    ]

    static func byId(_ id: String) -> JourneyDescriptor? { all.first { $0.id == id } }
}

extension JourneyDescriptor {
    /// Status for the current Hijri date. Buckets: active → in season; else this Hijri year's
    /// content-start still ahead → coming soon; else (began this year, not active) → ended.
    /// Graceful fallbacks instead of crashing if Hijri components are somehow unavailable.
    func status(using cal: IslamicCalendarManager = .shared) -> JourneyStatus {
        if let statusOverride { return statusOverride(cal) }
        if isActive() { return .active(line: statusLine()) }

        let icalendar = cal.islamicCalendar
        guard let year = cal.currentIslamicDate().year,
              let thisYearStart = icalendar.date(
                from: DateComponents(year: year, month: contentStartMonth, day: 1)) else {
            return .comingSoon(daysUntil: 0, startsLabel: "Coming soon")
        }

        let now = cal.now
        if now < thisYearStart {
            return .comingSoon(daysUntil: Self.daysBetween(now, thisYearStart),
                               startsLabel: "Begins \(Self.medium(thisYearStart))")
        }
        guard let nextYearStart = icalendar.date(
            from: DateComponents(year: year + 1, month: contentStartMonth, day: 1)) else {
            return .ended(daysUntil: 0, returnsLabel: "Returns next year")
        }
        return .ended(daysUntil: Self.daysBetween(now, nextYearStart),
                      returnsLabel: "Returns \(Self.medium(nextYearStart))")
    }

    private static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let c = Calendar.current
        return max(0, c.dateComponents([.day], from: c.startOfDay(for: a),
                                       to: c.startOfDay(for: b)).day ?? 0)
    }
    private static func medium(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: date)
    }
}
```

**Step 2: Build.** Expected: `** BUILD SUCCEEDED **` (references `RamadanJourneyView`/
`HajjJourneyView`, which already exist).

---

## Task 4: JourneyHubView (hub + card + cover + locked overlay)

The whole hub UI in one file, in AlBayan's `ThemeManager` idiom (no `Em*` port). The file
compiles only once all the types below are present, so write them all, then build.

**Files:**
- Create: `AlBayan/Views/JourneyHubView.swift`

**Step 1: Create the file with the full contents below.**

```swift
//
//  JourneyHubView.swift
//  AlBayan
//
//  Permanent "Journeys" hub: lists every journey with live Hijri status,
//  opens the active one full-screen, and explains locked ones.
//

import SwiftUI

/// Identifiable wrapper so `.fullScreenCover(item:)` can key on a journey id.
struct PresentedJourney: Identifiable { let id: String }

/// Content for the modal shown when a locked (non-active) journey is tapped.
struct LockedJourneyAlert: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let pointer: String?
}

struct JourneyHubView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cal = IslamicCalendarManager.shared
    @StateObject private var router = DeepLinkRouter.shared
    @State private var presented: PresentedJourney?
    @State private var lockedAlert: LockedJourneyAlert?

    /// Descriptors + status, sorted Active → Coming-soon(soonest) → Ended(soonest to return).
    private var ordered: [(descriptor: JourneyDescriptor, status: JourneyStatus)] {
        JourneyDescriptor.all.map { ($0, $0.status(using: cal)) }
            .sorted { sortKey($0.1) < sortKey($1.1) }
    }
    private func sortKey(_ s: JourneyStatus) -> (Int, Int) {
        switch s {
        case .active:               return (0, 0)
        case .comingSoon(let d, _): return (1, d)
        case .ended(let d, _):      return (2, d)
        }
    }

    /// The soonest journey to open — highlighted "NEXT UP" — but only when none is active.
    private var nextUpId: String? {
        let items = ordered
        guard !items.contains(where: { $0.status.isActive }) else { return nil }
        return items.first?.descriptor.id
    }

    var body: some View {
        ZStack {
            AdaptiveModernBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    ForEach(ordered, id: \.descriptor.id) { item in
                        JourneyCard(descriptor: item.descriptor, status: item.status,
                                    isNextUp: item.descriptor.id == nextUpId) {
                            handleTap(item.descriptor, item.status)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 120)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .fullScreenCover(item: $presented) { p in
            if let d = JourneyDescriptor.byId(p.id) {
                JourneyCover(descriptor: d) { presented = nil }
            }
        }
        .onAppear { consumePendingJourney() }
        .onChange(of: router.pendingJourneyId) { _, _ in consumePendingJourney() }
        .overlay {
            if let alert = lockedAlert {
                LockedJourneyOverlay(alert: alert) {
                    withAnimation(.easeInOut(duration: 0.2)) { lockedAlert = nil }
                }
                .transition(.opacity)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("SACRED SEASONS")
                .font(.system(size: 11, weight: .bold)).tracking(3)
                .foregroundColor(themeManager.accentColor)
            Text("Journeys")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryText)
            Text("Live each sacred season deeply, and let it transform you.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleTap(_ d: JourneyDescriptor, _ status: JourneyStatus) {
        if status.isActive {
            presented = PresentedJourney(id: d.id)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                lockedAlert = makeLockedAlert(for: d, status: status)
            }
        }
    }

    private func makeLockedAlert(for d: JourneyDescriptor, status: JourneyStatus) -> LockedJourneyAlert {
        let title: String, detail: String
        switch status {
        case .ended(_, let returns):     title = "\(d.title) has ended";      detail = returns
        case .comingSoon(_, let starts): title = "\(d.title) isn't open yet"; detail = starts
        case .active:                    title = d.title;                     detail = ""
        }
        return LockedJourneyAlert(title: title, detail: detail, pointer: pointerLine(excluding: d))
    }

    /// "Up next: X · in N days" for the soonest journey to open, excluding the tapped one.
    private func pointerLine(excluding tapped: JourneyDescriptor) -> String? {
        func opensIn(_ s: JourneyStatus) -> Int {
            switch s {
            case .active: return 0
            case .comingSoon(let d, _): return d
            case .ended(let d, _): return d
            }
        }
        let rows = JourneyDescriptor.all.map { ($0, $0.status(using: cal)) }
        guard let soonest = rows.min(by: { opensIn($0.1) < opensIn($1.1) }) else { return nil }
        if soonest.0.id == tapped.id { return nil }
        if soonest.1.isActive { return "\(soonest.0.title) is open now" }
        let days = opensIn(soonest.1)
        if days <= 0 { return "Up next: \(soonest.0.title) · today" }
        return "Up next: \(soonest.0.title) · in \(days) day\(days == 1 ? "" : "s")"
    }

    /// If a deep-link queued a journey and it is currently active, open it. Always clear the id.
    private func consumePendingJourney() {
        guard let id = router.pendingJourneyId else { return }
        if let d = JourneyDescriptor.byId(id), d.isActive() {
            presented = PresentedJourney(id: id)
        }
        router.pendingJourneyId = nil
    }
}

// MARK: - Journey card

struct JourneyCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    let descriptor: JourneyDescriptor
    let status: JourneyStatus
    var isNextUp = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                iconChip
                VStack(alignment: .leading, spacing: 4) {
                    if isNextUp {
                        nextUpPill
                    } else {
                        Text(descriptor.eyebrow.uppercased())
                            .font(.system(size: 10.5, weight: .bold)).tracking(2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    Text(descriptor.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryText)
                    Text(detailLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                }
                Spacer(minLength: 8)
                trailingGlyph
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.cardBackground)
                    .shadow(color: Color.black.opacity(status.isActive ? 0.10 : 0.05),
                            radius: status.isActive ? 16 : 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: (status.isActive || isNextUp) ? 1.5 : 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var borderColor: Color {
        if status.isActive { return themeManager.accentColor.opacity(0.5) }
        if isNextUp { return themeManager.accentColor.opacity(0.4) }
        return themeManager.strokeColor
    }

    private var iconChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(status.isActive ? AnyShapeStyle(themeManager.accentGradient)
                                      : AnyShapeStyle(themeManager.accentColor.opacity(0.12)))
                .frame(width: 50, height: 50)
            Image(systemName: descriptor.sfSymbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(status.isActive ? .white : themeManager.accentColor)
        }
    }

    private var nextUpPill: some View {
        Text("NEXT UP")
            .font(.system(size: 9, weight: .heavy)).tracking(1.6)
            .foregroundColor(.white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(themeManager.accentGradient))
    }

    private var detailLine: String {
        switch status {
        case .active(let line):        return line
        case .comingSoon(let days, _): return "Coming soon · in \(days) day\(days == 1 ? "" : "s")"
        case .ended(_, let returns):   return isNextUp ? returns : "Ended · \(returns)"
        }
    }

    @ViewBuilder private var trailingGlyph: some View {
        switch status {
        case .active:
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeManager.accentColor)
        case .comingSoon, .ended:
            EmptyView()
        }
    }
}

// MARK: - Full-screen cover (hosts the existing journey view + a close control)

struct JourneyCover: View {
    @StateObject private var themeManager = ThemeManager.shared
    let descriptor: JourneyDescriptor
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            // Slim top bar with a right-aligned close control, so it never overlaps the
            // hosted journey's own header (which occupies both top corners: title + icon).
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(themeManager.primaryBackground)

            descriptor.destination()
        }
        .background(themeManager.primaryBackground.ignoresSafeArea())
    }
}

// MARK: - Locked-journey modal

struct LockedJourneyOverlay: View {
    @StateObject private var themeManager = ThemeManager.shared
    let alert: LockedJourneyAlert
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { onDismiss() }
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(themeManager.accentColor.opacity(0.12)).frame(width: 56, height: 56)
                    Image(systemName: "hourglass")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(themeManager.accentColor)
                }
                VStack(spacing: 6) {
                    Text(alert.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryText)
                        .multilineTextAlignment(.center)
                    if !alert.detail.isEmpty {
                        Text(alert.detail)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    if let pointer = alert.pointer {
                        Text(pointer)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(themeManager.accentGradient))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeManager.cardBackground))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.strokeColor, lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 16)
            .padding(40)
        }
    }
}

// MARK: - Previews (debug-date matrix)

#if DEBUG
private func hijriDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
    IslamicCalendarManager.shared.islamicCalendar.date(from: DateComponents(year: y, month: m, day: d))!
}
#Preview("Hub · Ramadan active (9/3)") {
    IslamicCalendarManager.debugNowOverride = hijriDate(1449, 9, 3); return JourneyHubView()
}
#Preview("Hub · Dhul-Hijjah active (12/3)") {
    IslamicCalendarManager.debugNowOverride = hijriDate(1449, 12, 3); return JourneyHubView()
}
#Preview("Hub · Rajab — none active (7/10)") {
    IslamicCalendarManager.debugNowOverride = hijriDate(1449, 7, 10); return JourneyHubView()
}
#endif
```

**Step 2: Build.** Expected: `** BUILD SUCCEEDED **`.

**Step 3: Verify the three `#Preview`s in Xcode.**
- *Ramadan active (9/3):* Ramadan card on top with a gradient icon + "Day 3 of Ramadan" +
  chevron; Dhul-Hijjah below as "Coming soon · in N days" or "Ended · Returns …" (no chevron).
- *Dhul-Hijjah active (12/3):* Dhul-Hijjah card active ("Day 3 of Dhul-Hijjah"); Ramadan locked.
- *Rajab (7/10):* nothing active → the soonest opener shows the **NEXT UP** pill; tap a card →
  the locked modal appears with a correct "Up next: …" pointer.

> If a preview shows a blank canvas, it's usually a stale index — trust `xcodebuild`, not the
> editor squiggle.

---

## Task 5: Swap MainTabView to the permanent hub + deep-link receiver

**Files:**
- Modify: `AlBayan/Views/MainTabView.swift`

**Step 1: Remove the now-unused season computed vars.**
Delete these two properties (lines ~14–21):

```swift
    // Check if Ramadan season is active
    private var isRamadanSeason: Bool {
        IslamicCalendarManager.shared.isRamadanSeason()
    }

    private var isHajjSeason: Bool {
        IslamicCalendarManager.shared.isHajjSeason()
    }
```

**Step 2: Replace the conditional tag-3 block with the permanent hub.**
Replace this whole block (the `if isRamadanSeason { … } else if isHajjSeason { … }`,
lines ~55–76):

```swift
            // Conditional Ramadan tab - only visible during Ramadan season
            if isRamadanSeason {
                RamadanJourneyView()
                    .tabItem {
                        Label {
                            Text("Ramadan")
                        } icon: {
                            Image(systemName: "moon.stars.fill")
                        }
                    }
                    .tag(3)
            } else if isHajjSeason {
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
with:
```swift
            // Permanent Journeys hub (lists every journey with live Hijri status).
            JourneyHubView()
                .tabItem {
                    Label {
                        Text("Journeys")
                    } icon: {
                        Image(systemName: "map.fill")
                    }
                }
                .tag(3)
```

**Step 3: Add the deep-link receiver.**
Replace the closing modifier line:
```swift
        .tint(themeManager.accentColor)
```
with:
```swift
        .tint(themeManager.accentColor)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToJourney)) { note in
            guard let journeyId = note.userInfo?["journey"] as? String else { return }
            DeepLinkRouter.shared.pendingJourneyId = journeyId
            selectedTab = 3
        }
```

(Also update the file's top comment from "conditional seasonal (Ramadan / Hajj) tab" to
"permanent Journeys hub tab" — optional.)

**Step 4: Build.** Expected: `** BUILD SUCCEEDED **`.

**Step 5: Run in the simulator and verify behavior.**
```bash
xcodebuild -scheme AlBayan -destination 'platform=iOS Simulator,name=iPhone 17' build
# then run the app from Xcode, or boot the sim + install the built .app
```
- A permanent **Journeys** tab (map icon) is always present (tab index 3).
- Tapping it shows the hub with both journey cards in the right order/status.
- **In season** (or via a preview date): the active card opens the journey full-screen; the
  **chevron-down** in the cover's slim top bar dismisses it. The bar sits *above* the journey
  header, so nothing overlaps (verified in the simulator).
- Tapping a locked card shows the modal with the correct "Up next" pointer.
- Deep-link: trigger
  ```swift
  NotificationCenter.default.post(name: .navigateToJourney, object: nil, userInfo: ["journey": "ramadan"])
  ```
  (e.g. from a temporary debug button) → the app switches to the Journeys tab and, if Ramadan
  is active, auto-opens it; otherwise it just lands on the hub. The pending id is always cleared.

---

## Task 6 (optional): Point onboarding at the permanent tab

If you want the onboarding "seasonal features" copy to reflect the always-available hub.

**Files:**
- Modify: `AlBayan/Views/Onboarding/SeasonalFeaturesScreen.swift`

**Step 1:** Update the copy to mention that journeys now live in a permanent **Journeys**
tab (available year-round, opening automatically when each season arrives). Keep it to a
one-line tweak of the existing text; no structural change.

**Step 2: Build.** Expected: `** BUILD SUCCEEDED **`.

---

## Final verification (whole feature)

1. `xcodebuild … build` → `** BUILD SUCCEEDED **`.
2. `#Preview` matrix (Task 4) renders all three states correctly.
3. Simulator behavior checks (Task 5, Step 5) all pass.
4. Sanity: the previously-conditional journeys are still fully functional **inside** the
   cover (progress marking persists, premium gating + paywall still work, verse "Full Tafsir"
   deep-links still open) — because their views/managers were not modified.

## Suggested commit (user runs when satisfied)

```bash
git add AlBayan/Services/JourneyCatalog.swift AlBayan/Services/DeepLinkRouter.swift \
        AlBayan/Views/JourneyHubView.swift AlBayan/Services/IslamicCalendarManager.swift \
        AlBayan/Views/MainTabView.swift docs/plans/2026-06-08-journeys-hub-design.md \
        docs/plans/2026-06-08-journeys-hub.md
# (+ AlBayan.xcodeproj/project.pbxproj if Xcode added the new files to the target)
# (+ AlBayan/Views/Onboarding/SeasonalFeaturesScreen.swift if Task 6 done)
git commit -m "feat(journeys): permanent Journeys hub tab + catalog + deep-link routing"
```

## Out of scope (deferred)

Muharram journey (reframed Sunni) · `JourneyAnnouncements` season-announcement scheduler ·
the festive/somber `observedDays` split · any change to existing journey views, managers,
JSON, badges, or premium gating.
