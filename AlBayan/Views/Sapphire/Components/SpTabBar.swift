//
//  SpTabBar.swift
//  AlBayan
//
//  Floating Royal Sapphire tab bar — shown only when the Sapphire theme is active.
//

import SwiftUI

struct SpTabBar: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var selection: Int

    private struct Item { let title: String; let icon: String; let tag: Int }
    private let items = [
        Item(title: "Today",    icon: "sun.max",        tag: 0),
        Item(title: "Quran",    icon: "book",           tag: 1),
        Item(title: "Explore",  icon: "sparkles",       tag: 2),
        Item(title: "Progress", icon: "chart.bar.fill", tag: 3),
        Item(title: "Journey",  icon: "map",            tag: 4),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                let active = selection == item.tag
                Button {
                    selection = item.tag
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon).font(.system(size: 18, weight: .regular))
                        Text(item.title).font(.system(size: 10, weight: .semibold)).tracking(0.4)
                        Circle().fill(active ? themeManager.accentBright : Color.clear).frame(width: 4, height: 4)
                    }
                    .foregroundColor(active ? themeManager.accentBright : themeManager.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "#0A1124").opacity(0.74))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(themeManager.strokeColor, lineWidth: 1)
        )
        .shadow(color: themeManager.cardShadowElevated, radius: 18, x: 0, y: 14)
        .padding(.horizontal, 18)
        .padding(.bottom, 30)
    }
}
