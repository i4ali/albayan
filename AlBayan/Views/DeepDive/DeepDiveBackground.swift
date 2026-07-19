//
//  DeepDiveBackground.swift
//  AlBayan
//
//  The progress-driven "descent" background for an immersive "Inside the Surah"
//  experience. Ported from the surah-journey handoff; the palette is retuned from
//  the source's green-black to AlBayan's Royal Sapphire navy + gold so the dive
//  matches the premium paywall aesthetic. The colour + vignette deepen as you
//  descend, with slow rising gold light-motes.
//
//  Self-contained: SwiftUI + Foundation only, no app-specific types.
//

import SwiftUI

// MARK: - Palette + interpolation math

/// Colours and the two progress ramps (background + vignette) that drive the
/// descent, plus the piecewise-linear interpolation used to sample them. Fixed
/// navy + gold (theme-independent) so the descent reads the same on every theme.
enum DeepDivePalette {

    // Fixed accent colours (AlBayan navy+gold, matching PaywallView). Built in sRGB
    // so this file needs no Color(hex:) helper.
    static let gold       = Color(.sRGB, red: 217.0/255.0, green: 192.0/255.0, blue: 121.0/255.0, opacity: 1) // #D9C079
    static let goldBright = Color(.sRGB, red: 242.0/255.0, green: 226.0/255.0, blue: 168.0/255.0, opacity: 1) // #F2E2A8
    static let cream      = Color(.sRGB, red: 244.0/255.0, green: 236.0/255.0, blue: 214.0/255.0, opacity: 1) // #F4ECD6
    // Navy-tinted muted tier for thin serif-italic body text on the dark descent.
    static let mute       = Color(.sRGB, red: 130.0/255.0, green: 139.0/255.0, blue: 163.0/255.0, opacity: 1) // #828BA3

    /// Background colour stops (navy descent). `p` is the descent progress 0...1;
    /// r/g/b are normalised to 0...1 (hex value divided by 255).
    static let bgStops: [(p: CGFloat, r: Double, g: Double, b: Double)] = [
        (0.00, 13.0/255.0, 20.0/255.0, 48.0/255.0), // #0D1430 navy surface
        (0.32, 10.0/255.0, 15.0/255.0, 38.0/255.0), // #0A0F26
        (0.55,  7.0/255.0, 10.0/255.0, 27.0/255.0), // #070A1B
        (0.72,  4.0/255.0,  6.0/255.0, 15.0/255.0), // #04060F
        (0.82,  2.0/255.0,  3.0/255.0, 10.0/255.0), // #02030A deepest
        (0.90,  6.0/255.0, 11.0/255.0, 28.0/255.0), // #060B1C lift
        (1.00, 10.0/255.0, 18.0/255.0, 48.0/255.0), // #0A1230 back toward surface
    ]

    /// Vignette-opacity stops (VIG_STOPS): how dark the outer vignette gets at
    /// each depth. `o` is the black opacity 0...1.
    static let vigStops: [(p: CGFloat, o: Double)] = [
        (0.00, 0.32),
        (0.55, 0.60),
        (0.82, 0.94),
        (1.00, 0.50),
    ]

    /// Piecewise-linear background colour at descent progress `p` (clamped 0...1).
    static func bg(_ p: CGFloat) -> Color {
        let cp = min(max(p, 0), 1)
        let stops = bgStops
        for i in 0 ..< (stops.count - 1) {
            let a = stops[i], b = stops[i + 1]
            if cp >= a.p && cp <= b.p {
                let span = b.p - a.p
                let t = span > 0 ? Double((cp - a.p) / span) : 0
                return Color(.sRGB,
                             red:   a.r + (b.r - a.r) * t,
                             green: a.g + (b.g - a.g) * t,
                             blue:  a.b + (b.b - a.b) * t,
                             opacity: 1)
            }
        }
        let last = stops[stops.count - 1]
        return Color(.sRGB, red: last.r, green: last.g, blue: last.b, opacity: 1)
    }

    /// Piecewise-linear vignette opacity at descent progress `p` (clamped 0...1).
    static func vignette(_ p: CGFloat) -> Double {
        let cp = min(max(p, 0), 1)
        let stops = vigStops
        for i in 0 ..< (stops.count - 1) {
            let a = stops[i], b = stops[i + 1]
            if cp >= a.p && cp <= b.p {
                let span = b.p - a.p
                let t = span > 0 ? Double((cp - a.p) / span) : 0
                return a.o + (b.o - a.o) * t
            }
        }
        return stops[stops.count - 1].o
    }
}

// MARK: - Rising motes (shared)

/// Slow rising gold light-motes over a transparent background. Honours Reduce
/// Motion (a static scatter with no per-frame redraw).
struct DeepDiveMotes: View {
    /// How many motes to draw. The immersive background uses 16.
    let count: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Random mote parameters, generated ONCE so they stay stable across redraws.
    @State private var motes: [Mote]

    init(count: Int = 16) {
        self.count = count
        _motes = State(initialValue: DeepDiveMotes.makeMotes(count))
    }

    var body: some View {
        Group {
            if reduceMotion {
                moteCanvas(time: nil)
            } else {
                TimelineView(.animation) { timeline in
                    moteCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Draws all motes. `time == nil` -> static placement (Reduce Motion).
    private func moteCanvas(time: Double?) -> some View {
        Canvas { ctx, size in
            for mote in motes {
                let yFrac: CGFloat = time.map { 1.08 - 1.16 * mote.phase(at: $0) } ?? mote.seed
                let x = mote.x * size.width
                let y = yFrac * size.height
                let d = mote.size
                let rect = CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)
                ctx.fill(Path(ellipseIn: rect),
                         with: .color(DeepDivePalette.goldBright.opacity(mote.opacity)))
            }
        }
        .blur(radius: 0.3)
        .allowsHitTesting(false)
    }

    /// One rising light-mote.
    private struct Mote: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
        let seed: CGFloat

        func phase(at time: Double) -> CGFloat {
            let cycles = (time - delay) / duration
            return CGFloat(cycles - cycles.rounded(.down))
        }
    }

    private static func makeMotes(_ count: Int) -> [Mote] {
        (0 ..< count).map { _ in
            Mote(
                x: CGFloat.random(in: 0 ... 1),
                size: CGFloat.random(in: 1 ... 3),
                duration: Double.random(in: 16 ... 36),
                delay: -Double.random(in: 0 ... 30),
                opacity: Double.random(in: 0.06 ... 0.22),
                seed: CGFloat.random(in: 0 ... 1)
            )
        }
    }
}

// MARK: - Descent background view

/// Immersive background whose colour + vignette deepen as `progress` (0...1)
/// advances, with slow rising gold light-motes drifting up the screen.
struct DeepDiveBackground: View {
    /// Descent progress, 0 (surface) ... 1 (deepest).
    var progress: CGFloat

    var body: some View {
        ZStack {
            DeepDivePalette.bg(progress)
                .animation(.linear(duration: 0.4), value: progress)

            DeepDiveMotes()

            GeometryReader { geo in
                let vig = DeepDivePalette.vignette(progress)
                let maxDim = max(geo.size.width, geo.size.height)
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.30),
                        .init(color: Color.black.opacity(vig), location: 1.0),
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: maxDim * 0.72
                )
                .animation(.linear(duration: 0.4), value: progress)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Descent 0.0 / 0.5 / 1.0") {
    HStack(spacing: 0) {
        ForEach([0.0, 0.5, 1.0] as [CGFloat], id: \.self) { p in
            ZStack {
                DeepDiveBackground(progress: p)
                VStack {
                    Spacer()
                    Text(String(format: "%.1f", Double(p)))
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }
    .ignoresSafeArea()
}
#endif
