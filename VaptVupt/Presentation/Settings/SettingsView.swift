//
//  SettingsView.swift
//  SnapChef
//
//  Aba de ajustes: aparência (claro/escuro/sistema), estado das
//  notificações e informações do app.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @AppStorage("snapchef.appearance") private var appearance: AppearanceMode = .system
    @Environment(NotificationService.self) private var notifications
    @Environment(\.modelContext) private var modelContext

    @Query private var historyEntries: [CookedRecipeEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    appearanceSection
                    notificationsSection
                    historySection
                    aboutSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Ajustes")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        section(title: "Aparência") {
            VStack(spacing: 0) {
                ForEach(AppearanceMode.allCases) { mode in
                    appearanceRow(mode)
                    if mode != AppearanceMode.allCases.last {
                        Divider().padding(.leading, Theme.Spacing.xxl)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private func appearanceRow(_ mode: AppearanceMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appearance = mode
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: mode.systemIcon)
                    .font(.callout)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 28)
                Text(mode.displayName)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
                if appearance == mode {
                    Image(systemName: "checkmark")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var notificationsSection: some View {
        section(title: "Notificações") {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: "bell.badge.fill")
                    .font(.callout)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationsStatusTitle)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text(notificationsStatusSubtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                Spacer()
                if notifications.authorizationStatus == .notDetermined {
                    Button("Permitir") {
                        Task { await notifications.requestPermissionIfNeeded() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private var historySection: some View {
        section(title: "Histórico") {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 28)
                    Text("\(historyEntries.count) preparos registrados")
                        .font(Theme.Typography.body)
                    Spacer()
                    if !historyEntries.isEmpty {
                        Button("Limpar") { clearHistory() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private var aboutSection: some View {
        section(title: "Sobre") {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("SnapChef")
                    .font(Theme.Typography.cardTitle)
                Text("MVP — versão 0.1")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .textCase(.uppercase)
            content()
        }
    }

    private var notificationsStatusTitle: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: "Ativas"
        case .denied: "Desativadas no iOS"
        case .notDetermined: "Permitir notificações"
        @unknown default: "Indisponíveis"
        }
    }

    private var notificationsStatusSubtitle: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            "Avisamos quando o timer do Modo Cozinha terminar."
        case .denied:
            "Ative em Ajustes › SnapChef para receber alertas do timer."
        case .notDetermined:
            "Receba um aviso quando o timer terminar."
        @unknown default:
            ""
        }
    }

    private func clearHistory() {
        for entry in historyEntries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .environment(NotificationService())
        .modelContainer(for: CookedRecipeEntry.self, inMemory: true)
}
