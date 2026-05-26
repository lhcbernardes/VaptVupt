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

// MARK: - UnitSystem

/// Sistema de medidas para apresentação dos ingredientes. A conversão
/// é puramente cosmética — o `Ingredient` continua armazenando valores
/// no sistema métrico (g/ml).
enum UnitSystem: String, CaseIterable, Identifiable, Hashable {
    case metric   = "Métrico"
    case imperial = "Imperial"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .metric:   "scalemass"
        case .imperial: "ruler"
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

    /// Representação amigável para exibição na UI no sistema métrico.
    /// Exemplos: "200 g", "1,5 xícara", "a gosto".
    var formattedQuantity: String {
        formatted(in: .metric)
    }

    /// Devolve a string formatada no sistema escolhido. Em `.imperial`,
    /// converte gramas → onças, kg → lb, ml → fl oz, litro → quart. Para
    /// unidades sem equivalência clara (colher, xícara, pitada, etc.) o
    /// valor é mantido como está, já que a maioria das receitas em
    /// inglês também usa "tbsp / cup / pinch".
    func formatted(in system: UnitSystem) -> String {
        if unit == .toTaste { return unit.rawValue }

        // 1) Aplica conversão se imperial.
        let (displayValue, displayUnitLabel) = convertedForDisplay(in: system)

        // 2) Formata número (inteiro / 1 casa decimal).
        let isInteger = displayValue == floor(displayValue)
        let qtyString: String
        if isInteger {
            qtyString = "\(Int(displayValue))"
        } else {
            qtyString = String(format: "%.1f", displayValue).replacingOccurrences(of: ".", with: ",")
        }

        return "\(qtyString) \(displayUnitLabel)"
    }

    private func convertedForDisplay(in system: UnitSystem) -> (Double, String) {
        let baseLabel = pluralizedUnitLabel(for: unit, quantity: quantity)

        guard system == .imperial else {
            return (quantity, baseLabel)
        }

        switch unit {
        case .gram:
            // 1 oz ≈ 28.3495 g
            let oz = quantity / 28.3495
            return (oz.rounded(toPlaces: 2), oz == 1 ? "oz" : "oz")
        case .kilogram:
            // 1 lb ≈ 0.453592 kg → kg / 0.453592 = lb
            let lb = quantity / 0.453592
            return (lb.rounded(toPlaces: 2), lb == 1 ? "lb" : "lb")
        case .milliliter:
            // 1 fl oz ≈ 29.5735 ml
            let flOz = quantity / 29.5735
            return (flOz.rounded(toPlaces: 2), "fl oz")
        case .liter:
            // 1 quart ≈ 0.946353 L
            let qt = quantity / 0.946353
            return (qt.rounded(toPlaces: 2), qt == 1 ? "qt" : "qt")
        default:
            // Demais unidades (colher, xícara, pitada) já são compatíveis
            // entre culturas — mantemos rótulo localizado.
            return (quantity, baseLabel)
        }
    }

    private func pluralizedUnitLabel(for unit: IngredientUnit, quantity: Double) -> String {
        guard unit.allowsPlural, quantity > 1 else { return unit.rawValue }
        switch unit {
        case .cup:      return "xícaras"
        case .spoon:    return "colheres"
        case .teaspoon: return "colheres de chá"
        case .unit:     return "unidades"
        case .pinch:    return "pitadas"
        default:        return unit.rawValue
        }
    }
}

// MARK: - Double helpers

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
