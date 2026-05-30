//
//  AppLanguage.swift
//  SnapChef
//
//  Idioma do app — sobrescreve o do sistema iOS quando o usuário escolhe
//  algo diferente de `system` em Ajustes. Aplicado via
//  `.environment(\.locale, ...)` no root da cena, então qualquer view com
//  `Text(LocalizedStringKey)` reage à mudança em tempo real.
//
//  rawValue em inglês estável (para `@AppStorage`) — nomes exibidos na UI
//  permanecem no idioma nativo de cada opção (`English`, `Español`, etc.),
//  então o usuário sempre consegue identificar a própria língua.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Hashable {
    case system = "system"
    case ptBR   = "pt-BR"
    case en     = "en"
    case es     = "es"

    var id: Self { self }

    /// `Locale` efetivo a ser injetado no environment. `nil` para `system`
    /// — quem consumir cai em `Locale.current`.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .ptBR:   Locale(identifier: "pt_BR")
        case .en:     Locale(identifier: "en")
        case .es:     Locale(identifier: "es")
        }
    }

    /// Nome do idioma exibido no seletor. Cada opção fica no próprio
    /// idioma para o usuário identificar mesmo se não falar o idioma
    /// atual do app. `Sistema` é a única exceção — segue o catalog.
    var displayName: String {
        switch self {
        case .system: String(localized: "Sistema")
        case .ptBR:   "Português (Brasil)"
        case .en:     "English"
        case .es:     "Español"
        }
    }
}
