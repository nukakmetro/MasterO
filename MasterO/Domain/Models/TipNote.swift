import Foundation
import SwiftData

@Model
final class TipNote {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date.now

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}
