//
//  DeepDiveShims.swift
//  AlBayan
//
//  Thin compatibility layer so the ported DeepDiveView renderer (from the
//  surah-journey handoff) compiles verbatim against AlBayan's design system.
//  The renderer itself is theme-independent (always-dark navy+gold via
//  DeepDivePalette); these shims bridge its font ramp, press style, chrome
//  strings, and the two audio affordances to AlBayan's own primitives.
//

import SwiftUI

// MARK: - EmType (font ramp -> SapphireFont / EB Garamond + Amiri)

/// Weight vocabulary the renderer uses. EB Garamond ships Medium (500) and
/// SemiBold (600); `.medium` is the default body/display weight.
enum EmWeight { case medium, semiBold }

/// The renderer's serif/Arabic font ramp, mapped onto `SapphireFont`.
enum EmType {
    /// Serif display/body (EB Garamond). `.semiBold` bumps 500 -> 600.
    static func serif(_ size: CGFloat, _ weight: EmWeight = .medium) -> Font {
        SapphireFont.serif(size, semibold: weight == .semiBold)
    }
    /// Serif italic (EB Garamond italic) - reflections, subtitles.
    static func serifItalic(_ size: CGFloat) -> Font {
        SapphireFont.serif(size, semibold: false, italic: true)
    }
    /// Qur'anic Arabic (Amiri).
    static func arabic(_ size: CGFloat, bold: Bool = false) -> Font {
        SapphireFont.arabic(size, bold: bold)
    }
}

// MARK: - EmPressStyle (subtle press feedback)

/// Scale + opacity press feedback, matching the app's `SpPressStyle`.
struct EmPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - JourneyStrings (dive chrome, English-first)

/// English-first UI strings for the immersive dive chrome. `ur`/`ar` come in a
/// later localization pass (the argument is kept so call sites stay unchanged).
enum JourneyStrings {
    static func done(_ l: CommentaryLanguage) -> String { "Done" }
    static func premium(_ l: CommentaryLanguage) -> String { "Premium" }
    static func readTheFullSurah(_ l: CommentaryLanguage) -> String { "Read the full surah" }
    static func veilEyebrow(_ l: CommentaryLanguage) -> String { "The descent continues" }
    static func veilNote(_ l: CommentaryLanguage) -> String { "the rest of this journey lies beneath" }
    static func veilCta(_ l: CommentaryLanguage) -> String { "Unlock the full journey" }
}

// MARK: - VerseRecitationButton (Hear it recited)

/// "Hear it recited" affordance under a `.verse` beat. Plays the verse through
/// the app's shared AudioManager; the global mini-player surfaces automatically.
struct VerseRecitationButton: View {
    let surahNumber: Int
    let verseNumber: Int

    var body: some View {
        Button(action: play) {
            HStack(spacing: 7) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Hear it recited")
                    .font(EmType.serif(14))
                    .tracking(0.3)
            }
            .foregroundColor(DeepDivePalette.gold)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .overlay(Capsule().stroke(DeepDivePalette.gold.opacity(0.32), lineWidth: 1))
        }
        .buttonStyle(EmPressStyle())
    }

    private func play() {
        guard let verse = DataManager.shared.getVerse(surah: surahNumber, verse: verseNumber),
              let surah = DataManager.shared.getSurah(number: surahNumber) else { return }
        Task { await AudioManager.shared.playVerse(verse, in: surah.surah) }
    }
}

// MARK: - DuaListenButton (placeholder)

/// Listen affordance for a *taught du'a / refrain* Arabic phrase (not a Qur'an
/// verse, so it has no surah:ayah to play through AudioManager). AlBayan has no
/// du'a-audio pipeline yet, and no shipped dive uses it (only `.refrain` / `.dua`
/// beats do - al-Rahman etc.). Rendered as nothing for now; wire it to a du'a
/// audio / TTS source when the first refrain surah lands.
struct DuaListenButton: View {
    let arabic: String
    var body: some View { EmptyView() }
}
