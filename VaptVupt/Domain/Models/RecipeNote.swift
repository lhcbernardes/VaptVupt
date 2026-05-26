//
//  RecipeNote.swift
//  SnapChef
//
//  Anotação pessoal do usuário sobre uma receita — variações, ajustes
//  de sal, comentários após cozinhar. Persistida via SwiftData no mesmo
//  container do histórico de preparos.
//

import Foundation
import SwiftData

@Model
final class RecipeNote {
    @Attribute(.unique) var recipeID: UUID
    var text: String
    var updatedAt: Date

    init(recipeID: UUID, text: String, updatedAt: Date = .now) {
        self.recipeID = recipeID
        self.text = text
        self.updatedAt = updatedAt
    }
}
