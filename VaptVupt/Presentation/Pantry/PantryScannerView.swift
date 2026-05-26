//
//  PantryScannerView.swift
//  SnapChef
//
//  Sheet que abre a câmera com `DataScannerViewController` (VisionKit) e
//  captura texto em tempo real para alimentar a Despensa. O scanner roda
//  com `recognizedDataTypes: [.text]` e, a cada item reconhecido, filtra
//  contra um conjunto de palavras-âncora (lista de sugestões + dicionário
//  estendido) para ignorar ruído de rótulo ("INGREDIENTES:", marcas, etc.).
//
//  Pré-requisitos no Info.plist do target:
//    • NSCameraUsageDescription = "Usamos a câmera para escanear rótulos
//      de alimentos e adicionar à sua despensa automaticamente."
//

import SwiftUI
import VisionKit

struct PantryScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PantryStore.self) private var pantry

    @State private var recentlyAdded: [String] = []
    @State private var isSupported: Bool = DataScannerViewController.isSupported

    var body: some View {
        NavigationStack {
            ZStack {
                if isSupported {
                    DataScannerRepresentable { recognized in
                        addIfRecognized(recognized)
                    }
                    .ignoresSafeArea()

                    feedbackOverlay
                } else {
                    unsupportedView
                }
            }
            .navigationTitle("Escanear Despensa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Concluir") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Overlay

    private var feedbackOverlay: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "viewfinder")
                        .foregroundStyle(Theme.Colors.accent)
                    Text("Aponte para o rótulo do alimento")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(.white)
                }
                if recentlyAdded.isEmpty {
                    Text("Nada adicionado ainda…")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Text("Adicionados: " + recentlyAdded.suffix(5).joined(separator: ", "))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(.black.opacity(0.55))
            )
            .padding(Theme.Spacing.md)
        }
    }

    private var unsupportedView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "camera.metering.unknown")
                .font(.largeTitle)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Câmera não disponível")
                .font(Theme.Typography.cardTitle)
            Text("Este recurso requer iOS 16+ e um aparelho com câmera traseira compatível.")
                .font(Theme.Typography.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Match logic

    private func addIfRecognized(_ rawText: String) {
        let normalized = rawText
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else { return }

        // Vocabulário base = sugestões âncora + extras comuns.
        let vocab = (PantryStore.quickSuggestions + Self.extraVocab).map { $0.lowercased() }

        guard let match = vocab.first(where: { normalized.contains($0) }) else { return }
        let cleanName = match.capitalized

        if pantry.contains(cleanName) { return }
        pantry.add(cleanName)
        recentlyAdded.append(cleanName)
    }

    /// Dicionário extra para reconhecimento — adicione novos termos aqui
    /// conforme o app cresce (substituir por NLP/embedding em produção).
    private static let extraVocab: [String] = [
        "Iogurte", "Café", "Pão", "Chocolate", "Mel", "Aveia",
        "Cenoura", "Batata", "Carne", "Peixe", "Atum", "Sardinha",
        "Macarrão", "Lentilha", "Grão de bico", "Quinoa", "Castanha"
    ]
}

// MARK: - UIViewControllerRepresentable

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onText: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onText: onText) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onText: (String) -> Void
        init(onText: @escaping (String) -> Void) { self.onText = onText }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case let .text(text) = item {
                    onText(text.transcript)
                }
            }
        }
    }
}
