//
//  VaptVuptWidget.swift
//  VaptVuptWidget
//
//  Widget de Homescreen com a "Receita do Dia". A escolha é determinística
//  pelo dia do ano (mesma lógica do Dashboard do app), então a timeline
//  refresca uma única vez por dia à meia-noite.
//
//  Este arquivo é self-contained: define internamente o tipo mínimo de
//  receita (`WidgetRecipe`) e uma seed leve, evitando depender de tipos do
//  target principal (que viriam via Target Membership). Quando o app for
//  conectado a um backend, troque `seedRecipes` por uma leitura de um
//  App Group compartilhado.
//

import SwiftUI
import WidgetKit

// MARK: - Tipo local

struct WidgetRecipe: Identifiable, Hashable {
    let id: UUID
    let title: String
    let prepTimeMinutes: Int
    let difficulty: String
    let accent: Color

    var prepTimeFormatted: String {
        if prepTimeMinutes < 60 { return "\(prepTimeMinutes) min" }
        let h = prepTimeMinutes / 60
        let m = prepTimeMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)min"
    }
}

private let seedRecipes: [WidgetRecipe] = [
    WidgetRecipe(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "Frango grelhado fit",
        prepTimeMinutes: 25,
        difficulty: "Fácil",
        accent: Color(red: 0.35, green: 0.65, blue: 0.40)
    ),
    WidgetRecipe(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "Omelete proteica",
        prepTimeMinutes: 10,
        difficulty: "Fácil",
        accent: Color(red: 0.95, green: 0.55, blue: 0.20)
    ),
    WidgetRecipe(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Macarrão ao alho e óleo",
        prepTimeMinutes: 20,
        difficulty: "Fácil",
        accent: Color(red: 0.95, green: 0.55, blue: 0.20)
    ),
    WidgetRecipe(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Caipirinha clássica",
        prepTimeMinutes: 5,
        difficulty: "Fácil",
        accent: Color(red: 0.85, green: 0.35, blue: 0.55)
    ),
    WidgetRecipe(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        title: "Salada de quinoa",
        prepTimeMinutes: 30,
        difficulty: "Médio",
        accent: Color(red: 0.35, green: 0.65, blue: 0.40)
    )
]

private func pickRecipe(for date: Date) -> WidgetRecipe {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    return seedRecipes[(dayOfYear - 1) % seedRecipes.count]
}

// MARK: - Timeline

struct VaptVuptWidgetEntry: TimelineEntry {
    let date: Date
    let recipe: WidgetRecipe
}

struct VaptVuptWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> VaptVuptWidgetEntry {
        VaptVuptWidgetEntry(date: Date(), recipe: seedRecipes[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (VaptVuptWidgetEntry) -> Void) {
        completion(VaptVuptWidgetEntry(date: Date(), recipe: pickRecipe(for: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaptVuptWidgetEntry>) -> Void) {
        let now = Date()
        let startOfTomorrow = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86_400)

        let entry = VaptVuptWidgetEntry(date: now, recipe: pickRecipe(for: now))
        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }
}

// MARK: - View

struct VaptVuptWidgetEntryView: View {
    let entry: VaptVuptWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECEITA DO DIA")
                .font(.caption2.weight(.bold))
                .foregroundStyle(entry.recipe.accent)
                .tracking(1)

            Text(entry.recipe.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Label(entry.recipe.prepTimeFormatted, systemImage: "clock")
                Label(entry.recipe.difficulty, systemImage: "flame")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Deep link para abrir a receita no app — registrar `vaptvupt://recipe/<UUID>`
        // no `.onOpenURL` do RootTabView para tratar.
        .widgetURL(URL(string: "vaptvupt://recipe/\(entry.recipe.id.uuidString)"))
    }
}

// MARK: - Widget

struct VaptVuptWidget: Widget {
    let kind: String = "VaptVuptWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaptVuptWidgetProvider()) { entry in
            VaptVuptWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Receita do Dia")
        .description("A receita sugerida para você hoje, atualizada todo dia.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    VaptVuptWidget()
} timeline: {
    VaptVuptWidgetEntry(date: .now, recipe: seedRecipes[0])
    VaptVuptWidgetEntry(date: .now, recipe: seedRecipes[1])
}
