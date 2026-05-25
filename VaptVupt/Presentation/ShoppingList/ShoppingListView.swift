//
//  ShoppingListView.swift
//  SnapChef
//
//  Lista de compras gerada automaticamente a partir dos ingredientes da
//  receita (já ajustados pelas porções atuais). Permite marcar/desmarcar
//  itens e compartilhar a lista via share sheet do iOS.
//

import SwiftUI

struct ShoppingListView: View {
    let recipeTitle: String
    let ingredients: [Ingredient]

    @Environment(\.dismiss) private var dismiss
    @State private var checkedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header
                    list
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Lista de Compras")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(recipeTitle)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("\(checkedIDs.count) de \(ingredients.count) itens")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
            ProgressView(value: progress)
                .tint(Theme.Colors.accent)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var list: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(ingredients) { ingredient in
                row(for: ingredient)
            }
        }
    }

    private func row(for ingredient: Ingredient) -> some View {
        let isChecked = checkedIDs.contains(ingredient.id)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isChecked {
                    checkedIDs.remove(ingredient.id)
                } else {
                    checkedIDs.insert(ingredient.id)
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? Theme.Colors.accent : Theme.Colors.secondaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .strikethrough(isChecked, color: Theme.Colors.secondaryText)
                    Text(ingredient.formattedQuantity)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
            .opacity(isChecked ? 0.65 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived

    private var progress: Double {
        guard !ingredients.isEmpty else { return 0 }
        return Double(checkedIDs.count) / Double(ingredients.count)
    }

    private var shareText: String {
        var lines = ["🛒 Lista de Compras — \(recipeTitle)", ""]
        for ingredient in ingredients {
            lines.append("• \(ingredient.name) — \(ingredient.formattedQuantity)")
        }
        return lines.joined(separator: "\n")
    }
}

#Preview {
    ShoppingListView(
        recipeTitle: MockRecipes.fitChicken.title,
        ingredients: MockRecipes.fitChicken.ingredients
    )
}
