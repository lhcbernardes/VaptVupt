//
//  RecipeCategory.swift
//  SnapChef
//
//  Taxonomia de categorias do app. Cada `RecipeSubcategory` pertence
//  exatamente a um `RecipeCategoryGroup`, permitindo navegação hierárquica
//  (Home -> Categoria -> Grid de receitas).
//

import SwiftUI

// MARK: - RecipeCategoryGroup

/// Grupos principais exibidos no Dashboard como cards visuais.
enum RecipeCategoryGroup: String, CaseIterable, Identifiable, Codable, Hashable {
    case meals  = "Refeições"
    case fit    = "Espaço Fit"
    case drinks = "Drinks & Bebidas"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .meals:  "☀️"
        case .fit:    "🌱"
        case .drinks: "🍹"
        }
    }

    var systemIcon: String {
        switch self {
        case .meals:  "sun.max.fill"
        case .fit:    "leaf.fill"
        case .drinks: "wineglass.fill"
        }
    }

    /// Cor de destaque usada nos cards e tags da categoria.
    var accentColor: Color {
        switch self {
        case .meals:  Color(red: 0.95, green: 0.55, blue: 0.20) // âmbar
        case .fit:    Color(red: 0.35, green: 0.65, blue: 0.40) // verde sálvia
        case .drinks: Color(red: 0.85, green: 0.35, blue: 0.55) // rosa berry
        }
    }

    var subtitle: String {
        switch self {
        case .meals:  "Café, almoço, lanche e jantar"
        case .fit:    "Low carb, proteico, sem açúcar"
        case .drinks: "Com e sem álcool"
        }
    }

    var subcategories: [RecipeSubcategory] {
        RecipeSubcategory.allCases.filter { $0.group == self }
    }
}

// MARK: - RecipeSubcategory

/// Subcategorias granulares para classificação fina das receitas.
enum RecipeSubcategory: String, CaseIterable, Identifiable, Codable, Hashable {
    // Refeições
    case breakfast = "Café da Manhã"
    case lunch     = "Almoço"
    case snack     = "Lanche"
    case dinner    = "Jantar"

    // Fit
    case lowCarb   = "Low Carb"
    case protein   = "Proteico"
    case sugarFree = "Sem Açúcar"

    // Bebidas
    case alcoholic    = "Com Álcool"
    case nonAlcoholic = "Sem Álcool"

    var id: String { rawValue }

    var group: RecipeCategoryGroup {
        switch self {
        case .breakfast, .lunch, .snack, .dinner:
            .meals
        case .lowCarb, .protein, .sugarFree:
            .fit
        case .alcoholic, .nonAlcoholic:
            .drinks
        }
    }
}
