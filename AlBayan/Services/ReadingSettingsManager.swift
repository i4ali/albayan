import SwiftUI

/// Global reading-text-size preference: a discrete font-scale multiplier,
/// adjusted from the in-screen "Aa" control and the Settings stepper, and
/// persisted across launches. Same singleton + UserDefaults pattern as ThemeManager.
@MainActor
final class ReadingSettingsManager: ObservableObject {
    static let shared = ReadingSettingsManager()

    private static let storageKey = "readingFontScaleIndex"

    /// Multiplier steps applied to body font size + leading.
    /// Default index 1 (= 1.0×): one step smaller, three larger.
    static let steps: [CGFloat] = [0.9, 1.0, 1.15, 1.3, 1.5]
    static let defaultIndex = 1

    @Published var stepIndex: Int {
        didSet { UserDefaults.standard.set(stepIndex, forKey: Self.storageKey) }
    }

    private init() {
        if let saved = UserDefaults.standard.object(forKey: Self.storageKey) as? Int {
            stepIndex = min(max(saved, 0), Self.steps.count - 1)   // clamp on load
        } else {
            stepIndex = Self.defaultIndex
        }
    }

    var scale: CGFloat { Self.steps[stepIndex] }
    var stepCount: Int { Self.steps.count }
    var canIncrease: Bool { stepIndex < Self.steps.count - 1 }
    var canDecrease: Bool { stepIndex > 0 }

    func increase() { if canIncrease { stepIndex += 1 } }
    func decrease() { if canDecrease { stepIndex -= 1 } }
}
