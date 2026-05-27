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

    @State private var isTipJarPresented: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    achievementsSection
                    appearanceSection
                    notificationsSection
                    historySection
                    supportSection
                    aboutSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Ajustes")
            .sheet(isPresented: $isTipJarPresented) {
                TipJarView()
            }
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
        .accessibilityLabel("Aparência: \(mode.displayName)")
        .accessibilityAddTraits(appearance == mode ? [.isSelected] : [])
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

    private var achievementsSection: some View {
        let snapshot = StreakService.snapshot(from: historyEntries)
        let unlocked = Set(StreakService.unlockedBadges(from: historyEntries).map(\.id))

        return section(title: "Conquistas") {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                streakHeader(snapshot)
                badgesGrid(unlocked: unlocked)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private func streakHeader(_ snapshot: StreakService.Snapshot) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(snapshot.currentStreak) dia\(snapshot.currentStreak == 1 ? "" : "s") seguidos")
                    .font(Theme.Typography.cardTitle)
                Text(snapshot.longestStreak > snapshot.currentStreak
                     ? "Recorde: \(snapshot.longestStreak) dias"
                     : "Continue cozinhando!")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(snapshot.totalCount)")
                    .font(Theme.Typography.title)
                    .monospacedDigit()
                Text("receitas")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
    }

    private func badgesGrid(unlocked: Set<String>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Theme.Spacing.sm)], spacing: Theme.Spacing.sm) {
            ForEach(AchievementBadge.catalog) { badge in
                let isUnlocked = unlocked.contains(badge.id)
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: badge.systemIcon)
                        .font(.title2)
                        .foregroundStyle(isUnlocked ? badge.tint : Theme.Colors.secondaryText.opacity(0.4))
                    Text(badge.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isUnlocked ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
                        .lineLimit(1)
                    Text(badge.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .fill(isUnlocked ? badge.tint.opacity(0.10) : Theme.Colors.background)
                )
                .opacity(isUnlocked ? 1 : 0.55)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(badge.title), \(isUnlocked ? "desbloqueado" : "bloqueado"). \(badge.subtitle).")
            }
        }
    }

    private var supportSection: some View {
        section(title: "Apoie o desenvolvedor") {
            Button {
                isTipJarPresented = true
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pagar um café para o dev")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                        Text("Doação simbólica — escolha o tamanho.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
