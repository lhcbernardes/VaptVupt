//
//  RecipeAIService.swift
//  SnapChef
//
//  Serviço (mock) que simula a chamada a uma LLM (Gemini/OpenAI/Claude) responsável
//  por transformar texto bruto em uma `Recipe` estruturada. Em produção, esta camada
//  encapsularia a chamada de rede + parsing JSON. Aqui aplicamos heurísticas leves
//  apenas para entregar uma simulação convincente para o MVP.
//

import Foundation

@Observable
final class RecipeAIService {

    /// Fonte do texto que será analisado — usada apenas para enriquecer o título
    /// e o telemetry/logging em uma implementação real.
    enum InputSource {
        case photo  // OCR de imagem
        case voice  // Transcrição de áudio
        case link   // Conteúdo extraído de URL
        case text   // Texto colado pelo usuário
    }

    /// Função principal exigida pela especificação. Recebe um texto bruto e devolve
    /// uma `Recipe?` estruturada, inferindo categorias com base no conteúdo.
    func parseRecipeFromText(_ text: String, source: InputSource = .text) async -> Recipe? {
        // Simula a latência da chamada à LLM (~1.2s).
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        let normalized = text.lowercased()
        let subcategories = inferSubcategories(from: normalized)
        let title = inferTitle(from: text, source: source)
        let prepTime = inferPrepTime(from: normalized)
        let servings = inferServings(from: normalized)

        return Recipe(
            title: title,
            description: String(text.prefix(140)),
            prepTime: prepTime,
            servings: servings,
            imageURL: nil,
            subcategories: subcategories,
            difficulty: .easy,
            ingredients: extractIngredients(from: text),
            steps: extractSteps(from: text)
        )
    }

    // MARK: - Heurísticas (substituem o JSON da LLM no MVP)

    private func inferSubcategories(from normalized: String) -> [RecipeSubcategory] {
        var result: [RecipeSubcategory] = []

        if normalized.containsAny(["café da manhã", "aveia", "pão", "ovo", "ovos"]) {
            result.append(.breakfast)
        }
        if normalized.containsAny(["almoço", "arroz", "feijão", "frango grelhado", "carne"]) {
            result.append(.lunch)
        }
        if normalized.containsAny(["jantar", "sopa", "macarrão"]) {
            result.append(.dinner)
        }
        if normalized.containsAny(["lanche", "sanduíche", "wrap"]) {
            result.append(.snack)
        }
        if normalized.containsAny(["fit", "proteico", "whey", "frango", "ovos"]) {
            result.append(.protein)
        }
        if normalized.containsAny(["low carb", "sem carbo"]) {
            result.append(.lowCarb)
        }
        if normalized.containsAny(["sem açúcar", "zero açúcar", "adoçante"]) {
            result.append(.sugarFree)
        }
        if normalized.containsAny(["drink", "coquetel", "mojito", "caipirinha"]) {
            if normalized.containsAny(["vodka", "gin", "rum", "cachaça", "tequila"]) {
                result.append(.alcoholic)
            } else {
                result.append(.nonAlcoholic)
            }
        }

        // Garantia: sempre devolve ao menos uma subcategoria coerente.
        return result.isEmpty ? [.snack] : Array(Set(result))
    }

    private func inferTitle(from text: String, source: InputSource) -> String {
        let firstLine = text
            .split(whereSeparator: { $0.isNewline })
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstLine, !firstLine.isEmpty, firstLine.count < 60 {
            return firstLine
        }

        switch source {
        case .photo: return "Receita identificada (foto)"
        case .voice: return "Receita ditada"
        case .link:  return "Receita importada"
        case .text:  return "Nova Receita"
        }
    }

    private func inferPrepTime(from normalized: String) -> Int {
        // Procura padrões do tipo "30 minutos" ou "1 hora".
        if let minutes = firstMatch(in: normalized, pattern: #"(\d+)\s*(minutos|min)"#) {
            return minutes
        }
        if let hours = firstMatch(in: normalized, pattern: #"(\d+)\s*(horas|hora|h)"#) {
            return hours * 60
        }
        return 15
    }

    private func inferServings(from normalized: String) -> Int {
        if let servings = firstMatch(in: normalized, pattern: #"(\d+)\s*porções"#) {
            return servings
        }
        return 2
    }

    private func extractIngredients(from text: String) -> [Ingredient] {
        // Heurística simples baseada em tokens "<número> <unidade> <ingrediente>".
        let tokens = text
            .replacingOccurrences(of: ",", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        var ingredients: [Ingredient] = []
        var index = 0
        while index < tokens.count {
            if let qty = Double(tokens[index].replacingOccurrences(of: ",", with: ".")) {
                let unitToken = index + 1 < tokens.count ? tokens[index + 1] : ""
                let unit = matchUnit(for: unitToken) ?? .unit
                let unitConsumed = matchUnit(for: unitToken) != nil

                // Nome do ingrediente — pega 1-2 palavras após a unidade.
                let nameStart = index + (unitConsumed ? 2 : 1)
                let nameEnd = min(nameStart + 2, tokens.count)
                let nameSlice = tokens[nameStart..<nameEnd]
                    .joined(separator: " ")
                    .trimmingCharacters(in: .punctuationCharacters)

                if !nameSlice.isEmpty {
                    ingredients.append(Ingredient(name: nameSlice.capitalized, quantity: qty, unit: unit))
                }
                index = nameEnd
            } else {
                index += 1
            }
        }

        if ingredients.isEmpty {
            ingredients = [Ingredient(name: "Ingrediente principal", quantity: 1, unit: .unit)]
        }
        return ingredients
    }

    private func matchUnit(for token: String) -> IngredientUnit? {
        switch token.lowercased() {
        case "g", "gramas":             .gram
        case "kg", "quilo", "quilos":   .kilogram
        case "ml":                      .milliliter
        case "l", "litro", "litros":    .liter
        case "xícara", "xícaras":       .cup
        case "colher", "colheres":      .spoon
        case "pitada", "pitadas":       .pinch
        case "unidade", "unidades":     .unit
        default:                        nil
        }
    }

    private func extractSteps(from text: String) -> [Step] {
        let sentences = text
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !sentences.isEmpty else {
            return [Step(sequence: 1, instruction: text, imageURL: nil)]
        }

        return sentences.enumerated().map { index, sentence in
            Step(sequence: index + 1, instruction: sentence, imageURL: nil)
        }
    }

    private func firstMatch(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Int(text[numberRange])
    }
}

// MARK: - String helpers

private extension String {
    func containsAny(_ needles: [String]) -> Bool {
        needles.contains { self.contains($0) }
    }
}
