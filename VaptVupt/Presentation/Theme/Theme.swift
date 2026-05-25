//
//  Theme.swift
//  SnapChef
//
//  Design System centralizado: cores, tipografia, espaçamentos e raios.
//  Inspiração visual: "Quiet Luxury" da Apple — minimalismo, tipografia
//  serif para títulos, paleta neutra com cores quentes de destaque.
//

import SwiftUI

enum Theme {

    // MARK: - Colors

    enum Colors {
        static let background    = Color(.systemBackground)
        static let surface       = Color(.secondarySystemBackground)
        static let elevated      = Color(.tertiarySystemBackground)
        static let primaryText   = Color.primary
        static let secondaryText = Color.secondary
        static let separator     = Color(.separator).opacity(0.4)

        /// Cor de destaque "âmbar queimado" — usada em CTAs e tags primárias.
        static let accent = Color(red: 0.95, green: 0.55, blue: 0.20)
    }

    // MARK: - Radius

    enum Radius {
        static let small: CGFloat  = 10
        static let medium: CGFloat = 16
        static let large: CGFloat  = 24
        static let xlarge: CGFloat = 32
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Typography

    enum Typography {
        static let display      = Font.system(.largeTitle, design: .serif, weight: .bold)
        static let title        = Font.system(.title, design: .serif, weight: .semibold)
        static let sectionTitle = Font.system(.title3, design: .default, weight: .semibold)
        static let cardTitle    = Font.system(.headline, design: .default, weight: .semibold)
        static let body         = Font.system(.body, design: .default)
        static let caption      = Font.system(.caption, design: .default, weight: .medium)
    }
}
