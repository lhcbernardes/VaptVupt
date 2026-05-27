//
//  RecipeClipView.swift
//  VaptVuptClip
//
//  Detalhe simplificado da receita exibido pelo App Clip. Mostra hero
//  com gradient, tempo/dificuldade/porções, ingredientes e modo de
//  preparo. CTA final convida a abrir / instalar o app completo.
//
//  Esta view é deliberadamente self-contained — não usa ShoppingList,
//  Modo Cozinha, favoritos ou FavoritesStore, que ficam fora do App
//  Clip por limite de 15MB e por escopo.
//

import SwiftUI

struct RecipeClipView: View {
    let recipe: Recipe
    let onOpenFullApp: () -> Void

    private let heroHeight: CGFloat = 240

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                hero
                content
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.background)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: recipe.imageURL)
                .frame(height: heroHeight)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(recipe.subcategories, id: \.self) { sub in
                        TagPill(title: sub.rawValue, tint: sub.group.accentColor)
                    }
                }
                Text(recipe.title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding(Theme.Spacing.md)
        }
        .frame(height: heroHeight)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            quickFacts

            if let description = recipe.description {
                Text(description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }

            if !recipe.dietaryRestrictions.isEmpty {
                dietaryBadges
            }

            ingredientsSection
            stepsSection
            openFullAppButton
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xl)
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

    private var dietaryBadges: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(recipe.dietaryRestrictions, id: \.self) { restriction in
                    TagPill(
                        title: restriction.rawValue,
                        systemIcon: restriction.systemIcon,
                        tint: restriction.accentColor
                    )
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Ingredientes")
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
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Modo de preparo")
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

    private var openFullAppButton: some View {
        Button(action: onOpenFullApp) {
            HStack {
                Image(systemName: "arrow.down.app.fill")
                Text("Abrir no app completo")
                    .font(Theme.Typography.cardTitle)
            }
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
