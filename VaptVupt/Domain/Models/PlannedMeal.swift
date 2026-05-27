//
//  PlannedMeal.swift
//  SnapChef
//
//  Item do Meal Planner semanal. Cada `PlannedMeal` referencia uma
//  receita do catálogo (pelo `recipeID`), o dia em que será preparada
//  e o slot de refeição (café / almoço / jantar / lanche). Persistido
//  via SwiftData no mesmo container do histórico e das anotações.
//

import Foundation
import SwiftData

@Model
final class PlannedMeal {
    var id: UUID
    var recipeID: UUID
    var recipeTitle: String
    /// Apenas a parte da data (yyyy-MM-dd) interessa — para evitar
    /// agrupamento errado pelo horário, normalizamos no `init`.
    var day: Date
    var slot: String

    init(recipeID: UUID, recipeTitle: String, day: Date, slot: MealSlot) {
        self.id = UUID()
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.day = Calendar.current.startOfDay(for: day)
        self.slot = slot.rawValue
    }

    var mealSlot: MealSlot {
        MealSlot(rawValue: slot) ?? .lunch
    }
}

// MARK: - MealSlot

enum MealSlot: String, CaseIterable, Identifiable, Hashable {
    case breakfast = "Café da manhã"
    case lunch     = "Almoço"
    case snack     = "Lanche"
    case dinner    = "Jantar"

    var id: String { rawValue }

    /// Ordem cronológica do dia — usada para ordenar slots no calendário.
    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .snack:     1
        case .lunch:     2
        case .dinner:    3
        }
    }

    var systemIcon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch:     "sun.max.fill"
        case .snack:     "leaf.fill"
        case .dinner:    "moon.stars.fill"
        }
    }
}
