//
//  CategoryRecipesViewModel.swift
//  SnapChef
//

import Foundation

@Observable
final class CategoryRecipesViewModel {

    // MARK: - State

    let group: RecipeCategoryGroup
    private let allRecipes: [Recipe]

    var selectedSubcategory: RecipeSubcategory?
    var timeFilter: PrepTimeFilter = .all

    // MARK: - Init

    init(
        group: RecipeCategoryGroup,
        recipes: [Recipe],
        selectedSubcategory: RecipeSubcategory? = nil
    ) {
        self.group = group
        self.allRecipes = recipes
        self.selectedSubcategory = selectedSubcategory
    }

    // MARK: - Derived

    var subcategories: [RecipeSubcategory] {
        group.subcategories
    }

    /// Receitas filtradas pelo grupo + (opcional) subcategoria + filtro de tempo.
    var recipes: [Recipe] {
        let inGroup = allRecipes.filter { $0.categoryGroups.contains(group) }
        let bySub: [Recipe]
        if let sub = selectedSubcategory {
            bySub = inGroup.filter { $0.subcategories.contains(sub) }
        } else {
            bySub = inGroup
        }
        return bySub.filter { timeFilter.matches($0) }
    }

    // MARK: - Actions

    func randomPick() -> Recipe? { recipes.randomElement() }
}
