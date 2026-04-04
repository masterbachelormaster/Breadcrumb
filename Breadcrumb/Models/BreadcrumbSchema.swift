import SwiftData

enum BreadcrumbSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self]
    }
}

enum BreadcrumbMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BreadcrumbSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
