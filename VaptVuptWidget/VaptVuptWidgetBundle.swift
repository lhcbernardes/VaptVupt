//
//  VaptVuptWidgetBundle.swift
//  VaptVuptWidget
//
//  Entry-point do bundle do Widget Extension. Agrupa a Live Activity do
//  Modo Cozinha + o Widget de Receita do Dia. Adicione novos widgets
//  ao corpo do `body` à medida que forem implementados.
//

import SwiftUI
import WidgetKit

@main
struct VaptVuptWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecipeOfTheDayWidget()
        CookingLiveActivity()
    }
}
