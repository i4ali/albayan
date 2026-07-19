//
//  InsideSurahScreen.swift
//  AlBayan
//
//  Onboarding Screen: "Inside the Surah" feature highlight.
//
//  Showcases the immersive, illustrated surah experiences (SurahExperienceCatalog)
//  with a hero cover that cross-fades through the premium cover art in a loop, the
//  surah's name and evocative subtitle updating beneath it in sync. The covers,
//  names and subtitles all come from SurahExperienceDescriptor.all, so this screen
//  grows automatically as the catalog does - single source of truth.
//
//  Reduce Motion: the auto-cycle is disabled and a single static hero is shown
//  (mirrors OpeningVerseScreen's treatment of looping motion). The loop also only
//  advances while this is the active onboarding page, so off-screen pages stay idle.
//

import SwiftUI

struct InsideSurahScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The active onboarding page + this screen's index, so the loop only runs while
    /// this page is on screen (TabView keeps neighbouring pages alive).
    @Binding var currentPage: Int
    let pageIndex: Int

    @State private var isVisible = false
    @State private var index = 0
    @State private var glowPulse = false

    /// One tick per cover - the cross-fade duration lives on the `.animation(value:)`.
    private let ticker = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    /// The surah experiences that actually have cover art - the loop's content, in
    /// catalog order. Non-optional cover names after the filter (`hasCover` guards nil).
    private let covers: [SurahExperienceDescriptor] = SurahExperienceDescriptor.all
        .filter { CoverMiniTile.hasCover($0.coverAssetName) }

    private var lang: CommentaryLanguage { languageManager.selectedLanguage }

    /// Advance the loop only when this page is visible and motion is allowed.
    private var autoplay: Bool { !reduceMotion && currentPage == pageIndex && covers.count > 1 }

    // 4:5 covers - kept moderate so the whole screen fits without scrolling on small phones.
    private let coverWidth: CGFloat = 212
    private var coverHeight: CGFloat { coverWidth * 5 / 4 }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 74)
                .padding(.bottom, 24)

            Spacer(minLength: 8)

            hero
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.92)
                .animation(Animation.easeOut(duration: 0.7).delay(0.45), value: isVisible)

            caption
                .padding(.top, 22)
                .opacity(isVisible ? 1 : 0)
                .animation(Animation.easeOut(duration: 0.6).delay(0.6), value: isVisible)

            progressDots
                .padding(.top, 18)
                .opacity(isVisible ? 1 : 0)
                .animation(Animation.easeOut(duration: 0.6).delay(0.7), value: isVisible)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
            glowPulse = true
        }
        .onReceive(ticker) { _ in
            guard autoplay else { return }
            index = (index + 1) % covers.count
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Text("INSIDE THE SURAH")
                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 13, weight: .bold))
                .tracking(themeManager.isSapphire ? 3 : 2)
                .foregroundColor(themeManager.accentColor)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -16)
                .animation(Animation.easeOut(duration: 0.6).delay(0.15), value: isVisible)

            Text("Step inside the surah.")
                .font(themeManager.isSapphire ? SapphireFont.serif(30) : .system(size: 30, weight: .bold))
                .foregroundColor(themeManager.primaryText)
                .onboardingTitle()
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -16)
                .animation(Animation.easeOut(duration: 0.6).delay(0.25), value: isVisible)

            Text("Immersive, illustrated journeys into a surah - its story, its themes, and the moment it was revealed.")
                .font(themeManager.isSapphire ? SapphireFont.serif(18, semibold: false) : .system(size: 16, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .onboardingSubtitle()
                .opacity(isVisible ? 1 : 0)
                .animation(Animation.easeOut(duration: 0.6).delay(0.35), value: isVisible)
        }
    }

    // MARK: - Hero cover (cross-fade loop)

    private var hero: some View {
        ZStack {
            // Soft pulsing accent glow behind the poster - ties into the app's glow motifs.
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(themeManager.accentColor.opacity(0.28))
                .frame(width: coverWidth + 44, height: coverHeight + 44)
                .blur(radius: 36)
                .scaleEffect(glowPulse ? 1.05 : 0.95)
                .animation(reduceMotion ? nil
                           : Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                           value: glowPulse)

            // All covers stacked; only the active one is opaque. Opacity animation on
            // `index` gives a guaranteed cross-dissolve (old fades out as new fades in).
            ZStack {
                ForEach(covers.indices, id: \.self) { i in
                    coverImage(covers[i].coverAssetName ?? "")
                        .opacity(i == index ? 1 : 0)
                }
            }
            .animation(.easeInOut(duration: 0.9), value: index)
            .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 12)
        }
    }

    private func coverImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: coverWidth, height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1)
            )
    }

    // MARK: - Caption (name + Arabic + subtitle, cross-fading in sync)

    private var caption: some View {
        ZStack {
            ForEach(covers.indices, id: \.self) { i in
                captionText(covers[i])
                    .opacity(i == index ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: 0.9), value: index)
        .frame(minHeight: 92, alignment: .top)   // stable height as the copy changes
    }

    private func captionText(_ descriptor: SurahExperienceDescriptor) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Text(descriptor.title.text(for: lang))
                    .font(themeManager.isSapphire ? SapphireFont.serif(23) : .system(size: 23, weight: .bold))
                    .foregroundColor(themeManager.primaryText)

                Text(descriptor.titleAr)
                    .font(themeManager.isSapphire ? SapphireFont.arabic(19) : .system(size: 19, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
            }

            Text(descriptor.subtitle.text(for: lang))
                .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isSapphire ? themeManager.tertiaryText : themeManager.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
        }
    }

    // MARK: - Progress dots (growing active pill)

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(covers.indices, id: \.self) { i in
                Capsule()
                    .fill(i == index ? themeManager.accentColor : themeManager.strokeColor)
                    .frame(width: i == index ? 18 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: index)
    }
}

#Preview {
    InsideSurahScreen(currentPage: .constant(3), pageIndex: 3)
}
