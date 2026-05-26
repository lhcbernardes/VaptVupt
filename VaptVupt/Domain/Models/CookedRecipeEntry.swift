//
//  CookedRecipeEntry.swift
//  SnapChef
//
//  Registro persistido via SwiftData de cada vez que o usuário inicia
//  o Modo Cozinha. Alimenta a seção "Recentemente cozinhados" da Home
//  e — opcionalmente — guarda uma foto do prato pronto.
//

import Foundation
import SwiftData

@Model
final class CookedRecipeEntry {
    var id: UUID
    var recipeID: UUID
    var title: String
    var cookedAt: Date
    /// Foto do prato pronto, capturada ao concluir o Modo Cozinha.
    /// Armazenada como JPEG comprimido para limitar o tamanho do banco.
    var photoData: Data?

    init(recipeID: UUID, title: String, cookedAt: Date = .now, photoData: Data? = nil) {
        self.id = UUID()
        self.recipeID = recipeID
        self.title = title
        self.cookedAt = cookedAt
        self.photoData = photoData
    }
}
