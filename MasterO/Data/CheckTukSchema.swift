import SwiftData

/// Schema used before tips were added. Keep prior versions immutable.
enum CheckTukSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ReleaseApplication.self,
            ChecklistEntry.self,
            ChecklistTemplate.self,
            ChecklistTemplateItem.self
        ]
    }
}

/// Current schema. The only change from V1 is the new tips entity.
enum CheckTukSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            ReleaseApplication.self,
            ChecklistEntry.self,
            ChecklistTemplate.self,
            ChecklistTemplateItem.self,
            TipNote.self
        ]
    }
}

enum CheckTukMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CheckTukSchemaV1.self, CheckTukSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: CheckTukSchemaV1.self, toVersion: CheckTukSchemaV2.self)
        ]
    }
}
