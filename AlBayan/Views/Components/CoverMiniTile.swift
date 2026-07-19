//
//  CoverMiniTile.swift
//  AlBayan
//
//  Shared premium-art mini poster tile (premium-art-sunni doc 02.2).
//  A small 54x68 (4:5) cover thumbnail that replaces the old icon chip on
//  list rows. The same `coverAssetName` that feeds a screen's header band feeds
//  this tile, so the art a user sees in the list is the art they land on.
//  Renders in ALL themes (posters/tiles are not gated to Royal Sapphire).
//

import SwiftUI

struct CoverMiniTile: View {
    /// Asset-catalog name of the cover (the single `coverAssetName` for the entry).
    let assetName: String
    var width: CGFloat = 54
    var height: CGFloat = 68

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1)
            )
    }

    /// True when the named cover asset actually exists in the bundle. Callers use
    /// this to fall back to their icon chip when an entry has no cover art (doc 02.2).
    static func hasCover(_ assetName: String?) -> Bool {
        guard let assetName, !assetName.isEmpty else { return false }
        return UIImage(named: assetName) != nil
    }

    /// The cover asset for a surah, or nil if that surah has no cover (only the curated
    /// ~12 surahs do). Naming: `CoverSurah` + zero-padded 3-digit number (e.g. CoverSurah018).
    static func surahCoverAssetName(_ surahNumber: Int) -> String? {
        let name = String(format: "CoverSurah%03d", surahNumber)
        return hasCover(name) ? name : nil
    }
}
