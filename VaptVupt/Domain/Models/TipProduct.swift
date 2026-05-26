//
//  TipProduct.swift
//  SnapChef
//
//  Catálogo estático dos itens de doação ao desenvolvedor (tip jar).
//  Cada item mapeia para um Product ID do StoreKit/App Store Connect
//  (e do arquivo VaptVupt.storekit para testes locais).
//

import Foundation

struct TipProduct: Identifiable, Hashable {

    let id: String
    let emoji: String
    let title: String
    let subtitle: String

    /// Catálogo completo, na ordem em que deve ser exibido.
    static let all: [TipProduct] = [
        TipProduct(
            id: "com.lhcbernardes.vaptvupt.tip.coffee",
            emoji: "☕️",
            title: "Café",
            subtitle: "Um cafezinho pra agradecer."
        ),
        TipProduct(
            id: "com.lhcbernardes.vaptvupt.tip.lunch",
            emoji: "🥪",
            title: "Almoço",
            subtitle: "Um lanche pra ajudar a manter o dev acordado."
        ),
        TipProduct(
            id: "com.lhcbernardes.vaptvupt.tip.dinner",
            emoji: "🍝",
            title: "Jantar",
            subtitle: "Um jantar pra fechar o dia bem."
        ),
        TipProduct(
            id: "com.lhcbernardes.vaptvupt.tip.feast",
            emoji: "🎉",
            title: "Banquete",
            subtitle: "Um banquete pra celebrar este app."
        )
    ]

    static var allIDs: Set<String> { Set(all.map(\.id)) }
}
