import Foundation
import SwiftData

@MainActor
final class ChecklistRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func applications() throws -> [ReleaseApplication] {
        try context.fetch(FetchDescriptor<ReleaseApplication>(sortBy: [SortDescriptor(\.createdAt)]))
    }

    func templates() throws -> [ChecklistTemplate] {
        try context.fetch(FetchDescriptor<ChecklistTemplate>(sortBy: [SortDescriptor(\.name)]))
    }

    func createApplication(name: String, link: String, template: ChecklistTemplate?) throws -> ReleaseApplication {
        let application = ReleaseApplication(
            name: name,
            link: link,
            checklistTypeName: template?.name ?? "Без шаблона"
        )
        if let template {
            for item in template.items.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let entry = ChecklistEntry(title: item.title, link: item.link, sortOrder: item.sortOrder)
                entry.application = application
            }
        }
        context.insert(application)
        try context.save()
        return application
    }

    func deleteApplication(_ application: ReleaseApplication) throws {
        context.delete(application)
        try context.save()
    }

    func updateApplication(_ application: ReleaseApplication, name: String, link: String) throws {
        application.name = name
        application.link = link
        try context.save()
    }

    func setStatus(_ status: ApplicationStatus, for application: ReleaseApplication) throws {
        application.status = status
        try context.save()
    }

    func toggle(_ item: ChecklistEntry) throws {
        item.isChecked.toggle()
        try context.save()
    }

    func addItem(to application: ReleaseApplication, title: String, link: String) throws {
        let item = ChecklistEntry(title: title, link: link, sortOrder: application.checklistItems.count)
        item.application = application
        try context.save()
    }

    func deleteItem(_ item: ChecklistEntry) throws {
        context.delete(item)
        try context.save()
    }

    func updateChecklist(_ application: ReleaseApplication, with drafts: [ChecklistItemDraft]) throws {
        let existingByID = Dictionary(uniqueKeysWithValues: application.checklistItems.map { ($0.id, $0) })
        let retainedIDs = Set(drafts.compactMap(\.id))
        for item in application.checklistItems where !retainedIDs.contains(item.id) {
            context.delete(item)
        }
        for (index, draft) in drafts.enumerated() {
            if let id = draft.id, let item = existingByID[id] {
                item.title = draft.title
                item.link = draft.link
                item.sortOrder = index
            } else {
                let item = ChecklistEntry(title: draft.title, link: draft.link, isChecked: draft.isChecked, sortOrder: index)
                item.application = application
            }
        }
        try context.save()
    }

    func createTemplate(name: String, items: [(title: String, link: String)]) throws {
        let template = ChecklistTemplate(name: name)
        for (index, item) in items.enumerated() {
            let templateItem = ChecklistTemplateItem(title: item.title, link: item.link, sortOrder: index)
            templateItem.template = template
        }
        context.insert(template)
        try context.save()
    }

    func updateTemplate(_ template: ChecklistTemplate, name: String, items: [(title: String, link: String)]) throws {
        template.name = name
        for item in template.items { context.delete(item) }
        template.items = []
        for (index, item) in items.enumerated() {
            let templateItem = ChecklistTemplateItem(title: item.title, link: item.link, sortOrder: index)
            templateItem.template = template
        }
        try context.save()
    }

    func deleteTemplate(_ template: ChecklistTemplate) throws {
        context.delete(template)
        try context.save()
    }

}
