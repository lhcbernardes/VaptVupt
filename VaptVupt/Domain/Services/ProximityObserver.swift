//
//  ProximityObserver.swift
//  SnapChef
//
//  Observa o sensor de proximidade do iPhone para permitir navegação
//  "mãos livres" no Modo Cozinha — passar a mão por cima da câmera frontal
//  emite um evento que pode ser usado para avançar/voltar passos sem tocar
//  na tela suja.
//
//  O sensor reporta apenas dois estados (perto / longe). Tratamos cada
//  transição de "longe → perto" como um gesto e aplicamos debounce para
//  evitar múltiplos disparos quando o usuário apoia o telefone numa
//  superfície.
//

import UIKit

@Observable
final class ProximityObserver {

    /// Incrementado a cada gesto detectado. Use `.onChange(of:)` para reagir.
    private(set) var triggerCount: Int = 0

    /// Estado bruto do sensor (true = mão/objeto próximo).
    private(set) var isNear: Bool = false

    /// Intervalo mínimo entre gestos consecutivos para descartar ruído.
    private let debounceInterval: TimeInterval = 0.6

    private var lastTriggerDate: Date = .distantPast
    private var observer: NSObjectProtocol?

    deinit { stop() }

    // MARK: - Lifecycle

    /// Liga o sensor e começa a escutar transições. Idempotente.
    func start() {
        let device = UIDevice.current
        guard !device.isProximityMonitoringEnabled else { return }

        device.isProximityMonitoringEnabled = true

        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: device,
            queue: .main
        ) { [weak self] _ in
            self?.handleProximityChange()
        }
    }

    /// Desliga o sensor. Sempre chamar no `onDisappear`.
    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        UIDevice.current.isProximityMonitoringEnabled = false
        isNear = false
    }

    // MARK: - Internal

    private func handleProximityChange() {
        let newValue = UIDevice.current.proximityState
        defer { isNear = newValue }

        // Só conta como gesto a transição longe → perto.
        guard !isNear, newValue else { return }

        let now = Date()
        guard now.timeIntervalSince(lastTriggerDate) >= debounceInterval else { return }
        lastTriggerDate = now
        triggerCount &+= 1
    }
}
