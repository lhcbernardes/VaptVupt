//
//  RecipeCard.swift
//  SnapChef
//
//  Card de receita utilizado no Grid (LazyVGrid) da Home e da tela de
//  categoria. Mostra foto, título, tempo de preparo, dificuldade e
//  permite favoritar diretamente pelo ícone de coração.
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe

    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Imagem
            RemoteImage(url: recipe.imageURL)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    difficultyTag
                        .padding(Theme.Spacing.sm)
                }
                .overlay(alignment: .topLeading) {
                    favoriteButton
                        .padding(Theme.Spacing.sm)
                }

            // Conteúdo textual
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(recipe.title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock")
                    Text(recipe.prepTimeFormatted)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    // MARK: - Subviews

    private var difficultyTag: some View {
        HStack(spacing: 4) {
            Text(recipe.difficulty.indicator)
            Text(recipe.difficulty.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var favoriteButton: some View {
        let isFav = favorites.isFavorite(recipe)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favorites.toggle(recipe)
            }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.callout.weight(.semibold))
                .foregroundStyle(isFav ? .red : .white)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .symbolEffect(.bounce, value: isFav)
        }
        .buttonStyle(.plain)
    }
}
