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
    @AppStorage("vaptvupt.hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    /// Container SwiftData usado para o histórico de preparos
    /// (`CookedRecipeEntry`), anotações pessoais (`RecipeNote`) e o meal
    /// planner (`PlannedMeal`). Pronto para CloudKit Sync — basta marcar
    /// a capability iCloud + CloudKit no target e o ModelConfiguration
    /// abaixo passa a sincronizar automaticamente entre dispositivos.
    ///
    /// **Pré-requisitos no Xcode UI** para habilitar o sync:
    ///   1. Signing & Capabilities → + Capability → iCloud.
    ///   2. Marque "CloudKit" e crie/escolha um container
    ///      (ex.: `iCloud.com.lhcbernardes.vaptvupt`).
    ///   3. Signing & Capabilities → + Capability → Background Modes →
    ///      marque "Remote notifications".
    ///   4. Modelos `@Model` precisam ter todas as propriedades opcionais
    ///      OU com valor padrão — o que já é o caso aqui.
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            CookedRecipeEntry.self,
            RecipeNote.self,
            PlannedMeal.self
        ])
        // .automatic = SwiftData decide entre sync remoto e local conforme
        // a presença da capability iCloud. Sem a capability, comporta-se
        // exatamente como o container local atual.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Falha ao iniciar o ModelContainer do SwiftData: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView(dashboardViewModel: dashboardViewModel)
                if !hasSeenOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(favoritesStore)
            .environment(notificationService)
            .environment(pantryStore)
            .modelContainer(modelContainer)
            .tint(Theme.Colors.accent)
            .preferredColorScheme(appearance.colorScheme)
        }
    }
}
