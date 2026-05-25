//
//  NotificationService.swift
//  SnapChef
//
//  Encapsula `UNUserNotificationCenter` para o ciclo do timer do Modo
//  Cozinha. Garante que, se o usuário fechar o app ou o iPhone bloquear
//  a tela, ele ainda receba a notificação ao tempo do passo zerar.
//

import Foundation
import UserNotifications

@Observable
final class NotificationService {

    /// Identificador único usado para o timer ativo. Como só existe um
    /// timer por vez, sobrescrevemos o pendente quando um novo é agendado.
    private let timerIdentifier = "snapchef.cooking.timer"

    /// Estado de autorização do usuário. Atualizado de forma reativa.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    init() {
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Permissions

    @discardableResult
    func requestPermissionIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()

        switch authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                return granted
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    @MainActor
    private func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Timer notifications

    /// Agenda o "ding" final do timer. Sobrescreve qualquer notificação
    /// anterior — só há um timer ativo por vez no Modo Cozinha.
    func scheduleTimerEnd(after minutes: Int, recipeTitle: String, stepNumber: Int) {
        guard minutes > 0 else { return }
        cancelTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = "Tempo do passo \(stepNumber) terminado"
        content.body = recipeTitle
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: timerIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { _ in /* fire-and-forget */ }
    }

    /// Cancela a notificação pendente do timer (chamado em pause/cancel).
    func cancelTimerNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [timerIdentifier])
    }
}
