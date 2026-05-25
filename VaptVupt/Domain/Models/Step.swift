//
//  Step.swift
//  SnapChef
//

import Foundation

/// Passo individual no preparo de uma receita.
struct Step: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var sequence: Int
    var instruction: String
    var imageURL: URL?
}
