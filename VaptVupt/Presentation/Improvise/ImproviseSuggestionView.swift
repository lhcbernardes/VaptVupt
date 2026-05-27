//
//  ImproviseSuggestionView.swift
//  SnapChef
//
//  Sheet do "Modo Improviso" — pega os ingredientes da despensa atual e
//  passa para o `RecipeAIService.suggestRecipe(from:)`, que devolve uma
//  receita curta plausível. Usuário pode regenerar até gostar e salvar
//  no Dashboard com um toque.
//

import SwiftUI

struct ImproviseSuggestionView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PantryStore.self) private var pantry

    /// Callback para anexar a receita aceita ao dashboard.
    let onSave: (Recipe) -> Void

    @State private var service = RecipeAIService()
    @State private var suggestion: Recipe? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    if isLoading {
                        loadingState
                    } else if let suggestion {
                        suggestionCard(suggestion)
                    } else if pantry.items.isEmpty {
                        emptyState
                    } else {
                        primeState
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Modo Improviso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .task { await generate() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(Theme.Colors.accent)
                Text("Sugestão a partir da despensa")
                    .font(Theme.Typography.cardTitle)
            }
            Text("Usamos o que você tem em casa para improvisar uma receita rápida.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var loadingState: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
            Text("Improvisando uma receita…")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Despensa vazia")
                .font(Theme.Typography.cardTitle)
            Text("Adicione alguns ingredientes na Despensa pra eu poder sugerir.")
                .font(Theme.Typography.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
    }

    private var primeState: some View {
        Button {
            Task { await generate() }
        } label: {
            Label("Improvisar receita", systemImage: "wand.and.stars")
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                        .fill(Theme.Colors.accent)
                )
        }
        .buttonStyle(.plain)
    }

    private func suggestionCard(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(recipe.title)
                .font(Theme.Typography.title)

            HStack(spacing: Theme.Spacing.md) {
                Label(recipe.prepTimeFormatted, systemImage: "clock")
                Label("\(recipe.servings) porções", systemImage: "person.2")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.secondaryText)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Ingredientes")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
                ForEach(recipe.ingredients) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text(ingredient.formattedQuantity)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    .font(Theme.Typography.body)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Modo de preparo")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
                ForEach(recipe.steps) { step in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Text("\(step.sequence).")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.Colors.accent)
                        Text(step.instruction)
                            .font(Theme.Typography.body)
                    }
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    Task { await generate() }
                } label: {
                    Label("Outra sugestão", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                                .fill(Theme.Colors.accent.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    onSave(recipe)
                    dismiss()
                } label: {
                    Label("Salvar", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                                .fill(Theme.Colors.accent)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    // MARK: - Actions

    private func generate() async {
        guard !pantry.items.isEmpty else { return }
        isLoading = true
        let names = pantry.items.map(\.name).shuffled()
        suggestion = await service.suggestRecipe(from: Array(names.prefix(8)))
        isLoading = false
    }
}
