//
//  VaptVuptWidgetLiveActivity.swift
//  VaptVuptWidget
//
//  UI da Live Activity do timer do Modo Cozinha. Implementa o
//  `ActivityConfiguration<CookingActivityAttributes>` para Lock Screen
//  e três variantes de Dynamic Island (compact / minimal / expanded).
//
//  Usa `Text(timerInterval:)` para deixar o sistema desenhar a contagem
//  regressiva sem que o app precise emitir `update` a cada segundo.
//
//  Pré-requisito: `CookingActivityAttributes.swift` (em
//  `VaptVupt/Domain/Models/`) precisa ter Target Membership ativado
//  também para o target VaptVuptWidgetExtension. No Xcode: selecione o
//  arquivo, File Inspector (cmd+opt+1), marque "VaptVuptWidgetExtension".
//

import ActivityKit
import SwiftUI
import WidgetKit

struct VaptVuptWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookingActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerLabel(for: context.state)
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Passo \(context.attributes.stepNumber)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.recipeTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                timerLabel(for: context.state)
                    .font(.caption.monospacedDigit().weight(.semibold))
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
            .keylineTint(.orange)
        }
    }

    /// Mostra `mm:ss` em modo regressivo. Se pausado, exibe o tempo
    /// estático congelado em `pausedRemainingSeconds`.
    @ViewBuilder
    private func timerLabel(for state: CookingActivityAttributes.ContentState) -> some View {
        if state.isPaused, let remaining = state.pausedRemainingSeconds {
            Text(formatted(remaining))
        } else {
            Text(timerInterval: Date()...state.endDate, countsDown: true)
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Lock Screen view

private struct LockScreenView: View {
    let context: ActivityViewContext<CookingActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.25), lineWidth: 4)
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("MODO COZINHA — Passo \(context.attributes.stepNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                    .tracking(1.2)
                Text(context.attributes.recipeTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            timerDisplay
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var timerDisplay: some View {
        if context.state.isPaused, let remaining = context.state.pausedRemainingSeconds {
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
        } else {
            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
        }
    }
}
