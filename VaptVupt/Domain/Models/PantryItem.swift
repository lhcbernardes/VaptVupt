//
//  PantryItem.swift
//  SnapChef
//
//  Item da Despensa Inteligente — algo que o usuário tem em casa e que
//  pode ser cruzado com a lista de ingredientes das receitas.
//

import Foundation

struct PantryItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var addedAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.addedAt = .now
    }
}

// MARK: - Normalization

extension String {
    /// Normalização agressiva usada nos matches da Despensa.
    /// Remove acentos, baixa caixa e poda espaços, para que "Frango" case
    /// com "frango", "Frangos" e "FRÂNGO".
    var normalizedForPantry: String {
        self.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
