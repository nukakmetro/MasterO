import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TipsViewModel {
    private(set) var tips: [TipNote] = []
    var errorMessage: String?
    private var repository: TipsRepository?

    func connect(to context: ModelContext) {
        repository = TipsRepository(context: context)
        refresh()
    }

    func refresh() {
        guard let repository else { return }
        do { tips = try repository.allTips() }
        catch { report(error) }
    }

    func save(_ text: String, editing tip: TipNote?) {
        guard let repository else { return }
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else { return }
        do {
            if let tip { try repository.update(tip, text: normalizedText) }
            else { try repository.create(text: normalizedText) }
            refresh()
        } catch { report(error) }
    }

    func delete(ids: Set<UUID>) {
        guard let repository else { return }
        let selectedTips = tips.filter { ids.contains($0.id) }
        do { try repository.delete(selectedTips); refresh() }
        catch { report(error) }
    }

    func exportTips(_ tips: [TipNote]) -> Data? {
        do { return try TipArchiveCodec.encode(tips) }
        catch { report(error); return nil }
    }

    func importTips(from data: Data) -> Int? {
        guard let repository else { return nil }
        do {
            let entries = try TipArchiveCodec.decode(data)
            let count = try repository.importTips(entries)
            refresh()
            return count
        } catch { report(error); return nil }
    }

    private func report(_ error: Error) {
        errorMessage = "Не удалось выполнить действие: \(error.localizedDescription)"
    }
}
