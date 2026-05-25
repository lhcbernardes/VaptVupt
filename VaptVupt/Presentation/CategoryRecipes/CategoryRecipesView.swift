//
//  CategoryRecipesView.swift
//  SnapChef
//
//  Grid de receitas dentro de uma categoria com:
//   - Filtros por subcategoria
//   - Filtros rápidos por tempo (≤15/30/60 min)
//   - Botão "Surpreenda-me" (random pick)
//

import SwiftUI

struct CategoryRecipesView: View {
    @Bindable var viewModel: CategoryRecipesViewModel

    /// Callback do "Surpreenda-me" para empurrar a receita sorteada na
    /// NavigationStack do pai.
    let onPushRecipe: (Recipe) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                subcategoryFilters
                timeFilters
                surpriseCard
                grid
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .navigationTitle(viewModel.group.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(viewModel.group.emoji)
                .font(.system(size: 44))
            Text(viewModel.group.rawValue)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.primaryText)
            Text(viewModel.group.subtitle)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var subcategoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                TagPill(
                    title: "Todas",
                    tint: viewModel.group.accentColor,
                    isSelected: viewModel.selectedSubcategory == nil,
                    isInteractive: true,
                    action: { viewModel.selectedSubcategory = nil }
                )
                ForEach(viewModel.subcategories) { sub in
                    TagPill(
                        title: sub.rawValue,
                        tint: viewModel.group.accentColor,
                        isSelected: viewModel.selectedSubcategory == sub,
                        isInteractive: true,
                        action: {
                            viewModel.selectedSubcategory =
                                viewModel.selectedSubcategory == sub ? nil : sub
                        }
                    )
                }
            }
        }
    }

    private var timeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PrepTimeFilter.allCases) { filter in
                    TagPill(
                        title: filter.rawValue,
                        systemIcon: filter == .all ? nil : "clock",
                        tint: viewModel.group.accentColor,
                        isSelected: viewModel.timeFilter == filter,
                        isInteractive: true,
                        action: { viewModel.timeFilter = filter }
                    )
                }
            }
        }
    }

    private var surpriseCard: some View {
        Button {
            if let pick = viewModel.randomPick() {
                onPushRecipe(pick)
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "dice.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(viewModel.group.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(viewModel.group.accentColor.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Surpreenda-me")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text(surpriseSubtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(viewModel.group.accentColor)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(viewModel.group.accentColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.recipes.isEmpty)
        .opacity(viewModel.recipes.isEmpty ? 0.4 : 1)
    }

    private var surpriseSubtitle: String {
        var parts: [String] = []
        if let sub = viewModel.selectedSubcategory { parts.append(sub.rawValue) }
        if viewModel.timeFilter != .all { parts.append(viewModel.timeFilter.rawValue) }
        if parts.isEmpty { return "Sortear uma receita da categoria" }
        return "Sortear receita (" + parts.joined(separator: " · ") + ")"
    }

    private var grid: some View {
        Group {
            if viewModel.recipes.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: Theme.Spacing.md) {
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Nenhuma receita aqui ainda.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }
}
