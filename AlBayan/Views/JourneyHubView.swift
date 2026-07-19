//
//  JourneyHubView.swift
//  AlBayan
//
//  Permanent "Journeys" hub. A compact, sectioned 2-column poster grid: each
//  section (Sacred Seasons, Inside the Surah) shows its first two entries as
//  premium-art poster tiles, with an "All N ›" link into a full-list screen when
//  the section holds more. Opens the active journey / surah experience full-screen,
//  and explains locked ones. Restructured from the old single-column list so the
//  whole hub reads above the fold (premium-art-sunni doc 03).
//

import SwiftUI

/// Identifiable wrapper so `.fullScreenCover(item:)` can key on a journey id.
struct PresentedJourney: Identifiable { let id: String }

/// Identifiable wrapper so `.fullScreenCover(item:)` can key on a surah-experience id.
struct PresentedSurahExperience: Identifiable { let id: String }

/// Content for the modal shown when a locked (non-active) journey is tapped.
struct LockedJourneyAlert: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let pointer: String?
}

/// The two content families in the hub. Drives section headers and the "All N ›"
/// full-list destination.
enum JourneyCategory: String, Identifiable, Hashable {
    case sacredSeasons
    case insideTheSurah
    var id: String { rawValue }
    var eyebrow: String {
        switch self {
        case .sacredSeasons:  return "SACRED SEASONS"
        case .insideTheSurah: return "INSIDE THE SURAH"
        }
    }
    var title: String {
        switch self {
        case .sacredSeasons:  return "Sacred Seasons"
        case .insideTheSurah: return "Inside the Surah"
        }
    }
    var blurb: String {
        switch self {
        case .sacredSeasons:  return "Live each sacred season deeply, and let it transform you."
        case .insideTheSurah: return "Descend through a single surah in one sitting."
        }
    }
}

// MARK: - Presentation coordinator

/// Owns what the hub is presenting (a journey cover, an experience cover, a locked
/// modal) and the tap → present logic. Shared with the pushed "All N" list so a card
/// tapped there drives the same full-screen covers (attached once at the hub root,
/// which sit above the whole navigation stack).
@MainActor
final class JourneyHubModel: ObservableObject {
    @Published var presented: PresentedJourney?
    @Published var presentedExperience: PresentedSurahExperience?
    @Published var lockedAlert: LockedJourneyAlert?

    private let cal = IslamicCalendarManager.shared
    private var lang: CommentaryLanguage { CommentaryLanguageManager.shared.selectedLanguage }

    // MARK: Seasons

    func handleTap(_ d: JourneyDescriptor, _ status: JourneyStatus) {
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
    func consumePendingJourney() {
        let router = DeepLinkRouter.shared
        guard let id = router.pendingJourneyId else { return }
        if let d = JourneyDescriptor.byId(id), d.isActive() {
            presented = PresentedJourney(id: id)
        }
        router.pendingJourneyId = nil
    }

    // MARK: Inside the Surah

    func handleSurahExperienceTap(_ d: SurahExperienceDescriptor) {
        if d.available {
            presentedExperience = PresentedSurahExperience(id: d.id)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                lockedAlert = LockedJourneyAlert(
                    title: "\(d.title.text(for: lang)) is on the way",
                    detail: "This journey is coming soon. al-Fatiha is ready to walk now.",
                    pointer: nil)
            }
        }
    }

    /// If a deep-link queued a surah experience, open it (the premium gate is still
    /// honored inside DeepDiveView via the veil). Always clear the id.
    func consumePendingSurahExperience() {
        let router = DeepLinkRouter.shared
        guard let id = router.pendingSurahExperienceId else { return }
        router.pendingSurahExperienceId = nil
        guard let d = SurahExperienceDescriptor.byId(id), d.available, d.dive != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.presentedExperience = PresentedSurahExperience(id: id)
        }
    }
}

// MARK: - Hub

struct JourneyHubView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cal = IslamicCalendarManager.shared
    @StateObject private var router = DeepLinkRouter.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var model = JourneyHubModel()
    private var lang: CommentaryLanguage { languageManager.selectedLanguage }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    /// Season descriptors + status, sorted Active → Coming-soon(soonest) → Ended(soonest to return).
    private var orderedSeasons: [(descriptor: JourneyDescriptor, status: JourneyStatus)] {
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

    var body: some View {
        ZStack {
            AdaptiveModernBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    section(.sacredSeasons, posters: seasonPosters)
                    section(.insideTheSurah, posters: surahPosters)
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 120)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .navigationDestination(for: JourneyCategory.self) { category in
            JourneyCategoryListView(category: category)
        }
        .journeyPresentation(model)
        .onAppear {
            model.consumePendingJourney()
            model.consumePendingSurahExperience()
        }
        .onChange(of: router.pendingJourneyId) { _, _ in model.consumePendingJourney() }
        .onChange(of: router.pendingSurahExperienceId) { _, _ in model.consumePendingSurahExperience() }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("GROW")
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 11, weight: .bold))
                .tracking(themeManager.isSapphire ? 2.5 : 3)
                .foregroundColor(themeManager.accentColor)
            Text("Journeys")
                .font(themeManager.isSapphire ? SapphireFont.screenTitle : .system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryText)
            Text("Enter a season, or descend into a single surah.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Section (header + first-two poster grid)

    @ViewBuilder
    private func section(_ category: JourneyCategory, posters: [JourneyPoster]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(category, total: posters.count)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(posters.prefix(2))) { poster in
                    JourneyPosterCard(poster: poster)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ category: JourneyCategory, total: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(category.eyebrow)
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 11, weight: .bold))
                .tracking(themeManager.isSapphire ? 2.5 : 3)
                .foregroundColor(themeManager.accentColor)
            Spacer()
            // A "see all" link only earns its place when the section holds more than
            // the two tiles shown here.
            if total > 2 {
                NavigationLink(value: category) {
                    HStack(spacing: 3) {
                        Text("All \(total)")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(themeManager.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Poster view-models

    private var seasonPosters: [JourneyPoster] {
        orderedSeasons.map { item in
            let d = item.descriptor, status = item.status
            return JourneyPoster(
                id: "season-\(d.id)",
                coverAssetName: d.coverAssetName,
                sfSymbol: d.sfSymbol,
                eyebrow: seasonEyebrow(status),
                tone: status.isActive ? .live : .muted,
                title: d.title,
                onTap: { model.handleTap(d, status) })
        }
    }

    private func seasonEyebrow(_ status: JourneyStatus) -> String {
        switch status {
        case .active:                  return "LIVE"
        case .comingSoon(let days, _): return days <= 0 ? "SOON" : "IN \(days) DAY\(days == 1 ? "" : "S")"
        case .ended:                   return "ENDED"
        }
    }

    private var surahPosters: [JourneyPoster] {
        SurahExperienceDescriptor.all.map { d in
            let locked = d.available && !premiumManager.canAccessSurahExperience(d.id)
            let eyebrow = !d.available ? "SOON" : (locked ? "PREMIUM" : "READY")
            return JourneyPoster(
                id: "surah-\(d.id)",
                coverAssetName: d.coverAssetName,
                sfSymbol: d.sfSymbol,
                eyebrow: eyebrow,
                tone: d.available ? .ready : .muted,
                title: d.title.text(for: lang),
                onTap: { model.handleSurahExperienceTap(d) })
        }
    }

}

// MARK: - Shared presentation (covers + locked modal)

/// Attaches the journey / experience full-screen covers and the locked-journey modal,
/// all driven by a `JourneyHubModel`. Each screen that shows journey cards owns its
/// own model + this modifier, so a tapped card always presents from the *topmost*
/// screen - robust whether that's the hub or a pushed "All N" list.
private struct JourneyPresentationModifier: ViewModifier {
    @ObservedObject var model: JourneyHubModel
    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $model.presented) { p in
                if let d = JourneyDescriptor.byId(p.id) {
                    JourneyCover(descriptor: d) { model.presented = nil }
                }
            }
            .fullScreenCover(item: $model.presentedExperience) { p in
                JourneyExperienceCover(presented: p) { model.presentedExperience = nil }
            }
            .overlay {
                if let alert = model.lockedAlert {
                    LockedJourneyOverlay(alert: alert) {
                        withAnimation(.easeInOut(duration: 0.2)) { model.lockedAlert = nil }
                    }
                    .transition(.opacity)
                }
            }
    }
}

extension View {
    func journeyPresentation(_ model: JourneyHubModel) -> some View {
        modifier(JourneyPresentationModifier(model: model))
    }
}

/// Full-screen descent for a presented experience, honoring the premium gate
/// (a gated reader gets the veiled preview, not a bounce).
private struct JourneyExperienceCover: View {
    @StateObject private var premiumManager = PremiumManager.shared
    let presented: PresentedSurahExperience
    let onClose: () -> Void
    var body: some View {
        if let d = SurahExperienceDescriptor.byId(presented.id), let dive = d.dive {
            let locked = !premiumManager.canAccessSurahExperience(d.id)
            DeepDiveView(
                dive: dive,
                onClose: onClose,
                onReadSurah: {
                    onClose()
                    NotificationCenter.default.post(
                        name: .navigateToVerse, object: nil,
                        userInfo: ["surah": d.surahNumber, "verse": 1])
                },
                coverAssetName: d.coverAssetName,
                lockedPaywallContext: locked
                    ? PaywallContext(coverAssetName: d.coverAssetName, eyebrow: "INSIDE THE SURAH")
                    : nil
            )
        }
    }
}

// MARK: - "All N" full-list screen

/// Pushed from a section's "All N ›" link. Renders every entry in the category as a
/// full detail row (reusing JourneyCard / SurahExperienceCard) and drives the same
/// presentation coordinator as the hub, so the full-screen covers - attached at the
/// hub root - still fire over this pushed screen.
struct JourneyCategoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cal = IslamicCalendarManager.shared
    @StateObject private var model = JourneyHubModel()
    let category: JourneyCategory

    private var orderedSeasons: [(descriptor: JourneyDescriptor, status: JourneyStatus)] {
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

    var body: some View {
        ZStack {
            AdaptiveModernBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    switch category {
                    case .sacredSeasons:
                        ForEach(orderedSeasons, id: \.descriptor.id) { item in
                            JourneyCard(descriptor: item.descriptor, status: item.status) {
                                model.handleTap(item.descriptor, item.status)
                            }
                        }
                    case .insideTheSurah:
                        ForEach(SurahExperienceDescriptor.all) { d in
                            SurahExperienceCard(descriptor: d) { model.handleSurahExperienceTap(d) }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 120)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) { backButton }
        .journeyPresentation(model)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(category.eyebrow)
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 11, weight: .bold))
                .tracking(themeManager.isSapphire ? 2.5 : 3)
                .foregroundColor(themeManager.accentColor)
            Text(category.title)
                .font(themeManager.isSapphire ? SapphireFont.screenTitle : .system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.primaryText)
            Text(category.blurb)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 44) // clear the back button
    }

    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeManager.primaryText)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 16)
        .padding(.top, 60)
    }
}

// MARK: - Journey card (full detail row, used in the "All N" list)

struct JourneyCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    let descriptor: JourneyDescriptor
    let status: JourneyStatus
    var isNextUp = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                leadingArt
                VStack(alignment: .leading, spacing: 4) {
                    if isNextUp {
                        nextUpPill
                    } else {
                        Text(descriptor.eyebrow.uppercased())
                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10.5, weight: .bold))
                            .tracking(themeManager.isSapphire ? 2.5 : 2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    Text(descriptor.title)
                        .font(themeManager.isSapphire ? SapphireFont.serif(21) : .system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryText)
                    Text(detailLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.isSapphire ? themeManager.tertiaryText : themeManager.secondaryText)
                }
                Spacer(minLength: 8)
                trailingGlyph
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.isSapphire && status.isActive
                          ? themeManager.cardElevated
                          : themeManager.cardBackground)
                    .shadow(color: Color.black.opacity(status.isActive ? 0.10 : 0.05),
                            radius: status.isActive ? 16 : 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: (status.isActive || isNextUp) ? 1.5 : 1)
            }
            // Coming-soon / ended journeys recede (premium-art doc 02.2); the featured
            // NEXT UP and active journeys stay at full strength.
            .opacity(isDimmed ? 0.82 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Unavailable journeys (ended, or a coming-soon that isn't the featured NEXT UP) dim.
    private var isDimmed: Bool { !status.isActive && !isNextUp }

    /// Leading art: the journey's premium-art cover as a mini poster tile (doc 02.2),
    /// falling back to the SF Symbol icon chip when the journey has no cover.
    @ViewBuilder private var leadingArt: some View {
        if let cover = descriptor.coverAssetName, CoverMiniTile.hasCover(cover) {
            CoverMiniTile(assetName: cover)
        } else {
            iconChip
        }
    }

    private var borderColor: Color {
        if status.isActive { return themeManager.accentColor.opacity(0.5) }
        if isNextUp { return themeManager.accentColor.opacity(0.4) }
        return themeManager.strokeColor
    }

    private var iconChip: some View {
        ZStack {
            if themeManager.isSapphire {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(themeManager.goldChipFill)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(status.isActive ? AnyShapeStyle(themeManager.accentGradient)
                                          : AnyShapeStyle(themeManager.accentColor.opacity(0.12)))
                    .frame(width: 50, height: 50)
            }
            Image(systemName: descriptor.sfSymbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor
                                                         : (status.isActive ? .white : themeManager.accentColor))
        }
    }

    private var nextUpPill: some View {
        Text("NEXT UP")
            .font(.system(size: 9, weight: .heavy)).tracking(1.6)
            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : .white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                Capsule().fill(
                    themeManager.isSapphire
                        ? AnyShapeStyle(themeManager.goldChipFill)
                        : AnyShapeStyle(themeManager.accentGradient)
                )
            )
            .overlay(
                themeManager.isSapphire
                    ? AnyView(Capsule().stroke(themeManager.accentColor.opacity(0.5), lineWidth: 1))
                    : AnyView(EmptyView())
            )
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
