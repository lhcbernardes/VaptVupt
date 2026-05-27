//
//  VoiceCommandRecognizer.swift
//  SnapChef
//
//  Reconhecedor de comandos de voz curtos para o Modo Cozinha. Mantém
//  uma sessão contínua de `SFSpeechRecognizer` (locale pt-BR) e mapeia
//  o transcript para comandos discretos consumíveis pela View.
//
//  IMPORTANTE — Antes de usar, adicione no Info.plist do target:
//   • NSSpeechRecognitionUsageDescription
//   • NSMicrophoneUsageDescription
//
//  O reconhecimento é caro em bateria — ligue APENAS dentro do Modo
//  Cozinha e desligue no `onDisappear`.
//

import AVFoundation
import Foundation
import Speech

@Observable
final class VoiceCommandRecognizer {

    // MARK: - Command

    enum Command: String, CaseIterable {
        case next
        case previous
        case pause
        case resume
        case start
        case cancel

        /// Sinônimos em português aceitos para cada comando.
        var aliases: [String] {
            switch self {
            case .next:     ["próximo", "proximo", "avançar", "avancar", "segue"]
            case .previous: ["voltar", "anterior"]
            case .pause:    ["pausar", "pausa"]
            case .resume:   ["continuar", "retomar"]
            case .start:    ["iniciar", "começar", "comecar"]
            case .cancel:   ["cancelar", "parar"]
            }
        }
    }

    // MARK: - State

    /// Último comando reconhecido. A View observa para reagir.
    private(set) var lastCommand: Command? = nil

    /// Trigger crescente — útil quando o mesmo comando é dito duas vezes
    /// seguidas e a View precisa reagir nas duas.
    private(set) var triggerCount: Int = 0

    private(set) var isListening: Bool = false
    private(set) var permissionDenied: Bool = false

    /// `true` quando o Info.plist do app não declara as chaves de uso
    /// necessárias (`NSSpeechRecognitionUsageDescription` e
    /// `NSMicrophoneUsageDescription`). Sem elas, qualquer chamada ao
    /// `SFSpeechRecognizer.requestAuthorization` mata o processo. A View
    /// observa essa flag e exibe um alerta amigável em vez de tentar.
    private(set) var infoPlistKeysMissing: Bool = false

    // MARK: - Engine

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt_BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Último trecho processado — evita re-disparar o mesmo comando em
    /// transcrições parciais sucessivas.
    private var lastProcessedSuffix: String = ""

    // MARK: - Public API

    /// Pede permissão (Speech + Microfone) e inicia escuta. Idempotente.
    /// Antes de chamar a API que mata o processo se a chave Info.plist
    /// estiver ausente, validamos o bundle.
    func start() async {
        guard !isListening else { return }

        let info = Bundle.main.infoDictionary ?? [:]
        let hasSpeechKey = (info["NSSpeechRecognitionUsageDescription"] as? String)?.isEmpty == false
        let hasMicKey = (info["NSMicrophoneUsageDescription"] as? String)?.isEmpty == false
        guard hasSpeechKey, hasMicKey else {
            infoPlistKeysMissing = true
            return
        }

        let speechGranted = await requestSpeechAuthorization()
        let micGranted = await requestMicrophonePermission()

        guard speechGranted, micGranted else {
            permissionDenied = true
            return
        }

        do {
            try startEngine()
            isListening = true
        } catch {
            isListening = false
        }
    }

    /// Encerra o reconhecimento e libera recursos de áudio.
    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isListening = false
        lastProcessedSuffix = ""
    }

    // MARK: - Internal

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startEngine() throws {
        // Configura categoria de áudio compatível com gravação + leitura.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.handleTranscript(result.bestTranscription.formattedString)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.restart()
            }
        }
    }

    /// Reinicia o stream periodicamente (resultado final encerra a task).
    private func restart() {
        guard isListening else { return }
        stop()
        Task { await start() }
    }

    @MainActor
    private func handleTranscript(_ transcript: String) {
        let normalized = transcript
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Processa apenas o sufixo novo desde a última detecção.
        guard normalized.count > lastProcessedSuffix.count else { return }
        let suffix = String(normalized.dropFirst(lastProcessedSuffix.count))

        for command in Command.allCases {
            if command.aliases.contains(where: { suffix.contains($0) }) {
                lastCommand = command
                triggerCount &+= 1
                lastProcessedSuffix = normalized
                return
            }
        }
    }
}
