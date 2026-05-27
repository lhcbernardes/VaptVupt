//
//  MealPlannerView.swift
//  SnapChef
//
//  Calendário semanal de refeições. Cada dia tem quatro slots (café,
//  lanche, almoço, jantar) onde o usuário pode arrastar receitas do
//  catálogo. A semana atual fica padrão; usuário pode navegar pra trás
//  e pra frente. Botão flutuante agrega ingredientes de todas as
//  refeições planejadas e abre a `ShoppingListView`.
//

import SwiftData
import SwiftUI

struct MealPlannerView: View {
    let allRecipes: [Recipe]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allPlanned: [PlannedMeal]

    @State private var anchorDate: Date = .now
    @State private var isCatalogPresented: Bool = false
    @State private var slotPickerTarget: SlotTarget? = nil
    @State private var isShoppingListPresented: Bool = false

    private struct SlotTarget: Identifiable, Hashable {
        let id = UUID()
        let day: Date
        let slot: MealSlot
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    weekSwitcher
                    weekGrid
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Cardápio da semana")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShoppingListPresented = true
                    } label: {
                        Label("Lista", systemImage: "cart.fill")
                    }
                    .disabled(planned.isEmpty)
                }
            }
            .sheet(item: $slotPickerTarget) { target in
                RecipePickerSheet(recipes: allRecipes) { picked in
                    add(picked, to: target)
                    slotPickerTarget = nil
                }
            }
            .sheet(isPresented: $isShoppingListPresented) {
                ShoppingListView(
                    recipeTitle: "Cardápio da semana",
                    ingredients: aggregatedIngredients
                )
            }
        }
    }

    // MARK: - Week switcher

    private var weekSwitcher: some View {
        HStack {
            Button {
                anchorDate = Calendar.current.date(byAdding: .day, value: -7, to: anchorDate) ?? anchorDate
            } label: {
                Image(systemName: "chevron.left")
                    .padding(Theme.Spacing.md)
                    .background(Circle().fill(Theme.Colors.surface))
            }
            .buttonStyle(.plain)

            Spacer()
            VStack(spacing: 2) {
                Text("Semana de")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Text(weekTitle)
                    .font(Theme.Typography.cardTitle)
            }
            Spacer()

            Button {
                anchorDate = Calendar.current.date(byAdding: .day, value: 7, to: anchorDate) ?? anchorDate
            } label: {
                Image(systemName: "chevron.right")
                    .padding(Theme.Spacing.md)
                    .background(Circle().fill(Theme.Colors.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        let start = weekDays.first ?? anchorDate
        let end = weekDays.last ?? anchorDate
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    // MARK: - Grid

    private var weekGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(weekDays, id: \.self) { day in
                dayCard(for: day)
            }
        }
    }

    private func dayCard(for day: Date) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(dayLabel(for: day))
                    .font(Theme.Typography.sectionTitle)
                Spacer()
                if Calendar.current.isDateInToday(day) {
                    Text("Hoje")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.Colors.accent))
                }
            }

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(MealSlot.allCases.sorted { $0.sortOrder < $1.sortOrder }) { slot in
                    slotRow(for: day, slot: slot)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private func slotRow(for day: Date, slot: MealSlot) -> some View {
        let item = mealAt(day: day, slot: slot)
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: slot.systemIcon)
                .font(.callout)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.rawValue)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Text(item?.recipeTitle ?? "Toque para escolher")
                    .font(Theme.Typography.body)
                    .foregroundStyle(item == nil ? Theme.Colors.secondaryText : Theme.Colors.primaryText)
                    .lineLimit(1)
            }

            Spacer()

            if let item {
                Button {
                    modelContext.delete(item)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            slotPickerTarget = SlotTarget(day: day, slot: slot)
        }
    }

    // MARK: - Helpers

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: anchorDate)?.start ?? anchorDate
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: date).capitalized
    }

    private func mealAt(day: Date, slot: MealSlot) -> PlannedMeal? {
        let normalized = Calendar.current.startOfDay(for: day)
        return planned.first { $0.day == normalized && $0.slot == slot.rawValue }
    }

    private var planned: [PlannedMeal] {
        allPlanned
    }

    private var weekPlanned: [PlannedMeal] {
        let days = Set(weekDays.map { Calendar.current.startOfDay(for: $0) })
        return planned.filter { days.contains($0.day) }
    }

    private var aggregatedIngredients: [Ingredient] {
        // Para cada `PlannedMeal`, pega a receita correspondente do catálogo
        // e somamos quantidades de ingredientes de mesmo nome+unidade.
        var bucket: [String: Ingredient] = [:]
        for meal in weekPlanned {
            guard let recipe = allRecipes.first(where: { $0.id == meal.recipeID }) else { continue }
            for ing in recipe.ingredients {
                let key = ing.name.lowercased() + "|" + ing.unit.rawValue
                if var existing = bucket[key] {
                    existing.quantity += ing.quantity
                    bucket[key] = existing
                } else {
                    bucket[key] = ing
                }
            }
        }
        return Array(bucket.values).sorted { $0.name < $1.name }
    }

    private func add(_ recipe: Recipe, to target: SlotTarget) {
        // Substitui caso já exista uma refeição naquele slot.
        if let existing = mealAt(day: target.day, slot: target.slot) {
            modelContext.delete(existing)
        }
        let meal = PlannedMeal(
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            day: target.day,
            slot: target.slot
        )
        modelContext.insert(meal)
        try? modelContext.save()
    }
}

// MARK: - Recipe picker sheet

private struct RecipePickerSheet: View {
    let recipes: [Recipe]
    let onPick: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            List(filtered) { recipe in
                Button {
                    onPick(recipe)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.title)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.primaryText)
                            Text(recipe.prepTimeFormatted)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Escolher receita")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Buscar receita")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private var filtered: [Recipe] {
        let q = search.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return recipes }
        return recipes.filter { $0.title.lowercased().contains(q) }
    }
}
