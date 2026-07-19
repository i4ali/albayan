//
//  DeepDive.swift
//  AlBayan
//
//  Data for one immersive "Inside the Surah" descent, rendered by DeepDiveView.
//  Pure data - adding a surah is a content-only addition (a new Surah<Name>Dive.swift
//  returning a `static let`). Ported from the surah-journey handoff; the model is
//  sect-agnostic (no content lives here).
//
//  Prose is localized (EN / UR / AR) via `LocalizedText` (defined once in
//  DailyChallengeModels.swift). Qur'an Arabic, references, and surah/ayah numbers
//  stay single-string (identical across languages).
//

import SwiftUI

// `LocalizedText` (en + optional ur/ar, resolved via `.text(for:)`) is defined in
// DailyChallengeModels.swift and reused here - no duplicate type. These additive
// conveniences let the deep-dive content read ergonomically:
extension LocalizedText {
    /// Resolve like a function: `field(lang)` == `field.text(for: lang)`.
    func callAsFunction(_ l: CommentaryLanguage) -> String { text(for: l) }
    /// Text identical in every language (proper nouns, transliterations, symbols).
    init(_ shared: String) { self.init(en: shared, ur: shared, ar: shared) }
    /// English + Urdu only; Arabic falls back to English.
    init(en: String, ur: String) { self.init(en: en, ur: ur, ar: nil) }
}

extension LocalizedText: ExpressibleByStringLiteral {
    /// A plain string literal is treated as English-only (ur/ar fall back to en). Keeps
    /// not-yet-localized dive content compiling - `subtitle: "…"` works alongside
    /// `LocalizedText(en:ur:ar:)`.
    public init(stringLiteral value: String) { self.init(en: value, ur: nil, ar: nil) }
}

/// The movement metadata (e.g. The Praise / The Turn / The Path for al-Fatiha).
struct ActInfo: Identifiable {
    let number: Int
    let ar: String
    let tr: String
    let name: LocalizedText
    var id: Int { number }
}

/// One row in the "depths" interactive map (optional, narrative surahs only).
struct Depth: Identifiable {
    let ar: String
    let tr: String
    let label: LocalizedText
    let desc: LocalizedText
    let reference: String?
    let embodies: LocalizedText
    var id: String { tr }
}

/// A short bridge verse carried by an `act` (movement) section.
struct BridgeVerse {
    let surah: Int
    let ayah: Int
    let arabic: String
    let translation: LocalizedText
    let reference: String
}

/// One full-screen beat in the descent.
enum DeepDiveSection {
    case open(kicker: LocalizedText, titleAr: String, titleEn: String, subtitle: LocalizedText, line: LocalizedText)
    /// A guiding "how this works + the promise" beat, shown right after the open.
    case orientation(eyebrow: LocalizedText, promise: LocalizedText, leaveWith: LocalizedText)
    case verse(act: Int, tag: LocalizedText, surah: Int, ayah: Int, arabic: String, translation: LocalizedText, reference: String, reflection: LocalizedText)
    case depths(act: Int, tag: LocalizedText, reference: String, items: [Depth])
    /// A movement divider. `connector` names the thread back to the prior movement.
    case act(act: Int, connector: LocalizedText?, line: LocalizedText, bridge: BridgeVerse?)
    case narration(act: Int, tag: LocalizedText, source: LocalizedText, body: LocalizedText, reflection: LocalizedText)
    /// A "He answers" reply beat: after a verse the servant has recited, God's answer
    /// (the division of the prayer, Sahih Muslim). Renders as call-and-response, not a
    /// story block. `replyingTo` names the line He answers; `arabic` anchors His words.
    case response(act: Int, replyingTo: LocalizedText, arabic: String, words: LocalizedText, source: LocalizedText, reflection: LocalizedText)
    case climax(act: Int, tag: LocalizedText, source: LocalizedText, arabic: String, translation: LocalizedText, body: LocalizedText, reflection: LocalizedText)
    /// A recurring-question refrain (e.g. al-Rahman): the verse glows and the reader
    /// answers it. `teachSource` is non-nil on the first occurrence only; `replyArabic`
    /// is a taught devotional phrase, not Qur'an (no byte-check).
    case refrain(act: Int, tag: LocalizedText, surah: Int, ayah: Int, arabic: String, translation: LocalizedText, reference: String, intro: LocalizedText, teachSource: LocalizedText?, replyArabic: String, replyTransliteration: String, replyTranslation: LocalizedText, reflection: LocalizedText)
    case reflectionPrompt(tag: LocalizedText, prompt: LocalizedText, placeholder: LocalizedText, subline: LocalizedText, nextLabel: LocalizedText)
    /// Interactive entrustment close (Tawakkul): the reader names, grips, then releases.
    case release(tag: LocalizedText, prompt: LocalizedText, subline: LocalizedText, arabic: String, translation: LocalizedText, reference: String, note: LocalizedText, nextLabel: LocalizedText)
    /// Interactive gratitude close (Shukr): the reader taps to count blessings.
    case count(tag: LocalizedText, prompt: LocalizedText, subline: LocalizedText, arabic: String, translation: LocalizedText, reference: String, note: LocalizedText, nextLabel: LocalizedText)
    /// A devotional du'a close.
    case dua(tag: LocalizedText, intro: LocalizedText, arabic: String, translation: LocalizedText, source: LocalizedText, note: LocalizedText, close: LocalizedText)
    /// The final beat of a surah experience: restates the essence and hands off to
    /// reading the full surah. Replaces `dua` for surah dives.
    case closing(tag: LocalizedText, titleAr: String, essence: LocalizedText, line: LocalizedText)

    /// Act number for the persistent depth stepper (0 = opening, 4 = reflection/close).
    var act: Int {
        switch self {
        case .open, .orientation:                          return 0
        case .verse(let a, _, _, _, _, _, _, _):           return a
        case .depths(let a, _, _, _):                      return a
        case .act(let a, _, _, _):                         return a
        case .narration(let a, _, _, _, _):                return a
        case .response(let a, _, _, _, _, _):              return a
        case .climax(let a, _, _, _, _, _, _):             return a
        case .refrain(let a, _, _, _, _, _, _, _, _, _, _, _, _): return a
        case .reflectionPrompt, .release, .count, .dua, .closing:  return 4
        }
    }
}

/// One immersive deep dive. Data-driven so new dives are pure content additions
/// rendered by the same `DeepDiveView`.
struct DeepDive: Identifiable {
    let id: String
    let titleEn: String
    let titleAr: String
    let subtitle: LocalizedText
    let sfSymbol: String
    let estMinutes: Int
    /// Noun in the movement-card chrome ("… · MOVEMENT 1 OF 3") - each dive's spine
    /// vocabulary. Defaults to "Movement".
    var stageNoun: String = "Movement"
    let acts: [ActInfo]
    let sections: [DeepDiveSection]

    func actInfo(_ n: Int) -> ActInfo? { acts.first { $0.number == n } }

    /// First section index of each act - drives the persistent depth stepper.
    func firstIndex(ofAct n: Int) -> Int? { sections.firstIndex { $0.act == n } }
}
