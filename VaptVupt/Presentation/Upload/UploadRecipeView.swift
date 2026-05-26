//
//  UploadRecipeView.swift
//  SnapChef
//
//  Tela "core" do app — Upload Inteligente. Combina três pontos de entrada
//  alimentados por IA (foto/voz/link) com um formulário manual que reflete
//  os campos preenchidos pela LLM.
//

import SwiftUI

struct UploadRecipeView: View {
    @Bindable var viewModel: UploadRecipeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    aiHeader
                    aiActionsRow
                    if viewModel.showLinkInput { linkInput }
                    aiStateBanner
                    Divider().padding(.vertical, Theme.Spacing.xs)
                    formSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Colors.background)
            .sensoryFeedback(trigger: viewModel.aiState) { _, newValue in
                switch newValue {
                case .finished: .success
                case .failed:   .error
                default:        nil
                }
            }
            .navigationTitle("Nova Receita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - AI Section

    private var aiHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Adicionar com IA")
                .font(Theme.Typography.sectionTitle)
            Text("Deixe a inteligência artificial estruturar a receita para você.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private var aiActionsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            aiButton(
                title: "Tirar Foto",
                subtitle: "OCR & IA",
                systemIcon: "camera.fill",
                action: viewModel.triggerPhotoCapture
            )
            aiButton(
                title: "Ditado",
                subtitle: "Voz → texto",
                systemIcon: "waveform",
                action: viewModel.triggerVoiceDictation
            )
            aiButton(
                title: "Colar Link",
                subtitle: "Importar URL",
                systemIcon: "link",
                action: {
                    withAnimation { viewModel.showLinkInput.toggle() }
                }
            )
        }
    }

    private func aiButton(title: String, subtitle: String, systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Image(systemName: systemIcon)
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.accent)
                Text(title)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text(subtitle)
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
        .buttonStyle(.plain)
    }

    private var linkInput: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "link")
                .foregroundStyle(Theme.Colors.secondaryText)
            TextField("Cole o link da receita", text: $viewModel.pastedLink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            Button("Importar") {
                viewModel.triggerLinkParse()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Colors.accent)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private var aiStateBanner: some View {
        switch viewModel.aiState {
        case .idle:
            EmptyView()
        case .processing(let source):
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                Text(processingMessage(for: source))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.accent.opacity(0.10))
            )
        case .finished:
            stateBanner(icon: "sparkles", text: "Receita estruturada! Revise abaixo e salve.", tint: .green)
        case .failed(let message):
            stateBanner(icon: "exclamationmark.triangle.fill", text: message, tint: .red)
        }
    }

    private func processingMessage(for source: RecipeAIService.InputSource) -> String {
        switch source {
        case .photo: "Lendo a foto e interpretando ingredientes..."
        case .voice: "Transcrevendo o áudio e estruturando..."
        case .link:  "Importando conteúdo do link..."
        case .text:  "Processando texto..."
        }
    }

    private func stateBanner(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.primaryText)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(tint.opacity(0.10))
        )
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            titleAndDescription
            metricsSection
            categoriesSection
            ingredientsSection
            stepsSection
        }
    }

    private var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            labeledField(label: "Título") {
                TextField("Ex: Frango grelhado fit", text: $viewModel.title)
                    .textFieldStyle(.plain)
            }
            labeledField(label: "Descrição (opcional)") {
                TextField("Resumo curto da receita", text: $viewModel.description, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
            }
        }
    }

    private var metricsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            metricStepper(label: "Tempo (min)", value: $viewModel.prepTime, range: 1...600, step: 5)
            metricStepper(label: "Porções", value: $viewModel.servings, range: 1...20, step: 1)
        }
    }

    private func metricStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            Stepper(value: value, in: range, step: step) {
                Text("\(value.wrappedValue)")
                    .font(Theme.Typography.cardTitle)
                    .monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.Colors.surface)
            )
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Categorias")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)

            ForEach(RecipeCategoryGroup.allCases) { group in
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(group.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(group.accentColor)
                    flowLayout(items: group.subcategories) { sub in
                        TagPill(
                            title: sub.rawValue,
                            tint: group.accentColor,
                            isSelected: viewModel.selectedSubcategories.contains(sub),
                            isInteractive: true,
                            action: { viewModel.toggle(subcategory: sub) }
                        )
                    }
                }
                .padding(.bottom, Theme.Spacing.xs)
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Ingredientes")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                Button {
                    viewModel.addEmptyIngredient()
                } label: {
                    Label("Adicionar", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Theme.Colors.accent)
            }

            if viewModel.ingredients.isEmpty {
                emptyHint("Use a IA acima ou adicione ingredientes manualmente.")
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, _ in
                        ingredientRow(index: index)
                    }
                }
            }
        }
    }

    private func ingredientRow(index: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Ingrediente", text: $viewModel.ingredients[index].name)
                .textFieldStyle(.plain)
            TextField("Qtd", value: $viewModel.ingredients[index].quantity, format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
            Picker("Unidade", selection: $viewModel.ingredients[index].unit) {
                ForEach(IngredientUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Theme.Colors.accent)
            Button {
                viewModel.removeIngredient(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Color.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Modo de preparo")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                Button {
                    viewModel.addEmptyStep()
                } label: {
                    Label("Adicionar", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Theme.Colors.accent)
            }

            if viewModel.steps.isEmpty {
                emptyHint("Descreva o passo a passo da receita ou deixe a IA fazer isso.")
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, _ in
                        stepRow(index: index)
                    }
                }
            }
        }
    }

    private func stepRow(index: Int) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("\(viewModel.steps[index].sequence)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Colors.accent))
            TextField("Descreva o passo", text: $viewModel.steps[index].instruction, axis: .vertical)
                .lineLimit(1...4)
            Button {
                viewModel.removeStep(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(Color.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    // MARK: - Helpers

    private func labeledField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            content()
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                        .fill(Theme.Colors.surface)
                )
        }
    }

    private func emptyHint(_ message: String) -> some View {
        Text(message)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Colors.separator, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
    }

    /// Layout estilo "flow" usando o `Layout` protocolo do SwiftUI para as Pills
    /// de subcategoria. Quebra para a próxima linha quando excede a largura.
    @ViewBuilder
    private func flowLayout<Item: Identifiable, ItemView: View>(
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> ItemView
    ) -> some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

// MARK: - FlowLayout

/// Layout que organiza filhos em linhas, quebrando para a próxima quando o
/// espaço horizontal é insuficiente. Usado para os seletores de tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    UploadRecipeView(viewModel: UploadRecipeViewModel(onSave: { _ in }))
}
