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
