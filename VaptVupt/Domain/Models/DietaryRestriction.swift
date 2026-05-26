//
//  DietaryRestriction.swift
//  SnapChef
//
//  Restrições alimentares que podem ser anexadas a uma `Recipe` e usadas
//  como filtros granulares no Dashboard. Codable para sobreviver a uma
//  serialização futura via API.
//

import SwiftUI

enum DietaryRestriction: String, CaseIterable, Identifiable, Codable, Hashable {
    case vegetarian = "Vegetariano"
    case vegan      = "Vegano"
    case glutenFree = "Sem Glúten"
    case lactoseFree = "Sem Lactose"
    case sugarFree  = "Sem Açúcar"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .vegetarian:  "leaf.fill"
        case .vegan:       "leaf.arrow.triangle.circlepath"
        case .glutenFree:  "circle.slash"
        case .lactoseFree: "drop.fill"
        case .sugarFree:   "bolt.slash.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .vegetarian:  Color(red: 0.35, green: 0.65, blue: 0.40)
        case .vegan:       Color(red: 0.25, green: 0.70, blue: 0.45)
        case .glutenFree:  Color(red: 0.85, green: 0.55, blue: 0.20)
        case .lactoseFree: Color(red: 0.30, green: 0.60, blue: 0.85)
        case .sugarFree:   Color(red: 0.70, green: 0.30, blue: 0.60)
        }
    }
}
