//
//  DashboardViewModel.swift
//  SnapChef
//

import Foundation

@Observable
final class DashboardViewModel {

    // MARK: - State

    var timeFilter: PrepTimeFilter = .all
    var searchQuery: String = ""
    var dietaryFilters: Set<DietaryRestriction> = []
    var isPantrySheetPresented: Bool = false
    private(set) var allRecipes: [Recipe]

    // MARK: - Init

    init(recipes: [Recipe] = MockRecipes.all) {
        self.allRecipes = recipes
    }

    // MARK: - Derived

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return switch hour {
        case 5..<12:  "Bom dia"
        case 12..<18: "Boa tarde"
        default:      "Boa noite"
        }
    }

    /// Receitas após aplicar todos os filtros ativos: tempo + restrições
    /// alimentares + busca textual (título, descrição, ingredientes,
    /// subcategorias). A busca é case-insensitive e fuzzy via `contains`.
    var filteredRecipes: [Recipe] {
        allRecipes
            .filter { timeFilter.matches($0) }
            .filter { recipe in
                dietaryFilters.isEmpty ||
                dietaryFilters.isSubset(of: Set(recipe.dietaryRestrictions))
            }
            .filter { recipe in
                let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !q.isEmpty else { return true }
                if recipe.title.lowercased().contains(q) { return true }
                if let description = recipe.description, description.lowercased().contains(q) { return true }
                if recipe.ingredients.contains(where: { $0.name.lowercased().contains(q) }) { return true }
                if recipe.subcategories.contains(where: { $0.rawValue.lowercased().contains(q) }) { return true }
                return false
            }
    }

    var hasActiveFilters: Bool {
        timeFilter != .all || !dietaryFilters.isEmpty || !searchQuery.isEmpty
    }

    func toggleDietary(_ restriction: DietaryRestriction) {
        if dietaryFilters.contains(restriction) {
            dietaryFilters.remove(restriction)
        } else {
            dietaryFilters.insert(restriction)
        }
    }

    func clearAllFilters() {
        timeFilter = .all
        dietaryFilters.removeAll()
        searchQuery = ""
    }

    /// Receita destacada do dia. A escolha é determinística pelo dia do
    /// ano — fica estável durante 24h e troca à meia-noite, criando um
    /// hábito leve de "voltar amanhã pra ver qual será".
    var recipeOfTheDay: Recipe? {
        guard !allRecipes.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return allRecipes[(dayOfYear - 1) % allRecipes.count]
    }

    // MARK: - Actions

    func append(recipe: Recipe) {
        allRecipes.insert(recipe, at: 0)
    }

    /// Sorteia uma receita aleatória respeitando o filtro de tempo.
    func randomPick() -> Recipe? {
        filteredRecipes.randomElement() ?? allRecipes.randomElement()
    }
}
