//
//  PremiumManager.swift
//  AlBayan
//
//  Manages premium status derived from StoreKit Transaction.currentEntitlements.
//  StoreKit's local entitlement cache is the offline-safe source of truth and
//  cross-device-syncs automatically via the App Store account.
//

import Foundation
import StoreKit
import Combine

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium: Bool = false

    private let productID = "com.albayan.premium.tafsir"

    init() {
        Task { await refreshFromStoreKit() }
    }

    /// Re-derive `isPremium` from the current StoreKit entitlement set.
    func refreshFromStoreKit() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID, transaction.revocationDate == nil {
                found = true
                print("🌟 PREMIUM USER — entitlement active. productID=\(transaction.productID) " +
                      "txID=\(transaction.id) originalTxID=\(transaction.originalID) " +
                      "env=\(transaction.environment.rawValue) " +
                      "ownership=\(transaction.ownershipType.rawValue) " +
                      "purchaseDate=\(transaction.purchaseDate)")
                break
            }
        }
        if !found {
            print("🆓 FREE USER — no premium entitlement on the signed-in App Store account.")
        }
        isPremium = found
    }

    // MARK: - Access Control

    func canAccessTafsir(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessOverview(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessQuiz(surahNumber: Int) -> Bool {
        if surahNumber == 1 { return true }
        return isPremium
    }

    func canAccessLayer(_ layer: TafsirLayer, surahNumber: Int) -> Bool {
        if surahNumber == 1 {
            switch layer {
            case .foundation, .classical:
                return true
            case .contemporary, .comparative:
                return isPremium
            }
        }
        return isPremium
    }

    func canAccessPremiumReciter(_ reciter: Reciter) -> Bool { true }
    func getPremiumReciters() -> [Reciter] { [] }
    func getFreeReciters() -> [Reciter] { Reciter.popularReciters }

    func canAccessFastingCategory(_ categoryId: String) -> Bool {
        if categoryId == "obligation" { return true }
        return isPremium
    }

    func canAccessRamadanDay(_ dayNumber: Int) -> Bool {
        if dayNumber == 1 { return true }
        return isPremium
    }

    func canAccessHajjDay(_ dayNumber: Int) -> Bool {
        if dayNumber == 1 { return true }
        return isPremium
    }
}
