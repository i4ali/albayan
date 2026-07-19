//
//  CoverHeaderBand.swift
//  AlBayan
//
//  Shared premium-art header band (premium-art-sunni doc 03).
//  A fixed-height, full-bleed cover image placed BEHIND a screen's header text
//  stack, top-aligned to the screen. The art is CENTER-anchored within the band
//  so the composed subject (which sits mid-frame in the 4:5 covers) reads, then
//  the art fades to transparent at the bottom (alpha mask) so it melts into the
//  screen background. A gentle top scrim keeps the eyebrow/title legible.
//
//  Flagship (Royal Sapphire) theme only - callers gate on themeManager.isSapphire.
//  Build once, use everywhere: Explore/section detail headers and journey headers.
//

import SwiftUI

struct CoverHeaderBand: View {
    /// Asset-catalog name of the cover (the single `coverAssetName` for the entry).
    let assetName: String
    /// Band height: ~440 for hub/overview screens, ~280 for detail screens.
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            Image(assetName)
                .resizable()
                .scaledToFill()
                // Center-anchored: the covers place their subject mid-frame, so a
                // top-aligned crop would show only the dark sky. Center shows the subject.
                .frame(width: geo.size.width, height: height, alignment: .center)
                .clipped()
                // Gentle top scrim - keeps the eyebrow/title legible over the art.
                .overlay(alignment: .top) {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.55), location: 0.00),
                            .init(color: .black.opacity(0.25), location: 0.14),
                            .init(color: .clear,               location: 0.34),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                // Fade the art itself into the screen background at the bottom.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.00),
                            .init(color: .black, location: 0.68),
                            .init(color: .clear, location: 1.00),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: height)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
