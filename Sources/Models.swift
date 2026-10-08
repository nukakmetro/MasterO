import Foundation
import SwiftData

enum ApplicationStatus: String, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notStarted: "Не начат"
        case .inProgress: "В работе"
        case .completed: "Завершён"
        }
    }

    var colorName: String {
        switch self {
        case .notStarted: "secondary"
        case .inProgress: "orange"
        case .completed: "green"
        }
    }
}

@Model
final class ReleaseApplication {
    var id: UUID = UUID()
    var name: String = ""
    var link: String = ""
    var createdAt: Date = Date()
    var statusRawValue: String = ApplicationStatus.notStarted.rawValue
    var checklistTypeName: String = ""

    @Relationship(deleteRule: .cascade, inverse: \ChecklistEntry.application)
    var checklistItems: [ChecklistEntry] = []

    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRawValue) ?? .notStarted }
        set { statusRawValue = newValue.rawValue }
    }

    init(name: String, link: String = "", createdAt: Date = .now, checklistTypeName: String = "") {
        self.name = name
        self.link = link
        self.createdAt = createdAt
        self.checklistTypeName = checklistTypeName
    }
}

@Model
final class ChecklistEntry {
    var id: UUID = UUID()
    var title: String = ""
    var link: String = ""
    var isChecked: Bool = false
    var sortOrder: Int = 0
    var application: ReleaseApplication?

    init(title: String, link: String = "", isChecked: Bool = false, sortOrder: Int = 0) {
        self.title = title
        self.link = link
        self.isChecked = isChecked
        self.sortOrder = sortOrder
    }
}

@Model
final class ChecklistTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ChecklistTemplateItem.template)
    var items: [ChecklistTemplateItem] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class ChecklistTemplateItem {
    var id: UUID = UUID()
    var title: String = ""
    var link: String = ""
    var sortOrder: Int = 0
    var template: ChecklistTemplate?

    init(title: String, link: String = "", sortOrder: Int = 0) {
        self.title = title
        self.link = link
        self.sortOrder = sortOrder
    }
}
