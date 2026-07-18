//
//  LayersScreen.swift
//  AlBayan
//
//  Onboarding Screen 3: Four Layers of Wisdom
//

import SwiftUI

struct LayersScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isVisible = false
    @State private var selectedLayer: TafsirLayer?

    private let layers: [(layer: TafsirLayer, emoji: String, title: String, description: String)] = [
        (.foundation, "🏛️", "Foundation", "Simple explanations and historical context"),
        (.classical, "📚", "Classical Sunni", "Tabari, Ibn Kathir, Qurtubi"),
        (.contemporary, "🌍", "Contemporary", "Modern perspectives and scientific analysis"),
        (.comparative, "⚖️", "Comparative", "Balanced Sunni and Shia scholarly analysis")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Understand it at your own depth.")
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(32)
                          : .system(size: 32, weight: .bold))
                    .foregroundColor(themeManager.primaryText)
                    .onboardingTitle()
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(Animation.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                Text("From plain-words simple to deep classical tafsir - real scholarship, in language you'll actually follow.")
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(18, semibold: false)
                          : .system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .onboardingSubtitle()
                    .opacity(isVisible ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.6).delay(0.4), value: isVisible)
            }
            .padding(.top, 80)
            .padding(.bottom, 30)

            // Layers stack
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(layers.enumerated()), id: \.offset) { index, item in
                        LayerCard(
                            layer: item.layer,
                            emoji: item.emoji,
                            title: item.title,
                            description: item.description,
                            index: index,
                            isExpanded: selectedLayer == item.layer,
                            isVisible: isVisible,
                            onTap: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedLayer = selectedLayer == item.layer ? nil : item.layer
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Layer Card

struct LayerCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    let layer: TafsirLayer
    let emoji: String
    let title: String
    let description: String
    let index: Int
    let isExpanded: Bool
    let isVisible: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 14) {
                    // Emoji icon
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(layer.color.opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(20)
                                  : .system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.primaryText)

                        if !isExpanded {
                            Text(description)
                                .font(themeManager.isSapphire
                                      ? SapphireFont.serif(16, semibold: false)
                                      : .system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
                }

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(description)
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(17)
                                  : .system(size: 15, weight: .medium))
                            .foregroundColor(themeManager.primaryText)
                            .lineSpacing(4)

                        // Layer-specific details
                        Text(layerDetails)
                            .font(themeManager.isSapphire
                                  ? SapphireFont.serif(16, semibold: false)
                                  : .system(size: 14, weight: .regular))
                            .foregroundColor(themeManager.secondaryText)
                            .lineSpacing(3)

                        // Badge
                        HStack {
                            Text(layer.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(layer.color)
                                )

                            Spacer()
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.glassEffect)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isExpanded ? layer.color.opacity(0.5) : themeManager.strokeColor,
                                lineWidth: isExpanded ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isExpanded ? layer.color.opacity(0.2) : Color.clear,
                radius: isExpanded ? 12 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(Animation.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: isVisible)
    }

    private var layerDetails: String {
        switch layer {
        case .foundation:
            return "Perfect for beginners. Clear explanations of verses with historical context and basic Islamic principles."
        case .classical:
            return "Dive deep into classical Sunni scholarship with insights from Tabari's Jami al-Bayan, Ibn Kathir's Tafsir al-Quran al-Azim, and al-Qurtubi."
        case .contemporary:
            return "Modern Islamic scholars provide fresh perspectives, addressing contemporary issues and scientific connections."
        case .comparative:
            return "Unique to Tafakkur: Balanced analysis comparing Sunni and Shia scholarly interpretations with academic integrity."
        }
    }
}

extension TafsirLayer {
    var color: Color {
        switch self {
        case .foundation:
            return Color.blue
        case .classical:
            return Color.purple
        case .contemporary:
            return Color.green
        case .comparative:
            return Color.indigo
        }
    }
}

#Preview {
    LayersScreen()
}
