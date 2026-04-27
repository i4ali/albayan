//
//  EmeraldGardenSurahDetailView.swift
//  AlBayan
//
//  Standalone mockup of the Emerald Garden Surah Detail View
//  based on ui_variants/emerald_garden/variant_02_Surah_Detail_View_1242x2688.png.
//  Hardcoded Al-Fatihah data for visual iteration. Not wired to ThemeManager.
//

import SwiftUI

// MARK: - Palette

private enum EG {
    // Parchment / backgrounds
    static let parchment       = Color(red: 0.984, green: 0.961, blue: 0.902) // #FBF5E6
    static let parchmentDeep   = Color(red: 0.969, green: 0.945, blue: 0.882) // #F7F1E1
    static let cardIvory       = Color(red: 0.992, green: 0.973, blue: 0.918) // #FDF8EA
    static let agedIvory       = Color(red: 0.965, green: 0.937, blue: 0.867) // slightly older card

    // Brass family
    static let brassLight      = Color(red: 0.910, green: 0.820, blue: 0.540) // #E8D28A
    static let brassMid        = Color(red: 0.761, green: 0.680, blue: 0.420) // #C2AD6B
    static let brassDeep       = Color(red: 0.510, green: 0.443, blue: 0.286) // #826F49
    static let brassHairline   = Color(red: 0.761, green: 0.725, blue: 0.573) // #C2B992

    // Emerald family
    static let emerald         = Color(red: 0.278, green: 0.369, blue: 0.271) // #475E45
    static let deepEmerald     = Color(red: 0.208, green: 0.294, blue: 0.176) // #354B2D
    static let mutedOlive      = Color(red: 0.380, green: 0.490, blue: 0.330)

    // Ink
    static let sepiaInk        = Color(red: 0.176, green: 0.141, blue: 0.098) // #2D2419
    static let umberInk        = Color(red: 0.420, green: 0.369, blue: 0.259) // #6B5E42
    static let taupe           = Color(red: 0.659, green: 0.604, blue: 0.478)
}

// MARK: - Hardcoded Al-Fatihah

struct FatihahVerse: Identifiable {
    let id: Int
    let arabic: String
    let english: String
}

private let fatihahVerses: [FatihahVerse] = [
    FatihahVerse(
        id: 1,
        arabic: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
        english: "In the name of Allah, the Entirely Merciful, the Especially Merciful."
    ),
    FatihahVerse(
        id: 2,
        arabic: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
        english: "[All] praise is [due] to Allah, Lord of the worlds."
    ),
    FatihahVerse(
        id: 3,
        arabic: "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
        english: "The Entirely Merciful, the Especially Merciful."
    ),
    FatihahVerse(
        id: 4,
        arabic: "مَٰلِكِ يَوْمِ ٱلدِّينِ",
        english: "Sovereign of the Day of Recompense."
    ),
    FatihahVerse(
        id: 5,
        arabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
        english: "It is You we worship and You we ask for help."
    ),
    FatihahVerse(
        id: 6,
        arabic: "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
        english: "Guide us to the straight path."
    ),
    FatihahVerse(
        id: 7,
        arabic: "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
        english: "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."
    )
]

// MARK: - Shapes

/// Mihrab-arched card silhouette: flat-bottomed rectangle with a pointed
/// onion-dome peak at the top-center, flanked by two rounded shoulders.
/// Approximates the ornate header/verse card frames in the mockup.
struct MihrabCardShape: Shape {
    /// Height of the dome portion above the rectangular body, as a ratio of width.
    var peakHeightRatio: CGFloat = 0.22
    /// Radius of the bottom corners.
    var bottomCornerRadius: CGFloat = 20
    /// Radius of the rounded shoulders where the dome meets the sides.
    var shoulderRadius: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height
        let peakHeight = min(w * peakHeightRatio, h * 0.45)
        let bodyTop = peakHeight            // y where vertical sides begin
        let midX = w / 2
        let bcr = bottomCornerRadius
        let sr = shoulderRadius

        // Start at bottom-left corner (just above the corner radius)
        path.move(to: CGPoint(x: 0, y: h - bcr))

        // Up the left side to the shoulder
        path.addLine(to: CGPoint(x: 0, y: bodyTop + sr))

        // Left shoulder: curve up and inward towards the dome
        path.addQuadCurve(
            to: CGPoint(x: sr, y: bodyTop),
            control: CGPoint(x: 0, y: bodyTop)
        )

        // Left dome curve up to the peak
        path.addQuadCurve(
            to: CGPoint(x: midX, y: 0),
            control: CGPoint(x: midX * 0.55, y: bodyTop * 0.15)
        )

        // Right dome curve down from the peak
        path.addQuadCurve(
            to: CGPoint(x: w - sr, y: bodyTop),
            control: CGPoint(x: w - midX * 0.55, y: bodyTop * 0.15)
        )

        // Right shoulder
        path.addQuadCurve(
            to: CGPoint(x: w, y: bodyTop + sr),
            control: CGPoint(x: w, y: bodyTop)
        )

        // Down the right side
        path.addLine(to: CGPoint(x: w, y: h - bcr))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: w - bcr, y: h),
            control: CGPoint(x: w, y: h)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: bcr, y: h))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - bcr),
            control: CGPoint(x: 0, y: h)
        )

        path.closeSubpath()
        return path
    }
}

/// Simple rhombus used for mosaic inlay tiles along the card borders.
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// 8-point Islamic star polygon (khatam/rub-el-hizb motif).
struct IslamicStar: Shape {
    var points: Int = 8
    var innerRatio: CGFloat = 0.48

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        let total = points * 2
        let step = 2 * .pi / Double(total)
        let start = -Double.pi / 2

        for i in 0..<total {
            let r: CGFloat = (i % 2 == 0) ? outer : inner
            let a = start + Double(i) * step
            let p = CGPoint(
                x: c.x + r * CGFloat(cos(a)),
                y: c.y + r * CGFloat(sin(a))
            )
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Ornaments

/// Manuscript-illumination rosette used as a corner ornament on the parchment
/// background. Outer ring → beaded ring → radiating petal spokes → inner ring →
/// filled emerald 8-point star with brass outline → center dot.
struct EmeraldRosette: View {
    var brass: Color = EG.brassDeep
    var emerald: Color = EG.emerald
    var lineWidth: CGFloat = 1.4
    var dotCount: Int = 24
    var petalCount: Int = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(brass, lineWidth: lineWidth)

            GeometryReader { geo in
                let radius = min(geo.size.width, geo.size.height) / 2 * 0.92
                let cx = geo.size.width / 2
                let cy = geo.size.height / 2
                let bead = max(2.6, lineWidth * 1.9)
                ForEach(0..<dotCount, id: \.self) { i in
                    let angle = (Double(i) / Double(dotCount)) * 2 * .pi - .pi / 2
                    Circle()
                        .fill(brass)
                        .frame(width: bead, height: bead)
                        .position(
                            x: cx + CGFloat(cos(angle)) * radius,
                            y: cy + CGFloat(sin(angle)) * radius
                        )
                }
            }

            Circle()
                .stroke(brass.opacity(0.85), lineWidth: lineWidth * 0.8)
                .scaleEffect(0.82)

            // Radiating petal spokes
            ForEach(0..<petalCount, id: \.self) { i in
                Capsule()
                    .stroke(brass.opacity(0.85), lineWidth: lineWidth * 0.6)
                    .frame(width: 4, height: 34)
                    .padding(.bottom, 170)
                    .rotationEffect(.degrees(Double(i) * 360.0 / Double(petalCount)))
            }

            Circle()
                .stroke(brass, lineWidth: lineWidth * 0.75)
                .scaleEffect(0.42)

            IslamicStar(points: 8, innerRatio: 0.42)
                .fill(emerald)
                .scaleEffect(0.34)

            IslamicStar(points: 8, innerRatio: 0.42)
                .stroke(brass, lineWidth: lineWidth * 0.7)
                .scaleEffect(0.34)

            Circle()
                .fill(brass)
                .frame(width: max(5, lineWidth * 3), height: max(5, lineWidth * 3))
        }
    }
}

/// Horizontal/vertical strip of emerald + brass mosaic diamond tiles used as
/// decorative inlays along the mihrab frame edges.
struct MosaicInlayStrip: View {
    enum Axis { case horizontal, vertical }
    var axis: Axis = .horizontal
    var tileSize: CGFloat = 10
    var spacing: CGFloat = 2
    var tileCount: Int = 8

    private let palette: [Color] = [
        EG.emerald,
        EG.brassMid,
        EG.deepEmerald,
        EG.brassLight
    ]

    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: spacing) { tiles }
            } else {
                VStack(spacing: spacing) { tiles }
            }
        }
    }

    @ViewBuilder private var tiles: some View {
        ForEach(0..<tileCount, id: \.self) { i in
            Diamond()
                .fill(palette[i % palette.count])
                .overlay(
                    Diamond()
                        .stroke(EG.brassDeep.opacity(0.8), lineWidth: 0.6)
                )
                .frame(width: tileSize, height: tileSize)
        }
    }
}

/// Full-screen parchment background: warm ivory gradient plus very faint
/// corner rosette watermarks in each corner and a center mandala.
struct ParchmentBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [EG.parchment, EG.parchmentDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Top-left watermark
            EmeraldRosette(
                brass: EG.brassDeep.opacity(0.18),
                emerald: EG.emerald.opacity(0.15),
                lineWidth: 1.0
            )
            .frame(width: 340, height: 340)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: -140, y: -120)
            .allowsHitTesting(false)

            // Top-right watermark
            EmeraldRosette(
                brass: EG.brassDeep.opacity(0.18),
                emerald: EG.emerald.opacity(0.15),
                lineWidth: 1.0
            )
            .frame(width: 340, height: 340)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .offset(x: 140, y: -120)
            .allowsHitTesting(false)

            // Center watermark (very faint)
            EmeraldRosette(
                brass: EG.brassDeep.opacity(0.08),
                emerald: EG.emerald.opacity(0.06),
                lineWidth: 0.8
            )
            .frame(width: 420, height: 420)
            .allowsHitTesting(false)

            // Bottom-left watermark
            EmeraldRosette(
                brass: EG.brassDeep.opacity(0.15),
                emerald: EG.emerald.opacity(0.13),
                lineWidth: 0.9
            )
            .frame(width: 300, height: 300)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .offset(x: -110, y: 110)
            .allowsHitTesting(false)

            // Bottom-right watermark
            EmeraldRosette(
                brass: EG.brassDeep.opacity(0.15),
                emerald: EG.emerald.opacity(0.13),
                lineWidth: 0.9
            )
            .frame(width: 300, height: 300)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .offset(x: 110, y: 110)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Header card

struct EGHeaderCard: View {
    var body: some View {
        let cardShape = MihrabCardShape(
            peakHeightRatio: 0.22,
            bottomCornerRadius: 22,
            shoulderRadius: 26
        )

        ZStack {
            // Inner emerald backdrop layer (visible only behind the mosaic inlay
            // strips that border the ivory card)
            cardShape
                .fill(EG.emerald.opacity(0.9))

            // Main ivory card, inset to reveal a thin emerald frame
            cardShape
                .fill(EG.cardIvory)
                .overlay(
                    cardShape
                        .stroke(EG.brassDeep, lineWidth: 1.4)
                )
                .padding(8)

            // Emerald hairline inside the ivory
            cardShape
                .stroke(EG.brassDeep.opacity(0.4), lineWidth: 0.8)
                .padding(14)

            // Mosaic inlay accents at the four corners of the emerald frame
            VStack {
                HStack {
                    MosaicInlayStrip(axis: .horizontal, tileSize: 12, tileCount: 5)
                    Spacer()
                    MosaicInlayStrip(axis: .horizontal, tileSize: 12, tileCount: 5)
                }
                .padding(.horizontal, 18)
                .padding(.top, 70)

                Spacer()

                HStack {
                    MosaicInlayStrip(axis: .horizontal, tileSize: 12, tileCount: 8)
                    Spacer()
                    MosaicInlayStrip(axis: .horizontal, tileSize: 12, tileCount: 8)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }

            // Vertical mosaic runs along the emerald side-panels
            HStack {
                MosaicInlayStrip(axis: .vertical, tileSize: 10, tileCount: 7)
                    .padding(.leading, -2)
                Spacer()
                MosaicInlayStrip(axis: .vertical, tileSize: 10, tileCount: 7)
                    .padding(.trailing, -2)
            }
            .padding(.top, 110)
            .padding(.bottom, 40)

            // Content
            VStack(spacing: 14) {
                Text("سُورَةُ ٱلْفَاتِحَةِ")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(EG.emerald)
                    .padding(.top, 72)

                Text("The Opening")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(EG.brassDeep)

                HStack(spacing: 28) {
                    HStack(spacing: 6) {
                        Image(systemName: "book")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EG.umberInk)
                        Text("7 verses")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(EG.sepiaInk)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "location")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EG.umberInk)
                        Text("Meccan")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(EG.sepiaInk)
                    }
                }
                .padding(.top, 4)

                // Play Sequence button
                Button(action: {}) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Play Sequence")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(EG.cardIvory)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(EG.deepEmerald)
                            .overlay(
                                Capsule()
                                    .stroke(EG.brassLight.opacity(0.6), lineWidth: 1)
                            )
                    )
                    .shadow(color: EG.deepEmerald.opacity(0.25), radius: 6, y: 3)
                }
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
        }
        .aspectRatio(0.97, contentMode: .fit)
        .shadow(color: EG.sepiaInk.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Verse card

struct EGVerseCard: View {
    let verse: FatihahVerse

    var body: some View {
        let shape = MihrabCardShape(
            peakHeightRatio: 0.10,
            bottomCornerRadius: 18,
            shoulderRadius: 22
        )

        ZStack(alignment: .top) {
            shape
                .fill(EG.cardIvory)
                .overlay(
                    shape
                        .stroke(EG.brassDeep, lineWidth: 1.2)
                )
                .overlay(
                    shape
                        .stroke(EG.brassHairline.opacity(0.7), lineWidth: 0.7)
                        .padding(6)
                )

            VStack(alignment: .trailing, spacing: 18) {
                // Top row: verse number chip (leading) + play/heart (trailing)
                HStack {
                    // Verse number — small ivory disc with emerald numeral
                    ZStack {
                        Circle()
                            .fill(EG.agedIvory)
                            .overlay(
                                Circle()
                                    .stroke(EG.brassDeep.opacity(0.85), lineWidth: 1)
                            )
                            .frame(width: 36, height: 36)

                        Text("\(verse.id)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(EG.emerald)
                    }

                    Spacer()

                    // Play icon chip
                    iconChip(systemName: "play.fill")

                    // Heart icon chip
                    iconChip(systemName: "heart")
                }

                // Arabic verse (RTL)
                Text(verse.arabic)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(EG.emerald)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineSpacing(10)
                    .environment(\.layoutDirection, .rightToLeft)

                // English translation
                Text(verse.english)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(EG.sepiaInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(4)

                // View Commentary button
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "book")
                            .font(.system(size: 14, weight: .semibold))
                        Text("View Commentary")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(EG.sepiaInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(EG.agedIvory)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(EG.brassDeep.opacity(0.65), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 40)
            .padding(.bottom, 22)
        }
        .shadow(color: EG.sepiaInk.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private func iconChip(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(EG.emerald)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(EG.agedIvory)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(EG.brassDeep.opacity(0.7), lineWidth: 0.9)
                    )
            )
    }
}

// MARK: - Back button

struct EGBackButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "arrow.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(EG.cardIvory)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(EG.deepEmerald)
                        .overlay(
                            Circle()
                                .stroke(EG.brassLight.opacity(0.5), lineWidth: 0.8)
                        )
                )
                .shadow(color: EG.deepEmerald.opacity(0.3), radius: 4, y: 2)
        }
    }
}

// MARK: - Main view

struct EmeraldGardenSurahDetailView: View {
    var body: some View {
        ZStack {
            ParchmentBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header: back button on left, mihrab card center
                    ZStack(alignment: .topLeading) {
                        EGHeaderCard()
                            .frame(maxWidth: 340)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        EGBackButton()
                            .padding(.leading, 18)
                            .padding(.top, 18)
                    }

                    // Verses
                    VStack(spacing: 18) {
                        ForEach(fatihahVerses) { verse in
                            EGVerseCard(verse: verse)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    EmeraldGardenSurahDetailView()
}
