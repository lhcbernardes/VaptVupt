//
//  VaptVuptClipApp.swift
//  VaptVuptClip
//
//  Entry-point do App Clip. Escuta links de invocação (Universal Link
//  `https://vaptvupt.app/recipe?data=…` ou esquema custom
//  `vaptvupt://import?data=…`) e renderiza uma versão simplificada do
//  detalhe da receita, sem favoritos, Modo Cozinha ou upload.
//
//  Importante:
//   • Este arquivo PERTENCE ao target App Clip. NÃO marque como
//     membro do target principal.
//   • Os tipos `Recipe`, `Ingredient`, `Step`, `RecipeCategory`,
//     `DietaryRestriction`, `RecipeShareService`, `Theme`,
//     `RemoteImage` e `TagPill` precisam ter Target Membership ATIVADO
//     também para este target (File Inspector → Target Membership) —
//     instruções em README.md.
//

import SwiftUI

@main
struct VaptVuptClipApp: App {

    @State private var receivedRecipe: Recipe? = nil
    @State private var showEmptyState: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if let recipe = receivedRecipe {
                    RecipeClipView(recipe: recipe, onOpenFullApp: openFullApp)
                } else if showEmptyState {
                    emptyState
                }
            }
            .tint(Theme.Colors.accent)
            // Esquema custom — `vaptvupt://import?data=…`
            .onOpenURL { url in
                handle(url: url)
            }
            // Universal Link — `https://vaptvupt.app/recipe?data=…`
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL {
                    handle(url: url)
                }
            }
        }
    }

    // MARK: - URL handling

    private func handle(url: URL) {
        if let recipe = RecipeShareService.decode(from: url) {
            receivedRecipe = recipe
            showEmptyState = false
            return
        }
        // Universal Link no formato `https://<domain>/recipe?data=…` —
        // converte para o scheme custom e decodifica.
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let dataValue = components.queryItems?.first(where: { $0.name == "data" })?.value {
            var rewritten = URLComponents()
            rewritten.scheme = RecipeShareService.urlScheme
            rewritten.host = RecipeShareService.importHost
            rewritten.queryItems = [URLQueryItem(name: RecipeShareService.dataQueryItem, value: dataValue)]
            if let alt = rewritten.url, let recipe = RecipeShareService.decode(from: alt) {
                receivedRecipe = recipe
                showEmptyState = false
            }
        }
    }

    /// Tenta abrir a receita no app completo (se instalado). Se não estiver,
    /// o iOS leva o usuário à App Store via flow nativo do App Clip Card.
    private func openFullApp() {
        guard
            let recipe = receivedRecipe,
            let url = RecipeShareService.encode(recipe)
        else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.accent)
            Text("VaptVupt App Clip")
                .font(Theme.Typography.title)
            Text("Abra um link de receita compartilhada para visualizar aqui.")
                .font(Theme.Typography.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }
}
