//
//  TafsirSourcesView.swift
//  AlBayan
//
//  Displays the sources and scholars referenced in the tafsir commentary
//

import SwiftUI

struct TafsirSourcesView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.primaryBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Introduction
                        Text("The commentary in this app is grounded in classical and contemporary Sunni scholarship, with a comparative layer that surfaces Shia perspectives alongside the Sunni position. Below are the primary sources referenced for each layer.")
                            .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 15, weight: .regular))
                            .foregroundColor(themeManager.secondaryText)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Layer 1 - Foundation
                        SourceSection(
                            icon: "building.columns.fill",
                            title: "Foundation",
                            iconColor: .blue,
                            sources: [
                                SourceItem(title: "General Islamic Scholarship", subtitle: "Historical context and foundational understanding"),
                                SourceItem(title: "Classical Tafsir Methodology", subtitle: "Traditional exegetical approaches"),
                                SourceItem(title: "Tafsir al-Jalalayn", subtitle: "Al-Mahalli and al-Suyuti")
                            ]
                        )

                        // Layer 2 - Classical Sunni
                        SourceSection(
                            icon: "books.vertical.fill",
                            title: "Classical Sunni",
                            iconColor: .purple,
                            sources: [
                                SourceItem(title: "Jami al-Bayan", subtitle: "Imam al-Tabari"),
                                SourceItem(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir"),
                                SourceItem(title: "Al-Jami li-Ahkam al-Quran", subtitle: "Imam al-Qurtubi"),
                                SourceItem(title: "Mafatih al-Ghayb", subtitle: "Fakhr al-Din al-Razi")
                            ]
                        )

                        // Layer 3 - Contemporary
                        SourceSection(
                            icon: "globe",
                            title: "Contemporary",
                            iconColor: .green,
                            sources: [
                                SourceItem(title: "Fi Zilal al-Quran", subtitle: "Sayyid Qutb"),
                                SourceItem(title: "Al-Tafsir al-Munir", subtitle: "Wahbah al-Zuhayli"),
                                SourceItem(title: "Ibn Uthaymeen", subtitle: "Contemporary Sunni scholar"),
                                SourceItem(title: "Muhammad al-Sha'rawi", subtitle: "Contemporary Sunni scholar")
                            ]
                        )

                        // Layer 4 - Comparative
                        SourceSection(
                            icon: "scale.3d",
                            title: "Comparative",
                            iconColor: .indigo,
                            sources: [
                                SourceItem(title: "Sunni Position", subtitle: "Drawn from the Layer 2 and Layer 3 sources above"),
                                SourceItem(title: "Al-Mizan fi Tafsir al-Quran", subtitle: "Allama Muhammad Husayn al-Tabatabai (Shia perspective)"),
                                SourceItem(title: "Majma al-Bayan", subtitle: "Al-Tabrisi (Shia perspective)"),
                                SourceItem(title: "Editorial framing", subtitle: "Sunni position presented first; Shia perspective surfaced for comparison only")
                            ]
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
            .toolbarBackground(themeManager.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(themeManager.isSapphire ? "" : "Tafsir Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if themeManager.isSapphire {
                    ToolbarItem(placement: .principal) {
                        Text("TAFSIR SOURCES")
                            .font(SapphireFont.eyebrow)
                            .tracking(2.5)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : .blue)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SourceItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct SourceSection: View {
    let icon: String
    let title: String
    let iconColor: Color
    let sources: [SourceItem]

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                if themeManager.isSapphire {
                    // Sapphire: gold chip fill with accent icon and stroke border
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(themeManager.goldChipFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(themeManager.strokeColor, lineWidth: 1)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                }

                if themeManager.isSapphire {
                    // Sapphire: uppercase eyebrow with accent color and tracking
                    Text(title.uppercased())
                        .font(SapphireFont.eyebrow)
                        .tracking(2.5)
                        .foregroundColor(themeManager.accentColor)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                }
            }
            .padding(.horizontal, 20)

            // Sources List
            VStack(spacing: 0) {
                ForEach(sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.title)
                            .font(themeManager.isSapphire ? SapphireFont.serif(19) : .system(size: 15, weight: .semibold))
                            .foregroundColor(themeManager.primaryText)

                        Text(source.subtitle)
                            .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 13, weight: .regular))
                            .foregroundColor(themeManager.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)

                    if source.id != sources.last?.id {
                        Divider()
                            .background(themeManager.strokeColor)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    TafsirSourcesView()
}
