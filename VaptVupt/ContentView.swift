//
//  ContentView.swift
//  SnapChef
//
//  Container raiz com TabView. Abas:
//   - Início (Dashboard)
//   - Adicionar (abre Upload Inteligente em sheet)
//   - Ajustes (aparência, notificações, histórico)
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Bindable var dashboardViewModel: DashboardViewModel

    @State private var selectedTab: Tab = .home
    @State private var isUploadPresented: Bool = false

    enum Tab: Hashable {
        case home
        case upload
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }
                .tag(Tab.home)

            // Aba central — abre upload via sheet, mantendo a tab no Home.
            Color.clear
                .tabItem {
                    Label("Adicionar", systemImage: "plus.circle.fill")
                }
                .tag(Tab.upload)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .upload {
                isUploadPresented = true
                selectedTab = .home
            }
        }
        .sheet(isPresented: $isUploadPresented) {
            UploadRecipeView(
                viewModel: UploadRecipeViewModel(onSave: { recipe in
                    dashboardViewModel.append(recipe: recipe)
                })
            )
        }
    }
}

#Preview {
    RootTabView(dashboardViewModel: DashboardViewModel())
        .environment(FavoritesStore())
        .environment(NotificationService())
        .environment(PantryStore())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}
