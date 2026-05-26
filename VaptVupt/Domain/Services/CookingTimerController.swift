//
//  CookingTimerController.swift
//  SnapChef
//
//  Controlador de timer reativo usado dentro do Modo Cozinha. Detecta
//  minutos mencionados nas instruções, faz a contagem regressiva e
//  agenda uma notificação local (via `NotificationService`) para o
//  caso do usuário sair do app ou bloquear a tela.
//

import ActivityKit
import Foundation

@Observable
final class CookingTimerController {

    // MARK: - State

    private(set) var totalSeconds: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning: Bool = false
    private(set) var activeStepID: UUID? = nil

    /// Timers extras criados pelo usuário no Modo Cozinha — independentes
    /// do timer "principal" do passo atual. Permite cozinhar a massa
    /// (timer principal) e o molho (timer extra) em paralelo.
    private(set) var extraTimers: [AuxiliaryTimer] = []
    private var auxTickers: [UUID: Timer] = [:]

    /// Injetado pelo `CookingModeView` no onAppear para que o timer possa
    /// agendar/cancelar notificações locais sem acoplar a View diretamente.
    var notificationService: NotificationService?
    var recipeTitle: String = ""

    private var timer: Timer?
    private var activeStepNumber: Int = 0
    private var liveActivity: Activity<CookingActivityAttributes>?

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

        startLiveActivity(stepNumber: stepNumber)
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
        endLiveActivity()
    }

    // MARK: - Internal

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        // Pausamos a notificação local para evitar disparo enquanto pausado.
        // Será reagendada com o tempo restante ao retomar.
        notificationService?.cancelTimerNotification()
        updateLiveActivity(isPaused: true)
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
        updateLiveActivity(isPaused: false)
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
        endLiveActivity()
    }

    // MARK: - Live Activity

    /// Inicia uma Live Activity para o timer atual. Usa `endDate` como fonte
    /// de verdade — a UI do widget desenha a contagem sozinha via
    /// `Text(timerInterval:)`, então o app não precisa atualizar a cada segundo.
    private func startLiveActivity(stepNumber: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = CookingActivityAttributes(
            recipeTitle: recipeTitle,
            stepNumber: stepNumber
        )
        let state = CookingActivityAttributes.ContentState(
            endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
            totalSeconds: totalSeconds,
            isPaused: false,
            pausedRemainingSeconds: nil
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            liveActivity = nil
        }
    }

    /// Atualiza apenas o estado de pausa — recalcula `endDate` quando retoma.
    private func updateLiveActivity(isPaused: Bool) {
        guard let liveActivity else { return }

        let newState: CookingActivityAttributes.ContentState
        if isPaused {
            newState = CookingActivityAttributes.ContentState(
                endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
                totalSeconds: totalSeconds,
                isPaused: true,
                pausedRemainingSeconds: remainingSeconds
            )
        } else {
            newState = CookingActivityAttributes.ContentState(
                endDate: Date().addingTimeInterval(TimeInterval(remainingSeconds)),
                totalSeconds: totalSeconds,
                isPaused: false,
                pausedRemainingSeconds: nil
            )
        }

        Task {
            await liveActivity.update(ActivityContent(state: newState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let liveActivity else { return }
        Task {
            await liveActivity.end(nil, dismissalPolicy: .immediate)
        }
        self.liveActivity = nil
    }

    // MARK: - Auxiliary timers

    /// Adiciona um timer extra com o rótulo e duração informados.
    func addExtraTimer(label: String, minutes: Int) {
        guard minutes > 0 else { return }
        let aux = AuxiliaryTimer(label: label, totalSeconds: minutes * 60)
        extraTimers.append(aux)
        scheduleExtraTick(for: aux.id)
    }

    func toggleExtraTimer(_ id: UUID) {
        guard let index = extraTimers.firstIndex(where: { $0.id == id }) else { return }
        if extraTimers[index].isRunning {
            extraTimers[index].isRunning = false
            auxTickers[id]?.invalidate()
            auxTickers[id] = nil
        } else if extraTimers[index].remainingSeconds > 0 {
            extraTimers[index].isRunning = true
            scheduleExtraTick(for: id)
        }
    }

    func removeExtraTimer(_ id: UUID) {
        auxTickers[id]?.invalidate()
        auxTickers[id] = nil
        extraTimers.removeAll { $0.id == id }
    }

    func cancelAllExtraTimers() {
        for (_, ticker) in auxTickers { ticker.invalidate() }
        auxTickers.removeAll()
        extraTimers.removeAll()
    }

    private func scheduleExtraTick(for id: UUID) {
        auxTickers[id]?.invalidate()
        auxTickers[id] = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            guard let index = self.extraTimers.firstIndex(where: { $0.id == id }) else {
                timer.invalidate()
                return
            }
            if self.extraTimers[index].remainingSeconds > 0 {
                self.extraTimers[index].remainingSeconds -= 1
                if self.extraTimers[index].remainingSeconds == 0 {
                    self.extraTimers[index].isRunning = false
                    self.auxTickers[id]?.invalidate()
                    self.auxTickers[id] = nil
                }
            }
        }
    }
}

// MARK: - Auxiliary timer

/// Timer extra simples — sem notificação local nem Live Activity.
/// Pensado para usos paralelos ("molho", "vinagrete") durante o preparo.
struct AuxiliaryTimer: Identifiable, Hashable {
    let id: UUID = UUID()
    var label: String
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool

    init(label: String, totalSeconds: Int) {
        self.label = label
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
        self.isRunning = true
    }

    var formatted: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }
}
