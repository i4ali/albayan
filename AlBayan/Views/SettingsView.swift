//
//  SettingsView.swift
//  AlBayan
//
//  Centralized settings hub for the app
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var progressManager = ProgressManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var voiceManager = TTSVoiceManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearDataAlert = false
    @State private var clearDataMessage = ""
    @State private var showingTimePickerSheet = false
    @State private var showingResetProgressAlert = false
    @State private var showingReciterSelection = false
    @State private var showingTTSVoiceSelection = false
    @State private var selectedTTSLanguage: CommentaryLanguage = .english
    @State private var showingTafsirSources = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                themeManager.primaryBackground
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.primaryText)
                                .frame(width: 40, height: 40)
                        }
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.primaryText)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the close button
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // Settings content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Theme Section
                            SettingsSection(title: "Theme") {
                                VStack(spacing: 12) {
                                    ForEach(ThemeVariant.allCases) { variant in
                                        ThemePickerTile(
                                            variant: variant,
                                            isSelected: themeManager.selectedTheme == variant
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                themeManager.setTheme(variant)
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                            }

                            // Reading Text Size Section
                            SettingsSection(title: "Reading") {
                                ReadingSizeSettingRow()
                            }

                            // Daily Verse Notifications Section
                            SettingsSection(title: "Daily Verse") {
                                VStack(spacing: 12) {
                                    // Enable/Disable toggle
                                    SettingsToggleRow(
                                        icon: "bell.fill",
                                        title: "Daily Notifications",
                                        subtitle: notificationManager.preferences.enabled ? "Enabled" : "Tap to enable",
                                        iconColor: .blue,
                                        isOn: Binding(
                                            get: { notificationManager.preferences.enabled },
                                            set: { newValue in
                                                if newValue && notificationManager.permissionStatus != .authorized {
                                                    Task {
                                                        let granted = await notificationManager.requestPermission()
                                                        if granted {
                                                            notificationManager.preferences.enabled = true
                                                        }
                                                    }
                                                } else {
                                                    notificationManager.preferences.enabled = newValue
                                                }
                                            }
                                        )
                                    )

                                    // Show additional settings only if enabled
                                    if notificationManager.preferences.enabled {
                                        // Time picker
                                        SettingsRow(
                                            icon: "clock.fill",
                                            title: "Notification Time",
                                            subtitle: formatTime(notificationManager.preferences.time),
                                            iconColor: .orange
                                        ) {
                                            showingTimePickerSheet = true
                                        }

                                        // Language preference
                                        SettingsRow(
                                            icon: "globe",
                                            title: "Language",
                                            subtitle: notificationManager.preferences.language.displayName,
                                            iconColor: .green
                                        ) {
                                            toggleNotificationLanguage()
                                        }

                                        // Include tafsir toggle
                                        SettingsToggleRow(
                                            icon: "book.fill",
                                            title: "Include Commentary",
                                            subtitle: notificationManager.preferences.includeTafsir ? "Brief tafsir shown" : "Verse only",
                                            iconColor: .purple,
                                            isOn: Binding(
                                                get: { notificationManager.preferences.includeTafsir },
                                                set: { notificationManager.preferences.includeTafsir = $0 }
                                            )
                                        )

                                        // Today's verse preview
                                        if let verse = notificationManager.selectTodayVerse(),
                                           let monthData = notificationManager.currentMonthData() {
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.yellow)
                                                    Text("Today's Verse (\(monthData.name))")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(themeManager.primaryText)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.top, 12)

                                                Text("Surah \(verse.surah), Verse \(verse.verse)")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(themeManager.secondaryText)
                                                    .padding(.horizontal, 16)

                                                Text(verse.theme)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(themeManager.tertiaryText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.bottom, 12)
                                            }
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(themeManager.primaryBackground.opacity(0.5))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.strokeColor.opacity(0.5), lineWidth: 1)
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }

                            // Reading Progress Section
                            SettingsSection(title: "Reading Progress") {
                                VStack(spacing: 12) {
                                    // Current Streak
                                    SettingsRow(
                                        icon: "flame.fill",
                                        title: "Current Streak",
                                        subtitle: "\(progressManager.streak.currentStreak) days",
                                        iconColor: .orange
                                    ) {
                                        // Just displays info, no action
                                    }

                                    // Progress Notifications Toggle
                                    SettingsToggleRow(
                                        icon: "bell.badge.fill",
                                        title: "Progress Notifications",
                                        subtitle: progressManager.preferences.notificationsEnabled ? "Motivational reminders" : "Tap to enable",
                                        iconColor: .purple,
                                        isOn: Binding(
                                            get: { progressManager.preferences.notificationsEnabled },
                                            set: { newValue in
                                                var newPrefs = progressManager.preferences
                                                newPrefs.notificationsEnabled = newValue
                                                progressManager.updatePreferences(newPrefs)
                                            }
                                        )
                                    )

                                    // Badge Celebrations Toggle
                                    SettingsToggleRow(
                                        icon: "star.fill",
                                        title: "Badge Celebrations",
                                        subtitle: progressManager.preferences.celebrationsEnabled ? "Show celebrations" : "Quiet mode",
                                        iconColor: .yellow,
                                        isOn: Binding(
                                            get: { progressManager.preferences.celebrationsEnabled },
                                            set: { newValue in
                                                var newPrefs = progressManager.preferences
                                                newPrefs.celebrationsEnabled = newValue
                                                progressManager.updatePreferences(newPrefs)
                                            }
                                        )
                                    )

                                    // Reset Progress
                                    SettingsRow(
                                        icon: "arrow.counterclockwise",
                                        title: "Reset Progress",
                                        subtitle: "Clear all reading progress",
                                        iconColor: .red
                                    ) {
                                        showingResetProgressAlert = true
                                    }
                                }
                            }

                            // Audio Section
                            SettingsSection(title: "Audio") {
                                VStack(spacing: 12) {
                                    // Reciter selection
                                    SettingsRow(
                                        icon: "person.wave.2.fill",
                                        title: "Reciter",
                                        subtitle: audioManager.configuration.selectedReciter.nameEnglish,
                                        iconColor: .purple
                                    ) {
                                        showingReciterSelection = true
                                    }

                                    // Repeat mode
                                    SettingsRow(
                                        icon: audioManager.configuration.repeatMode.icon,
                                        title: "Repeat Mode",
                                        subtitle: audioManager.configuration.repeatMode.title,
                                        iconColor: .green
                                    ) {
                                        cycleRepeatMode()
                                    }
                                }
                            }

                            // Text-to-Speech Section
                            SettingsSection(title: "Text-to-Speech") {
                                VStack(spacing: 12) {
                                    ForEach(TTSVoiceManager.supportedTTSLanguages, id: \.self) { language in
                                        SettingsRow(
                                            icon: "speaker.wave.2.fill",
                                            title: "\(language.displayName) Voice",
                                            subtitle: voiceManager.selectedVoice(for: language)?.name ?? "No voices",
                                            iconColor: .teal
                                        ) {
                                            selectedTTSLanguage = language
                                            showingTTSVoiceSelection = true
                                        }
                                    }
                                }
                            }
                            
                            // App Info Section
                            SettingsSection(title: "About") {
                                VStack(spacing: 12) {
                                    SettingsRow(
                                        icon: "books.vertical.fill",
                                        title: "Tafsir Sources",
                                        subtitle: "Books and scholars referenced",
                                        iconColor: .indigo
                                    ) {
                                        showingTafsirSources = true
                                    }

                                    SettingsRow(
                                        icon: "info.circle.fill",
                                        title: "Version",
                                        subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                                        iconColor: .gray
                                    ) {
                                        // Could show app info
                                    }

                                    SettingsRow(
                                        icon: "heart.fill",
                                        title: "Support",
                                        subtitle: "Rate or review the app",
                                        iconColor: .red
                                    ) {
                                        // Could open App Store review
                                    }

                                    SettingsRow(
                                        icon: "trash.fill",
                                        title: "Clear All Local Data",
                                        subtitle: "Remove bookmarks, preferences, cache",
                                        iconColor: .red
                                    ) {
                                        performClearAllLocalData()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTimePickerSheet) {
            TimePickerSheet(
                selectedTime: Binding(
                    get: { notificationManager.preferences.time },
                    set: { notificationManager.preferences.time = $0 }
                ),
                isPresented: $showingTimePickerSheet
            )
        }
        .sheet(isPresented: $showingReciterSelection) {
            ReciterSelectionView()
        }
        .sheet(isPresented: $showingTTSVoiceSelection) {
            TTSVoicePickerView(language: selectedTTSLanguage)
        }
        .fullScreenCover(isPresented: $showingTafsirSources) {
            TafsirSourcesView()
        }
        .alert("Local Data Cleared", isPresented: $showingClearDataAlert) {
            Button("OK") {
                // Force UI refresh
                DispatchQueue.main.async {
                    bookmarkManager.objectWillChange.send()
                }
            }
        } message: {
            Text(clearDataMessage)
        }
        .alert("Reset Progress?", isPresented: $showingResetProgressAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await progressManager.resetProgress()
                }
            }
        } message: {
            Text("This will clear all your reading progress, streaks, and badges. This action cannot be undone.")
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func toggleNotificationLanguage() {
        notificationManager.preferences.language = notificationManager.preferences.language == .english ? .urdu : .english
    }

    private func cycleRepeatMode() {
        let modes: [RepeatMode] = [.off, .verse, .surah, .continuous]
        if let currentIndex = modes.firstIndex(of: audioManager.configuration.repeatMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            audioManager.updateRepeatMode(modes[nextIndex])
        }
    }

    private func performClearAllLocalData() {
        print("🧹 SettingsView: Starting clear all local data")
        
        // Clear BookmarkManager data
        #if DEBUG
        BookmarkManager.shared.clearAllLocalData()
        #endif
        
        // Clear other UserDefaults that might exist
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        clearDataMessage = "All local data cleared successfully!\n\nBookmarks: 0\nPreferences: Reset\nCache: Cleared"
        showingClearDataAlert = true
        
        print("🧹 SettingsView: Completed clearing all local data")
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.primaryText)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.strokeColor, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Reading text-size setting (Settings screen)

/// Label + A−/dots/A+ stepper + a live preview line that resizes with the global scale.
/// Self-contained: observes both singletons; the host just calls `ReadingSizeSettingRow()`.
/// No own card — it sits inside `SettingsSection`, which provides the card.
struct ReadingSizeSettingRow: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settings = ReadingSettingsManager.shared

    private func stepButton(_ label: String, size: CGFloat, enabled: Bool,
                            a11y: String, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.18)) { action() } }) {
            Text(label)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(enabled ? themeManager.accentColor : themeManager.tertiaryText)
                .frame(width: 34, height: 34)
                .background(Circle().fill(themeManager.accentColor.opacity(0.15)))
                .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .disabled(!enabled)
        .accessibilityLabel(a11y)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title row
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.accentColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "textformat.size")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Text Size")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                    Text("Verses, translation & commentary")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                }
                Spacer(minLength: 8)
            }

            // Stepper: A−   ● ● ● ○ ○   A+
            HStack(spacing: 18) {
                stepButton("A", size: 15, enabled: settings.canDecrease, a11y: "Decrease text size") { settings.decrease() }
                HStack(spacing: 8) {
                    ForEach(0..<settings.stepCount, id: \.self) { i in
                        Circle()
                            .fill(i <= settings.stepIndex ? themeManager.accentColor : themeManager.tertiaryText.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
                stepButton("A", size: 23, enabled: settings.canIncrease, a11y: "Increase text size") { settings.increase() }
            }

            // Live preview — resizes on tap. (Basmala translation; universal — keep.)
            Text("In the name of Allah, the Most Gracious, the Most Merciful.")
                .font(.system(size: 17 * settings.scale, weight: .medium, design: .serif))
                .foregroundColor(themeManager.secondaryText)
                .lineSpacing(4 * settings.scale)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: settings.stepIndex)
        }
        .padding(16)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                icon: icon,
                title: title,
                subtitle: subtitle,
                iconColor: iconColor
            )
        }
    }
}

// MARK: - Settings Row Content (for use with NavigationLink)

struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.secondaryText)
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.tertiaryText)
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var isOn: Bool
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(themeManager.secondaryText)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.primaryBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Choose your preferred notification time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)

                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .toolbarBackground(themeManager.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Notification Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

// MARK: - Theme Picker Tile

struct ThemePickerTile: View {
    let variant: ThemeVariant
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Preview swatch: bg + two accent dots
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(previewBackground)
                        .frame(width: 56, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(themeManager.strokeColor.opacity(0.6), lineWidth: 1)
                        )

                    HStack(spacing: 6) {
                        Circle().fill(previewPurpleGradient).frame(width: 14, height: 14)
                        Circle().fill(previewAccentGradient).frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                    Text(variant.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(themeManager.secondaryText)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.tertiaryText)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Previews resolve to the *variant's* own palette, regardless of which theme is active,
    // so the user sees what each theme looks like.

    private var previewBackground: Color {
        switch variant {
        case .warmInviting:  return Color(red: 0.973, green: 0.961, blue: 1.0)
        case .rosewater:     return Color(red: 0.992, green: 0.953, blue: 0.949)
        case .royalSapphire: return Color(hex: "#0A1124")
        }
    }

    private var previewPurpleGradient: LinearGradient {
        switch variant {
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.608, green: 0.561, blue: 0.749),
                    Color(red: 0.545, green: 0.498, blue: 0.659)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.663, green: 0.549, blue: 0.710),
                    Color(red: 0.576, green: 0.471, blue: 0.631)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .royalSapphire:
            return LinearGradient(
                colors: [Color(hex: "#F2E2A8"), Color(hex: "#B5963F")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var previewAccentGradient: LinearGradient {
        switch variant {
        case .warmInviting:
            return LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.604, blue: 0.435),
                    Color(red: 0.847, green: 0.541, blue: 0.373)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rosewater:
            return LinearGradient(
                colors: [
                    Color(red: 0.847, green: 0.514, blue: 0.502),
                    Color(red: 0.749, green: 0.420, blue: 0.408)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .royalSapphire:
            return LinearGradient(
                colors: [Color(hex: "#5B9BE0"), Color(hex: "#3F7BC0")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}