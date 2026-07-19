//
//  SapphireFont.swift
//  AlBayan
//
//  Royal Sapphire type scale. Serif display = EB Garamond, Arabic = Amiri,
//  sans (UI) role = system. PostScript names below were extracted directly from the
//  bundled .ttf files (AlBayan/Resources/Fonts) — do not "tidy" them; SwiftUI's
//  `.custom` silently falls back to the system font if a name is wrong.
//
//    EBGaramond-Medium.ttf          -> "EBGaramond-Medium"
//    EBGaramond-SemiBold.ttf        -> "EBGaramond-SemiBold"
//    EBGaramond-MediumItalic.ttf    -> "EBGaramondItalic-MediumItalic"
//    EBGaramond-SemiBoldItalic.ttf  -> "EBGaramondItalic-SemiBoldItalic"
//    Amiri-Regular.ttf                     -> "Amiri-Regular"
//    Amiri-Bold.ttf                        -> "Amiri-Bold"
//

import SwiftUI

enum SapphireFont {

    // MARK: - Global size adjustment

    /// App-wide additive bump applied to every Sapphire size (serif, Arabic, eyebrow).
    /// Callers still pass the design-handoff sizes (e.g. `serif(20)`); the *rendered*
    /// point size is that value + `sizeBump`. Kept in one place so the whole Sapphire
    /// type scale stays consistent — bump this, never individual call sites.
    private static let sizeBump: CGFloat = 1

    // MARK: - Families (exact PostScript names)

    private enum PS {
        static let serifMedium         = "EBGaramond-Medium"
        static let serifSemiBold       = "EBGaramond-SemiBold"
        static let serifMediumItalic   = "EBGaramondItalic-MediumItalic"
        static let serifSemiBoldItalic = "EBGaramondItalic-SemiBoldItalic"
        static let arabicRegular       = "Amiri-Regular"
        static let arabicBold          = "Amiri-Bold"
    }

    /// EB Garamond. `semibold` picks weight 600 (vs 500 Medium); `italic` picks the italic cut.
    static func serif(_ size: CGFloat, semibold: Bool = true, italic: Bool = false) -> Font {
        let name: String
        switch (semibold, italic) {
        case (true,  false): name = PS.serifSemiBold
        case (true,  true):  name = PS.serifSemiBoldItalic
        case (false, false): name = PS.serifMedium
        case (false, true):  name = PS.serifMediumItalic
        }
        return .custom(name, size: size + sizeBump)
    }

    /// Amiri (Arabic Naskh). Rendered RTL by the text view.
    static func arabic(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? PS.arabicBold : PS.arabicRegular, size: size + sizeBump)
    }

    // MARK: - Handoff type scale (see design_handoff_royal_sapphire/README.md §Typography)

    /// Large screen title — EB Garamond 40 / 600.
    static var screenTitle: Font { serif(40) }
    /// Card / section headline — EB Garamond 21–27 / 600 (default 24).
    static func headline(_ size: CGFloat = 24) -> Font { serif(size) }
    /// Big numeral / stat figure — EB Garamond 26–36 / 600 (default 30).
    static func numeral(_ size: CGFloat = 30) -> Font { serif(size) }
    /// Body / verse translation — EB Garamond 17–20 / 500 (default 17).
    static func body(_ size: CGFloat = 17) -> Font { serif(size, semibold: false) }
    /// Italic English subtitle (e.g. "The Opening") — EB Garamond italic.
    static func italicTitle(_ size: CGFloat = 19) -> Font { serif(size, semibold: false, italic: true) }
    /// Eyebrow / kicker — system 11 / 700 (before `sizeBump`), used UPPERCASE with +3 tracking by the caller.
    static var eyebrow: Font { .system(size: 11 + sizeBump, weight: .bold) }
    /// Arabic Qur'anic verse — Amiri 27–30 (default 28).
    static func arabicVerse(_ size: CGFloat = 28) -> Font { arabic(size) }
}
