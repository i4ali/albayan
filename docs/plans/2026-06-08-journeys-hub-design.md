# Journeys Hub — Design

**Date:** 2026-06-08
**Status:** Approved
**Source spec:** `2026-06-08-albayan-journeys-tab-handoff.md` (port guide from the Shia
sibling app Thaqalayn; root-level, intentionally untracked)

## Goal

Replace AlBayan's *conditional, in-season-only* seasonal tab (tag 3, which swaps
Ramadan↔Hajj and disappears off-season) with a **permanent "Journeys" hub tab**: a
year-round catalog of every journey showing live Hijri status (Active / Coming soon /
Ended). Tap the active journey → it opens full-screen; tap a locked one → a "why +
what's next" modal. The hub wraps the **existing Ramadan + Dhul-Hijjah** journeys
unchanged, and is built so Muharram (or any journey) is added later as one registry row.

## Scope decisions (this pass)

- **Roster:** Ramadan + Dhul-Hijjah only. Muharram deferred (registry carries a
  commented template + the architecture already handles any N journeys).
- **Tab model:** permanent hub tab (not the "auto-open the active journey" variant) —
  the hub is always the landing surface; the active journey is one tap away.
- **Notifications:** lean — `DeepLinkRouter` only (a tapped journey notification opens
  the hub and auto-opens the active journey). No `JourneyAnnouncements` scheduler;
  reuse AlBayan's existing notification scheduling.

## Approach decisions (where the handoff was adapted)

1. **Native AlBayan design, not the Thaqalayn `Em*`/Cormorant kit.** The handoff ships a
   full component library (`EmCard`, `EmIconChip`, `EmType`, …) on Cormorant Garamond +
   Amiri. AlBayan already has its own idiom (`ThemeManager` tokens, solid warm cards,
   `accentGradient`, SF Pro). The ~3 new hub components are built in *that* idiom,
   matching `RamadanDayCard` / `ModernSurahCard`. No second design language.
2. **Reuse the journey screens verbatim in `.fullScreenCover`.** `RamadanJourneyView` and
   `HajjJourneyView` each already wrap themselves in a `NavigationView`, so they drop
   straight into a cover. They are **not modified**; the cover wrapper adds only a
   dismiss affordance.
3. **Graceful fallbacks, not `preconditionFailure`.** The handoff's `status(using:)`
   fails fast on (effectively impossible) missing Hijri components. AlBayan returns a
   sensible default instead of crashing.

## Architecture (mental model)

```
MainTabView  (tab 3 → permanent "Journeys", map.fill)
  └─ JourneyHubView
       • JourneyCatalog.all → [(descriptor, status)]   (status from the Hijri date)
       • sort: Active → Coming-soon(soonest) → Ended(soonest-to-return)
       • "NEXT UP" pill on the soonest opener when nothing is active
       • tap Active  → .fullScreenCover( JourneyCover → RamadanJourneyView / HajjJourneyView )
       • tap Locked  → LockedJourneyOverlay (why + "Up next: …")
       • consumes DeepLinkRouter.pendingJourneyId (notification → auto-open active)
```

A **static registry** (`JourneyCatalog`) describes each journey; the shared
`IslamicCalendarManager` computes each journey's status from the current Hijri date; the
hub presents the active journey in a `.fullScreenCover`. No backend, no shared engine —
journeys are added by appending one descriptor row. Journey *progress* stays exactly
where it is today (each journey's own manager + `UserDefaults` key); the hub is
presentation only.

## Components

### New files

| File | Contents |
|---|---|
| `Services/JourneyCatalog.swift` | `JourneyStatus` enum (`active`/`comingSoon`/`ended`); `JourneyDescriptor` (id, eyebrow, title, sfSymbol, contentStartMonth, `isActive`, `statusLine`, `destination`, optional `statusOverride`); `.all` registry (Ramadan, Dhul-Hijjah); `status(using:)` bucketing + sort/label helpers. |
| `Services/DeepLinkRouter.swift` | `@MainActor` singleton; `@Published var pendingJourneyId: String?`; `extension Notification.Name { static let navigateToJourney }`. |
| `Views/JourneyHubView.swift` | `JourneyHubView` (hub list, sort, NEXT-UP, full-screen cover, locked overlay, deep-link consume) + `JourneyCard` + `JourneyCover` + `LockedJourneyOverlay`, all in AlBayan's `ThemeManager` idiom. |

### Modified files

- **`Services/IslamicCalendarManager.swift`** — add a `#if DEBUG static var debugNowOverride: Date?`
  and a `var now: Date` anchor; route `currentIslamicDate()` through `now`. Enables the
  `#Preview` Hijri-date matrix and gives `status()` a single time source. Existing season
  methods (`isRamadanSeason`, `ramadanSeasonStatus`, `isHajjSeason`, `hajjSeasonStatus`,
  …) are untouched — they already read through `currentIslamicDate()`.
- **`Views/MainTabView.swift`** — replace the
  `if isRamadanSeason {…} else if isHajjSeason {…}` tag-3 block with a permanent
  `JourneyHubView()` at tag 3 (label "Journeys", `map.fill`); add
  `.onReceive(.navigateToJourney)` → set `selectedTab = 3` + `DeepLinkRouter.shared.pendingJourneyId`.

No asset-catalog entries — SF Symbols only. No model changes. No change to the journey
views, their JSON, managers, badges, premium gating, or notification scheduling.

## Design-system mapping (Em* → AlBayan)

| Handoff token | AlBayan equivalent |
|---|---|
| `tm.accentColor` / `accentGradient` | `accentColor` / `accentGradient` |
| `tm.onAccentText` | `.white` (text on gradient fills, as in `RamadanDayCard`) |
| `tm.accentChip` | `accentColor.opacity(0.12)` |
| `tm.glassSurface[Elevated]` | `glassEffect` (= `cardBackground`) |
| `tm.strokeColor` | `strokeColor` |
| `tm.semanticGreen` | `Color.green` |
| `tm.primary/secondary/tertiaryText`, `tertiaryBackground`, `colorScheme` | same names exist |
| `EmType.serif/arabic`, `EmCard`, `EmPressStyle`, … | plain SwiftUI + rounded-rect cards + `PlainButtonStyle` |
| `AdaptiveModernBackground()` | reuse as-is (it's `primaryBackground.ignoresSafeArea()`) |

Single visual path: `colorScheme` is `.light` and `useWarmLayout` is always true today,
so no dark-mode / dual-theme branching.

## Data flow

`JourneyHubView` observes `IslamicCalendarManager.shared` + `DeepLinkRouter.shared`. On
render it maps `JourneyCatalog.all` → `(descriptor, status(using:))`, sorts, and renders a
`JourneyCard` per row. Tapping Active sets `presented` → `.fullScreenCover` hosts
`JourneyCover(descriptor)` → `descriptor.destination()` (the existing journey view, with
its own `NavigationView` + progress + day rows + day detail). Tapping Locked sets
`lockedAlert` → `LockedJourneyOverlay`. A notification → `MainTabView` sets tab 3 +
`pendingJourneyId`; the hub's `consumePendingJourney()` opens the journey **only if it is
currently active**, and always clears the id.

## Error handling

`status(using:)` uses graceful fallbacks (never crashes on missing Hijri components). The
hub itself loads no JSON and owns no persistence, so there is no decode path to fail; the
journey managers keep their existing no-fallback `errorMessage` behavior unchanged.

## Testing (no XCTest target — repo convention)

1. `xcodebuild build` clean.
2. `#Preview` Hijri-date matrix via `IslamicCalendarManager.debugNowOverride`:
   - 1449/9/3 → Ramadan **Active** ("Day 3 of Ramadan"); Dhul-Hijjah Ended/Coming-soon.
   - 1449/12/3 → Dhul-Hijjah **Active** ("Day 3 of Dhul-Hijjah").
   - 1449/7/10 (Rajab) → nothing active → soonest opener shows **NEXT UP**; other "Coming soon · in N days" / "Ended".
3. Simulator: tap Active → cover opens + chevron-down dismisses; tap locked → overlay with
   correct "Up next" pointer; mark/unmark a day inside a journey still persists (unchanged
   managers); post `.navigateToJourney` `userInfo:["journey":"ramadan"]` → hub auto-opens
   the active journey.

## Deltas from the handoff (codebase reality)

1. **Integration, not greenfield.** Ramadan & Dhul-Hijjah journeys, their models,
   managers, JSON, badges, premium gating, and `IslamicCalendarManager` season API already
   exist — the hub only adds the catalog + tab + deep-link layer over them.
2. **Permanent tab is `tag(3)`** (replacing the conditional seasonal tab), not the
   handoff's `tag(4)` — AlBayan has 4 tabs, not 5.
3. **No `Em*` port / no Cormorant/Amiri** — native `ThemeManager` idiom (see mapping).
4. **`preconditionFailure` → graceful fallback** in `status(using:)`.
5. **Muharram, `JourneyAnnouncements`, and the festive/somber `observedDays` split are
   out of scope** this pass (deferred per the roster decision).
6. **Verse lookup / deep-link untouched** — the hub never reaches into Quran data; that
   lives inside the already-built journey day-detail views (`DataManager` + the
   `.navigateToVerse`/local-`NavigationLink` paths they already use).
