//
//  Ingredient.swift
//  SnapChef
//

import Foundation

// MARK: - IngredientUnit

/// Unidades de medida suportadas pelos ingredientes.
enum IngredientUnit: String, CaseIterable, Identifiable, Codable, Hashable {
    case gram      = "g"
    case kilogram  = "kg"
    case milliliter = "ml"
    case liter     = "l"
    case cup       = "xícara"
    case spoon     = "colher"
    case teaspoon  = "colher de chá"
    case unit      = "unidade"
    case pinch     = "pitada"
    case toTaste   = "a gosto"

    var id: String { rawValue }

    /// Define se a unidade comporta pluralização (ex.: 2 colheres).
    var allowsPlural: Bool {
        switch self {
        case .cup, .spoon, .teaspoon, .unit, .pinch: true
        default: false
        }
    }
}

// MARK: - Ingredient

struct Ingredient: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: IngredientUnit

    /// Retorna uma cópia do ingrediente com a quantidade multiplicada pelo fator
    /// informado. Usado para recalcular as quantidades quando o usuário altera
    /// o número de porções na tela de detalhes.
    func scaled(by factor: Double) -> Ingredient {
        var copy = self
        copy.quantity = (quantity * factor).rounded(toPlaces: 2)
        return copy
    }

    /// Representação amigável para exibição na UI.
    /// Exemplos: "200 g", "1,5 xícara", "a gosto".
    var formattedQuantity: String {
        if unit == .toTaste { return unit.rawValue }

        let isInteger = quantity == floor(quantity)
        let qtyString: String
        if isInteger {
            qtyString = "\(Int(quantity))"
        } else {
            qtyString = String(format: "%.1f", quantity).replacingOccurrences(of: ".", with: ",")
        }

        let unitString: String = {
            guard unit.allowsPlural, quantity > 1 else { return unit.rawValue }
            // Pluralização simples em português.
            switch unit {
            case .cup:      return "xícaras"
            case .spoon:    return "colheres"
            case .teaspoon: return "colheres de chá"
            case .unit:     return "unidades"
            case .pinch:    return "pitadas"
            default:        return unit.rawValue
            }
        }()

        return "\(qtyString) \(unitString)"
    }
}

// MARK: - Double helpers

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
