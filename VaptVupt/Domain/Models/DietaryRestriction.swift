//
//  DietaryRestriction.swift
//  SnapChef
//
//  Restrições alimentares que podem ser anexadas a uma `Recipe` e usadas
//  como filtros granulares no Dashboard.
//
//  Conceitualmente os casos se dividem em dois grupos:
//   1. Filosofia alimentar: `vegetarian`, `vegan`
//   2. Restrições por ingrediente: `glutenFree`, `lactoseFree`, `sugarFree`
//
//  Decisões de design:
//   • `rawValue` em inglês (chave estável de serialização). Labels em
//     português ficam em `DietaryRestriction+UI.swift`.
//   • `init(from:)` customizado aceita tanto o rawValue novo quanto os
//     rótulos antigos em português, mantendo decodificação compatível
//     com receitas geradas antes da renomeação (links `vaptvupt://import`,
//     respostas atuais do backend, etc.).
//   • `Foundation` apenas — nenhuma dependência de SwiftUI no domínio.
//

import Foundation

enum DietaryRestriction: String, CaseIterable, Identifiable, Codable, Hashable {
    // Filosofia
    case vegetarian = "vegetarian"
    case vegan      = "vegan"
    // Restrições por ingrediente
    case glutenFree  = "gluten_free"
    case lactoseFree = "lactose_free"
    case sugarFree   = "sugar_free"

    var id: Self { self }

    // MARK: - Backwards-compatible decoding

    /// Tenta resolver uma `DietaryRestriction` a partir do rawValue novo
    /// (inglês) ou de qualquer rótulo legado em português. Retorna `nil`
    /// se a string não corresponde a nenhum caso conhecido.
    static func fromAnyRawValue(_ raw: String) -> Self? {
        if let direct = Self(rawValue: raw) { return direct }
        switch raw {
        case "Vegetariano":  return .vegetarian
        case "Vegano":       return .vegan
        case "Sem Glúten":   return .glutenFree
        case "Sem Lactose":  return .lactoseFree
        case "Sem Açúcar":   return .sugarFree
        default:             return nil
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let resolved = Self.fromAnyRawValue(raw) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Valor desconhecido para DietaryRestriction: \(raw)"
            )
        }
        self = resolved
    }
}
