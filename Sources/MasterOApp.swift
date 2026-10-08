import SwiftData
import SwiftUI

@main
struct MasterOApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: ReleaseApplication.self,
                ChecklistEntry.self,
                ChecklistTemplate.self,
                ChecklistTemplateItem.self
            )
        } catch {
            fatalError("Не удалось открыть базу данных: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .frame(minWidth: 920, minHeight: 620)
        }
        .windowStyle(.automatic)
    }
}
