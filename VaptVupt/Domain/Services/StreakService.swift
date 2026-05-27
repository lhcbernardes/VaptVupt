//
//  StreakService.swift
//  SnapChef
//
//  Calcula streak (dias consecutivos cozinhando) e maior streak de todos
//  os tempos a partir do histórico em SwiftData. Função pura — não tem
//  estado próprio, todas as queries derivam de `[CookedRecipeEntry]`.
//

import Foundation

enum StreakService {

    struct Snapshot: Hashable {
        let currentStreak: Int
        let longestStreak: Int
        let totalCount: Int
        let lastCookedDate: Date?
    }

    /// Calcula os números a partir dos preparos. Considera "hoje" e "ontem"
    /// como dentro do streak corrente — se o último preparo foi anteontem
    /// ou antes, o streak é zero.
    static func snapshot(from entries: [CookedRecipeEntry], now: Date = .now) -> Snapshot {
        guard !entries.isEmpty else {
            return Snapshot(currentStreak: 0, longestStreak: 0, totalCount: 0, lastCookedDate: nil)
        }

        let calendar = Calendar.current
        // Dias únicos (sem hora) ordenados do mais recente para o mais antigo.
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.cookedAt) })
            .sorted(by: >)

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        // Streak corrente: contagem dos dias consecutivos a partir do
        // último dia cozinhado (precisa ser hoje ou ontem para contar).
        var current = 0
        if let mostRecent = uniqueDays.first, mostRecent >= yesterday {
            current = 1
            var cursor = mostRecent
            for day in uniqueDays.dropFirst() {
                let expected = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
                if day == expected {
                    current += 1
                    cursor = day
                } else {
                    break
                }
            }
        }

        // Maior streak de todos os tempos: itera de trás pra frente
        // contando runs de dias consecutivos.
        let ascending = uniqueDays.sorted()
        var longest = 0
        var run = 0
        var previous: Date? = nil
        for day in ascending {
            if let prev = previous,
               let expected = calendar.date(byAdding: .day, value: 1, to: prev),
               day == expected {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }

        return Snapshot(
            currentStreak: current,
            longestStreak: longest,
            totalCount: entries.count,
            lastCookedDate: entries.max(by: { $0.cookedAt < $1.cookedAt })?.cookedAt
        )
    }

    static func unlockedBadges(from entries: [CookedRecipeEntry], now: Date = .now) -> [AchievementBadge] {
        let s = snapshot(from: entries, now: now)
        return AchievementBadge.catalog.filter { $0.isUnlocked(streakDays: s.currentStreak, totalCount: s.totalCount) }
    }
}
