//
//  PantryStore.swift
//  SnapChef
//
//  Estado global da Despensa Inteligente. A persistência é delegada a
//  um `PantryRepository` injetado (padrão: `LocalPantryRepository`,
//  baseado em `UserDefaults`). Trocar por uma implementação remota
//  (Firebase/Supabase) é uma única troca de injeção em `VaptVuptApp`.
//

import Foundation

@Observable
final class PantryStore {

    // MARK: - State

    private(set) var items: [PantryItem] = []

    private let repository: PantryRepository

    /// Sugestões rápidas exibidas no topo da PantryView para acelerar a
    /// curadoria inicial. Escolhidos por serem itens "âncora" no preparo
    /// de quase todas as receitas básicas brasileiras.
    static let quickSuggestions: [String] = [
        "Ovo", "Leite", "Arroz", "Feijão", "Frango", "Macarrão",
        "Tomate", "Cebola", "Alho", "Azeite", "Sal", "Açúcar",
        "Farinha", "Manteiga", "Queijo", "Limão", "Banana", "Aveia"
    ]

    // MARK: - Init

    init(repository: PantryRepository = LocalPantryRepository()) {
        self.repository = repository
        self.items = repository.loadItems()
    }

    // MARK: - Mutations

    func add(_ rawName: String) {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !contains(trimmed) else { return }
        items.append(PantryItem(name: trimmed))
        repository.saveItems(items)
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        repository.saveItems(items)
    }

    func clear() {
        items.removeAll()
        repository.saveItems(items)
    }

    // MARK: - Queries

    func contains(_ name: String) -> Bool {
        let normalized = name.normalizedForPantry
        return items.contains { $0.name.normalizedForPantry == normalized }
    }

    /// Calcula quantos ingredientes da receita o usuário tem disponíveis
    /// na Despensa. Match é bidirecional + fuzzy (contains nos dois lados)
    /// para que "ovo" case com "ovos" e "leite" com "leite integral".
    func matchScore(for recipe: Recipe) -> PantryMatch {
        let pantry = items.map { $0.name.normalizedForPantry }
        let ingredients = recipe.ingredients.map { $0.name.normalizedForPantry }

        let matched = ingredients.filter { ingredient in
            pantry.contains { p in
                ingredient == p || ingredient.contains(p) || p.contains(ingredient)
            }
        }

        return PantryMatch(matchedCount: matched.count, totalCount: ingredients.count)
    }

    /// Receitas que o usuário "pode fazer agora", ordenadas pelo melhor match.
    /// `minPercentage` controla quão tolerante é o filtro (default 70%).
    func cookableRecipes(in source: [Recipe], minPercentage: Double = 0.7) -> [Recipe] {
        source
            .compactMap { recipe -> (Recipe, PantryMatch)? in
                let match = matchScore(for: recipe)
                guard match.percentage >= minPercentage else { return nil }
                return (recipe, match)
            }
            .sorted { $0.1.percentage > $1.1.percentage }
            .map(\.0)
    }
}

// MARK: - PantryMatch

struct PantryMatch: Hashable {
    let matchedCount: Int
    let totalCount: Int

    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(matchedCount) / Double(totalCount)
    }

    var canCookNow: Bool { matchedCount == totalCount && totalCount > 0 }

    /// Label amigável para exibir nos cards e badges.
    var label: String {
        guard totalCount > 0 else { return "" }
        if matchedCount == totalCount { return "Tem tudo!" }
        return "Tem \(matchedCount)/\(totalCount)"
    }
}
