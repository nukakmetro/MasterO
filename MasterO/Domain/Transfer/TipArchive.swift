import Foundation

struct TipArchive: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let tips: [TipArchiveEntry]

    init(tips: [TipArchiveEntry], exportedAt: Date = .now) {
        formatVersion = 1
        self.exportedAt = exportedAt
        self.tips = tips
    }
}

struct TipArchiveEntry: Codable {
    let text: String
    let createdAt: Date

    init(tip: TipNote) {
        text = tip.text
        createdAt = tip.createdAt
    }
}

enum TipArchiveCodec {
    static func encode(_ tips: [TipNote]) throws -> Data {
        let archive = TipArchive(tips: tips.map(TipArchiveEntry.init))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(archive)
    }

    static func decode(_ data: Data) throws -> [TipArchiveEntry] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(TipArchive.self, from: data)
        guard archive.formatVersion == 1 else {
            throw NSError(domain: "CheckTuk.TipsArchive", code: 1, userInfo: [NSLocalizedDescriptionKey: "Формат архива версии \(archive.formatVersion) не поддерживается."])
        }
        guard !archive.tips.isEmpty else {
            throw NSError(domain: "CheckTuk.TipsArchive", code: 2, userInfo: [NSLocalizedDescriptionKey: "В архиве нет подсказок."])
        }
        return archive.tips
    }
}
