//
//  RecipeDetailView.swift
//  SnapChef
//
//  Tela de detalhe com:
//   - Imagem de topo com efeito de parallax no scroll
//   - Seletor [-] porções [+] com recálculo reativo dos ingredientes
//   - Toolbar com favorito (coração) e compartilhar (share sheet)
//   - Botões "Lista de Compras" e "Iniciar Modo Cozinha"
//

import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Bindable var viewModel: RecipeDetailViewModel
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.modelContext) private var modelContext

    @Query private var allNotes: [RecipeNote]
    @State private var noteDraft: String = ""

    private let heroHeight: CGFloat = 320

    private var currentNote: RecipeNote? {
        allNotes.first(where: { $0.recipeID == viewModel.recipe.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                hero
                content
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Theme.Spacing.sm) {
                    favoriteToolbarButton
                    ShareLink(item: viewModel.shareText) {
                        toolbarIcon("square.and.arrow.up")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isCookingModeOpen) {
            CookingModeView(recipe: viewModel.recipe)
        }
        .sheet(isPresented: $viewModel.isShoppingListOpen) {
            ShoppingListView(
                recipeTitle: viewModel.recipe.title,
                ingredients: viewModel.scaledIngredients
            )
        }
    }

    // MARK: - Toolbar helpers

    private var favoriteToolbarButton: some View {
        let isFav = favorites.isFavorite(viewModel.recipe)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favorites.toggle(viewModel.recipe)
            }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.callout.weight(.semibold))
                .foregroundStyle(isFav ? .red : Theme.Colors.primaryText)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .symbolEffect(.bounce, value: isFav)
        }
        .sensoryFeedback(.success, trigger: isFav) { oldValue, newValue in
            newValue && !oldValue
        }
    }

    private func toolbarIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Theme.Colors.primaryText)
            .frame(width: 32, height: 32)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityLabel("Compartilhar receita")
    }

    // MARK: - Hero (parallax)

    private var hero: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .global).minY
            let isPulling = offset > 0
            let height = heroHeight + (isPulling ? offset : 0)
            let translation = isPulling ? -offset : 0

            RemoteImage(url: viewModel.recipe.imageURL)
                .frame(width: proxy.size.width, height: max(height, 0))
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(viewModel.recipe.subcategories) { sub in
                                TagPill(
                                    title: sub.rawValue,
                                    tint: sub.group.accentColor
                                )
                            }
                        }
                        Text(viewModel.recipe.title)
                            .font(Theme.Typography.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding(Theme.Spacing.md)
                }
                .offset(y: translation)
        }
        .frame(height: heroHeight)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            quickFacts
            if let description = viewModel.recipe.description {
                Text(description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            if !viewModel.recipe.dietaryRestrictions.isEmpty {
                dietaryBadges
            }
            servingsSelector
            ingredientsSection
            stepsSection
            personalNoteSection
            actionButtons
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xl)
        .onAppear { noteDraft = currentNote?.text ?? "" }
    }

    // MARK: - Dietary badges

    private var dietaryBadges: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Adequado para")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.recipe.dietaryRestrictions, id: \.self) { restriction in
                        TagPill(
                            title: restriction.rawValue,
                            systemIcon: restriction.systemIcon,
                            tint: restriction.accentColor
                        )
                    }
                }
            }
        }
    }

    // MARK: - Personal note

    private var personalNoteSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label("Minha anotação", systemImage: "note.text")
                    .font(Theme.Typography.sectionTitle)
                Spacer()
                if !noteDraft.isEmpty {
                    Button("Salvar") { saveNote() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            TextEditor(text: $noteDraft)
                .frame(minHeight: 100)
                .padding(Theme.Spacing.sm)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .fill(Theme.Colors.surface)
                )
                .overlay(alignment: .topLeading) {
                    if noteDraft.isEmpty {
                        Text("Variações, ajustes de sal, dicas que você descobriu cozinhando…")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.secondaryText.opacity(0.7))
                            .padding(Theme.Spacing.md)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func saveNote() {
        let trimmed = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = currentNote {
            if trimmed.isEmpty {
                modelContext.delete(existing)
            } else {
                existing.text = trimmed
                existing.updatedAt = .now
            }
        } else if !trimmed.isEmpty {
            modelContext.insert(RecipeNote(recipeID: viewModel.recipe.id, text: trimmed))
        }
        try? modelContext.save()
    }

    private var quickFacts: some View {
        HStack(spacing: Theme.Spacing.md) {
            factTile(icon: "clock", value: viewModel.recipe.prepTimeFormatted, label: "preparo")
            factTile(icon: "flame", value: viewModel.recipe.difficulty.rawValue, label: "dificuldade")
            factTile(icon: "person.2", value: "\(viewModel.servings)", label: "porções")
        }
    }

    private func factTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.accent)
            Text(value)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var servingsSelector: some View {
        HStack {
            Text("Porções")
                .font(Theme.Typography.sectionTitle)
            Spacer()
            HStack(spacing: Theme.Spacing.md) {
                stepperButton(systemName: "minus", label: "Diminuir porções", action: viewModel.decreaseServings)
                Text("\(viewModel.servings)")
                    .font(Theme.Typography.cardTitle)
                    .monospacedDigit()
                    .frame(minWidth: 24)
                    .accessibilityLabel("\(viewModel.servings) porções")
                stepperButton(systemName: "plus", label: "Aumentar porções", action: viewModel.increaseServings)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule().fill(Theme.Colors.surface)
            )
        }
    }

    private func stepperButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.callout.weight(.bold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Colors.accent.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Ingredientes")
                    .font(Theme.Typography.sectionTitle)
                Spacer()
                unitSystemToggle
            }
            VStack(spacing: 0) {
                ForEach(Array(viewModel.scaledIngredients.enumerated()), id: \.element.id) { index, ingredient in
                    HStack {
                        Text(ingredient.name)
                            .font(Theme.Typography.body)
                        Spacer()
                        Text(ingredient.formatted(in: viewModel.unitSystem))
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .contentTransition(.numericText())
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    if index < viewModel.scaledIngredients.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private var unitSystemToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleUnitSystem()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.unitSystem.systemIcon)
                Text(viewModel.unitSystem.rawValue)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .foregroundStyle(Theme.Colors.accent)
            .background(Capsule().fill(Theme.Colors.accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: viewModel.unitSystem)
        .accessibilityLabel("Sistema de unidades")
        .accessibilityValue(viewModel.unitSystem.rawValue)
        .accessibilityHint("Toque para alternar entre métrico e imperial.")
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Modo de preparo")
                .font(Theme.Typography.sectionTitle)
            VStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.recipe.steps) { step in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Text("\(step.sequence)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.Colors.accent))
                        Text(step.instruction)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: viewModel.openShoppingList) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("Gerar Lista de Compras")
                        .font(Theme.Typography.cardTitle)
                }
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                        .fill(Theme.Colors.accent.opacity(0.12))
                )
            }
            .buttonStyle(.plain)

            Button(action: viewModel.startCookingMode) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("Iniciar Modo Cozinha")
                        .font(Theme.Typography.cardTitle)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                        .fill(Theme.Colors.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(viewModel: RecipeDetailViewModel(recipe: MockRecipes.fitChicken))
            .environment(FavoritesStore())
    }
}
