//
//  Recipe.swift
//  SnapChef
//
//  Entidade central de domínio. Imutável (struct) e Codable, pronta
//  para serialização/deserialização em integrações futuras (Firebase,
//  Supabase ou retorno de LLM).
//

import Foundation

// MARK: - RecipeDifficulty

enum RecipeDifficulty: String, CaseIterable, Identifiable, Codable, Hashable {
    case easy   = "Fácil"
    case medium = "Médio"
    case hard   = "Difícil"

    var id: String { rawValue }

    var indicator: String {
        switch self {
        case .easy:   "🟢"
        case .medium: "🟡"
        case .hard:   "🔴"
        }
    }
}

// MARK: - Recipe

struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    /// Tempo de preparo em minutos.
    var prepTime: Int
    /// Porções padrão produzidas pela receita.
    var servings: Int
    var imageURL: URL?
    var subcategories: [RecipeSubcategory]
    var difficulty: RecipeDifficulty
    var ingredients: [Ingredient]
    var steps: [Step]
    /// Restrições alimentares atendidas pela receita (vegetariano, sem
    /// glúten, etc.). Opcional na decode para receitas antigas que ainda
    /// não foram migradas no payload.
    var dietaryRestrictions: [DietaryRestriction] = []

    /// Grupos de categoria derivados das subcategorias atribuídas à receita.
    var categoryGroups: Set<RecipeCategoryGroup> {
        Set(subcategories.map(\.group))
    }

    /// Formatação amigável do tempo de preparo (ex.: "45 min", "1h 20min").
    var prepTimeFormatted: String {
        if prepTime < 60 {
            return "\(prepTime) min"
        }
        let hours = prepTime / 60
        let minutes = prepTime % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)min"
    }
}
