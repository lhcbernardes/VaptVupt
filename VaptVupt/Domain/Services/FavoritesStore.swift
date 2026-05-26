//
//  FavoritesStore.swift
//  SnapChef
//
//  Estado global de favoritos. A persistência é delegada a um
//  `FavoritesRepository` injetado — por padrão o `LocalFavoritesRepository`,
//  mas em produção pode ser substituído por uma implementação remota
//  sem mudar o restante do app.
//

import Foundation

@Observable
final class FavoritesStore {

    private(set) var favoriteIDs: Set<UUID> = []

    private let repository: FavoritesRepository

    init(repository: FavoritesRepository = LocalFavoritesRepository()) {
        self.repository = repository
        self.favoriteIDs = repository.loadFavoriteIDs()
    }

    // MARK: - Queries

    func isFavorite(_ recipe: Recipe) -> Bool {
        favoriteIDs.contains(recipe.id)
    }

    /// Filtra uma coleção mantendo apenas receitas marcadas como favoritas.
    func favoriteRecipes(in source: [Recipe]) -> [Recipe] {
        source.filter { favoriteIDs.contains($0.id) }
    }

    // MARK: - Mutations

    func toggle(_ recipe: Recipe) {
        if favoriteIDs.contains(recipe.id) {
            favoriteIDs.remove(recipe.id)
        } else {
            favoriteIDs.insert(recipe.id)
        }
        repository.saveFavoriteIDs(favoriteIDs)
    }
}
