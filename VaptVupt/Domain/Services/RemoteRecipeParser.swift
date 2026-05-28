//
//  RemoteRecipeParser.swift
//  SnapChef
//
//  Cliente HTTP do backend `vaptvupt-recipe-parser`. Envia uma URL (blog,
//  Instagram, TikTok, YouTube Shorts) e recebe uma `Recipe` estruturada
//  pronta pra ser usada no app.
//
//  Endpoint esperado:
//    POST {baseURL}/parse-url
//    Body: { "url": "https://..." }
//    Headers: Authorization: Bearer <APP_API_KEY> (se configurado)
//    Resposta: { "recipe": Recipe, "cached": Bool }
//
//  Para configurar, defina no Info.plist do target:
//    VaptVuptParserBaseURL  = https://api.vaptvupt.app
//    VaptVuptParserAPIKey   = <o APP_API_KEY do backend, opcional>
//

import Foundation

@Observable
final class RemoteRecipeParser {

    enum ParseError: Error {
        case notConfigured
        case invalidURL
        case http(status: Int, code: String?, message: String?)
        case network(Error)
        case decoding(Error)
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// `true` se o backend está configurado no Info.plist. Se `false`, o app
    /// continua usando o `RecipeAIService` mock local.
    var isConfigured: Bool {
        baseURL != nil
    }

    /// Faz POST /parse-url e devolve a receita estruturada.
    func parse(url: String) async throws -> Recipe {
        guard let baseURL else { throw ParseError.notConfigured }
        guard let endpoint = URL(string: "parse-url", relativeTo: baseURL) else {
            throw ParseError.invalidURL
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(["url": url])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ParseError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParseError.http(status: -1, code: nil, message: nil)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorEnvelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
            throw ParseError.http(
                status: httpResponse.statusCode,
                code: errorEnvelope?.error,
                message: errorEnvelope?.message
            )
        }

        do {
            let envelope = try JSONDecoder().decode(SuccessEnvelope.self, from: data)
            return envelope.recipe.toRecipe()
        } catch {
            throw ParseError.decoding(error)
        }
    }

    // MARK: - Info.plist config

    private var baseURL: URL? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "VaptVuptParserBaseURL") as? String,
            !raw.isEmpty,
            let url = URL(string: raw)
        else { return nil }
        return url
    }

    private var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "VaptVuptParserAPIKey") as? String
    }
}

// MARK: - Wire format

private struct SuccessEnvelope: Decodable {
    let recipe: WireRecipe
    let cached: Bool
}

private struct ErrorEnvelope: Decodable {
    let error: String?
    let message: String?
}

/// Espelha o JSON Schema do backend. Convertido para `Recipe` do domínio.
private struct WireRecipe: Decodable {
    let title: String
    let description: String?
    let prepTime: Int
    let servings: Int
    let imageURL: URL?
    let subcategories: [String]
    let difficulty: String
    let ingredients: [WireIngredient]
    let steps: [WireStep]
    let dietaryRestrictions: [String]

    func toRecipe() -> Recipe {
        Recipe(
            title: title,
            description: description,
            prepTime: prepTime,
            servings: servings,
            imageURL: imageURL,
            subcategories: subcategories.compactMap { RecipeSubcategory(rawValue: $0) },
            difficulty: RecipeDifficulty(rawValue: difficulty) ?? .easy,
            ingredients: ingredients.map { $0.toIngredient() },
            steps: steps.map { $0.toStep() },
            dietaryRestrictions: dietaryRestrictions.compactMap { DietaryRestriction(rawValue: $0) }
        )
    }
}

private struct WireIngredient: Decodable {
    let name: String
    let quantity: Double
    let unit: String

    func toIngredient() -> Ingredient {
        Ingredient(name: name, quantity: quantity, unit: IngredientUnit(rawValue: unit) ?? .unit)
    }
}

private struct WireStep: Decodable {
    let sequence: Int
    let instruction: String

    func toStep() -> Step {
        Step(sequence: sequence, instruction: instruction, imageURL: nil)
    }
}
