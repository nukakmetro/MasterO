import Foundation
import SwiftData

@MainActor
final class TipsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allTips() throws -> [TipNote] {
        try context.fetch(FetchDescriptor<TipNote>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    func create(text: String) throws {
        context.insert(TipNote(text: text))
        try context.save()
    }

    func update(_ tip: TipNote, text: String) throws {
        tip.text = text
        try context.save()
    }

    func delete(_ tips: [TipNote]) throws {
        tips.forEach(context.delete)
        try context.save()
    }

    func importTips(_ entries: [TipArchiveEntry]) throws -> Int {
        for entry in entries {
            context.insert(TipNote(text: entry.text, createdAt: entry.createdAt))
        }
        try context.save()
        return entries.count
    }
}
