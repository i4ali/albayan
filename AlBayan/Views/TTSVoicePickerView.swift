//
//  TTSVoicePickerView.swift
//  AlBayan
//
//  Voice selection UI for text-to-speech per language
//

import SwiftUI
import AVFoundation

struct TTSVoicePickerView: View {
    let language: CommentaryLanguage
    @StateObject private var voiceManager = TTSVoiceManager.shared
    @StateObject private var tafsirReader = TafsirReader.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.primaryBackground
                .ignoresSafeArea()

                if voiceManager.voicesForLanguage(language).isEmpty {
                    // No voices available
                    VStack(spacing: 16) {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(themeManager.tertiaryText)

                        Text("No voices available")
                            .font(themeManager.isSapphire ? SapphireFont.headline(22) : .system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.secondaryText)

                        Text("Your device does not have any \(language.displayName) voices installed.")
                            .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 14))
                            .foregroundColor(themeManager.tertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(voiceManager.voicesForLanguage(language), id: \.identifier) { voice in
                                VoiceRow(
                                    voice: voice,
                                    isSelected: voiceManager.selectedVoice(for: language)?.identifier == voice.identifier,
                                    onSelect: {
                                        voiceManager.setSelectedVoice(voice, for: language)
                                        playSample(for: language)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbarBackground(themeManager.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("\(language.displayName) Voices")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        tafsirReader.stop()
                        dismiss()
                    }
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : Color(red: 0.39, green: 0.4, blue: 0.95))
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onDisappear {
            tafsirReader.stop()
        }
    }

    private func playSample(for language: CommentaryLanguage) {
        let sampleText: String
        switch language {
        case .english:
            sampleText = "This is a sample of the selected voice for reading tafsir commentary."
        case .arabic:
            sampleText = "هذا نموذج للصوت المحدد لقراءة تفسير القرآن الكريم."
        case .urdu:
            sampleText = "یہ منتخب آواز کا نمونہ ہے تفسیر پڑھنے کے لیے۔"
        case .french:
            sampleText = "" // French TTS not supported
        }
        tafsirReader.speak(text: sampleText, language: language)
    }
}

struct VoiceRow: View {
    let voice: AVSpeechSynthesisVoice
    let isSelected: Bool
    let onSelect: () -> Void
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Voice icon
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentGradient : LinearGradient(colors: [themeManager.tertiaryBackground, themeManager.tertiaryBackground], startPoint: .top, endPoint: .bottom))
                        .frame(width: 50, height: 50)

                    Image(systemName: voice.gender == .male ? "person.fill" : voice.gender == .female ? "person.fill" : "waveform")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : themeManager.secondaryText)
                }

                // Voice info
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(themeManager.isSapphire ? SapphireFont.serif(18) : .system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)

                    HStack(spacing: 8) {
                        // Language code
                        Text(voice.language)
                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
                            .tracking(themeManager.isSapphire ? 2 : 0)
                            .textCase(themeManager.isSapphire ? .uppercase : .none)

                        // Quality badge
                        if voice.quality == .enhanced {
                            Text("Enhanced")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10, weight: .semibold))
                                .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldChipFill) : AnyShapeStyle(Color.green))
                                        .overlay(
                                            themeManager.isSapphire
                                                ? AnyView(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
                                                : AnyView(EmptyView())
                                        )
                                )
                        }

                        // Gender indicator
                        if voice.gender == .male {
                            Text("Male")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                        } else if voice.gender == .female {
                            Text("Female")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.tertiaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                        }
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : Color(red: 0.39, green: 0.4, blue: 0.95))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.cardBackground) : AnyShapeStyle(themeManager.secondaryBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? (themeManager.isSapphire ? themeManager.accentColor : Color(red: 0.39, green: 0.4, blue: 0.95).opacity(0.5))
                                    : (themeManager.isSapphire ? themeManager.strokeColor : Color.clear),
                                lineWidth: themeManager.isSapphire ? 1 : 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TTSVoicePickerView(language: .english)
}
