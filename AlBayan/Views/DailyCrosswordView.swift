//
//  DailyCrosswordView.swift
//  AlBayan
//
//  Full-screen play sheet for today's Daily Crossword. Shell matches StoryDetailView
//  (AdaptiveModernBackground + dismiss). All chrome is FIXED-SIZE — it deliberately does
//  NOT use ReadingSettingsManager. Layout: header (eyebrow + live mm:ss timer + hint +
//  close) → sparse grid → clue bar (prev/next) → custom A–Z keyboard. Letters are Latin
//  transliteration, so the grid and keyboard stay LTR even in Urdu/Arabic; only the clue
//  text localizes + flips RTL. Solving every occupied cell shows a celebratory overlay
//  and records the day's completion exactly once.
//

import SwiftUI

struct DailyCrosswordView: View {
    let puzzle: DailyCrossword

    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = CommentaryLanguageManager.shared
    @StateObject private var manager = DailyCrosswordManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// User-typed letters per cell.
    @State private var letters: [CellPos: Character] = [:]
    /// The currently selected cell (nil before the first tap).
    @State private var selected: CellPos?
    /// Active direction: true = across, false = down.
    @State private var acrossMode = true
    /// Whether a hint was used at any point (passed to complete()).
    @State private var usedHint = false
    /// Elapsed solve time in seconds.
    @State private var seconds = 0
    /// True once every occupied cell matches the solution.
    @State private var solved = false
    /// Guard so completion is recorded exactly once.
    @State private var didRecord = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var lang: CommentaryLanguage { languageManager.selectedLanguage }

    // MARK: - Derived puzzle geometry (built once)

    /// Entries sorted for stable prev/next cycling (number, then Across before Down).
    private var sortedEntries: [CrosswordEntry] {
        puzzle.entries.sorted { a, b in
            a.num != b.num ? a.num < b.num : (a.isAcross && !b.isAcross)
        }
    }

    /// Every occupied cell (a cell is occupied iff some entry passes through it).
    private var occupiedCells: Set<CellPos> {
        var s: Set<CellPos> = []
        for e in puzzle.entries { for rc in e.cells { s.insert(CellPos(r: rc[0], c: rc[1])) } }
        return s
    }

    /// Cell → entries passing through it.
    private var cellIndex: [CellPos: [CrosswordEntry]] {
        var m: [CellPos: [CrosswordEntry]] = [:]
        for e in sortedEntries { for rc in e.cells { m[CellPos(r: rc[0], c: rc[1]), default: []].append(e) } }
        return m
    }

    private let solution: [CellPos: Character]

    init(puzzle: DailyCrossword) {
        self.puzzle = puzzle
        self.solution = puzzle.solution
    }

    // MARK: - Active entry

    /// The entry the user is currently working in (direction-aware).
    private var activeEntry: CrosswordEntry? {
        guard let sel = selected, let here = cellIndex[sel] else { return nil }
        if let match = here.first(where: { $0.isAcross == acrossMode }) { return match }
        return here.first
    }

    private var activeCells: Set<CellPos> {
        guard let e = activeEntry else { return [] }
        return Set(e.cells.map { CellPos(r: $0[0], c: $0[1]) })
    }

    var body: some View {
        ZStack {
            AdaptiveModernBackground()

            VStack(spacing: 18) {
                header

                ScrollView {
                    VStack(spacing: 22) {
                        grid
                        clueBar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }

                keyboard
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }

            if solved {
                solvedOverlay
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear { selectFirstCell() }
        .onReceive(timer) { _ in
            if !solved { seconds += 1 }
        }
    }

    // MARK: - Header (chrome — fixed size, LTR)

    private var header: some View {
        HStack(spacing: 12) {
            Text(DailyCrosswordStrings.dailyCrossword(lang).uppercased())
                .font(SapphireFont.eyebrow)
                .tracking(themeManager.isSapphire ? 3 : 1.2)
                .foregroundColor(themeManager.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            timerPill

            hintButton

            closeButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .environment(\.layoutDirection, .leftToRight) // chrome stays LTR even in ur/ar
    }

    private var timerPill: some View {
        Text(formattedTime)
            .font(themeManager.isSapphire
                  ? SapphireFont.numeral(18)
                  : .system(size: 16, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                if themeManager.isSapphire {
                    Capsule().fill(themeManager.goldChipFill)
                        .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
                } else {
                    Capsule().fill(themeManager.accentColor.opacity(0.12))
                }
            }
    }

    private var hintButton: some View {
        Button {
            applyHint()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(DailyCrosswordStrings.hint(lang))
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                if themeManager.isSapphire {
                    Capsule().fill(themeManager.goldChipFill)
                        .overlay(Capsule().stroke(themeManager.strokeColor, lineWidth: 1))
                } else {
                    Capsule().fill(themeManager.accentColor.opacity(0.12))
                }
            }
        }
        .buttonStyle(SpPressStyle())
        .disabled(selected == nil || solved)
        .opacity(selected == nil || solved ? 0.45 : 1)
    }

    private var closeButton: some View {
        Button {
            Haptics.impact(.light)
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeManager.secondaryText)
                .frame(width: 34, height: 34)
                .background {
                    if themeManager.isSapphire {
                        Circle().fill(themeManager.goldChipFill)
                            .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
                    } else {
                        Circle().fill(themeManager.accentColor.opacity(0.1))
                    }
                }
        }
        .buttonStyle(SpPressStyle())
    }

    // MARK: - Grid (sparse, fixed-size, LTR Latin)

    private var grid: some View {
        let cell = cellSize
        return VStack(spacing: gridGap) {
            ForEach(0..<puzzle.rows, id: \.self) { r in
                HStack(spacing: gridGap) {
                    ForEach(0..<puzzle.cols, id: \.self) { c in
                        let pos = CellPos(r: r, c: c)
                        if occupiedCells.contains(pos) {
                            cellView(pos)
                                .frame(width: cell, height: cell)
                        } else {
                            // Blocked cell: empty space.
                            Color.clear.frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
        .padding(gridGap)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeManager.isSapphire ? themeManager.cardBackground : themeManager.accentColor.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, .leftToRight) // grid is always LTR Latin
    }

    private func cellView(_ pos: CellPos) -> some View {
        let isSelected = (pos == selected)
        let isActive = activeCells.contains(pos)
        let number = puzzle.number(at: pos)
        let letter = letters[pos]

        let fill: Color
        if isSelected {
            fill = themeManager.isSapphire ? themeManager.accentColor.opacity(0.55) : themeManager.accentColor.opacity(0.32)
        } else if isActive {
            fill = themeManager.isSapphire ? themeManager.accentColor.opacity(0.22) : themeManager.accentColor.opacity(0.12)
        } else {
            fill = themeManager.isSapphire ? themeManager.cardElevated : Color.white
        }

        return Button {
            tapCell(pos)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? themeManager.accentColor : themeManager.strokeColor,
                                lineWidth: isSelected ? 2 : 1))

                if let number {
                    Text("\(number)")
                        .font(.system(size: cellSize * 0.26, weight: .semibold))
                        .foregroundColor(themeManager.tertiaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(2)
                }

                if let letter {
                    Text(String(letter))
                        .font(.system(size: cellSize * 0.5, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.primaryText)
                }
            }
        }
        .buttonStyle(SpPressStyle())
    }

    /// Square cell sized to fit the puzzle width within ~330pt, clamped to a phone-friendly range.
    private var cellSize: CGFloat {
        let maxWidth: CGFloat = 330
        let cols = CGFloat(max(puzzle.cols, 1))
        let raw = (maxWidth - gridGap * (cols + 1)) / cols
        return min(48, max(30, raw))
    }

    private var gridGap: CGFloat { 4 }

    // MARK: - Clue bar (localizes + RTL; grid does not)

    private var clueBar: some View {
        HStack(spacing: 12) {
            clueNavButton(systemIcon: "chevron.left", accessibility: DailyCrosswordStrings.prevClue(lang)) {
                cycleEntry(forward: false)
            }

            VStack(alignment: .center, spacing: 4) {
                if let e = activeEntry {
                    Text((e.isAcross ? DailyCrosswordStrings.across(lang) : DailyCrosswordStrings.down(lang)).uppercased() + " \(e.num)")
                        .font(SapphireFont.eyebrow)
                        .tracking(themeManager.isSapphire ? 2 : 1)
                        .foregroundColor(themeManager.accentColor)

                    Text(e.clue.text(for: lang))
                        .font(themeManager.isSapphire
                              ? SapphireFont.body(17)
                              : .system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
                }
            }
            .frame(maxWidth: .infinity)

            clueNavButton(systemIcon: "chevron.right", accessibility: DailyCrosswordStrings.nextClue(lang)) {
                cycleEntry(forward: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeManager.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(themeManager.strokeColor, lineWidth: 1))
        }
        // Nav buttons keep their visual order; only the clue text flips.
        .environment(\.layoutDirection, .leftToRight)
    }

    private func clueNavButton(systemIcon: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                .frame(width: 36, height: 36)
                .background {
                    if themeManager.isSapphire {
                        Circle().fill(themeManager.goldChipFill)
                            .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
                    } else {
                        Circle().fill(themeManager.accentColor.opacity(0.12))
                    }
                }
        }
        .buttonStyle(SpPressStyle())
        .accessibilityLabel(accessibility)
    }

    // MARK: - Keyboard (custom A–Z, fixed-size, LTR)

    private let keyboardRows: [[Character]] = [
        Array("QWERTYUIOP"),
        Array("ASDFGHJKL"),
        Array("ZXCVBNM")
    ]

    private var keyboard: some View {
        VStack(spacing: 7) {
            ForEach(0..<keyboardRows.count, id: \.self) { rowIdx in
                HStack(spacing: 5) {
                    if rowIdx == keyboardRows.count - 1 {
                        Spacer(minLength: 0)
                    }
                    ForEach(keyboardRows[rowIdx], id: \.self) { ch in
                        keyButton(ch)
                    }
                    if rowIdx == keyboardRows.count - 1 {
                        backspaceKey
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight) // keyboard is always Latin LTR
    }

    private func keyButton(_ ch: Character) -> some View {
        Button {
            typeLetter(ch)
        } label: {
            Text(String(ch))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(themeManager.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(themeManager.isSapphire ? themeManager.cardElevated : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(themeManager.strokeColor, lineWidth: 1))
                }
        }
        .buttonStyle(SpPressStyle())
        .disabled(selected == nil || solved)
    }

    private var backspaceKey: some View {
        Button {
            backspace()
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
                .frame(width: 56)
                .frame(height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(themeManager.goldChipFill)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(themeManager.strokeColor, lineWidth: 1))
                }
        }
        .buttonStyle(SpPressStyle())
        .disabled(selected == nil || solved)
    }

    // MARK: - Solved overlay

    private var solvedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(themeManager.goldGradient)
                        .frame(width: 90, height: 90)
                        .shadow(color: themeManager.goldButtonShadow, radius: 18, x: 0, y: 10)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(themeManager.onAccentText)
                }

                Text(DailyCrosswordStrings.solved(lang))
                    .font(themeManager.isSapphire ? SapphireFont.headline(28) : .system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.primaryText)

                HStack(spacing: 28) {
                    statBlock(value: formattedTime, label: "")
                    statBlock(value: "🔥 \(manager.streak.currentStreak)", label: "")
                }

                Text(DailyCrosswordStrings.comeBackTomorrow(lang))
                    .font(themeManager.isSapphire ? SapphireFont.body(15) : .system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                SpGoldCTA(title: DailyCrosswordStrings.doneForToday(lang), systemIcon: "checkmark") {
                    Haptics.impact(.light)
                    dismiss()
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(themeManager.isSapphire ? themeManager.cardElevated : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(themeManager.strokeColor, lineWidth: 1))
                    .shadow(color: themeManager.cardShadowElevated, radius: 24, x: 0, y: 16)
            }
            .padding(.horizontal, 32)
            .environment(\.layoutDirection, lang.isRTL ? .rightToLeft : .leftToRight)
        }
        .transition(.opacity)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(themeManager.isSapphire ? SapphireFont.numeral(26) : .system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.accentColor)
            if !label.isEmpty {
                Text(label.uppercased())
                    .font(SapphireFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(themeManager.tertiaryText)
            }
        }
    }

    // MARK: - Interaction

    private func selectFirstCell() {
        guard selected == nil, let first = sortedEntries.first else { return }
        acrossMode = first.isAcross
        selected = first.cell(at: 0)
    }

    /// Tap a cell: select it. Tapping the already-selected cell toggles direction when both exist.
    private func tapCell(_ pos: CellPos) {
        guard !solved else { return }
        Haptics.impact(.light)
        let here = cellIndex[pos] ?? []
        guard !here.isEmpty else { return }

        if pos == selected {
            // Toggle direction if both an across and a down entry pass through this cell.
            let hasAcross = here.contains { $0.isAcross }
            let hasDown = here.contains { !$0.isAcross }
            if hasAcross && hasDown { acrossMode.toggle() }
            return
        }

        selected = pos
        // Prefer keeping the current direction if an entry supports it; otherwise flip.
        if !here.contains(where: { $0.isAcross == acrossMode }) {
            acrossMode.toggle()
        }
    }

    /// Type a letter into the selected cell, then advance along the active entry.
    private func typeLetter(_ ch: Character) {
        guard !solved, let sel = selected else { return }
        Haptics.impact(.light)
        letters[sel] = ch
        advance()
        checkSolved()
    }

    /// Backspace: clear the current cell if filled; otherwise retreat and clear the previous cell.
    private func backspace() {
        guard !solved, let sel = selected else { return }
        Haptics.impact(.light)
        if letters[sel] != nil {
            letters[sel] = nil
        } else if let prev = neighbor(of: sel, forward: false) {
            selected = prev
            letters[prev] = nil
        }
    }

    /// Move selection to the next cell along the active entry (if any).
    private func advance() {
        guard let next = neighbor(of: selected, forward: true) else { return }
        selected = next
    }

    /// The cell before/after the current one within the active entry.
    private func neighbor(of pos: CellPos?, forward: Bool) -> CellPos? {
        guard let pos, let e = activeEntry else { return nil }
        let cells = e.cells.map { CellPos(r: $0[0], c: $0[1]) }
        guard let idx = cells.firstIndex(of: pos) else { return nil }
        let target = forward ? idx + 1 : idx - 1
        guard target >= 0, target < cells.count else { return nil }
        return cells[target]
    }

    /// Cycle to the previous/next entry and select its first cell.
    private func cycleEntry(forward: Bool) {
        guard !solved else { return }
        Haptics.impact(.light)
        let entries = sortedEntries
        guard !entries.isEmpty else { return }
        let current = activeEntry
        let idx = current.flatMap { entries.firstIndex(of: $0) } ?? -1
        let nextIdx = ((idx + (forward ? 1 : -1)) % entries.count + entries.count) % entries.count
        let next = entries[nextIdx]
        acrossMode = next.isAcross
        selected = next.cell(at: 0)
    }

    /// Reveal the correct letter into the selected cell; flag that a hint was used.
    private func applyHint() {
        guard !solved, let sel = selected, let correct = solution[sel] else { return }
        Haptics.impact(.light)
        usedHint = true
        letters[sel] = correct
        advance()
        checkSolved()
    }

    /// Solved iff every occupied cell's typed letter matches the solution.
    private func checkSolved() {
        for pos in occupiedCells {
            if letters[pos] != solution[pos] { return }
        }
        guard !solved else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            solved = true
        }
        Haptics.impact(.medium)
        if !didRecord {
            manager.complete(seconds: seconds, usedHint: usedHint)
            didRecord = true
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    DailyCrosswordView(puzzle: DailyCrosswordProvider.shared.today)
}
