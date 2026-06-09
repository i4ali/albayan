//
//  DailyDuaManager.swift
//  AlBayan
//
//  Loads bundled daily_duas.json and rotates one du'a per Islamic day-of-month,
//  mirroring NotificationManager.selectTodayVerse().
//

import Foundation

final class DailyDuaManager: ObservableObject {
    static let shared = DailyDuaManager()

    private let islamicCalendar = IslamicCalendarManager.shared
    private var duas: [DailyDua] = []

    private init() {
        loadDuas()
    }

    private func loadDuas() {
        guard let url = Bundle.main.url(forResource: "daily_duas", withExtension: "json") else {
            print("❌ DailyDuaManager: Could not find daily_duas.json in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            self.duas = try JSONDecoder().decode(DailyDuaData.self, from: data).duas
        } catch {
            print("❌ DailyDuaManager: Error loading duas - \(error)")
        }
    }

    /// Today's du'a, rotating by Islamic day-of-month (same scheme as the daily verse).
    func selectTodayDua() -> DailyDua? {
        guard !duas.isEmpty else { return nil }
        let day = islamicCalendar.currentIslamicDay()
        let index = (day - 1) % duas.count
        return duas[index]
    }
}
