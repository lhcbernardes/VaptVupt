//
//  CookedRecipeEntry.swift
//  SnapChef
//
//  Registro persistido via SwiftData de cada vez que o usuário inicia
//  o Modo Cozinha. Alimenta a seção "Recentemente cozinhados" da Home.
//

import Foundation
import SwiftData

@Model
final class CookedRecipeEntry {
    var id: UUID
    var recipeID: UUID
    var title: String
    var cookedAt: Date

    init(recipeID: UUID, title: String, cookedAt: Date = .now) {
        self.id = UUID()
        self.recipeID = recipeID
        self.title = title
        self.cookedAt = cookedAt
    }
}
