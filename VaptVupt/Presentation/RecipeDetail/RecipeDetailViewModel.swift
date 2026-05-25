//
//  RecipeDetailViewModel.swift
//  SnapChef
//
//  Lida com o estado dinâmico da tela de detalhes:
//   - controle de porções (com recálculo reativo dos ingredientes)
//   - apresentação do Modo Cozinha e da Lista de Compras
//   - texto formatado para compartilhamento
//

import Foundation

@Observable
final class RecipeDetailViewModel {

    // MARK: - State

    let recipe: Recipe
    var servings: Int
    var isCookingModeOpen: Bool = false
    var isShoppingListOpen: Bool = false

    // MARK: - Init

    init(recipe: Recipe) {
        self.recipe = recipe
        self.servings = recipe.servings
    }

    // MARK: - Derived

    /// Fator de escala em relação à receita original.
    var scaleFactor: Double {
        guard recipe.servings > 0 else { return 1 }
        return Double(servings) / Double(recipe.servings)
    }

    /// Ingredientes recalculados conforme o número de porções atual.
    var scaledIngredients: [Ingredient] {
        recipe.ingredients.map { $0.scaled(by: scaleFactor) }
    }

    /// Texto formatado pronto para compartilhamento via iOS share sheet.
    var shareText: String {
        var lines: [String] = [recipe.title]
        if let description = recipe.description, !description.isEmpty {
            lines.append("")
            lines.append(description)
        }
        lines.append("")
        lines.append("⏱ \(recipe.prepTimeFormatted)  •  🍽 \(servings) porções")
        lines.append("")
        lines.append("Ingredientes:")
        for ingredient in scaledIngredients {
            lines.append("• \(ingredient.name) — \(ingredient.formattedQuantity)")
        }
        lines.append("")
        lines.append("Modo de preparo:")
        for step in recipe.steps {
            lines.append("\(step.sequence). \(step.instruction)")
        }
        lines.append("")
        lines.append("— Compartilhado via SnapChef")
        return lines.joined(separator: "\n")
    }

    // MARK: - Actions

    func increaseServings() { servings = min(servings + 1, 99) }
    func decreaseServings() { servings = max(servings - 1, 1) }

    func startCookingMode()  { isCookingModeOpen = true }
    func openShoppingList()  { isShoppingListOpen = true }
}
