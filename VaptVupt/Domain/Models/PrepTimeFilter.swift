//
//  PrepTimeFilter.swift
//  SnapChef
//
//  Filtros rápidos por tempo de preparo. A proposta do SnapChef é
//  receita fácil; tempo é a métrica de decisão dominante.
//

import Foundation

enum PrepTimeFilter: String, CaseIterable, Identifiable, Hashable {
    case all      = "Todos"
    case under15  = "≤ 15 min"
    case under30  = "≤ 30 min"
    case under60  = "≤ 1h"

    var id: String { rawValue }

    func matches(_ recipe: Recipe) -> Bool {
        switch self {
        case .all:     true
        case .under15: recipe.prepTime <= 15
        case .under30: recipe.prepTime <= 30
        case .under60: recipe.prepTime <= 60
        }
    }
}
