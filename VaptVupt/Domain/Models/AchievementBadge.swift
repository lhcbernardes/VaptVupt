//
//  AchievementBadge.swift
//  SnapChef
//
//  Badges desbloqueadas pelo usuário ao acumular preparos consecutivos
//  no histórico (`CookedRecipeEntry`). A regra é simples e determinística
//  — qualquer view pode chamar `AchievementBadge.unlocked(streak:total:)`
//  para descobrir o conjunto atual sem efeitos colaterais.
//

import SwiftUI

struct AchievementBadge: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemIcon: String
    let tint: Color
    /// Critério: streak de dias OU total de preparos.
    let requirement: Requirement

    enum Requirement: Hashable {
        case streak(days: Int)
        case total(count: Int)
    }

    static let catalog: [AchievementBadge] = [
        .init(
            id: "streak.3",
            title: "Começou bem",
            subtitle: "3 dias seguidos cozinhando",
            systemIcon: "flame.fill",
            tint: .orange,
            requirement: .streak(days: 3)
        ),
        .init(
            id: "streak.7",
            title: "Semana cheia",
            subtitle: "7 dias seguidos cozinhando",
            systemIcon: "flame.circle.fill",
            tint: .red,
            requirement: .streak(days: 7)
        ),
        .init(
            id: "streak.30",
            title: "Cozinheiro do mês",
            subtitle: "30 dias seguidos cozinhando",
            systemIcon: "crown.fill",
            tint: .yellow,
            requirement: .streak(days: 30)
        ),
        .init(
            id: "total.10",
            title: "Iniciante",
            subtitle: "10 receitas no histórico",
            systemIcon: "fork.knife.circle.fill",
            tint: .green,
            requirement: .total(count: 10)
        ),
        .init(
            id: "total.50",
            title: "Veterano",
            subtitle: "50 receitas no histórico",
            systemIcon: "star.fill",
            tint: .blue,
            requirement: .total(count: 50)
        ),
        .init(
            id: "total.100",
            title: "Chef da casa",
            subtitle: "100 receitas no histórico",
            systemIcon: "rosette",
            tint: .purple,
            requirement: .total(count: 100)
        )
    ]

    func isUnlocked(streakDays: Int, totalCount: Int) -> Bool {
        switch requirement {
        case .streak(let days):  streakDays >= days
        case .total(let count):  totalCount >= count
        }
    }
}
