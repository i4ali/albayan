//
//  PaywallView.swift
//  AlBayan
//
//  Paywall screen for premium upgrade
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        ZStack {
            // Background
            themeManager.primaryBackground
                .ignoresSafeArea()

            // Animated background orbs (matching app theme)
            ForEach(0..<3) { i in
                Circle()
                    .fill(
                        themeManager.isSapphire
                        ? AnyShapeStyle(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#D9C079").opacity(0.18),
                                Color(hex: "#5B9BE0").opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(
                        x: i == 0 ? -100 : (i == 1 ? 150 : 0),
                        y: i == 0 ? -150 : (i == 1 ? 300 : 500)
                    )
            }

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.secondaryText.opacity(0.6))
                    }
                    .padding()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Featured: Quick Gems
                        PaywallQuickGemsFeature()

                        // Hero: 4 Layers of Wisdom
                        PaywallLayersHero()

                        // Progress/Streak Teaser
                        PaywallProgressTeaser()

                        // Condensed Benefits list
                        VStack(spacing: 12) {
                            PremiumBenefitRow(
                                icon: "book.fill",
                                title: "All 114 Surahs",
                                description: "Comprehensive tafsir for the entire Quran",
                                color: .green
                            )

                            PremiumBenefitRow(
                                icon: "globe",
                                title: "Multilingual Support",
                                description: "Full commentary in English, Urdu & Arabic",
                                color: .purple
                            )

                            PremiumBenefitRow(
                                icon: "infinity.circle.fill",
                                title: "Lifetime Access",
                                description: "One-time purchase, no subscriptions",
                                color: .pink
                            )

                            PremiumBenefitRow(
                                icon: "speaker.wave.2.fill",
                                title: "Listen to Commentary",
                                description: "Text-to-speech with word highlighting",
                                color: .blue
                            )

                            PremiumBenefitRow(
                                icon: "brain.head.profile",
                                title: "Surah Quizzes",
                                description: "Interactive quizzes for every surah",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Price and purchase button
                        VStack(spacing: 16) {
                            // Price display
                            VStack(spacing: 4) {
                                if themeManager.isSapphire {
                                    Text("UNLOCK PREMIUM")
                                        .font(SapphireFont.eyebrow)
                                        .foregroundColor(themeManager.accentColor)
                                        .tracking(2.5)
                                        .textCase(.uppercase)
                                } else {
                                    Text("Only")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(themeManager.secondaryText)
                                }

                                if let price = purchaseManager.getProductPrice() {
                                    if themeManager.isSapphire {
                                        Text(price)
                                            .font(SapphireFont.numeral(48))
                                            .foregroundColor(themeManager.accentBright)
                                    } else {
                                        Text(price)
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(themeManager.primaryText)
                                    }
                                } else {
                                    ProgressView()
                                        .frame(height: 58)
                                }

                                Text("One-time payment")
                                    .font(themeManager.isSapphire ? SapphireFont.serif(14, semibold: false) : .system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.secondaryText)
                            }
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(themeManager.isSapphire ? themeManager.goldChipFill : themeManager.secondaryBackground.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(themeManager.accentColor.opacity(themeManager.isSapphire ? 0.55 : 0.3), lineWidth: themeManager.isSapphire ? 1.5 : 1)
                                    )
                            )

                            // Purchase button
                            Button(action: {
                                Task {
                                    do {
                                        try await purchaseManager.purchase()

                                        if purchaseManager.purchaseSuccess {
                                            alertTitle = "Success!"
                                            alertMessage = "Premium unlocked! All tafsir commentary is now available."
                                            showingAlert = true

                                            // Dismiss after showing success
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                dismiss()
                                            }
                                        }
                                    } catch {
                                        alertTitle = "Purchase Failed"
                                        alertMessage = error.localizedDescription
                                        showingAlert = true
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if purchaseManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.isSapphire ? themeManager.onAccentText : .white))
                                    } else {
                                        Image(systemName: "star.fill")
                                        Text("Unlock Premium")
                                            .font(themeManager.isSapphire ? SapphireFont.serif(18) : .system(size: 18, weight: .bold))
                                    }
                                }
                                .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    themeManager.isSapphire
                                    ? AnyShapeStyle(themeManager.goldGradient)
                                    : AnyShapeStyle(LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                )
                                .cornerRadius(16)
                                .shadow(
                                    color: themeManager.isSapphire ? themeManager.goldButtonShadow : Color.purple.opacity(0.5),
                                    radius: 15, x: 0, y: 8
                                )
                            }
                            .disabled(purchaseManager.isLoading || !purchaseManager.isProductLoaded)

                            // Restore purchases button
                            Button(action: {
                                Task {
                                    do {
                                        try await purchaseManager.restorePurchases()

                                        if purchaseManager.purchaseSuccess {
                                            alertTitle = "Restored!"
                                            alertMessage = "Your premium access has been restored."
                                            showingAlert = true

                                            // Dismiss after showing success
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                dismiss()
                                            }
                                        }
                                    } catch {
                                        alertTitle = "Restore Failed"
                                        alertMessage = purchaseManager.purchaseError ?? "No purchases found"
                                        showingAlert = true
                                    }
                                }
                            }) {
                                Text("Restore Purchases")
                                    .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.tertiaryText : themeManager.secondaryText)
                                    .underline()
                            }
                            .disabled(purchaseManager.isLoading)
                        }
                        .padding(.horizontal)

                        // Footer text
                        Text("Secure payment processed by Apple")
                            .font(themeManager.isSapphire ? SapphireFont.serif(12, semibold: false) : .system(size: 12))
                            .foregroundColor(themeManager.isSapphire ? themeManager.tertiaryText : themeManager.secondaryText.opacity(0.6))
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Benefit Row Component

struct PremiumBenefitRow: View {
    @StateObject private var themeManager = ThemeManager.shared

    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.isSapphire ? themeManager.goldChipFill : color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : color)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(themeManager.isSapphire ? SapphireFont.serif(18) : .system(size: 17, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)

                Text(description)
                    .font(themeManager.isSapphire ? SapphireFont.serif(14, semibold: false) : .system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.isSapphire ? themeManager.cardElevated : themeManager.secondaryBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.isSapphire ? themeManager.strokeColor : color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Hero 4-Layers Section

struct PaywallLayersHero: View {
    @StateObject private var themeManager = ThemeManager.shared

    private let layers: [(emoji: String, title: String, tagline: String, color: Color)] = [
        ("🏛️", "Foundation", "Historical context & basics", .blue),
        ("📚", "Classical Sunni", "Tabari, Ibn Kathir, Qurtubi", .purple),
        ("🌍", "Contemporary", "Modern perspectives", .green),
        ("⚖️", "Comparative", "Sunni & Shia analysis", .indigo)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                if themeManager.isSapphire {
                    Text("WISDOM")
                        .font(SapphireFont.eyebrow)
                        .foregroundColor(themeManager.accentColor)
                        .tracking(3)
                        .textCase(.uppercase)
                }

                Text("4 Layers of Wisdom")
                    .font(themeManager.isSapphire ? SapphireFont.serif(30) : .system(size: 28, weight: .bold))
                    .foregroundColor(themeManager.primaryText)

                Text("Unlock the depth of Quranic understanding")
                    .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 15, weight: .medium))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Layer cards grid (2x2)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    PaywallLayerCard(
                        emoji: layers[0].emoji,
                        title: layers[0].title,
                        tagline: layers[0].tagline,
                        color: layers[0].color
                    )
                    PaywallLayerCard(
                        emoji: layers[1].emoji,
                        title: layers[1].title,
                        tagline: layers[1].tagline,
                        color: layers[1].color
                    )
                }

                HStack(spacing: 10) {
                    PaywallLayerCard(
                        emoji: layers[2].emoji,
                        title: layers[2].title,
                        tagline: layers[2].tagline,
                        color: layers[2].color
                    )
                    PaywallLayerCard(
                        emoji: layers[3].emoji,
                        title: layers[3].title,
                        tagline: layers[3].tagline,
                        color: layers[3].color
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Layer Card Component

struct PaywallLayerCard: View {
    @StateObject private var themeManager = ThemeManager.shared

    let emoji: String
    let title: String
    let tagline: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 24))

            Text(title)
                .font(themeManager.isSapphire ? SapphireFont.serif(13) : .system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : themeManager.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(tagline)
                .font(themeManager.isSapphire ? SapphireFont.serif(10, semibold: false) : .system(size: 10, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isSapphire ? themeManager.cardElevated : themeManager.secondaryBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.isSapphire ? themeManager.strokeColor : color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Progress/Streak Teaser Section

struct PaywallProgressTeaser: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 12) {
            if themeManager.isSapphire {
                Text("JOURNEY")
                    .font(SapphireFont.eyebrow)
                    .foregroundColor(themeManager.accentColor)
                    .tracking(2.5)
                    .textCase(.uppercase)
            }

            Text("Track Your Spiritual Journey")
                .font(themeManager.isSapphire ? SapphireFont.serif(18) : .system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.primaryText)

            HStack(spacing: 12) {
                ProgressTeaserItem(icon: "flame.fill", label: "Build Streaks", color: .orange)
                ProgressTeaserItem(icon: "star.fill", label: "Earn Sawab", color: .yellow)
                ProgressTeaserItem(icon: "trophy.fill", label: "Unlock Badges", color: .purple)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Progress Teaser Item

struct ProgressTeaserItem: View {
    @StateObject private var themeManager = ThemeManager.shared

    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : color)

            Text(label)
                .font(themeManager.isSapphire ? SapphireFont.serif(11, semibold: false) : .system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isSapphire ? themeManager.cardElevated : themeManager.secondaryBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.isSapphire ? themeManager.strokeColor : color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Gems Feature Card

struct PaywallQuickGemsFeature: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Popular badge
            HStack {
                Spacer()
                if themeManager.isSapphire {
                    Text("POPULAR")
                        .font(SapphireFont.eyebrow)
                        .foregroundColor(themeManager.onAccentText)
                        .tracking(2)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(themeManager.accentColor))
                        .offset(y: -12)
                } else {
                    Text("POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.orange))
                        .offset(y: -12)
                }
            }
            .padding(.trailing, 16)

            // Icon and content
            HStack(spacing: 16) {
                // Sparkles icon with glow
                ZStack {
                    Circle()
                        .fill(themeManager.isSapphire ? themeManager.goldChipFill : Color.orange.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentBright : .orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gems")
                        .font(themeManager.isSapphire ? SapphireFont.serif(22) : .system(size: 20, weight: .bold))
                        .foregroundColor(themeManager.primaryText)

                    Text("Bite-size insights for every verse")
                        .font(themeManager.isSapphire ? SapphireFont.serif(14, semibold: false) : .system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.isSapphire ? themeManager.cardElevated : themeManager.secondaryBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(themeManager.isSapphire ? themeManager.accentColor.opacity(0.45) : Color.orange.opacity(0.4), lineWidth: themeManager.isSapphire ? 1.5 : 2)
                )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
