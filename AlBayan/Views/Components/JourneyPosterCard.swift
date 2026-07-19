//
//  JourneyPosterCard.swift
//  AlBayan
//
//  Tall, image-dominant poster tile for the 2-column Journeys hub grid
//  (premium-art-sunni doc 03 aesthetic). Full-bleed cover art with a top scrim;
//  the status eyebrow + title sit top-left over the scrim, mirroring the cover
//  header band. Falls back to a themed navy gradient + faint glyph when the entry
//  has no cover art. Renders in ALL themes (posters are not gated to Royal Sapphire).
//
//  The card is fed a `JourneyPoster` view-model, so a season (JourneyDescriptor)
//  and a surah experience (SurahExperienceDescriptor) both compose the same tile.
//

import SwiftUI

/// Display model for one poster tile. Decouples the card from the descriptor types.
struct JourneyPoster: Identifiable {
    let id: String
    let coverAssetName: String?
    let sfSymbol: String
    let eyebrow: String
    let tone: Tone
    let title: String
    let onTap: () -> Void

    /// Drives the eyebrow color and border over the art.
    enum Tone { case live, ready, muted }
}

struct JourneyPosterCard: View {
    @StateObject private var themeManager = ThemeManager.shared
    let poster: JourneyPoster

    var body: some View {
        Button(action: poster.onTap) {
            ZStack(alignment: .topLeading) {
                art
                scrim
                labels
            }
            .frame(maxWidth: .infinity)
            // Portrait 4:5-ish poster (width : height = 0.82 : 1).
            .aspectRatio(0.82, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: poster.tone == .live ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder private var art: some View {
        if let cover = poster.coverAssetName, CoverMiniTile.hasCover(cover) {
            Image(cover)
                .resizable()
                .scaledToFill()
        } else {
            fallbackArt
        }
    }

    /// Themed navy gradient + faint glyph for entries without cover art.
    private var fallbackArt: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#123047"), Color(hex: "#0A1B27")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: poster.sfSymbol)
                .font(.system(size: 46, weight: .light))
                .foregroundColor(.white.opacity(0.10))
        }
    }

    /// Top scrim - keeps the eyebrow/title legible over the art.
    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.62), location: 0.00),
                .init(color: .black.opacity(0.24), location: 0.32),
                .init(color: .clear,               location: 0.64),
            ],
            startPoint: .top, endPoint: .bottom)
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(poster.eyebrow.uppercased())
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10.5, weight: .bold))
                .tracking(2.2)
                .foregroundColor(eyebrowColor)
            Text(poster.title)
                .font(themeManager.isSapphire ? SapphireFont.serif(19) : .system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eyebrowColor: Color {
        switch poster.tone {
        case .live:  return themeManager.accentColor
        case .ready: return .white.opacity(0.92)
        case .muted: return .white.opacity(0.62)
        }
    }

    private var borderColor: Color {
        poster.tone == .live ? themeManager.accentColor.opacity(0.5) : .white.opacity(0.12)
    }
}
