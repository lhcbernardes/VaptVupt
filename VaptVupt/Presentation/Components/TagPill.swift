//
//  TagPill.swift
//  SnapChef
//
//  Pílula de seleção/exibição usada para categorias, dificuldade e tags.
//  Suporta dois modos: somente leitura (display) e seletor (selectable).
//

import SwiftUI

struct TagPill: View {
    let title: String
    var systemIcon: String? = nil
    var tint: Color = Theme.Colors.accent
    var isSelected: Bool = true
    var isInteractive: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if isInteractive {
                Button(action: { action?() }) {
                    pillContent
                }
                .buttonStyle(.plain)
            } else {
                pillContent
            }
        }
    }

    private var pillContent: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let systemIcon {
                Image(systemName: systemIcon)
                    .font(.caption.weight(.semibold))
            }
            Text(title)
                .font(Theme.Typography.caption)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Capsule()
                .fill(isSelected ? tint.opacity(0.18) : Theme.Colors.surface)
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? tint.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .foregroundStyle(isSelected ? tint : Theme.Colors.secondaryText)
    }
}
