//
//  JourneyDayVeil.swift
//  AlBayan
//
//  Veiled locked-day preview (premium-art-sunni doc 01-A4). When a non-subscriber taps a
//  locked journey day, this opens instead of bouncing straight to the paywall: the journey's
//  cover, blurred past legibility, backs a preview of what the day holds + an upgrade CTA.
//  The gate is a veil (it says what exists), not a wall. Always-dark regardless of theme,
//  gold/cream text tokens, and no lock glyph anywhere.
//

import SwiftUI

struct JourneyDayVeil: View {
    let coverAssetName: String
    let eyebrow: String          // e.g. "RAMADAN · DAY 12"
    let theme: String            // the day's theme (title)
    let openingLine: String      // a teaser (the day's tafsir focus)
    let insideItems: [String]    // "A daily du'a", "N verses…", "A guided reflection"
    let onUpgrade: () -> Void
    let onClose: () -> Void

    // Fixed always-dark premium palette (matches the paywall). NOT theme-derived: the art is
    // always dark, so a light-theme text color would vanish on it.
    private let gold       = Color(hex: "#D9C079")
    private let goldBright = Color(hex: "#F2E2A8")
    private let goldDeep   = Color(hex: "#C19A3E")
    private let cream      = Color(hex: "#F4ECD6")
    private let textMuted  = Color(hex: "#B7C0D6")
    private let onGold     = Color(hex: "#1B1606")

    var body: some View {
        ZStack {
            veiledBackdrop
            content
        }
    }

    // The cover blurred past legibility (01-A4 recipe): 1.22x overscan so the blur doesn't
    // vignette at the edges, blur 44 opaque, then a 0.52 black wash.
    private var veiledBackdrop: some View {
        GeometryReader { geo in
            Image(coverAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(1.22)
                .blur(radius: 44, opaque: true)
                .clipped()
                .overlay(Color.black.opacity(0.52))
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(cream.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 12)

            Text(eyebrow)
                .font(.system(size: 12, weight: .bold))
                .tracking(2.5)
                .foregroundColor(gold)

            Text(theme)
                .font(SapphireFont.serif(34))
                .foregroundColor(cream)
                .padding(.top, 8)

            Text(openingLine)
                .font(.system(size: 15))
                .foregroundColor(textMuted)
                .lineSpacing(3)
                .lineLimit(3)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 11) {
                Text("INSIDE THIS DAY")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(2)
                    .foregroundColor(gold.opacity(0.9))
                ForEach(insideItems, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundColor(goldBright)
                        Text(item)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(cream.opacity(0.92))
                    }
                }
            }
            .padding(.top, 24)

            Spacer(minLength: 12)

            Text("Unlock every day of the journey with Tafakkur Premium.")
                .font(.system(size: 13))
                .foregroundColor(textMuted)
                .padding(.bottom, 12)

            Button(action: onUpgrade) {
                Text("Unlock the journey")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(onGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(LinearGradient(colors: [goldBright, goldDeep],
                                                 startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: gold.opacity(0.3), radius: 14, y: 6)
            }
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
