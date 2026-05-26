//
//  CookingModeView.swift
//  SnapChef
//
//  Modo Cozinha: carrossel em tela cheia com os passos da receita.
//  Recursos integrados:
//   - `isIdleTimerDisabled` para manter a tela acesa
//   - Timer com detecção automática de minutos no texto
//   - Notificação local quando o timer terminar (mesmo com tela bloqueada)
//   - Registro do preparo no histórico (SwiftData)
//

import PhotosUI
import SwiftUI
import SwiftData
import UIKit

struct CookingModeView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationService.self) private var notifications

    @State private var currentIndex: Int = 0
    @State private var timerController = CookingTimerController()
    @State private var proximityObserver = ProximityObserver()
    @State private var voiceRecognizer = VoiceCommandRecognizer()
    @State private var didRecordHistory = false
    @State private var historyEntryID: PersistentIdentifier? = nil
    @State private var isHandsFreeEnabled: Bool = true
    @State private var isVoiceEnabled: Bool = false
    @State private var isMultiTimerSheetPresented: Bool = false
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var isFinishSheetPresented: Bool = false

    private var steps: [Step] { recipe.steps }

    var body: some View {
        rootStack
            .modifier(CookingModeLifecycle(
                isTimerActive: timerController.isActive,
                currentIndex: currentIndex,
                remainingSeconds: timerController.remainingSeconds,
                proximityTrigger: proximityObserver.triggerCount,
                voiceTrigger: voiceRecognizer.triggerCount,
                onAppearSetup: onAppearSetup,
                onTeardown: teardown,
                onProximityTrigger: advanceStep,
                onVoiceTrigger: handleVoiceCommand
            ))
    }

    private var rootStack: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                stepCarousel
                if !timerController.extraTimers.isEmpty {
                    extraTimersStrip
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if timerController.isActive {
                    timerBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                pagination
            }
        }
        .sheet(isPresented: $isMultiTimerSheetPresented) {
            AddExtraTimerSheet { label, minutes in
                timerController.addExtraTimer(label: label, minutes: minutes)
            }
            .presentationDetents([.fraction(0.35)])
        }
        .sheet(isPresented: $isFinishSheetPresented) {
            FinishCookingSheet(
                recipeTitle: recipe.title,
                photoItem: $photoPickerItem,
                onSkip: { isFinishSheetPresented = false; dismiss() },
                onSave: { savePhotoToHistory(); isFinishSheetPresented = false; dismiss() }
            )
            .presentationDetents([.medium])
        }
    }

    private func savePhotoToHistory() {
        Task { @MainActor in
            guard
                let item = photoPickerItem,
                let data = try? await item.loadTransferable(type: Data.self),
                let entryID = historyEntryID,
                let entry = modelContext.model(for: entryID) as? CookedRecipeEntry
            else { return }
            entry.photoData = data
            try? modelContext.save()
        }
    }

    private func teardown() {
        UIApplication.shared.isIdleTimerDisabled = false
        timerController.cancel()
        proximityObserver.stop()
        voiceRecognizer.stop()
    }

    private func advanceStep() {
        guard isHandsFreeEnabled, currentIndex < steps.count - 1 else { return }
        withAnimation { currentIndex += 1 }
    }

    private func goToPreviousStep() {
        guard currentIndex > 0 else { return }
        withAnimation { currentIndex -= 1 }
    }

    private func handleVoiceCommand() {
        guard let command = voiceRecognizer.lastCommand else { return }
        switch command {
        case .next:     advanceStep()
        case .previous: goToPreviousStep()
        case .pause:    if timerController.isRunning { timerController.togglePauseResume() }
        case .resume:   if !timerController.isRunning, timerController.isActive { timerController.togglePauseResume() }
        case .start:
            let step = steps[currentIndex]
            if let minutes = CookingTimerController.detectMinutes(in: step.instruction) {
                timerController.start(minutes: minutes, stepID: step.id, stepNumber: step.sequence)
            }
        case .cancel:   timerController.cancel()
        }
    }

    // MARK: - Lifecycle

    private func onAppearSetup() {
        UIApplication.shared.isIdleTimerDisabled = true

        // Configura o controlador para integrar notificações locais.
        timerController.notificationService = notifications
        timerController.recipeTitle = recipe.title

        // Liga o sensor de proximidade para navegação "mãos livres".
        if isHandsFreeEnabled {
            proximityObserver.start()
        }

        // Pede permissão de notificação (se ainda não decidido).
        Task { await notifications.requestPermissionIfNeeded() }

        // Registra o preparo no histórico (uma vez por apresentação).
        guard !didRecordHistory else { return }
        didRecordHistory = true
        let entry = CookedRecipeEntry(recipeID: recipe.id, title: recipe.title)
        modelContext.insert(entry)
        try? modelContext.save()
        historyEntryID = entry.persistentModelID
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MODO COZINHA")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.Colors.accent)
                    .tracking(1.5)
                Text(recipe.title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(1)
            }
            Spacer()
            multiTimerToggle
            voiceToggle
            handsFreeToggle
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Theme.Colors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.Colors.surface))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
    }

    /// Botão para adicionar um timer extra (paralelo ao timer do passo).
    private var multiTimerToggle: some View {
        Button {
            isMultiTimerSheetPresented = true
        } label: {
            Image(systemName: "timer.circle.fill")
                .font(.callout.weight(.bold))
                .foregroundStyle(Theme.Colors.primaryText)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.Colors.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Adicionar timer extra")
    }

    /// Strip horizontal com os timers extras ativos.
    private var extraTimersStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(timerController.extraTimers) { aux in
                    extraTimerChip(aux)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func extraTimerChip(_ aux: AuxiliaryTimer) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.Colors.accent.opacity(0.2))
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Theme.Colors.accent, lineWidth: aux.isRunning ? 1.5 : 0.5))
            VStack(alignment: .leading, spacing: 0) {
                Text(aux.label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(aux.formatted)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            Button { timerController.toggleExtraTimer(aux.id) } label: {
                Image(systemName: aux.isRunning ? "pause.fill" : "play.fill")
                    .font(.caption2.weight(.bold))
                    .padding(6)
                    .background(Circle().fill(Theme.Colors.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Button { timerController.removeExtraTimer(aux.id) } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Theme.Colors.surface)
        )
    }

    /// Toggle do reconhecimento de voz — diga "próximo", "voltar", "pausar"
    /// etc. para controlar o Modo Cozinha sem encostar no telefone.
    private var voiceToggle: some View {
        Button {
            if isVoiceEnabled {
                voiceRecognizer.stop()
                isVoiceEnabled = false
            } else {
                isVoiceEnabled = true
                Task { await voiceRecognizer.start() }
            }
        } label: {
            Image(systemName: isVoiceEnabled ? "mic.fill" : "mic.slash")
                .font(.callout.weight(.bold))
                .foregroundStyle(isVoiceEnabled ? .white : Theme.Colors.primaryText)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isVoiceEnabled ? Theme.Colors.accent : Theme.Colors.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Comandos de voz")
        .accessibilityValue(isVoiceEnabled ? "Ativados" : "Desativados")
    }

    /// Toggle do modo "mãos livres" — passe a mão por cima da câmera frontal
    /// para avançar o passo sem tocar na tela suja.
    private var handsFreeToggle: some View {
        Button {
            isHandsFreeEnabled.toggle()
            if isHandsFreeEnabled {
                proximityObserver.start()
            } else {
                proximityObserver.stop()
            }
        } label: {
            Image(systemName: isHandsFreeEnabled ? "hand.wave.fill" : "hand.wave")
                .font(.callout.weight(.bold))
                .foregroundStyle(isHandsFreeEnabled ? .white : Theme.Colors.primaryText)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isHandsFreeEnabled ? Theme.Colors.accent : Theme.Colors.surface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Modo mãos livres")
        .accessibilityValue(isHandsFreeEnabled ? "Ativado" : "Desativado")
    }

    // MARK: - Step carousel

    private var stepCarousel: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepCard(step)
                    .padding(.horizontal, Theme.Spacing.md)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func stepCard(_ step: Step) -> some View {
        let detectedMinutes = CookingTimerController.detectMinutes(in: step.instruction)

        return VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Passo \(step.sequence) de \(steps.count)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)

            Text(step.instruction)
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.Colors.primaryText)
                .multilineTextAlignment(.leading)

            if let minutes = detectedMinutes {
                Button {
                    timerController.start(minutes: minutes, stepID: step.id, stepNumber: step.sequence)
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "timer")
                        Text("Iniciar timer de \(minutes) min")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .foregroundStyle(.white)
                    .background(Capsule().fill(Theme.Colors.accent))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xlarge, style: .continuous)
                .fill(Theme.Colors.surface)
        )
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Timer banner

    private var timerBanner: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: timerController.progress)
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .frame(width: 40, height: 40)
            .animation(.linear(duration: 1), value: timerController.progress)

            VStack(alignment: .leading, spacing: 2) {
                Text(timerController.formatted)
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                Text(timerController.isRunning ? "Em andamento" : "Pausado")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }

            Spacer()

            Button {
                timerController.togglePauseResume()
            } label: {
                Image(systemName: timerController.isRunning ? "pause.fill" : "play.fill")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.Colors.accent))
            }
            .buttonStyle(.plain)

            Button {
                timerController.cancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.Colors.surface))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Pagination

    private var pagination: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                withAnimation { currentIndex = max(0, currentIndex - 1) }
            } label: {
                Image(systemName: "chevron.left")
                    .padding(Theme.Spacing.md)
                    .background(Circle().fill(Theme.Colors.surface))
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.4 : 1)

            HStack(spacing: 6) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Theme.Colors.accent : Theme.Colors.separator)
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            }

            if currentIndex == steps.count - 1 {
                Button {
                    isFinishSheetPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("Concluir")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(Theme.Spacing.md)
                    .background(Capsule().fill(.green))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    withAnimation { currentIndex = min(steps.count - 1, currentIndex + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .padding(Theme.Spacing.md)
                        .background(Circle().fill(Theme.Colors.accent))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

#Preview {
    CookingModeView(recipe: MockRecipes.fitChicken)
        .environment(NotificationService())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}

// MARK: - Lifecycle modifier

/// Centraliza todos os modifiers reativos do Modo Cozinha em um único
/// `ViewModifier` para aliviar o type-checker do SwiftUI — sem isso, o
/// body fica grande demais e o Swift recusa compilar.
private struct CookingModeLifecycle: ViewModifier {
    let isTimerActive: Bool
    let currentIndex: Int
    let remainingSeconds: Int
    let proximityTrigger: Int
    let voiceTrigger: Int
    let onAppearSetup: () -> Void
    let onTeardown: () -> Void
    let onProximityTrigger: () -> Void
    let onVoiceTrigger: () -> Void

    func body(content: Content) -> some View {
        content
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isTimerActive)
            .modifier(HapticsModifier(
                currentIndex: currentIndex,
                isTimerActive: isTimerActive,
                remainingSeconds: remainingSeconds
            ))
            .onAppear(perform: onAppearSetup)
            .onDisappear(perform: onTeardown)
            .onChange(of: proximityTrigger) { _, _ in onProximityTrigger() }
            .onChange(of: voiceTrigger) { _, _ in onVoiceTrigger() }
    }
}

// MARK: - Add Extra Timer sheet

private struct AddExtraTimerSheet: View {
    let onAdd: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label: String = ""
    @State private var minutes: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do timer (ex: molho)", text: $label)
                    Stepper(value: $minutes, in: 1...180, step: 1) {
                        Text("\(minutes) min")
                            .monospacedDigit()
                    }
                } header: {
                    Text("Novo timer paralelo")
                } footer: {
                    Text("Útil para acompanhar duas partes da receita ao mesmo tempo. Sem Live Activity nem notificação local.")
                }
            }
            .navigationTitle("Timer extra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Adicionar") {
                        let cleaned = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(cleaned.isEmpty ? "Timer \(minutes) min" : cleaned, minutes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Finish sheet (foto do prato pronto)

private struct FinishCookingSheet: View {
    let recipeTitle: String
    @Binding var photoItem: PhotosPickerItem?
    let onSkip: () -> Void
    let onSave: () -> Void

    @State private var previewData: Data? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Prato pronto! 🎉")
                        .font(Theme.Typography.title)
                    Text("Quer registrar uma foto do seu \(recipeTitle.lowercased())?")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.md)

                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.large)
                        .fill(Theme.Colors.surface)
                        .frame(height: 180)
                    if let data = previewData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    } else {
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundStyle(Theme.Colors.accent)
                            Text("Toque para escolher")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.secondaryText)
                        }
                    }
                }
                .overlay {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Color.clear
                    }
                }

                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        onSkip()
                    } label: {
                        Text("Pular")
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.large).fill(Theme.Colors.surface))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSave()
                    } label: {
                        Text("Salvar")
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.large).fill(Theme.Colors.accent))
                    }
                    .buttonStyle(.plain)
                    .disabled(previewData == nil)
                    .opacity(previewData == nil ? 0.5 : 1)
                }
            }
            .padding(Theme.Spacing.md)
            .navigationTitle("Concluído")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        previewData = data
                    }
                }
            }
        }
    }
}

private struct HapticsModifier: ViewModifier {
    let currentIndex: Int
    let isTimerActive: Bool
    let remainingSeconds: Int

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.selection, trigger: currentIndex)
            .sensoryFeedback(.success, trigger: isTimerActive, condition: timerStarted)
            .sensoryFeedback(.impact(weight: .heavy), trigger: remainingSeconds, condition: timerZeroed)
    }

    private func timerStarted(_ old: Bool, _ new: Bool) -> Bool {
        !old && new
    }

    private func timerZeroed(_ old: Int, _ new: Int) -> Bool {
        old == 1 && new == 0
    }
}
