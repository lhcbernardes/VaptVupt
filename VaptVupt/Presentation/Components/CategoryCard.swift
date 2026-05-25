//
//  CategoryCard.swift
//  SnapChef
//
//  Card visual grande para as 3 categorias principais exibido no
//  carrossel horizontal do Dashboard.
//

import SwiftUI

struct CategoryCard: View {
    let group: RecipeCategoryGroup

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(group.emoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(group.rawValue)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text(group.subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: Theme.Spacing.xs) {
                Text("Ver todas")
                    .font(Theme.Typography.caption)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(group.accentColor)
        }
        .padding(Theme.Spacing.md)
        .frame(width: 200, height: 200, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(group.accentColor.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .stroke(group.accentColor.opacity(0.18), lineWidth: 1)
        )
    }
}
