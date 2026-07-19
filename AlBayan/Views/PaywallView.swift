//
//  PaywallView.swift
//  AlBayan
//
//  Premium paywall — fixed dark "premium" look on every theme.
//  One-time lifetime unlock via StoreKit 2 (PurchaseManager / PremiumManager).
//

import SwiftUI

// MARK: - Fixed paywall palette (intentionally NOT ThemeManager — the paywall
// is always dark navy + gold regardless of the app's selected theme).
private enum PW {
    static let bgTop      = Color(hex: "#0D1430")
    static let bgBottom   = Color(hex: "#080D20")
    static let gold       = Color(hex: "#D9C079")
    static let goldBright = Color(hex: "#F2E2A8")
    static let goldDeep   = Color(hex: "#C19A3E")
    static let cream      = Color(hex: "#F4ECD6")
    static let textPrimary = Color(hex: "#EDE6D0")
    static let textMuted  = Color(hex: "#828BA3")
    static let textDim    = Color(hex: "#7F88A0")
    static let green      = Color(hex: "#6BCB77")
    static let onGold     = Color(hex: "#1B1606")
    static let cardFill   = Color.white.opacity(0.035)
    static let cardStroke = Color(hex: "#D9C079").opacity(0.3)   // subtle gold card border

    static var goldGradient: LinearGradient {
        LinearGradient(colors: [goldBright, goldDeep], startPoint: .top, endPoint: .bottom)
    }
    static var bgGradient: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
    }
}

/// Context for a contextual paywall (premium-art doc 04-A): the hero art + eyebrow swap to
/// show the very thing a gated tap reached for. The headline stays the whole-library sell.
struct PaywallContext {
    var coverAssetName: String? = nil
    var eyebrow: String = "TAFAKKUR PREMIUM"
}

struct PaywallView: View {
    /// Optional contextual hero (nil -> default hero + generic eyebrow). Passed by gated taps.
    var context: PaywallContext? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var purchaseManager = PurchaseManager.shared

    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var kenBurnsActive = false
    @State private var contentAppeared = false

    private let calendar = IslamicCalendarManager.shared

    private var heroAssetName: String { context?.coverAssetName ?? "PaywallHeroDefault" }
    // Default hero is composed for the band (center anchor). Context covers are 4:5 and
    // overflow the wide band, so they anchor .top or the crop rides the subject under the text.
    private var heroAnchor: UnitPoint { context?.coverAssetName == nil ? .center : .top }

    // Entrance cascade (premium-art doc 04-A): rows below the hero fade in + rise, staggered
    // by a continuous index. Reduce Motion shows them in place with no animation.
    private func cascaded<Content: View>(_ index: Int, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .opacity(contentAppeared || reduceMotion ? 1 : 0)
            .offset(y: contentAppeared || reduceMotion ? 0 : 14)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(Double(index) * 0.05),
                       value: contentAppeared)
    }

    var body: some View {
        ZStack {
            PW.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                closeBar
                ScrollView {
                    VStack(spacing: 16) {
                        heroBand
                        cascaded(0) { header }
                        cascaded(1) { layersCard }
                        featureCards
                        cascaded(8) { trustRow }
                        cascaded(9) { ctaSection }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                    .onAppear { contentAppeared = true }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Close

    private var closeBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PW.textMuted)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    // MARK: - Hero band (premium-art doc 04-A)

    private var heroBand: some View {
        ZStack(alignment: .bottomLeading) {
            heroArt
            heroText
        }
        .frame(height: 348)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, -22)   // escape the column's 22pt padding, bleed edge-to-edge
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 22).repeatForever(autoreverses: true)) {
                kenBurnsActive = true
            }
        }
    }

    private var heroArt: some View {
        Color.clear
            .frame(height: 348)
            .overlay {
                Image(heroAssetName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(kenBurnsActive ? 1.09 : 1.0, anchor: heroAnchor)
            }
            .clipped()
            .mask(
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.72), location: 0.00),
                    .init(color: .black,               location: 0.12),
                    .init(color: .black,               location: 0.55),
                    .init(color: .clear,               location: 1.00),
                ], startPoint: .top, endPoint: .bottom)
            )
            .accessibilityHidden(true)
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(context?.eyebrow ?? "TAFAKKUR PREMIUM")
                .font(.system(size: 12, weight: .bold))
                .tracking(3)
                .foregroundColor(PW.gold)
                .shadow(color: .black.opacity(0.5), radius: 8, y: 1)
            Text("Everything.\nForever.")
                .font(SapphireFont.serif(38))
                .foregroundColor(PW.cream)
                .lineSpacing(2)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 1)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }

    // MARK: - Header (price pill + lede, under the hero)

    private var header: some View {
        VStack(spacing: 13) {
            pricePill

            Text("One payment. No renewals.\nYour daily companion, for life.")
                .font(.system(size: 14))
                .foregroundColor(PW.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.top, 4)
    }

    private var pricePill: some View {
        HStack(spacing: 8) {
            Text(purchaseManager.getProductPrice() ?? "$9.99")
                .font(SapphireFont.serif(22))
                .foregroundColor(PW.goldBright)
            Text("ONE-TIME")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(PW.gold)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(PW.gold.opacity(0.08))
                .overlay(Capsule().stroke(PW.gold.opacity(0.5), lineWidth: 1))
        )
    }

    // MARK: - Tafsir layers card

    private var layersCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text("📖").font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("4 Layers of Tafsir")
                        .font(SapphireFont.serif(18))
                        .foregroundColor(PW.textPrimary)
                    Text("All 114 surahs · English, Urdu & Arabic")
                        .font(.system(size: 11))
                        .foregroundColor(PW.textDim)
                }
            }
            .padding(.bottom, 8)

            layerRow(1, "Foundation", "Historical context & basics", exclusive: false)
            layerRow(2, "Classical Sunni", "Tabari, Ibn Kathir, Qurtubi", exclusive: false)
            layerRow(3, "Contemporary", "Modern perspectives", exclusive: false)
            layerRow(4, "Comparative", "Sunni & Shia side by side", exclusive: true)
        }
        .padding(15)
        .background(cardBG)
    }

    private func layerRow(_ n: Int, _ title: String, _ desc: String, exclusive: Bool) -> some View {
        HStack(spacing: 10) {
            Text("\(n)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(PW.goldBright)
                .frame(width: 22, height: 22)
                .background(Circle().fill(PW.gold.opacity(0.16)))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(PW.textPrimary)
                .fixedSize(horizontal: true, vertical: false)

            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(PW.textDim)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 4)

            if exclusive {
                Text("EXCLUSIVE")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(PW.onGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(PW.goldGradient))
            }
        }
        .padding(.vertical, 7)
    }

    // MARK: - Feature cards

    private var featureCards: some View {
        VStack(spacing: 9) {
            cascaded(2) {
                featureCard("🕌", "Inside the Surah", "Immersive, illustrated journeys into a single surah",
                            badge: "IMMERSIVE", goldBadge: true)
            }
            cascaded(3) {
                featureCard("✨", "Gems", "Bite-size insights for every verse",
                            badge: "MOST LOVED", goldBadge: true)
            }
            cascaded(4) {
                featureCard("🌙", "Seasonal Journeys", "A guided path through every sacred season",
                            badge: seasonalBadge, goldBadge: true)
            }
            cascaded(5) {
                featureCard("🧠", "Surah Quizzes", "Lock in what you've learned, surah by surah",
                            badge: nil, goldBadge: false)
            }
            cascaded(6) {
                featureCard("🎯", "Daily Challenge", "Learn something new every day in under a minute",
                            badge: nil, goldBadge: false)
            }
            cascaded(7) {
                featureCard("🧩", "Daily Crossword", "A fun way to grow your Qur'anic vocabulary",
                            badge: nil, goldBadge: false)
            }
        }
    }

    private func featureCard(_ emoji: String, _ title: String, _ subtitle: String,
                             badge: String?, goldBadge: Bool) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10).fill(PW.gold.opacity(0.13)))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundColor(PW.textPrimary)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 8.5, weight: .heavy))
                            .tracking(0.6)
                            .foregroundColor(goldBadge ? PW.onGold : PW.goldBright)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(goldBadge
                                    ? AnyShapeStyle(PW.goldGradient)
                                    : AnyShapeStyle(PW.gold.opacity(0.16)))
                            )
                    }
                }
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(PW.textDim)
            }

            Spacer(minLength: 4)
        }
        .padding(12)
        .background(cardBG)
    }

    // MARK: - Trust row

    private var trustRow: some View {
        HStack(spacing: 14) {
            trustItem("Family Sharing")
            trustItem("Works offline")
            trustItem("No ads, ever")
        }
        .padding(.top, 2)
    }

    private func trustItem(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(PW.green)
            Text(text)
                .font(.system(size: 10.5))
                .foregroundColor(PW.textDim)
        }
    }

    // MARK: - CTA + footer

    private var ctaSection: some View {
        VStack(spacing: 11) {
            Button(action: purchase) {
                HStack(spacing: 9) {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: PW.onGold))
                    } else {
                        Text("Unlock Premium").font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundColor(PW.onGold)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 15).fill(PW.goldGradient))
                .shadow(color: PW.gold.opacity(0.3), radius: 14, x: 0, y: 6)
            }
            .disabled(purchaseManager.isLoading || !purchaseManager.isProductLoaded)

            HStack(spacing: 5) {
                Text("One-time · yours for life ·")
                    .font(.system(size: 11))
                    .foregroundColor(PW.textDim)
                Button(action: restore) {
                    Text("Restore")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(PW.gold)
                        .underline()
                }
                .disabled(purchaseManager.isLoading)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Shared card background

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(PW.cardFill)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(PW.cardStroke, lineWidth: 1))
    }

    // MARK: - Dynamic seasonal merchandising

    private var seasonalBadge: String? {
        if calendar.isRamadanSeason() {
            if let d = calendar.currentRamadanDay() { return "RAMADAN · DAY \(d)" }
            return "RAMADAN"
        }
        if calendar.isHajjSeason() {
            if let d = calendar.currentHajjDay() { return "HAJJ · DAY \(d)" }
            return "HAJJ"
        }
        return "DAY BY DAY"   // off-season fallback so the pill always shows
    }

    // MARK: - Purchase / restore (StoreKit wiring preserved)

    private func purchase() {
        Task {
            do {
                try await purchaseManager.purchase()
                if purchaseManager.purchaseSuccess {
                    alertTitle = "Success!"
                    alertMessage = "Premium unlocked! All tafsir commentary is now available."
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
                }
            } catch {
                alertTitle = "Purchase Failed"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }

    private func restore() {
        Task {
            do {
                try await purchaseManager.restorePurchases()
                if purchaseManager.purchaseSuccess {
                    alertTitle = "Restored!"
                    alertMessage = "Your premium access has been restored."
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
                }
            } catch {
                alertTitle = "Restore Failed"
                alertMessage = purchaseManager.purchaseError ?? "No purchases found"
                showingAlert = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
