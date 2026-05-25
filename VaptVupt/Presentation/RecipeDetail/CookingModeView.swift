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
    @State private var didRecordHistory = false

    private var steps: [Step] { recipe.steps }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                stepCarousel
                if timerController.isActive {
                    timerBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                pagination
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerController.isActive)
        .onAppear { onAppearSetup() }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timerController.cancel()
        }
    }

    // MARK: - Lifecycle

    private func onAppearSetup() {
        UIApplication.shared.isIdleTimerDisabled = true

        // Configura o controlador para integrar notificações locais.
        timerController.notificationService = notifications
        timerController.recipeTitle = recipe.title

        // Pede permissão de notificação (se ainda não decidido).
        Task { await notifications.requestPermissionIfNeeded() }

        // Registra o preparo no histórico (uma vez por apresentação).
        guard !didRecordHistory else { return }
        didRecordHistory = true
        let entry = CookedRecipeEntry(recipeID: recipe.id, title: recipe.title)
        modelContext.insert(entry)
        try? modelContext.save()
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

            Button {
                withAnimation { currentIndex = min(steps.count - 1, currentIndex + 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .padding(Theme.Spacing.md)
                    .background(Circle().fill(Theme.Colors.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == steps.count - 1)
            .opacity(currentIndex == steps.count - 1 ? 0.4 : 1)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
}

#Preview {
    CookingModeView(recipe: MockRecipes.fitChicken)
        .environment(NotificationService())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}
