//
//  AhlulbaytQuranView.swift
//  AlBayan
//
//  Ahl al-Bayt in the Quran - Verses honoring the Prophet's purified family
//

import SwiftUI

struct AhlulbaytQuranView: View {
    @StateObject private var ahlulbaytManager = AhlulbaytQuranManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: AhlulbaytCategory? = nil
    @State private var selectedEntry: AhlulbaytEntry?
    @State private var navigateToDetail = false

    var filteredEntries: [AhlulbaytEntry] {
        let searchFiltered = searchText.isEmpty ? ahlulbaytManager.entries : ahlulbaytManager.search(query: searchText)

        if let category = selectedCategory {
            return searchFiltered.filter { $0.category == category }
        }
        return searchFiltered
    }

    // Group entries by category
    var groupedEntries: [(AhlulbaytCategory, [AhlulbaytEntry])] {
        var grouped: [AhlulbaytCategory: [AhlulbaytEntry]] = [:]
        for entry in filteredEntries {
            grouped[entry.category, default: []].append(entry)
        }
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background with floating elements
                AdaptiveModernBackground()

                VStack(spacing: 0) {
                    // Modern header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if themeManager.isSapphire {
                                    Text("AHL AL-BAYT IN THE QURAN")
                                        .font(SapphireFont.eyebrow)
                                        .tracking(2.5)
                                        .foregroundColor(themeManager.accentColor)
                                    Text("The Purified Family")
                                        .font(SapphireFont.screenTitle)
                                        .tracking(0.2)
                                        .foregroundColor(themeManager.primaryText)
                                    Text("Verses honoring the Prophet's family")
                                        .font(.system(size: 13.5))
                                        .foregroundColor(themeManager.secondaryText)
                                } else {
                                    Text("Ahl al-Bayt in the Quran")
                                        .font(.system(size: themeManager.useWarmLayout ? 34 : 32, weight: .bold, design: themeManager.useWarmLayout ? .rounded : .default))
                                        .foregroundColor(themeManager.primaryText)

                                    Text("Verses honoring the Prophet's family")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeManager.secondaryText)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .background {
                        if !themeManager.useWarmLayout {
                            Rectangle()
                                .fill(themeManager.glassEffect)
                                .overlay(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.clear,
                                                    themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                )
                        }
                    }

                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.secondaryText)
                            .font(.system(size: 16, weight: .medium))

                        TextField("Search verses or members...", text: $searchText)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.primaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        if themeManager.useWarmLayout {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.glassEffect)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            AhlulbaytCategoryChip(
                                title: "All",
                                icon: "square.grid.2x2.fill",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(AhlulbaytCategory.allCases, id: \.self) { category in
                                AhlulbaytCategoryChip(
                                    title: category.displayName,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // Entries list
                    if ahlulbaytManager.isLoading {
                        AhlulbaytLoadingSection(message: "Loading entries...")
                    } else if let error = ahlulbaytManager.errorMessage {
                        AhlulbaytErrorSection(message: error)
                    } else if filteredEntries.isEmpty {
                        AhlulbaytEmptyStateSection()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedEntries, id: \.0) { category, entries in
                                    Section {
                                        ForEach(entries) { entry in
                                            AhlulbaytEntryCardView(entry: entry)
                                                .onTapGesture {
                                                    selectedEntry = entry
                                                    navigateToDetail = true
                                                }
                                        }
                                    } header: {
                                        HStack {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 16, weight: themeManager.isSapphire ? .regular : .semibold))
                                                .foregroundColor(themeManager.accentColor)

                                            Text(themeManager.isSapphire ? category.displayName.uppercased() : category.displayName)
                                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 18, weight: .bold))
                                                .tracking(themeManager.isSapphire ? 2.0 : 0)
                                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.primaryText)
                                                .textCase(nil)

                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(themeManager.primaryBackground)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }

                // Hidden NavigationLink for entry detail navigation
                if let entry = selectedEntry {
                    NavigationLink(
                        destination: AhlulbaytEntryDetailView(entry: entry),
                        isActive: $navigateToDetail
                    ) {
                        EmptyView()
                    }
                    .frame(width: 0, height: 0)
                    .hidden()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(themeManager.accentColor)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(themeManager.colorScheme)
    }
}

struct AhlulbaytEntryCardView: View {
    let entry: AhlulbaytEntry
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Category icon
            if themeManager.isSapphire {
                Image(systemName: entry.categoryIcon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(themeManager.goldChipFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(themeManager.accentGradient)
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: themeManager.accentColor.opacity(0.3),
                            radius: 8
                        )

                    Image(systemName: entry.categoryIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Entry content
            VStack(alignment: .leading, spacing: 6) {
                // Members involved badge (Sapphire: eyebrow style)
                if !entry.ahlulbaytMembers.isEmpty {
                    if themeManager.isSapphire {
                        Text(entry.ahlulbaytMembers.prefix(2).joined(separator: ", ").uppercased())
                            .font(SapphireFont.eyebrow)
                            .tracking(2.0)
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(themeManager.goldChipFill)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                    } else {
                        Text(entry.ahlulbaytMembers.prefix(2).joined(separator: ", "))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                            .lineLimit(1)
                    }
                }

                Text(entry.title)
                    .font(themeManager.isSapphire ? SapphireFont.serif(20) : .system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Verse count
                Text("\(entry.verseCount) verse\(entry.verseCount == 1 ? "" : "s") • \(entry.category.displayName)")
                    .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)

                // Verse references
                let verseRefs = entry.verses.prefix(2).map { $0.verseReference }.joined(separator: " • ")
                Text(verseRefs)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.tertiaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.tertiaryText)
        }
        .padding(20)
        .background {
            if themeManager.isSapphire {
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            } else if themeManager.useWarmLayout {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 1.0, green: 1.0, blue: 1.0).opacity(1.0))
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.glassEffect)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.floatingOrbColors[0].opacity(0.5),
                                        themeManager.floatingOrbColors[1].opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 20)
    }
}

struct AhlulbaytCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: themeManager.isSapphire ? .regular : .semibold))

                Text(themeManager.isSapphire ? title.uppercased() : title)
                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                    .tracking(themeManager.isSapphire ? 1.5 : 0)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? (themeManager.isSapphire ? themeManager.onAccentText : .white) : (themeManager.isSapphire ? themeManager.accentColor : themeManager.primaryText))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    if themeManager.isSapphire {
                        Capsule()
                            .fill(AnyShapeStyle(themeManager.goldGradient))
                    } else {
                        Capsule()
                            .fill(AnyShapeStyle(themeManager.accentGradient))
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 8)
                    }
                } else {
                    if themeManager.isSapphire {
                        Capsule()
                            .fill(themeManager.goldChipFill)
                            .overlay(
                                Capsule()
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                    } else if themeManager.useWarmLayout {
                        Capsule()
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                    } else {
                        Capsule()
                            .fill(themeManager.glassEffect)
                            .overlay(
                                Capsule()
                                    .stroke(themeManager.strokeColor, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

struct AhlulbaytEmptyStateSection: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)

            Text("No entries found")
                .font(themeManager.isSapphire ? SapphireFont.headline(22) : .system(size: 20, weight: .bold))
                .foregroundColor(themeManager.primaryText)

            Text("Try adjusting your search or category filter")
                .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct AhlulbaytLoadingSection: View {
    let message: String
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.accentColor)

            Text(message)
                .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 16, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

private struct AhlulbaytErrorSection: View {
    let message: String
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error Loading Entries")
                .font(themeManager.isSapphire ? SapphireFont.headline(22) : .system(size: 20, weight: .bold))
                .foregroundColor(themeManager.primaryText)

            Text(message)
                .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    AhlulbaytQuranView()
}
