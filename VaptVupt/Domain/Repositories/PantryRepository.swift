//
//  PantryRepository.swift
//  SnapChef
//
//  Abstração da fonte da Despensa. A implementação local persiste em
//  `UserDefaults`. Para sincronizar entre dispositivos, troque por uma
//  implementação Firebase/Supabase mantendo o mesmo contrato.
//

import Foundation

protocol PantryRepository: AnyObject {
    func loadItems() -> [PantryItem]
    func saveItems(_ items: [PantryItem])
}

// MARK: - Local (UserDefaults)

final class LocalPantryRepository: PantryRepository {

    private let storageKey: String
    private let defaults: UserDefaults

    init(storageKey: String = "snapchef.pantry.v1", defaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.defaults = defaults
    }

    func loadItems() -> [PantryItem] {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([PantryItem].self, from: data)
        else { return [] }
        return decoded
    }

    func saveItems(_ items: [PantryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
