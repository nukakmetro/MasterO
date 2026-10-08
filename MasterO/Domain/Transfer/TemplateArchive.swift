import Foundation

struct TemplateArchive: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let templates: [TemplateArchiveEntry]

    init(templates: [TemplateArchiveEntry], exportedAt: Date = .now) {
        self.formatVersion = 1
        self.exportedAt = exportedAt
        self.templates = templates
    }
}

struct TemplateArchiveEntry: Codable {
    let name: String
    let createdAt: Date
    let items: [TemplateArchiveItem]

    init(template: ChecklistTemplate) {
        name = template.name
        createdAt = template.createdAt
        items = template.items.sorted { $0.sortOrder < $1.sortOrder }.map(TemplateArchiveItem.init)
    }
}

struct TemplateArchiveItem: Codable {
    let title: String
    let link: String
    let sortOrder: Int

    init(item: ChecklistTemplateItem) {
        title = item.title
        link = item.link
        sortOrder = item.sortOrder
    }
}

enum TemplateArchiveError: LocalizedError {
    case unsupportedVersion(Int)
    case emptyArchive

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version): "Формат архива версии \(version) не поддерживается."
        case .emptyArchive: "В архиве нет шаблонов."
        }
    }
}

enum TemplateArchiveCodec {
    static func encode(_ templates: [ChecklistTemplate]) throws -> Data {
        let archive = TemplateArchive(templates: templates.map(TemplateArchiveEntry.init))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(archive)
    }

    static func decode(_ data: Data) throws -> [TemplateArchiveEntry] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(TemplateArchive.self, from: data)
        guard archive.formatVersion == 1 else {
            throw TemplateArchiveError.unsupportedVersion(archive.formatVersion)
        }
        guard !archive.templates.isEmpty else {
            throw TemplateArchiveError.emptyArchive
        }
        return archive.templates
    }
}
