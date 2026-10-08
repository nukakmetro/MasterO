import Foundation

struct ChecklistItemDraft: Identifiable {
    let id: UUID
    var storedID: UUID?
    var title: String
    var link: String
    var isChecked: Bool

    init(id: UUID? = nil, title: String = "", link: String = "", isChecked: Bool = false) {
        self.id = UUID()
        self.storedID = id
        self.title = title
        self.link = link
        self.isChecked = isChecked
    }
}
