//
//  MockRecipes.swift
//  SnapChef
//
//  Conjunto mínimo de receitas utilizadas no MVP para popular a Home
//  e validar todos os fluxos visuais (Refeição, Fit, Bebida).
//

import Foundation

enum MockRecipes {

    static let all: [Recipe] = [
        breakfastOats,
        fitChicken,
        mojitoZero
    ]

    // MARK: - Refeição diária (Café da Manhã)

    static let breakfastOats = Recipe(
        title: "Aveia com Banana e Mel",
        description: "Café da manhã rápido, nutritivo e cremoso — perfeito para começar o dia em 10 minutos.",
        prepTime: 8,
        servings: 1,
        imageURL: URL(string: "https://images.unsplash.com/photo-1517673400267-0251440c45dc?w=1200"),
        subcategories: [.breakfast],
        difficulty: .easy,
        ingredients: [
            Ingredient(name: "Aveia em flocos", quantity: 0.5, unit: .cup),
            Ingredient(name: "Leite", quantity: 200, unit: .milliliter),
            Ingredient(name: "Banana madura", quantity: 1, unit: .unit),
            Ingredient(name: "Mel", quantity: 1, unit: .spoon),
            Ingredient(name: "Canela em pó", quantity: 1, unit: .pinch)
        ],
        steps: [
            Step(sequence: 1, instruction: "Aqueça o leite em uma panela pequena até começar a soltar vapor, sem ferver.", imageURL: nil),
            Step(sequence: 2, instruction: "Adicione a aveia e cozinhe por 3 minutos em fogo baixo, mexendo sempre.", imageURL: nil),
            Step(sequence: 3, instruction: "Transfira para uma tigela, finalize com a banana fatiada, o mel e a canela.", imageURL: nil)
        ]
    )

    // MARK: - Comida fit proteica (Almoço Low Carb)

    static let fitChicken = Recipe(
        title: "Frango Grelhado com Brócolis",
        description: "Prato proteico, low carb e prático. Pronto em menos de 25 minutos.",
        prepTime: 25,
        servings: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=1200"),
        subcategories: [.lunch, .protein, .lowCarb],
        difficulty: .easy,
        ingredients: [
            Ingredient(name: "Peito de frango",     quantity: 300, unit: .gram),
            Ingredient(name: "Brócolis",            quantity: 200, unit: .gram),
            Ingredient(name: "Azeite extra virgem", quantity: 1,   unit: .spoon),
            Ingredient(name: "Alho",                quantity: 2,   unit: .unit),
            Ingredient(name: "Sal",                 quantity: 1,   unit: .toTaste),
            Ingredient(name: "Pimenta-do-reino",    quantity: 1,   unit: .toTaste)
        ],
        steps: [
            Step(sequence: 1, instruction: "Tempere o frango com sal, pimenta e alho amassado. Descanse por 5 minutos.", imageURL: nil),
            Step(sequence: 2, instruction: "Aqueça uma frigideira com azeite e grelhe o frango por 6 minutos de cada lado, até dourar.", imageURL: nil),
            Step(sequence: 3, instruction: "Cozinhe o brócolis no vapor por 4 minutos, mantendo a textura crocante.", imageURL: nil),
            Step(sequence: 4, instruction: "Sirva o frango fatiado ao lado do brócolis e regue com mais um fio de azeite.", imageURL: nil)
        ]
    )

    // MARK: - Drink sem álcool

    static let mojitoZero = Recipe(
        title: "Mojito Sem Álcool",
        description: "Versão refrescante do clássico cubano, com hortelã, limão e água com gás.",
        prepTime: 5,
        servings: 1,
        imageURL: URL(string: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=1200"),
        subcategories: [.nonAlcoholic],
        difficulty: .easy,
        ingredients: [
            Ingredient(name: "Folhas de hortelã", quantity: 8,   unit: .unit),
            Ingredient(name: "Limão",             quantity: 1,   unit: .unit),
            Ingredient(name: "Açúcar",            quantity: 2,   unit: .spoon),
            Ingredient(name: "Água com gás",      quantity: 200, unit: .milliliter),
            Ingredient(name: "Gelo",              quantity: 1,   unit: .toTaste)
        ],
        steps: [
            Step(sequence: 1, instruction: "Macere as folhas de hortelã com o açúcar no fundo de um copo alto.", imageURL: nil),
            Step(sequence: 2, instruction: "Esprema o limão por cima e mexa até dissolver o açúcar.", imageURL: nil),
            Step(sequence: 3, instruction: "Adicione gelo até a metade do copo e complete com água com gás.", imageURL: nil),
            Step(sequence: 4, instruction: "Decore com um galho de hortelã e uma rodela de limão.", imageURL: nil)
        ]
    )
}
