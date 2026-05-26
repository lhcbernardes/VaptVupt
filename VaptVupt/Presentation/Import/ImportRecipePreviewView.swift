//
//  ImportRecipePreviewView.swift
//  SnapChef
//
//  Sheet apresentada quando o app recebe um link `vaptvupt://import?data=...`.
//  Mostra um preview rápido da receita decodificada e pede confirmação
//  antes de adicionar ao Dashboard — protege o usuário contra adicionar
//  qualquer link sem revisão.
//

import SwiftUI

struct ImportRecipePreviewView: View {
    let recipe: Recipe
    let onImport: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    quickFacts
                    if let description = recipe.description, !description.isEmpty {
                        Text(description)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    ingredientsSection
                    stepsSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Receita Recebida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Descartar", role: .destructive) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Importar") {
                        onImport(recipe)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Receita compartilhada", systemImage: "tray.and.arrow.down.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.Colors.accent)
                .tracking(1)
            Text(recipe.title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.primaryText)

            if !recipe.subcategories.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(recipe.subcategories) { sub in
                        TagPill(title: sub.rawValue, tint: sub.group.accentColor)
                    }
                }
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var quickFacts: some View {
        HStack(spacing: Theme.Spacing.md) {
            factTile(icon: "clock", value: recipe.prepTimeFormatted, label: "preparo")
            factTile(icon: "flame", value: recipe.difficulty.rawValue, label: "dificuldade")
            factTile(icon: "person.2", value: "\(recipe.servings)", label: "porções")
        }
    }

    private func factTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.accent)
            Text(value)
                .font(Theme.Typography.cardTitle)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Ingredientes (\(recipe.ingredients.count))")
                .font(Theme.Typography.sectionTitle)
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                    HStack {
                        Text(ingredient.name)
                            .font(Theme.Typography.body)
                        Spacer()
                        Text(ingredient.formattedQuantity)
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    if index < recipe.ingredients.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Modo de preparo (\(recipe.steps.count) passos)")
                .font(Theme.Typography.sectionTitle)
            VStack(spacing: Theme.Spacing.md) {
                ForEach(recipe.steps) { step in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Text("\(step.sequence)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.Colors.accent))
                        Text(step.instruction)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
