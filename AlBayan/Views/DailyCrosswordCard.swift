//
//  DailyCrosswordCard.swift
//  AlBayan
//
//  Today-tab entry card for the Daily Crossword. Self-contained 3-state button
//  (locked / done / pending) in the Royal Sapphire theme. Mirrors DailyChallengeCard
//  exactly in structure/style. Owns its own sheets — the play sheet (pending) and the
//  paywall (locked). State is read from PremiumManager + DailyCrosswordManager +
//  DailyCrosswordProvider, so the card updates after a solve / a theme or language change.
//

import SwiftUI

struct DailyCrosswordCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var crosswordManager = DailyCrosswordManager.shared
    @StateObject private var provider = DailyCrosswordProvider.shared
    @ObservedObject private var premiumManager = PremiumManager.shared

    @State private var showPlaySheet = false
    @State private var showPaywall = false

    private var lang: CommentaryLanguage { languageManager.selectedLanguage }
    private var isLocked: Bool { !premiumManager.canAccessDailyCrossword() }

    var body: some View {
        Button {
            Haptics.impact(.light)
            if isLocked {
                showPaywall = true
            } else if !crosswordManager.isCompletedToday {
                showPlaySheet = true
            }
        } label: {
            SpCard(glow: !isLocked && !crosswordManager.isCompletedToday) {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(SpPressStyle())
        // Done state is not tappable.
        .disabled(!isLocked && crosswordManager.isCompletedToday)
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showPlaySheet) {
            DailyCrosswordView(puzzle: provider.today)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        if isLocked {
            lockedContent
        } else if crosswordManager.isCompletedToday {
            doneContent
        } else {
            pendingContent
        }
    }

    // MARK: - Locked

    private var lockedContent: some View {
        HStack(spacing: 16) {
            SpIconChip(systemIcon: "lock.fill", size: 46)

            VStack(alignment: .leading, spacing: 6) {
                premiumPill
                Text(DailyCrosswordStrings.lockedTagline(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(18)
                          : .system(size: 17, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
                    .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var premiumPill: some View {
        Text(DailyCrosswordStrings.premiumLabel(lang).uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(2)
            .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                if themeManager.isSapphire {
                    Capsule()
                        .fill(themeManager.goldChipFill)
                        .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
                } else {
                    Capsule().fill(themeManager.accentColor.opacity(0.15))
                }
            }
    }

    // MARK: - Done

    private var doneContent: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(themeManager.goldChipFill)
                    .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
                    .frame(width: 46, height: 46)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                eyebrow
                Text(DailyCrosswordStrings.solved(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(19)
                          : .system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
            }

            Spacer(minLength: 0)

            if crosswordManager.streak.currentStreak > 0 {
                streakBadge
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥").font(.system(size: 16))
            Text("\(crosswordManager.streak.currentStreak)")
                .font(themeManager.isSapphire
                      ? SapphireFont.numeral(20)
                      : .system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            if themeManager.isSapphire {
                Capsule()
                    .fill(themeManager.goldChipFill)
                    .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
            } else {
                Capsule().fill(themeManager.accentColor.opacity(0.12))
            }
        }
    }

    // MARK: - Pending

    private var pendingContent: some View {
        HStack(spacing: 16) {
            SpIconChip(systemIcon: "square.grid.3x3.fill", size: 46)

            VStack(alignment: .leading, spacing: 4) {
                eyebrow
                Text(DailyCrosswordStrings.dailyCrossword(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(20)
                          : .system(size: 19, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
                Text(DailyCrosswordStrings.teaser(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.body(15)
                          : .system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(lang.isRTL ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: lang.isRTL ? "chevron.left" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.tertiaryText)
        }
    }

    // MARK: - Shared chrome

    private var eyebrow: some View {
        Text(DailyCrosswordStrings.dailyCrossword(lang).uppercased())
            .font(SapphireFont.eyebrow)
            .tracking(themeManager.isSapphire ? 2.5 : 1.2)
            .foregroundColor(themeManager.accentColor)
    }
}

#Preview {
    ZStack {
        ThemeManager.shared.backgroundLayer
        DailyCrosswordCard().padding()
    }
}
