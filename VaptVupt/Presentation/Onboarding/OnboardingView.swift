//
//  OnboardingView.swift
//  SnapChef
//
//  Onboarding apresentado uma única vez (controle via @AppStorage).
//  Explica os três pilares do app: IA para parsear receitas, Despensa
//  Inteligente para mostrar o que dá pra fazer agora, e Modo Cozinha
//  mãos-livres com timer integrado.
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("vaptvupt.hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var page: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            tint: Color(red: 0.95, green: 0.55, blue: 0.20),
            title: "Upload com IA",
            subtitle: "Tire foto, dite por voz ou cole um link. A inteligência estrutura a receita inteira em segundos."
        ),
        OnboardingPage(
            icon: "refrigerator.fill",
            tint: Color(red: 0.35, green: 0.65, blue: 0.40),
            title: "Despensa inteligente",
            subtitle: "Adicione o que tem em casa (ou escaneie o rótulo) e veja na hora as receitas que você consegue fazer agora."
        ),
        OnboardingPage(
            icon: "flame.fill",
            tint: Color(red: 0.85, green: 0.35, blue: 0.55),
            title: "Modo cozinha mãos livres",
            subtitle: "Passe a mão por cima da câmera ou diga 'próximo' para avançar. O timer continua na Lock Screen e Dynamic Island."
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            indicators

            actions
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    // MARK: - Subviews

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.18))
                    .frame(width: 160, height: 160)
                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(page.tint)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(page.title)
                    .font(Theme.Typography.display)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.lg)
    }

    private var indicators: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.Colors.accent : Theme.Colors.separator)
                    .frame(width: index == page ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: Theme.Spacing.md) {
            if page < pages.count - 1 {
                Button {
                    complete()
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
                    withAnimation { page += 1 }
                } label: {
                    HStack {
                        Text("Próximo")
                            .font(Theme.Typography.cardTitle)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.large).fill(Theme.Colors.accent))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    complete()
                } label: {
                    Text("Começar a cozinhar")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.large).fill(Theme.Colors.accent))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: hasSeenOnboarding)
            }
        }
    }

    private func complete() {
        withAnimation { hasSeenOnboarding = true }
    }
}

// MARK: - Page model

private struct OnboardingPage: Hashable {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView()
}
