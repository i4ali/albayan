//
//  DailyCrosswordScreen.swift
//  AlBayan
//
//  Onboarding Screen: Daily Crossword Highlight
//

import SwiftUI

struct DailyCrosswordScreen: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isVisible = false
    @State private var iconPulse = false
    @State private var showGrid = false
    @State private var filledCells: Set<Int> = []
    @State private var isSolved = false

    // A tiny 4×4 crossword preview: indices of "active" (white) cells
    // Letters revealed one-by-one to simulate solving
    private let activeCells: [(Int, String)] = [
        (0, "N"), (1, "U"), (2, "R"), (3, ""),
        (4, ""),  (5, "A"), (6, ""),  (7, ""),
        (8, ""),  (9, "H"), (10,"M"),(11,"A"),
        (12,""),  (13,""),  (14,"D"),(15,"")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .scaleEffect(iconPulse ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: iconPulse
                            )

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal.opacity(0.35), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        if themeManager.isSapphire {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(AnyShapeStyle(themeManager.goldGradient))
                        } else {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.teal, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.5)
                    .animation(Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: isVisible)

                    // Title
                    Text("Make the words stick - the fun way.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(34)
                              : .system(size: 34, weight: .bold))
                        .foregroundColor(themeManager.primaryText)
                        .onboardingTitle()
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : -20)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                    // Subtitle
                    Text("A quick daily crossword for your Qur'anic vocabulary.")
                        .font(themeManager.isSapphire
                              ? SapphireFont.serif(19, semibold: false)
                              : .system(size: 17, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                        .onboardingSubtitle()
                        .opacity(isVisible ? 1 : 0)
                        .animation(Animation.easeOut(duration: 0.6).delay(0.5), value: isVisible)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Mini crossword demo
                CrosswordMiniGrid(
                    activeCells: activeCells,
                    filledCells: filledCells,
                    isSolved: isSolved,
                    isVisible: showGrid
                )
                .padding(.horizontal, 40)

                // Tagline
                Text("Two minutes. Genuinely fun.")
                    .font(themeManager.isSapphire
                          ? SapphireFont.serif(18, semibold: false)
                          : .system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    .opacity(isVisible ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.6).delay(0.8), value: isVisible)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.primaryBackground)
        .onAppear {
            isVisible = true
            iconPulse = true
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) { showGrid = true }
        }

        // Reveal letters one by one
        let revealableIndices = activeCells.enumerated().compactMap { $0.element.1.isEmpty ? nil : $0.offset }
        for (pos, cellIdx) in revealableIndices.enumerated() {
            let delay = 1.5 + Double(pos) * 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    filledCells.insert(cellIdx)
                }
                if cellIdx == revealableIndices.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isSolved = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mini Grid

private struct CrosswordMiniGrid: View {
    @StateObject private var themeManager = ThemeManager.shared
    let activeCells: [(Int, String)]
    let filledCells: Set<Int>
    let isSolved: Bool
    let isVisible: Bool

    private let columns = 4

    var body: some View {
        VStack(spacing: 0) {
            // Solved banner
            if isSolved {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.teal)
                    Text("SOLVED!")
                        .font(themeManager.isSapphire
                              ? SapphireFont.eyebrow
                              : .system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.teal)
                }
                .padding(.bottom, 12)
                .transition(.scale.combined(with: .opacity))
            }

            // Grid
            GeometryReader { geo in
                let cellSize = (geo.size.width - CGFloat(columns - 1) * 2) / CGFloat(columns)
                VStack(spacing: 2) {
                    ForEach(0..<4) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<columns) { col in
                                let idx = row * columns + col
                                let entry = activeCells.first { $0.0 == idx }
                                let hasLetter = entry != nil && !entry!.1.isEmpty
                                let isActive = entry != nil
                                let isFilled = filledCells.contains(idx)

                                ZStack {
                                    if !isActive {
                                        // Black blocked cell
                                        Rectangle()
                                            .fill(themeManager.isSapphire
                                                  ? Color(white: 0.08)
                                                  : Color(white: 0.18))
                                    } else {
                                        // White active cell
                                        Rectangle()
                                            .fill(isSolved
                                                  ? Color.teal.opacity(0.12)
                                                  : (isFilled
                                                     ? (themeManager.isSapphire ? themeManager.accentColor.opacity(0.15) : Color.blue.opacity(0.12))
                                                     : themeManager.cardBackground))
                                            .overlay(Rectangle().stroke(
                                                isSolved ? Color.teal.opacity(0.5) : themeManager.strokeColor,
                                                lineWidth: 1
                                            ))

                                        if hasLetter && isFilled {
                                            Text(entry!.1)
                                                .font(.system(size: cellSize * 0.45, weight: .bold, design: .rounded))
                                                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : .teal)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                                .frame(width: cellSize, height: cellSize)
                                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isFilled)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSolved)
                            }
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.secondaryBackground.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(
                    isSolved ? Color.teal.opacity(0.4) : themeManager.strokeColor,
                    lineWidth: isSolved ? 2 : 1
                ))
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSolved)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 40)
        .animation(.easeOut(duration: 0.6), value: isVisible)
    }
}

#Preview {
    DailyCrosswordScreen()
}
