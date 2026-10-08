import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ApplicationViewModel {
    private(set) var applications: [ReleaseApplication] = []
    private(set) var templates: [ChecklistTemplate] = []
    var selectedApplicationID: UUID?
    var errorMessage: String?
    private var repository: ChecklistRepository?

    var selectedApplication: ReleaseApplication? {
        applications.first { $0.id == selectedApplicationID }
    }

    func connect(to context: ModelContext) {
        repository = ChecklistRepository(context: context)
        refresh()
    }

    func refresh() {
        guard let repository else { return }
        do {
            applications = try repository.applications()
            templates = try repository.templates()
            if selectedApplicationID == nil || !applications.contains(where: { $0.id == selectedApplicationID }) {
                selectedApplicationID = applications.first?.id
            }
        } catch {
            errorMessage = "Не удалось загрузить данные: \(error.localizedDescription)"
        }
    }

    func createApplication(name: String, link: String, template: ChecklistTemplate?) {
        guard let repository else { return }
        do {
            let application = try repository.createApplication(name: name, link: link, template: template)
            refresh()
            selectedApplicationID = application.id
        } catch { report(error) }
    }

    func deleteApplication(_ application: ReleaseApplication) {
        guard let repository else { return }
        do { try repository.deleteApplication(application); refresh() }
        catch { report(error) }
    }

    func updateApplication(_ application: ReleaseApplication, name: String, link: String) {
        guard let repository else { return }
        do { try repository.updateApplication(application, name: name, link: link); refresh() }
        catch { report(error) }
    }

    func setStatus(_ status: ApplicationStatus, for application: ReleaseApplication) {
        guard let repository else { return }
        do { try repository.setStatus(status, for: application); refresh() }
        catch { report(error) }
    }

    func toggle(_ item: ChecklistEntry) {
        guard let repository else { return }
        do { try repository.toggle(item); refresh() }
        catch { report(error) }
    }

    func addItem(to application: ReleaseApplication, title: String, link: String) {
        guard let repository else { return }
        do { try repository.addItem(to: application, title: title, link: link); refresh() }
        catch { report(error) }
    }

    func deleteItem(_ item: ChecklistEntry) {
        guard let repository else { return }
        do { try repository.deleteItem(item); refresh() }
        catch { report(error) }
    }

    func updateChecklist(_ application: ReleaseApplication, drafts: [ChecklistItemDraft]) {
        guard let repository else { return }
        do { try repository.updateChecklist(application, with: drafts); refresh() }
        catch { report(error) }
    }

    func saveTemplate(name: String, items: [(title: String, link: String)], editing template: ChecklistTemplate?) {
        guard let repository else { return }
        do {
            if let template { try repository.updateTemplate(template, name: name, items: items) }
            else { try repository.createTemplate(name: name, items: items) }
            refresh()
        } catch { report(error) }
    }

    func deleteTemplate(_ template: ChecklistTemplate) {
        guard let repository else { return }
        do { try repository.deleteTemplate(template); refresh() }
        catch { report(error) }
    }

    func exportTemplates(_ templates: [ChecklistTemplate]) -> Data? {
        do { return try TemplateArchiveCodec.encode(templates) }
        catch { report(error); return nil }
    }

    func importTemplates(from data: Data) -> Int? {
        guard let repository else { return nil }
        do {
            let entries = try TemplateArchiveCodec.decode(data)
            let importedCount = try repository.importTemplates(entries)
            refresh()
            return importedCount
        } catch {
            report(error)
            return nil
        }
    }

    private func report(_ error: Error) {
        errorMessage = "Не удалось сохранить изменения: \(error.localizedDescription)"
    }
}
