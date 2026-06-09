import SwiftUI

// MARK: - Reading text-size control (shared across reading screens)
//
// Ported to AlBayan's primitives:
//   • tm                → themeManager (ThemeManager.shared)
//   • EmType.serif(…)   → .system(size:weight:) (chrome stays system)
//   • accentChip        → accentColor.opacity(0.15)
//   • strokeColorStrong → tertiaryText.opacity(0.4)  (empty dots)
//   • EmPressStyle      → PlainButtonStyle()
// The floating panel background stays `.ultraThinMaterial` (a system material).

/// The "Aa" toggle chip. Binds to a panel-visibility flag the host owns.
struct TextSizeButton: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var isPanelOpen: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { isPanelOpen.toggle() }
        }) {
            Text("Aa")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.accentColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(isPanelOpen ? themeManager.accentColor.opacity(0.15) : Color.clear))
                .overlay(Circle().stroke(themeManager.strokeColor, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Text size")
    }
}

/// The floating A− / step-dots / A+ panel. Reads + mutates ReadingSettingsManager directly.
struct TextSizePanel: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settings = ReadingSettingsManager.shared

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { withAnimation(.easeInOut(duration: 0.18)) { settings.decrease() } }) {
                Text("A")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(settings.canDecrease ? themeManager.accentColor : themeManager.tertiaryText)
                    .frame(width: 28, height: 28)
            }
            .disabled(!settings.canDecrease)
            .accessibilityLabel("Decrease text size")

            HStack(spacing: 7) {
                ForEach(0..<settings.stepCount, id: \.self) { i in
                    Circle()
                        .fill(i <= settings.stepIndex ? themeManager.accentColor : themeManager.tertiaryText.opacity(0.4))
                        .frame(width: 6, height: 6)
                }
            }

            Button(action: { withAnimation(.easeInOut(duration: 0.18)) { settings.increase() } }) {
                Text("A")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(settings.canIncrease ? themeManager.accentColor : themeManager.tertiaryText)
                    .frame(width: 28, height: 28)
            }
            .disabled(!settings.canIncrease)
            .accessibilityLabel("Increase text size")
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(themeManager.strokeColor, lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
        )
    }
}

extension View {
    /// Overlays the floating `TextSizePanel` at top-trailing with a transparent
    /// outside-tap catcher that closes it. Host owns the `isOpen` flag.
    func textSizePanelOverlay(isOpen: Binding<Bool>,
                              topPadding: CGFloat,
                              trailingPadding: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            self
            if isOpen.wrappedValue {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { isOpen.wrappedValue = false } }
                TextSizePanel()
                    .padding(.top, topPadding)
                    .padding(.trailing, trailingPadding)
                    .transition(.scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity))
            }
        }
    }
}
