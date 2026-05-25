//
//  RemoteImage.swift
//  SnapChef
//
//  Wrapper unificado sobre `AsyncImage` com placeholder visual consistente
//  para todo o app, usado em cards e cabeçalhos de detalhes.
//

import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.3))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .empty:
                placeholder.overlay(ProgressView().tint(.white.opacity(0.8)))
            case .failure:
                placeholder.overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                )
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Theme.Colors.accent.opacity(0.7), Theme.Colors.accent.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
