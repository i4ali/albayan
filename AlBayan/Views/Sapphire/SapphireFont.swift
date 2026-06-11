//
//  SapphireFont.swift
//  AlBayan
//
//  Royal Sapphire type scale. Serif display = Cormorant Garamond, Arabic = Amiri,
//  sans (UI) role = system. PostScript names below were extracted directly from the
//  bundled .ttf files (AlBayan/Resources/Fonts) — do not "tidy" them; SwiftUI's
//  `.custom` silently falls back to the system font if a name is wrong.
//
//    CormorantGaramond-Medium.ttf          -> "CormorantGaramond-Medium"
//    CormorantGaramond-SemiBold.ttf        -> "CormorantGaramond-SemiBold"
//    CormorantGaramond-MediumItalic.ttf    -> "CormorantGaramondItalic-MediumItalic"
//    CormorantGaramond-SemiBoldItalic.ttf  -> "CormorantGaramondItalic-SemiBoldItalic"
//    Amiri-Regular.ttf                     -> "Amiri-Regular"
//    Amiri-Bold.ttf                        -> "Amiri-Bold"
//

import SwiftUI

enum SapphireFont {

    // MARK: - Families (exact PostScript names)

    private enum PS {
        static let serifMedium         = "CormorantGaramond-Medium"
        static let serifSemiBold       = "CormorantGaramond-SemiBold"
        static let serifMediumItalic   = "CormorantGaramondItalic-MediumItalic"
        static let serifSemiBoldItalic = "CormorantGaramondItalic-SemiBoldItalic"
        static let arabicRegular       = "Amiri-Regular"
        static let arabicBold          = "Amiri-Bold"
    }

    /// Cormorant Garamond. `semibold` picks weight 600 (vs 500 Medium); `italic` picks the italic cut.
    static func serif(_ size: CGFloat, semibold: Bool = true, italic: Bool = false) -> Font {
        let name: String
        switch (semibold, italic) {
        case (true,  false): name = PS.serifSemiBold
        case (true,  true):  name = PS.serifSemiBoldItalic
        case (false, false): name = PS.serifMedium
        case (false, true):  name = PS.serifMediumItalic
        }
        return .custom(name, size: size)
    }

    /// Amiri (Arabic Naskh). Rendered RTL by the text view.
    static func arabic(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? PS.arabicBold : PS.arabicRegular, size: size)
    }

    // MARK: - Handoff type scale (see design_handoff_royal_sapphire/README.md §Typography)

    /// Large screen title — Cormorant 40 / 600.
    static var screenTitle: Font { serif(40) }
    /// Card / section headline — Cormorant 21–27 / 600 (default 24).
    static func headline(_ size: CGFloat = 24) -> Font { serif(size) }
    /// Big numeral / stat figure — Cormorant 26–36 / 600 (default 30).
    static func numeral(_ size: CGFloat = 30) -> Font { serif(size) }
    /// Body / verse translation — Cormorant 17–20 / 500 (default 17).
    static func body(_ size: CGFloat = 17) -> Font { serif(size, semibold: false) }
    /// Italic English subtitle (e.g. "The Opening") — Cormorant italic.
    static func italicTitle(_ size: CGFloat = 19) -> Font { serif(size, semibold: false, italic: true) }
    /// Eyebrow / kicker — system 11 / 700, used UPPERCASE with +3 tracking by the caller.
    static var eyebrow: Font { .system(size: 11, weight: .bold) }
    /// Arabic Qur'anic verse — Amiri 27–30 (default 28).
    static func arabicVerse(_ size: CGFloat = 28) -> Font { arabic(size) }
}
