//
//  DietaryRestriction+UI.swift
//  SnapChef
//
//  Camada de UI da `DietaryRestriction`. Mantém o modelo de domínio livre
//  de SwiftUI; quem renderiza importa `SwiftUI` e vê os campos visuais.
//

import SwiftUI

extension DietaryRestriction {

    /// Rótulo exibido na UI. Mantido em pt-BR por enquanto. Para suportar
    /// localização real, trocar por `LocalizedStringResource` (iOS 16+) ou
    /// `LocalizedStringKey` e mover as strings para `Localizable.xcstrings`.
    var displayName: String {
        switch self {
        case .vegetarian:  "Vegetariano"
        case .vegan:       "Vegano"
        case .glutenFree:  "Sem Glúten"
        case .lactoseFree: "Sem Lactose"
        case .sugarFree:   "Sem Açúcar"
        }
    }

    var systemIcon: String {
        switch self {
        case .vegetarian:  "leaf.fill"
        case .vegan:       "leaf.arrow.triangle.circlepath"
        case .glutenFree:  "circle.slash"
        case .lactoseFree: "drop.fill"
        case .sugarFree:   "bolt.slash.fill"
        }
    }

    /// Cor usada nos badges, filtros e selos. Renomeada de `accentColor`
    /// para evitar colisão com `View.accentColor` do SwiftUI.
    var tint: Color {
        switch self {
        case .vegetarian:  Color(red: 0.35, green: 0.65, blue: 0.40)
        case .vegan:       Color(red: 0.25, green: 0.70, blue: 0.45)
        case .glutenFree:  Color(red: 0.85, green: 0.55, blue: 0.20)
        case .lactoseFree: Color(red: 0.30, green: 0.60, blue: 0.85)
        case .sugarFree:   Color(red: 0.70, green: 0.30, blue: 0.60)
        }
    }
}
