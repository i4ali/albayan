//
//  SurahExperienceCard.swift
//  AlBayan
//
//  Hub card for one "Inside the Surah" experience. Deliberately the same layout
//  as JourneyCard so the "Inside the Surah" section reads as a peer of the Sacred
//  Seasons list. Available experiences show a chevron (a PREMIUM chip, never a
//  lock, when premium-gated and not subscribed); coming-soon experiences dim with
//  a "SOON" marker.
//

import SwiftUI

struct SurahExperienceCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    private var lang: CommentaryLanguage { languageManager.selectedLanguage }

    let descriptor: SurahExperienceDescriptor
    let onTap: () -> Void

    /// An available experience the user cannot yet open (premium-gated, not
    /// subscribed). Coming-soon cards are not "locked" - they read as "Soon".
    private var locked: Bool {
        descriptor.available && !premiumManager.canAccessSurahExperience(descriptor.id)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                leadingArt
                VStack(alignment: .leading, spacing: 4) {
                    if locked {
                        premiumPill
                    } else {
                        Text("INSIDE THE SURAH")
                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10.5, weight: .bold))
                            .tracking(themeManager.isSapphire ? 2.5 : 2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    Text(descriptor.title.text(for: lang))
                        .font(themeManager.isSapphire ? SapphireFont.serif(21) : .system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.primaryText)
                    Text(descriptor.subtitle.text(for: lang))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.isSapphire ? themeManager.tertiaryText : themeManager.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                trailingGlyph
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.isSapphire && descriptor.available
                          ? themeManager.cardElevated
                          : themeManager.cardBackground)
                    .shadow(color: Color.black.opacity(descriptor.available ? 0.10 : 0.05),
                            radius: descriptor.available ? 16 : 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: descriptor.available ? 1.5 : 1)
            }
            .opacity(descriptor.available ? 1 : 0.82)
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Leading art: the surah's cover as a mini poster tile, falling back to the
    /// SF Symbol icon chip when there is no cover.
    @ViewBuilder private var leadingArt: some View {
        if let cover = descriptor.coverAssetName, CoverMiniTile.hasCover(cover) {
            CoverMiniTile(assetName: cover)
        } else {
            iconChip
        }
    }

    private var borderColor: Color {
        if descriptor.available { return themeManager.accentColor.opacity(0.5) }
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
                    .fill(descriptor.available ? AnyShapeStyle(themeManager.accentGradient)
                                               : AnyShapeStyle(themeManager.accentColor.opacity(0.12)))
                    .frame(width: 50, height: 50)
            }
            Image(systemName: descriptor.sfSymbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor
                                                         : (descriptor.available ? .white : themeManager.accentColor))
        }
    }

    /// "PREMIUM" chip in the app's accent-chip treatment - no lock glyph.
    private var premiumPill: some View {
        Text("PREMIUM")
            .font(.system(size: 9, weight: .heavy)).tracking(1.4)
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

    @ViewBuilder private var trailingGlyph: some View {
        if descriptor.available {
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeManager.accentColor)
        } else {
            Text("SOON")
                .font(.system(size: 9, weight: .heavy)).tracking(1.4)
                .foregroundColor(themeManager.tertiaryText)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
        }
    }
}
