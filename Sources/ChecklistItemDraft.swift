import Foundation

struct ChecklistItemDraft: Identifiable {
    var id: UUID?
    var title: String
    var link: String
    var isChecked: Bool

    init(id: UUID? = nil, title: String = "", link: String = "", isChecked: Bool = false) {
        self.id = id
        self.title = title
        self.link = link
        self.isChecked = isChecked
    }
}
