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
    // CloudKit não suporta `@Attribute(.unique)`. A unicidade por
    // `recipeID` é garantida em aplicação (a view busca/atualiza pelo
    // primeiro match e nunca insere duplicatas).
    var recipeID: UUID
    var text: String
    var updatedAt: Date

    init(recipeID: UUID, text: String, updatedAt: Date = .now) {
        self.recipeID = recipeID
        self.text = text
        self.updatedAt = updatedAt
    }
}
