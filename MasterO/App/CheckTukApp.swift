import SwiftData
import SwiftUI

@main
struct CheckTukApp: App {
    private let modelContainer: ModelContainer
    @State private var appearanceSettings = AppearanceSettingsViewModel()

    init() {
        do {
            let schema = Schema(versionedSchema: CheckTukSchemaV2.self)
            if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: CheckTukMigrationPlan.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } else {
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: CheckTukMigrationPlan.self
                )
            }
        } catch {
            fatalError("Не удалось открыть базу данных: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: appearanceSettings)
                .modelContainer(modelContainer)
                .frame(minWidth: 720, minHeight: 480)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)

        WindowGroup("Подсказки", id: "tips") {
            TipsWindowView(settings: appearanceSettings)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 680, height: 560)
    }
}
