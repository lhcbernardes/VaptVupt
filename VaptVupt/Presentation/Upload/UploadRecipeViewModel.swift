//
//  UploadRecipeViewModel.swift
//  SnapChef
//
//  Orquestra os três modos de captura (Foto/Voz/Link) e a edição manual
//  da receita. Delega ao `RecipeAIService` a transformação de texto bruto
//  em estrutura `Recipe`.
//

import Foundation

@Observable
final class UploadRecipeViewModel {

    // MARK: - Estado de IA

    enum AIState: Equatable {
        case idle
        case processing(RecipeAIService.InputSource)
        case finished
        case failed(String)
    }

    // MARK: - Dependências

    private let aiService: RecipeAIService
    private let onSave: (Recipe) -> Void

    // MARK: - Estado do formulário

    var title: String = ""
    var description: String = ""
    var prepTime: Int = 15
    var servings: Int = 2
    var difficulty: RecipeDifficulty = .easy
    var selectedSubcategories: Set<RecipeSubcategory> = []
    var ingredients: [Ingredient] = []
    var steps: [Step] = []

    // MARK: - Estado de UI

    var aiState: AIState = .idle
    var pastedLink: String = ""
    var showLinkInput: Bool = false

    // MARK: - Init

    init(
        aiService: RecipeAIService = RecipeAIService(),
        onSave: @escaping (Recipe) -> Void
    ) {
        self.aiService = aiService
        self.onSave = onSave
    }

    // MARK: - Ações de IA (Foto, Voz, Link)

    /// Simula a captura/seleção de uma foto, OCR e parsing pela LLM.
    func triggerPhotoCapture() {
        let mockOCR = """
        Omelete proteica fit pro café da manhã.
        3 ovos
        1 colher de queijo cottage
        1 pitada de sal
        Bata os ovos com o sal e leve à frigideira. Cozinhe por 2 minutos. \
        Adicione o cottage e dobre. Sirva quente.
        """
        Task { await runParser(text: mockOCR, source: .photo) }
    }

    /// Simula a transcrição de uma fala natural.
    func triggerVoiceDictation() {
        let mockTranscript = """
        Bata 3 ovos com 1 xícara de aveia e faça na frigideira, fica fit pro café. \
        Adicione 1 colher de mel e canela em pó a gosto.
        """
        Task { await runParser(text: mockTranscript, source: .voice) }
    }

    /// Processa um link colado pelo usuário (simulado).
    func triggerLinkParse() {
        let text = pastedLink.isEmpty
            ? "Receita do link: Frango grelhado com brócolis, low carb, proteico. 30 minutos. 4 porções."
            : "Receita extraída do link \(pastedLink). 25 minutos, 2 porções. Almoço fit."
        Task { await runParser(text: text, source: .link) }
    }

    // MARK: - Ações de formulário

    func toggle(subcategory: RecipeSubcategory) {
        if selectedSubcategories.contains(subcategory) {
            selectedSubcategories.remove(subcategory)
        } else {
            selectedSubcategories.insert(subcategory)
        }
    }

    func addEmptyIngredient() {
        ingredients.append(Ingredient(name: "", quantity: 1, unit: .unit))
    }

    func removeIngredient(at index: Int) {
        guard ingredients.indices.contains(index) else { return }
        ingredients.remove(at: index)
    }

    func addEmptyStep() {
        steps.append(Step(sequence: steps.count + 1, instruction: "", imageURL: nil))
    }

    func removeStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps.remove(at: index)
        for i in steps.indices { steps[i].sequence = i + 1 }
    }

    // MARK: - Persistência

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ingredients.isEmpty &&
        !steps.isEmpty
    }

    func save() {
        let recipe = Recipe(
            title: title,
            description: description.isEmpty ? nil : description,
            prepTime: prepTime,
            servings: servings,
            imageURL: nil,
            subcategories: Array(selectedSubcategories),
            difficulty: difficulty,
            ingredients: ingredients,
            steps: steps
        )
        onSave(recipe)
    }

    // MARK: - Internals

    private func runParser(text: String, source: RecipeAIService.InputSource) async {
        await MainActor.run { aiState = .processing(source) }
        guard let parsed = await aiService.parseRecipeFromText(text, source: source) else {
            await MainActor.run { aiState = .failed("Não foi possível interpretar a receita.") }
            return
        }
        await MainActor.run { applyParsed(parsed) }
    }

    @MainActor
    private func applyParsed(_ recipe: Recipe) {
        title = recipe.title
        description = recipe.description ?? ""
        prepTime = recipe.prepTime
        servings = recipe.servings
        difficulty = recipe.difficulty
        selectedSubcategories = Set(recipe.subcategories)
        ingredients = recipe.ingredients
        steps = recipe.steps
        aiState = .finished
    }
}
