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

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var selectedTab: Tab = .home
    @State private var isUploadPresented: Bool = false
    @State private var importedRecipe: Recipe? = nil

    enum Tab: Hashable, CaseIterable {
        case home
        case upload
        case settings

        var label: LocalizedStringKey {
            switch self {
            case .home:     "Início"
            case .upload:   "Adicionar"
            case .settings: "Ajustes"
            }
        }

        var icon: String {
            switch self {
            case .home:     "house.fill"
            case .upload:   "plus.circle.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                splitLayout
            } else {
                compactTabs
            }
        }
        .sheet(isPresented: $isUploadPresented) {
            UploadRecipeView(
                viewModel: UploadRecipeViewModel(onSave: { recipe in
                    dashboardViewModel.append(recipe: recipe)
                })
            )
        }
        .sheet(item: $importedRecipe) { recipe in
            ImportRecipePreviewView(recipe: recipe) { confirmed in
                dashboardViewModel.append(recipe: confirmed)
            }
        }
        .onOpenURL { url in
            if let recipe = RecipeShareService.decode(from: url) {
                importedRecipe = recipe
            }
        }
    }

    // MARK: - Compact (iPhone)

    private var compactTabs: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem { Label(Tab.home.label, systemImage: Tab.home.icon) }
                .tag(Tab.home)

            Color.clear
                .tabItem { Label(Tab.upload.label, systemImage: Tab.upload.icon) }
                .tag(Tab.upload)

            SettingsView()
                .tabItem { Label(Tab.settings.label, systemImage: Tab.settings.icon) }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .upload {
                isUploadPresented = true
                selectedTab = .home
            }
        }
    }

    // MARK: - Regular (iPad)

    private var splitLayout: some View {
        NavigationSplitView {
            List {
                Section("Cozinhar") {
                    sidebarRow(.home)
                }
                Section("Ações") {
                    Button {
                        isUploadPresented = true
                    } label: {
                        Label(Tab.upload.label, systemImage: Tab.upload.icon)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                Section("Conta") {
                    sidebarRow(.settings)
                }
            }
            .navigationTitle("VaptVupt")
        } detail: {
            switch selectedTab {
            case .home, .upload:
                DashboardView(viewModel: dashboardViewModel)
            case .settings:
                SettingsView()
            }
        }
    }

    private func sidebarRow(_ tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack {
                Label(tab.label, systemImage: tab.icon)
                Spacer()
                if selectedTab == tab {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootTabView(dashboardViewModel: DashboardViewModel())
        .environment(FavoritesStore())
        .environment(NotificationService())
        .environment(PantryStore())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}
