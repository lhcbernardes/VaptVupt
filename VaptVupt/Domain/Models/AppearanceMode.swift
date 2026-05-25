//
//  AppearanceMode.swift
//  SnapChef
//
//  Preferência de tema do app. Persistida via `@AppStorage` e aplicada
//  na cena raiz através de `.preferredColorScheme(_:)`.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Sistema"
        case .light:  "Claro"
        case .dark:   "Escuro"
        }
    }

    var systemIcon: String {
        switch self {
        case .system: "iphone"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    /// `nil` significa "seguir o sistema". Valores explícitos sobrescrevem
    /// a preferência do iOS.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}
