//
//  CookingActivityAttributes.swift
//  SnapChef
//
//  Attributes da Live Activity do Modo Cozinha. Compartilhe este arquivo
//  entre o target principal e o Widget Extension (em "Target Membership").
//
//  Para habilitar a Live Activity:
//    1. Adicione o framework `ActivityKit` ao target.
//    2. No Info.plist do target principal, defina:
//         NSSupportsLiveActivities = YES
//    3. Crie um Widget Extension (File > New > Target > Widget Extension)
//       e implemente o `ActivityConfiguration<CookingActivityAttributes>`
//       no arquivo do widget, com Dynamic Island + Lock Screen UI.
//

import ActivityKit
import Foundation

struct CookingActivityAttributes: ActivityAttributes {

    /// Estado dinâmico — atualizado conforme o timer corre.
    struct ContentState: Codable, Hashable {
        /// Momento (UTC) em que o timer vai zerar. Usado por `Text(timerInterval:)`
        /// na UI para que a contagem se desenhe sozinha sem `Activity.update`
        /// a cada segundo (economiza budget de atualização do sistema).
        var endDate: Date

        /// Total da janela do passo (para a barra de progresso).
        var totalSeconds: Int

        /// `true` quando pausado — congela o display e oculta a contagem.
        var isPaused: Bool

        /// Cópia do tempo restante no momento da pausa, para reapresentar.
        var pausedRemainingSeconds: Int?
    }

    /// Conteúdo estático — definido na criação e não muda durante a atividade.
    var recipeTitle: String
    var stepNumber: Int
}
