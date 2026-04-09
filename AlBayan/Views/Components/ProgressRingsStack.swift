//
//  ProgressRingsStack.swift
//  AlBayan
//
//  Combines three/four concentric rings with Apple Watch styling
//

import SwiftUI

struct ProgressRingsStack: View {
    let quranProgress: Double      // Verses read / 6236
    let surahProgress: Double      // Surahs completed / 114
    let quizProgress: Double       // Quizzes completed / 114
    let ramadanProgress: Double    // Ramadan days / 30
    let showRamadanRing: Bool

    // Refined pastel category colors (matches Modern Light style guide)
    // Quran = Sage, Surahs = Dusty Rose, Quizzes = Muted Blue, Ramadan = Soft Amber
    private let quranGradient = LinearGradient(
        colors: [Color(hex: "89C9B4"), Color(hex: "6FB89E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let surahGradient = LinearGradient(
        colors: [Color(hex: "D995A1"), Color(hex: "C87A89")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let quizGradient = LinearGradient(
        colors: [Color(hex: "90BCE1"), Color(hex: "6FA3CE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let ramadanGradient = LinearGradient(
        colors: [Color(hex: "EBC078"), Color(hex: "D9A85C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Outer ring - Quran Reading (240pt, 20pt width)
            ProgressRingView(
                progress: quranProgress,
                gradient: quranGradient,
                lineWidth: 20,
                size: 240,
                shadowColor: Color(hex: "89C9B4")
            )

            // Middle ring - Surah Completion (180pt, 18pt width)
            ProgressRingView(
                progress: surahProgress,
                gradient: surahGradient,
                lineWidth: 18,
                size: 180,
                shadowColor: Color(hex: "D995A1")
            )

            // Inner ring - Quiz Progress (120pt, 16pt width)
            ProgressRingView(
                progress: quizProgress,
                gradient: quizGradient,
                lineWidth: 16,
                size: 120,
                shadowColor: Color(hex: "90BCE1")
            )

            // Innermost ring - Ramadan (60pt, 14pt width) - Seasonal only
            if showRamadanRing {
                ProgressRingView(
                    progress: ramadanProgress,
                    gradient: ramadanGradient,
                    lineWidth: 14,
                    size: 60,
                    shadowColor: Color(hex: "EBC078")
                )
            }

            // Center display - Quran reading percentage
            VStack(spacing: 2) {
                Text("\(Int(quranProgress * 100))%")
                    .font(.system(size: showRamadanRing ? 18 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryText)

                Text("Quran")
                    .font(.system(size: showRamadanRing ? 10 : 12, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.secondaryText)
            }
        }
        .frame(width: 240, height: 240)
    }
}

// MARK: - Ring Legend

struct RingLegend: View {
    let showRamadanRing: Bool
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            LegendItem(color: Color(hex: "89C9B4"), label: "Quran")
            LegendItem(color: Color(hex: "D995A1"), label: "Surahs")
            LegendItem(color: Color(hex: "90BCE1"), label: "Quizzes")

            if showRamadanRing {
                LegendItem(color: Color(hex: "EBC078"), label: "Ramadan")
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.secondaryText)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 24) {
            ProgressRingsStack(
                quranProgress: 0.45,
                surahProgress: 0.25,
                quizProgress: 0.15,
                ramadanProgress: 0.6,
                showRamadanRing: true
            )

            RingLegend(showRamadanRing: true)
        }
    }
}
