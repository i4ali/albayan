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
