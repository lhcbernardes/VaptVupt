//
//  RecipeOfTheDayWidget.swift
//  VaptVuptWidget
//
//  Widget de Homescreen com a "Receita do Dia". A escolha é determinística
//  pelo dia do ano (mesma lógica do `DashboardViewModel`), então a timeline
//  pode ser refrescada uma única vez por dia à meia-noite.
//
//  Configurações necessárias:
//   • Adicionar `MockRecipes.swift`, `Recipe.swift`, `Ingredient.swift`,
//     `Step.swift`, `RecipeCategory.swift` ao Target Membership do widget
//     (são acessados aqui).
//   • Para um futuro Widget que mostre FAVORITOS, será necessário um
//     App Group entitlement + mover `UserDefaults` para o suite do grupo
//     para que app e widget compartilhem o mesmo storage.
//

import SwiftUI
import WidgetKit

// MARK: - Entry

struct RecipeOfTheDayEntry: TimelineEntry {
    let date: Date
    let recipe: Recipe?
}

// MARK: - Provider

struct RecipeOfTheDayProvider: TimelineProvider {

    func placeholder(in context: Context) -> RecipeOfTheDayEntry {
        RecipeOfTheDayEntry(date: Date(), recipe: MockRecipes.all.first)
    }

    func getSnapshot(in context: Context, completion: @escaping (RecipeOfTheDayEntry) -> Void) {
        completion(RecipeOfTheDayEntry(date: Date(), recipe: pickRecipe(for: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecipeOfTheDayEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let startOfTomorrow = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        let entry = RecipeOfTheDayEntry(date: now, recipe: pickRecipe(for: now))
        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }

    private func pickRecipe(for date: Date) -> Recipe? {
        let recipes = MockRecipes.all
        guard !recipes.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return recipes[(dayOfYear - 1) % recipes.count]
    }
}

// MARK: - View

struct RecipeOfTheDayWidgetView: View {
    let entry: RecipeOfTheDayEntry

    var body: some View {
        if let recipe = entry.recipe {
            content(for: recipe)
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private func content(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECEITA DO DIA")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .tracking(1)

            Text(recipe.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Label(recipe.prepTimeFormatted, systemImage: "clock")
                Label(recipe.difficulty.rawValue, systemImage: "flame")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Deep link pra abrir a receita no app: `vaptvupt://recipe/<UUID>`.
        // Para suportar, adicione um handler `.onOpenURL` no `RootTabView`
        // que navega para o `RecipeDetailView` correspondente.
        .widgetURL(URL(string: "vaptvupt://recipe/\(recipe.id.uuidString)"))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.title)
                .foregroundStyle(.orange)
            Text("Receita do dia")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget

struct RecipeOfTheDayWidget: Widget {
    let kind: String = "RecipeOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecipeOfTheDayProvider()) { entry in
            RecipeOfTheDayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Receita do Dia")
        .description("A receita sugerida para você hoje, atualizada todo dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
