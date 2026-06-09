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
