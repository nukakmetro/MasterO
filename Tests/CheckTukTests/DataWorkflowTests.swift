import Foundation
import SwiftData
import XCTest
@testable import CheckTuk

@MainActor
final class DataWorkflowTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CheckTukSchemaV2.self)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: schema,
            migrationPlan: CheckTukMigrationPlan.self,
            configurations: configuration
        )
    }

    func testApplicationCopiesTemplateAndKeepsChecklistIndependent() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let repository = ChecklistRepository(context: context)
        try repository.createTemplate(name: "App Store", items: [
            (title: "Скриншоты", link: "https://example.com/screenshots"),
            (title: "Описание", link: "")
        ])
        let template = try XCTUnwrap(repository.templates().first)

        let app = try repository.createApplication(name: "CheckTuk", link: "https://checktuk.app", template: template)
        XCTAssertEqual(app.name, "CheckTuk")
        XCTAssertEqual(app.link, "https://checktuk.app")
        XCTAssertEqual(app.checklistTypeName, "App Store")
        XCTAssertEqual(app.status, .notStarted)
        XCTAssertEqual(app.checklistItems.sorted { $0.sortOrder < $1.sortOrder }.map(\.title), ["Скриншоты", "Описание"])
        XCTAssertEqual(app.checklistItems.sorted { $0.sortOrder < $1.sortOrder }.first?.link, "https://example.com/screenshots")
        XCTAssertTrue(app.checklistItems.allSatisfy { !$0.isChecked })

        try repository.updateTemplate(template, name: "Обновлённый шаблон", items: [(title: "Новый пункт", link: "")])
        XCTAssertEqual(app.checklistItems.count, 2, "Редактирование шаблона не должно менять уже созданное приложение")
        XCTAssertEqual(app.checklistTypeName, "App Store")
    }

    func testChecklistEditsPreserveCheckedItemsAndAllowAddRemove() throws {
        let container = try makeContainer()
        let repository = ChecklistRepository(context: ModelContext(container))
        let app = try repository.createApplication(name: "Тест", link: "", template: nil)
        try repository.addItem(to: app, title: "Пункт 1", link: "https://example.com/1")
        try repository.addItem(to: app, title: "Пункт 2", link: "")
        let originalItems = app.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
        try repository.toggle(originalItems[0])

        let drafts = [
            ChecklistItemDraft(id: originalItems[0].id, title: "Пункт 1 изменён", link: "https://example.com/new", isChecked: true),
            ChecklistItemDraft(title: "Добавленный пункт", link: "", isChecked: false)
        ]
        try repository.updateChecklist(app, with: drafts)

        let updated = app.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated.map(\.title), ["Пункт 1 изменён", "Добавленный пункт"])
        XCTAssertEqual(updated[0].link, "https://example.com/new")
        XCTAssertTrue(updated[0].isChecked)
        XCTAssertFalse(updated[1].isChecked)
    }

    func testApplicationStatusAndApplicationLinkCanBeUpdated() throws {
        let repository = ChecklistRepository(context: ModelContext(try makeContainer()))
        let app = try repository.createApplication(name: "Черновик", link: "", template: nil)

        try repository.updateApplication(app, name: "Готово", link: "https://example.com/app")
        try repository.setStatus(.inProgress, for: app)
        XCTAssertEqual(app.name, "Готово")
        XCTAssertEqual(app.link, "https://example.com/app")
        XCTAssertEqual(app.status, .inProgress)

        try repository.setStatus(.completed, for: app)
        XCTAssertEqual(app.status, .completed)
    }

    func testTemplateArchiveRoundTripAndImportAddsUniqueNames() throws {
        let repository = ChecklistRepository(context: ModelContext(try makeContainer()))
        try repository.createTemplate(name: "Публикация", items: [(title: "Проверить ссылку", link: "https://example.com")])
        let original = try XCTUnwrap(repository.templates().first)
        let data = try TemplateArchiveCodec.encode([original])
        let decoded = try TemplateArchiveCodec.decode(data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "Публикация")
        XCTAssertEqual(decoded[0].items.first?.link, "https://example.com")

        XCTAssertEqual(try repository.importTemplates(decoded), 1)
        XCTAssertEqual(try repository.templates().map(\.name), ["Публикация", "Публикация (импорт)"])
    }

    func testTipArchiveRoundTripAndRepositoryImportAppendsNotes() throws {
        let repository = TipsRepository(context: ModelContext(try makeContainer()))
        try repository.create(text: "Не забыть проверить локализацию")
        let original = try XCTUnwrap(repository.allTips().first)
        let data = try TipArchiveCodec.encode([original])
        let decoded = try TipArchiveCodec.decode(data)

        XCTAssertEqual(decoded.map(\.text), ["Не забыть проверить локализацию"])
        XCTAssertEqual(try repository.importTips(decoded), 1)
        XCTAssertEqual(try repository.allTips().count, 2)
    }

    func testAppearancePreferencesPersistAcrossViewModelInstances() {
        let suiteName = "CheckTukTests.\(UUID().uuidString)"
        let defaults = try! XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstInstance = AppearanceSettingsViewModel(defaults: defaults)
        firstInstance.theme = .dark
        firstInstance.accentHex = "#FF8800"
        firstInstance.fontChoice = .menlo

        let reopenedInstance = AppearanceSettingsViewModel(defaults: defaults)
        XCTAssertEqual(reopenedInstance.theme, .dark)
        XCTAssertEqual(reopenedInstance.accentHex, "#FF8800")
        XCTAssertEqual(reopenedInstance.fontChoice, .menlo)
    }

    func testCurrentSchemaIncludesTipsAndMigrationPathFromVersionOne() {
        XCTAssertEqual(CheckTukSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertEqual(CheckTukSchemaV2.versionIdentifier, Schema.Version(2, 0, 0))
        XCTAssertEqual(CheckTukSchemaV1.models.count, 4)
        XCTAssertEqual(CheckTukSchemaV2.models.count, 5)
        XCTAssertEqual(CheckTukMigrationPlan.schemas.count, 2)
        XCTAssertEqual(CheckTukMigrationPlan.stages.count, 1)
    }
}
