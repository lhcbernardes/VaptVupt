//
//  RecipeShareService.swift
//  SnapChef
//
//  Serializa e desserializa receitas para compartilhamento por link
//  (`vaptvupt://import?data=<base64url>`). O payload usa um envelope
//  versionado para permitir evolução compatível do formato.
//
//  Como funciona:
//   1. `encode(_:)` → JSON → base64url → URL `vaptvupt://import?data=...`
//   2. Qualquer canal de texto (WhatsApp, e-mail, etc.) preserva o link.
//   3. No destino, `decode(from:)` desfaz o caminho e devolve uma `Recipe`.
//
//  Limitações conhecidas:
//   • Receitas muito grandes podem estourar o limite de URL do iOS (~8KB).
//   • O esquema `vaptvupt://` precisa estar registrado em `CFBundleURLTypes`
//     no Info.plist para que o sistema abra o app ao tocar no link.
//

import Foundation

enum RecipeShareService {

    /// Esquema customizado registrado pelo app no Info.plist.
    static let urlScheme = "vaptvupt"
    static let importHost = "import"
    static let dataQueryItem = "data"

    /// Versão atual do envelope JSON. Incrementar ao quebrar compatibilidade.
    private static let currentVersion = 1

    // MARK: - Envelope

    /// Envelope versionado. Mantemos `Recipe` aninhada em `payload` para
    /// permitir incluir metadados (assinatura, autor, expiração) sem quebrar
    /// o parsing antigo.
    private struct Envelope: Codable {
        let v: Int
        let payload: Recipe
    }

    // MARK: - Encode

    /// Empacota uma receita em uma URL `vaptvupt://import?data=...`.
    /// Devolve `nil` se a serialização falhar (não deve acontecer em prática).
    static func encode(_ recipe: Recipe) -> URL? {
        let envelope = Envelope(v: currentVersion, payload: recipe)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        guard let json = try? encoder.encode(envelope) else { return nil }
        let base64 = json.base64URLEncodedString()

        var components = URLComponents()
        components.scheme = urlScheme
        components.host = importHost
        components.queryItems = [URLQueryItem(name: dataQueryItem, value: base64)]

        return components.url
    }

    // MARK: - Decode

    /// Tenta decodificar uma URL de import gerada por `encode(_:)`.
    /// Retorna `nil` para qualquer URL malformada ou de versão desconhecida.
    static func decode(from url: URL) -> Recipe? {
        guard
            url.scheme?.lowercased() == urlScheme,
            url.host?.lowercased() == importHost,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let base64 = components.queryItems?.first(where: { $0.name == dataQueryItem })?.value,
            let json = Data(base64URLEncoded: base64)
        else { return nil }

        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: json) else { return nil }
        guard envelope.v == currentVersion else { return nil }

        // Renova o id para evitar colisão com a receita original no destino.
        var imported = envelope.payload
        imported.id = UUID()
        return imported
    }

    /// Detecta uma URL de import em uma string arbitrária — útil para o
    /// campo "Colar Link" do Upload, em que o usuário pode colar texto
    /// solto contendo o link.
    static func extractImportURL(from text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in detector.matches(in: text, range: range) {
            if let url = match.url, url.scheme?.lowercased() == urlScheme {
                return url
            }
        }
        // Fallback: tenta interpretar a string inteira como URL.
        if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme?.lowercased() == urlScheme {
            return url
        }
        return nil
    }
}

// MARK: - Base64URL helpers

private extension Data {
    /// Base64URL = Base64 sem padding, com `-` e `_` no lugar de `+` e `/`.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Reaplica padding `=` necessário para o decoder padrão.
        let mod = s.count % 4
        if mod != 0 {
            s.append(String(repeating: "=", count: 4 - mod))
        }
        self.init(base64Encoded: s)
    }
}
