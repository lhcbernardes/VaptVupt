//
//  TipJarService.swift
//  SnapChef
//
//  Serviço de doações ao desenvolvedor (tip jar) usando StoreKit 2.
//  Carrega os produtos consumíveis declarados em `TipProduct.all`,
//  realiza a compra, e finaliza a transação imediatamente — como são
//  consumíveis, não há nada para restaurar nem rastrear depois.
//
//  Pré-requisitos:
//   • Em desenvolvimento: configure o esquema do app em "Edit Scheme →
//     Run → Options → StoreKit Configuration" para usar
//     `VaptVupt.storekit` (assim os produtos aparecem no simulador).
//   • Em produção: cadastre os mesmos product IDs no App Store Connect
//     como In-App Purchases do tipo Consumable.
//

import Foundation
import StoreKit

@Observable
@MainActor
final class TipJarService {

    // MARK: - State

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum PurchaseState: Equatable {
        case idle
        case purchasing(productID: String)
        case success(productID: String)
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var purchaseState: PurchaseState = .idle

    /// Produtos do StoreKit indexados pelo `TipProduct.id` para casar
    /// preço/título já localizados pela loja com o catálogo estático.
    private(set) var products: [String: Product] = [:]

    private var updatesTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Escuta transações disparadas fora do app (ex: Family Sharing).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case let .verified(transaction) = update {
                    await transaction.finish()
                    await self?.markSuccess(productID: transaction.productID)
                }
            }
        }
    }

    /// O `Task<Void, Never>` em `updatesTask` usa `[weak self]`, então
    /// finaliza naturalmente quando a instância é desalocada. Sem deinit
    /// porque acesso a propriedade MainActor dentro de deinit (nonisolated)
    /// é proibido em Swift 6.

    // MARK: - Load

    func loadProductsIfNeeded() async {
        switch loadState {
        case .loaded, .loading: return
        default: break
        }
        loadState = .loading

        do {
            let storeProducts = try await Product.products(for: TipProduct.allIDs)
            var indexed: [String: Product] = [:]
            for product in storeProducts {
                indexed[product.id] = product
            }
            products = indexed
            loadState = .loaded
        } catch {
            loadState = .failed("Não foi possível carregar os produtos.")
        }
    }

    // MARK: - Purchase

    func purchase(_ tip: TipProduct) async {
        guard let product = products[tip.id] else {
            purchaseState = .failed("Produto indisponível no momento.")
            return
        }

        purchaseState = .purchasing(productID: tip.id)

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case let .verified(transaction) = verification {
                    await transaction.finish()
                    purchaseState = .success(productID: tip.id)
                } else {
                    purchaseState = .failed("A transação não pôde ser verificada.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .failed("Compra pendente — aguarde aprovação.")
            @unknown default:
                purchaseState = .failed("Estado de compra desconhecido.")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }

    // MARK: - Internal

    private func markSuccess(productID: String) {
        purchaseState = .success(productID: productID)
    }
}
