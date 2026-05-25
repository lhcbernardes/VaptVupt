//
//  CookingTimerController.swift
//  SnapChef
//
//  Controlador de timer reativo usado dentro do Modo Cozinha. Detecta
//  minutos mencionados nas instruções, faz a contagem regressiva e
//  agenda uma notificação local (via `NotificationService`) para o
//  caso do usuário sair do app ou bloquear a tela.
//

import Foundation

@Observable
final class CookingTimerController {

    // MARK: - State

    private(set) var totalSeconds: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning: Bool = false
    private(set) var activeStepID: UUID? = nil

    /// Injetado pelo `CookingModeView` no onAppear para que o timer possa
    /// agendar/cancelar notificações locais sem acoplar a View diretamente.
    var notificationService: NotificationService?
    var recipeTitle: String = ""

    private var timer: Timer?
    private var activeStepNumber: Int = 0

    // MARK: - Derived

    var isActive: Bool { totalSeconds > 0 }

    var formatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    // MARK: - Detection

    /// Extrai a primeira menção de duração (em minutos) presente no texto.
    static func detectMinutes(in text: String) -> Int? {
        if let minutes = firstMatch(in: text, pattern: #"(\d+)\s*(minutos|minuto|min)"#) {
            return minutes
        }
        if let hours = firstMatch(in: text, pattern: #"(\d+)\s*(horas|hora|h)\b"#) {
            return hours * 60
        }
        return nil
    }

    private static func firstMatch(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges > 1,
            let numberRange = Range(match.range(at: 1), in: text)
        else { return nil }
        return Int(text[numberRange])
    }

    // MARK: - Actions

    func start(minutes: Int, stepID: UUID, stepNumber: Int) {
        cancel()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        activeStepID = stepID
        activeStepNumber = stepNumber
        isRunning = true
        scheduleTick()

        notificationService?.scheduleTimerEnd(
            after: minutes,
            recipeTitle: recipeTitle,
            stepNumber: stepNumber
        )
    }

    func togglePauseResume() {
        if isRunning { pause() } else { resume() }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        activeStepID = nil
        activeStepNumber = 0
        totalSeconds = 0
        remainingSeconds = 0
        notificationService?.cancelTimerNotification()
    }

    // MARK: - Internal

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        // Pausamos a notificação local para evitar disparo enquanto pausado.
        // Será reagendada com o tempo restante ao retomar.
        notificationService?.cancelTimerNotification()
    }

    private func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        scheduleTick()

        // Reagenda a notificação com o tempo restante.
        let minutesRemaining = Int((Double(remainingSeconds) / 60.0).rounded(.up))
        if minutesRemaining > 0 {
            notificationService?.scheduleTimerEnd(
                after: minutesRemaining,
                recipeTitle: recipeTitle,
                stepNumber: activeStepNumber
            )
        }
    }

    private func scheduleTick() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                if self.remainingSeconds == 0 { self.finish() }
            }
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        // Notificação já dispara via UNUserNotificationCenter no momento certo.
    }
}
