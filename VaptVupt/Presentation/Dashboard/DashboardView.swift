//
//  DashboardView.swift
//  SnapChef
//
//  Home reorganizada em torno de 3 hooks: Receita do Dia, Despensa
//  Inteligente e Surpreenda-me. A busca textual foi removida porque
//  a Despensa entrega muito mais valor pro DNA do app.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    @Environment(FavoritesStore.self) private var favorites
    @Environment(PantryStore.self) private var pantry
    @Query(sort: \CookedRecipeEntry.cookedAt, order: .reverse) private var history: [CookedRecipeEntry]

    @State private var path = NavigationPath()
    @Namespace private var heroNamespace

    private let gridColumns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    recipeOfTheDayHero
                    pantryCTA
                    plannerAndImproviseRow
                    surpriseCard
                    timeFilterRow
                    dietaryFilterRow
                    categoryCarousel
                    cookableSection
                    favoritesSection
                    recentlyCookedSection
                    featuredGrid
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Buscar receita ou ingrediente"
            )
            .navigationDestination(for: RecipeCategoryGroup.self) { group in
                CategoryRecipesView(
                    viewModel: CategoryRecipesViewModel(
                        group: group,
                        recipes: viewModel.allRecipes
                    ),
                    onPushRecipe: { recipe in path.append(recipe) }
                )
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(viewModel: RecipeDetailViewModel(recipe: recipe))
                    .navigationTransition(.zoom(sourceID: recipe.id, in: heroNamespace))
            }
            .sheet(isPresented: $viewModel.isPantrySheetPresented) {
                PantryView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $viewModel.isMealPlannerPresented) {
                MealPlannerView(allRecipes: viewModel.allRecipes)
            }
            .sheet(isPresented: $viewModel.isImprovisePresented) {
                ImproviseSuggestionView { recipe in
                    viewModel.append(recipe: recipe)
                }
                .environment(pantry)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(viewModel.greeting)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("O que vai cozinhar hoje?")
                .font(Theme.Typography.display)
                .foregroundStyle(Theme.Colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Recipe of the day

    @ViewBuilder
    private var recipeOfTheDayHero: some View {
        if let recipe = viewModel.recipeOfTheDay {
            Button {
                path.append(recipe)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: recipe.imageURL)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.65)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
                        )

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                            Text("RECEITA DO DIA")
                                .font(.caption.weight(.bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.ultraThinMaterial))

                        Text(recipe.title)
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.white)

                        HStack(spacing: Theme.Spacing.md) {
                            Label(recipe.prepTimeFormatted, systemImage: "clock")
                            Label(recipe.difficulty.rawValue, systemImage: "flame")
                        }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Receita do dia: \(recipe.title)")
            .accessibilityHint("Abre os detalhes da receita.")
        }
    }

    // MARK: - Pantry CTA

    private var pantryCTA: some View {
        Button {
            viewModel.isPantrySheetPresented = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "refrigerator.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Minha Despensa")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text(pantryCTASubtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                Spacer()
                Image(systemName: pantry.items.isEmpty ? "plus" : "pencil")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Colors.accent.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Minha Despensa, \(pantryCTASubtitle)")
        .accessibilityHint("Abre a tela da despensa.")
    }

    private var pantryCTASubtitle: String {
        let count = pantry.items.count
        switch count {
        case 0:  return "Adicione o que tem em casa pra ver sugestões"
        case 1:  return "1 ingrediente cadastrado"
        default: return "\(count) ingredientes cadastrados"
        }
    }

    // MARK: - Planner & Improvise row

    private var plannerAndImproviseRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            shortcutCard(
                title: "Cardápio da semana",
                subtitle: "Planejar refeições",
                icon: "calendar",
                tint: Theme.Colors.accent
            ) { viewModel.isMealPlannerPresented = true }

            shortcutCard(
                title: "Modo improviso",
                subtitle: "Sugerir da despensa",
                icon: "wand.and.stars",
                tint: Color(red: 0.85, green: 0.35, blue: 0.55)
            ) { viewModel.isImprovisePresented = true }
        }
    }

    private func shortcutCard(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(1)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    // MARK: - Surprise card

    private var surpriseCard: some View {
        Button {
            if let pick = viewModel.randomPick() {
                path.append(pick)
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 44, height: 44)
                    Image(systemName: "dice.fill")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Surpreenda-me")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(.white)
                    Text("Sortear uma receita do acervo")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Surpreenda-me")
        .accessibilityHint("Sorteia uma receita aleatória do acervo.")
    }

    // MARK: - Time filter

    private var timeFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PrepTimeFilter.allCases) { filter in
                    TagPill(
                        title: filter.rawValue,
                        systemIcon: filter == .all ? nil : "clock",
                        tint: Theme.Colors.accent,
                        isSelected: viewModel.timeFilter == filter,
                        isInteractive: true,
                        action: { viewModel.timeFilter = filter }
                    )
                }
            }
        }
    }

    // MARK: - Dietary filters

    private var dietaryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(DietaryRestriction.allCases) { restriction in
                    TagPill(
                        title: restriction.rawValue,
                        systemIcon: restriction.systemIcon,
                        tint: restriction.accentColor,
                        isSelected: viewModel.dietaryFilters.contains(restriction),
                        isInteractive: true,
                        action: { viewModel.toggleDietary(restriction) }
                    )
                }
                if viewModel.hasActiveFilters {
                    Button {
                        viewModel.clearAllFilters()
                    } label: {
                        Label("Limpar", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Category carousel

    private var categoryCarousel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Categorias")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(RecipeCategoryGroup.allCases) { group in
                        NavigationLink(value: group) {
                            CategoryCard(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Pantry matches ("Pronto pra fazer")

    @ViewBuilder
    private var cookableSection: some View {
        let cookable = pantry.cookableRecipes(in: viewModel.allRecipes)
        if !cookable.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.xs) {
                    sectionHeader(title: "Pronto pra fazer")
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(cookable) { recipe in
                            NavigationLink(value: recipe) {
                                pantryMatchCard(for: recipe)
                                    .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func pantryMatchCard(for recipe: Recipe) -> some View {
        let match = pantry.matchScore(for: recipe)
        return ZStack(alignment: .topLeading) {
            RecipeCard(recipe: recipe)
                .frame(width: 220)

            HStack(spacing: 4) {
                Image(systemName: match.canCookNow ? "checkmark.seal.fill" : "leaf.fill")
                    .font(.caption2.weight(.bold))
                Text(match.label)
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(Capsule().fill(match.canCookNow ? .green : Theme.Colors.accent))
            .padding(Theme.Spacing.md)
        }
    }

    // MARK: - Favorites

    @ViewBuilder
    private var favoritesSection: some View {
        let favoriteRecipes = favorites.favoriteRecipes(in: viewModel.allRecipes)
        if !favoriteRecipes.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    sectionHeader(title: "Seus Favoritos")
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(favoriteRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCard(recipe: recipe)
                                    .frame(width: 220)
                                    .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recently cooked

    @ViewBuilder
    private var recentlyCookedSection: some View {
        let recent = recentRecipes
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    sectionHeader(title: "Você cozinhou recentemente")
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Theme.Colors.accent)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(recent) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCard(recipe: recipe)
                                    .frame(width: 220)
                                    .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Featured grid

    private var featuredGrid: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Todas as receitas")

            if viewModel.filteredRecipes.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: Theme.Spacing.md) {
                    ForEach(viewModel.filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCard(recipe: recipe)
                                .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Nenhuma receita nesse filtro de tempo.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(Theme.Typography.sectionTitle)
            .foregroundStyle(Theme.Colors.primaryText)
    }

    // MARK: - Helpers

    private var recentRecipes: [Recipe] {
        var seen = Set<UUID>()
        var result: [Recipe] = []
        for entry in history {
            guard !seen.contains(entry.recipeID),
                  let recipe = viewModel.allRecipes.first(where: { $0.id == entry.recipeID })
            else { continue }
            seen.insert(entry.recipeID)
            result.append(recipe)
            if result.count >= 6 { break }
        }
        return result
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel())
        .environment(FavoritesStore())
        .environment(PantryStore())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}
