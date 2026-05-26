//
//  PantryView.swift
//  SnapChef
//
//  Sheet de gerenciamento da Despensa Inteligente. Mostra o input para
//  adicionar ingredientes, atalhos com sugestões comuns e a lista atual
//  do usuário. Persistência é tratada pelo `PantryStore`.
//

import SwiftUI

struct PantryView: View {

    @Environment(PantryStore.self) private var pantry
    @Environment(\.dismiss) private var dismiss

    @State private var newItemName: String = ""
    @State private var isScannerPresented: Bool = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    intro
                    inputField
                    suggestionsSection
                    itemsSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .sensoryFeedback(.selection, trigger: pantry.items.count)
            .navigationTitle("Minha Despensa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Concluir") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Button {
                            isScannerPresented = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                        }
                        if !pantry.items.isEmpty {
                            Button("Limpar") {
                                withAnimation { pantry.clear() }
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $isScannerPresented) {
                PantryScannerView()
                    .environment(pantry)
            }
        }
    }

    // MARK: - Subviews

    private var intro: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "refrigerator.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.accent)
                Text("\(pantry.items.count) ingredientes")
                    .font(Theme.Typography.cardTitle)
            }
            Text("Adicione o que tem em casa para receber receitas que você consegue fazer agora.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var inputField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Theme.Colors.accent)
            TextField("Adicionar ingrediente", text: $newItemName)
                .focused($inputFocused)
                .submitLabel(.done)
                .onSubmit(commitNewItem)
                .textInputAutocapitalization(.sentences)
            if !newItemName.isEmpty {
                Button("Adicionar", action: commitNewItem)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sugestões")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(filteredSuggestions, id: \.self) { suggestion in
                        Button {
                            withAnimation { pantry.add(suggestion) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                Text(suggestion)
                                    .font(Theme.Typography.caption)
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                Capsule().fill(Theme.Colors.accent.opacity(0.12))
                            )
                            .foregroundStyle(Theme.Colors.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sua despensa")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .textCase(.uppercase)

            if pantry.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(pantry.items) { item in
                        row(for: item)
                    }
                }
            }
        }
    }

    private func row(for item: PantryItem) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.accent)
            Text(item.name)
                .font(Theme.Typography.body)
            Spacer()
            Button {
                withAnimation { pantry.remove(item.id) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Sua despensa está vazia.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Comece adicionando o que você já tem em casa.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .stroke(Theme.Colors.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
    }

    // MARK: - Helpers

    /// Esconde sugestões que o usuário já adicionou à despensa.
    private var filteredSuggestions: [String] {
        PantryStore.quickSuggestions.filter { !pantry.contains($0) }
    }

    private func commitNewItem() {
        withAnimation { pantry.add(newItemName) }
        newItemName = ""
        inputFocused = true
    }
}

#Preview {
    PantryView()
        .environment(PantryStore())
}
