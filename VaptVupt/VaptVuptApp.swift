//
//  VaptVuptApp.swift
//  SnapChef
//
//  Entry-point do app. Mantém estados globais (Dashboard, Favoritos,
//  Notificações) vivos durante toda a sessão e instala o `ModelContainer`
//  do SwiftData para o histórico de preparos.
//

import SwiftUI
import SwiftData

@main
struct VaptVuptApp: App {

    @State private var dashboardViewModel = DashboardViewModel()
    @State private var favoritesStore = FavoritesStore()
    @State private var notificationService = NotificationService()
    @State private var pantryStore = PantryStore()

    @AppStorage("snapchef.appearance") private var appearance: AppearanceMode = .system

    /// Container SwiftData usado para o histórico de preparos
    /// (`CookedRecipeEntry`). Os erros são fatais aqui porque o app não
    /// é capaz de funcionar de forma consistente sem persistência.
    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: CookedRecipeEntry.self)
        } catch {
            fatalError("Falha ao iniciar o ModelContainer do SwiftData: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView(dashboardViewModel: dashboardViewModel)
                .environment(favoritesStore)
                .environment(notificationService)
                .environment(pantryStore)
                .modelContainer(modelContainer)
                .tint(Theme.Colors.accent)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
