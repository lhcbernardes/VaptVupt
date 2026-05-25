//
//  FavoritesStore.swift
//  SnapChef
//
//  Estado global de favoritos. Persiste IDs em `UserDefaults` para o MVP
//  (substituível por Firebase/Supabase em produção).
//

import Foundation

@Observable
final class FavoritesStore {

    private(set) var favoriteIDs: Set<UUID> = []

    private let storageKey = "snapchef.favorites.v1"

    init() { load() }

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
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data)
        else { return }
        favoriteIDs = ids
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favoriteIDs) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
