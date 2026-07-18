//
//  OnboardingTextStyle.swift
//  AlBayan
//
//  Shared text-fit modifiers for onboarding hero titles / subtitles.
//
//  EB Garamond is wider than the Cormorant Garamond these screens were originally
//  tuned for, so several fixed one-line titles began to overflow and truncate. These
//  modifiers let a title wrap (default 2 lines) and shrink only as a last resort, so
//  nothing ever truncates. `frame(maxWidth:)` pins the width so wrapping works even
//  inside the paging TabView; the trailing padding keeps text off the screen edges.
//

import SwiftUI

extension View {
    /// Onboarding hero title: centered, wraps to `lines`, shrinks only if still too
    /// wide, never truncates.
    func onboardingTitle(lines: Int = 2, padding: CGFloat = 26) -> some View {
        self
            .multilineTextAlignment(.center)
            .lineLimit(lines)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, padding)
    }

    /// Onboarding subtitle / supporting line: a few more lines allowed and a gentler
    /// shrink floor.
    func onboardingSubtitle(lines: Int = 3, padding: CGFloat = 34) -> some View {
        self
            .multilineTextAlignment(.center)
            .lineLimit(lines)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, padding)
    }
}
