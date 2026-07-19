//
//  ExploreRow.swift
//  AlBayan
//
//  Reusable row component for Explore tab
//

import SwiftUI

struct ExploreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var coverAssetName: String? = nil
    let action: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Leading art: premium-art mini poster tile (doc 02.2), falling back to
                // the icon chip when the entry has no cover art.
                if CoverMiniTile.hasCover(coverAssetName), let cover = coverAssetName {
                    CoverMiniTile(assetName: cover)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : (themeManager.useWarmLayout ? .white : themeManager.accentColor))
                        .frame(width: 44, height: 44)
                        .background {
                            if themeManager.isSapphire {
                                Circle()
                                    .fill(themeManager.goldChipFill)
                                    .overlay(
                                        Circle()
                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                    )
                            } else if themeManager.useWarmLayout {
                                Circle()
                                    .fill(themeManager.accentGradient)
                                    .shadow(color: themeManager.accentColor.opacity(0.3), radius: 6)
                            } else {
                                Circle()
                                    .fill(themeManager.glassEffect)
                                    .overlay(
                                        Circle()
                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                    )
                            }
                        }
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(themeManager.isSapphire ? SapphireFont.serif(21) : .system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                if themeManager.isSapphire {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.tertiaryText)
                } else if themeManager.useWarmLayout {
                    Text(">")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.tertiaryText)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.tertiaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                themeManager.useWarmLayout
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(themeManager.glassEffect)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()

        VStack(spacing: 0) {
            ExploreRow(
                icon: "heart.fill",
                title: "Life Moments",
                subtitle: "Find solace for any situation"
            ) {
                print("Tapped")
            }

            Divider()

            ExploreRow(
                icon: "questionmark.circle",
                title: "Questions & Answers",
                subtitle: "Quranic answers to questions"
            ) {
                print("Tapped")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}
