//
//  TipJarView.swift
//  SnapChef
//
//  Sheet de doações ao desenvolvedor. Lista os produtos consumíveis
//  carregados pelo `TipJarService` e permite que o usuário escolha
//  livremente um valor de apoio.
//

import StoreKit
import SwiftUI

struct TipJarView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var service = TipJarService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    content
                    externalLinksSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Apoiar o dev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task { await service.loadProductsIfNeeded() }
            .alert(
                "Obrigado! ❤️",
                isPresented: thanksAlertBinding,
                actions: {
                    Button("De nada") { service.resetPurchaseState() }
                },
                message: {
                    Text("Seu apoio mantém o VaptVupt vivo e em evolução.")
                }
            )
            .alert(
                "Algo deu errado",
                isPresented: errorAlertBinding,
                actions: {
                    Button("OK") { service.resetPurchaseState() }
                },
                message: {
                    Text(errorMessage ?? "Tente novamente em instantes.")
                }
            )
            .sensoryFeedback(.success, trigger: successTrigger)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Curtindo o app?")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("VaptVupt é mantido por um desenvolvedor independente. Se ele te ajudou na cozinha, um cafezinho de incentivo cai super bem.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch service.loadState {
        case .idle, .loading:
            loadingState
        case .failed(let message):
            failureState(message: message)
        case .loaded:
            productsList
        }
    }

    private var loadingState: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
            Text("Carregando opções...")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private func failureState(message: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title)
            Text(message)
                .font(Theme.Typography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.secondaryText)
            Button("Tentar de novo") {
                Task { await service.loadProductsIfNeeded() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private var productsList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(TipProduct.all) { tip in
                productRow(for: tip)
            }
        }
    }

    @ViewBuilder
    private func productRow(for tip: TipProduct) -> some View {
        let product = service.products[tip.id]
        let priceLabel = product?.displayPrice ?? "—"
        let isPurchasing = isPurchasing(tip.id)
        let isUnavailable = product == nil

        Button {
            Task { await service.purchase(tip) }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Text(tip.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(Theme.Colors.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.title)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text(tip.subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                } else {
                    Text(priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            Capsule().fill(isUnavailable ? Color.gray : Theme.Colors.accent)
                        )
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing || isUnavailable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tip.title), \(priceLabel)")
        .accessibilityHint(isUnavailable ? "Produto indisponível." : "Toque duplo para apoiar o desenvolvedor com \(tip.title.lowercased()).")
    }

    // MARK: - External links (Ko-fi / Buy Me a Coffee)

    private var externalLinksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Outras formas de apoiar")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .textCase(.uppercase)

            HStack(spacing: Theme.Spacing.sm) {
                externalLink(
                    title: "Ko-fi",
                    subtitle: "Doação única",
                    systemIcon: "cup.and.saucer.fill",
                    url: URL(string: "https://ko-fi.com/leandrobernardes")!
                )
                externalLink(
                    title: "Buy Me a Coffee",
                    subtitle: "PayPal & cartão",
                    systemIcon: "heart.fill",
                    url: URL(string: "https://buymeacoffee.com/leandrobernardes")!
                )
            }
        }
    }

    private func externalLink(title: String, subtitle: String, systemIcon: String, url: URL) -> some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Image(systemName: systemIcon)
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.accent)
                Text(title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func isPurchasing(_ id: String) -> Bool {
        if case .purchasing(let purchasingID) = service.purchaseState, purchasingID == id {
            return true
        }
        return false
    }

    private var thanksAlertBinding: Binding<Bool> {
        Binding(
            get: { if case .success = service.purchaseState { return true } else { return false } },
            set: { newValue in if !newValue { service.resetPurchaseState() } }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = service.purchaseState { return true } else { return false } },
            set: { newValue in if !newValue { service.resetPurchaseState() } }
        )
    }

    private var errorMessage: String? {
        if case .failed(let message) = service.purchaseState { return message }
        return nil
    }

    /// Inteiro crescente que dispara háptico apenas quando o estado vira `.success`.
    private var successTrigger: Int {
        if case .success = service.purchaseState { return 1 } else { return 0 }
    }
}

#Preview {
    TipJarView()
}
