//
//  DailyChallengeCard.swift
//  AlBayan
//
//  Today-tab entry card for the Daily Challenge. Self-contained 3-state button
//  (locked / done / pending) rebuilt in the Royal Sapphire theme. Owns its own
//  sheets — the play sheet (pending) and the paywall (locked). State is read from
//  PremiumManager + DailyChallengeManager + DailyChallengeProvider, so the card
//  updates after completion / a theme or language change.
//

import SwiftUI

struct DailyChallengeCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var challengeManager = DailyChallengeManager.shared
    @StateObject private var provider = DailyChallengeProvider.shared
    @ObservedObject private var premiumManager = PremiumManager.shared

    @State private var showPlaySheet = false
    @State private var showPaywall = false

    private var lang: CommentaryLanguage { languageManager.selectedLanguage }
    private var isLocked: Bool { !premiumManager.canAccessDailyChallenge() }

    var body: some View {
        Button {
            Haptics.impact(.light)
            if isLocked {
                showPaywall = true
            } else if !challengeManager.isCompletedToday {
                showPlaySheet = true
            }
        } label: {
            SpCard(glow: !isLocked && !challengeManager.isCompletedToday) {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(SpPressStyle())
        // Done state is not tappable.
        .disabled(!isLocked && challengeManager.isCompletedToday)
        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showPlaySheet) { DailyChallengeView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - State routing

    @ViewBuilder
    private var content: some View {
        if isLocked {
            lockedContent
        } else if challengeManager.isCompletedToday {
            doneContent
        } else {
            pendingContent
        }
    }

    // MARK: - Locked

    private var lockedContent: some View {
        HStack(spacing: 16) {
            SpIconChip(systemIcon: "crown.fill", size: 46)

            VStack(alignment: .leading, spacing: 6) {
                premiumPill
                Text(DailyChallengeStrings.lockedTagline(lang))
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
        Text(DailyChallengeStrings.premiumLabel(lang).uppercased())
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
                Text(DailyChallengeStrings.doneForToday(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(19)
                          : .system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
            }

            Spacer(minLength: 0)

            if challengeManager.streak.currentStreak > 0 {
                streakBadge
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥").font(.system(size: 16))
            Text("\(challengeManager.streak.currentStreak)")
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
            SpIconChip(systemIcon: "sparkles", size: 46)

            VStack(alignment: .leading, spacing: 4) {
                eyebrow
                Text(DailyChallengeStrings.dailyChallenge(lang))
                    .font(themeManager.isSapphire
                          ? SapphireFont.headline(20)
                          : .system(size: 19, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
                Text(DailyChallengeStrings.teaser(for: provider.today.format, lang))
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
        Text(DailyChallengeStrings.dailyChallenge(lang).uppercased())
            .font(SapphireFont.eyebrow)
            .tracking(themeManager.isSapphire ? 2.5 : 1.2)
            .foregroundColor(themeManager.accentColor)
    }
}

#Preview {
    ZStack {
        ThemeManager.shared.backgroundLayer
        DailyChallengeCard().padding()
    }
}
