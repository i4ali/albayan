//
//  DeepLinkRouter.swift
//  AlBayan
//
//  Routes a journey deep-link (from a tapped notification) to the Journeys hub.
//  Set by MainTabView on a `.navigateToJourney` notification; consumed (+cleared)
//  by JourneyHubView, which opens the journey only if it is currently active.
//

import Foundation

/// A verse deep-link waiting to be routed (e.g. from a tapped notification).
struct PendingVerse {
    let surah: Int
    let verse: Int
}

final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    /// Journey id ("ramadan" | "hajj") to auto-open once the hub appears.
    @Published var pendingJourneyId: String? = nil

    /// Verse to navigate to once the Quran tab appears. Set by the notification
    /// delegate / onOpenURL so cold launches survive until views are subscribed;
    /// consumed (+cleared) by HomeView.
    @Published var pendingVerse: PendingVerse? = nil

    private init() {}
}

extension Notification.Name {
    /// Posted with `userInfo: ["journey": "<id>"]` to jump to the Journeys hub
    /// and auto-open the active journey.
    static let navigateToJourney = Notification.Name("navigateToJourney")
}
