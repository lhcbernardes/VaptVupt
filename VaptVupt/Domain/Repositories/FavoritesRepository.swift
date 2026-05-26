//
//  FavoritesRepository.swift
//  SnapChef
//
//  Abstração da fonte de favoritos. A implementação local persiste em
//  `UserDefaults`; uma implementação Firebase/Supabase plugaria aqui
//  sem que o `FavoritesStore` precise mudar.
//

import Foundation

/// Contrato síncrono — favoritos são uma coleção pequena que cabe em
/// memória. Para um backend remoto, encapsule o tráfego em um cache
/// local antes de expor pelos métodos `load`/`save`.
protocol FavoritesRepository: AnyObject {
    func loadFavoriteIDs() -> Set<UUID>
    func saveFavoriteIDs(_ ids: Set<UUID>)
}

// MARK: - Local (UserDefaults)

final class LocalFavoritesRepository: FavoritesRepository {

    private let storageKey: String
    private let defaults: UserDefaults

    init(storageKey: String = "snapchef.favorites.v1", defaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.defaults = defaults
    }

    func loadFavoriteIDs() -> Set<UUID> {
        guard
            let data = defaults.data(forKey: storageKey),
            let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data)
        else { return [] }
        return ids
    }

    func saveFavoriteIDs(_ ids: Set<UUID>) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
