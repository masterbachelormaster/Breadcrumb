import Foundation
import SwiftData

enum BreadcrumbSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self]
    }

    // MARK: - Frozen Enums

    enum SessionType: String, Codable {
        case work
        case shortBreak
        case longBreak
    }

    enum DocumentType: String, Codable {
        case file
        case url
    }

    // MARK: - Frozen Models

    @Model
    final class Project {
        var id: UUID
        var name: String
        var icon: String
        var isActive: Bool
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \StatusEntry.project)
        var entries: [StatusEntry]

        @Relationship(deleteRule: .cascade, inverse: \PomodoroSession.project)
        var pomodoroSessions: [PomodoroSession]

        @Relationship(deleteRule: .cascade, inverse: \LinkedDocument.project)
        var linkedDocuments: [LinkedDocument] = []

        init(id: UUID = UUID(), name: String = "", icon: String = "doc.text", isActive: Bool = true, createdAt: Date = .now, entries: [StatusEntry] = [], pomodoroSessions: [PomodoroSession] = [], linkedDocuments: [LinkedDocument] = []) {
            self.id = id
            self.name = name
            self.icon = icon
            self.isActive = isActive
            self.createdAt = createdAt
            self.entries = entries
            self.pomodoroSessions = pomodoroSessions
            self.linkedDocuments = linkedDocuments
        }
    }

    @Model
    final class StatusEntry {
        var id: UUID
        var timestamp: Date
        var freeText: String
        var lastAction: String?
        var nextStep: String?
        var openQuestions: String?
        var project: Project?

        @Relationship(inverse: \PomodoroSession.statusEntry)
        var pomodoroSession: PomodoroSession?

        init(id: UUID = UUID(), timestamp: Date = .now, freeText: String = "", lastAction: String? = nil, nextStep: String? = nil, openQuestions: String? = nil, project: Project? = nil, pomodoroSession: PomodoroSession? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.freeText = freeText
            self.lastAction = lastAction
            self.nextStep = nextStep
            self.openQuestions = openQuestions
            self.project = project
            self.pomodoroSession = pomodoroSession
        }
    }

    @Model
    final class PomodoroSession {
        var id: UUID
        var startedAt: Date
        var endedAt: Date?
        var plannedDuration: TimeInterval
        var actualDuration: TimeInterval?
        var sessionType: SessionType
        var sessionNumber: Int
        var completed: Bool
        var project: Project?
        var statusEntry: StatusEntry?

        init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, plannedDuration: TimeInterval = 0, actualDuration: TimeInterval? = nil, sessionType: SessionType = .work, sessionNumber: Int = 1, completed: Bool = false, project: Project? = nil, statusEntry: StatusEntry? = nil) {
            self.id = id
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.plannedDuration = plannedDuration
            self.actualDuration = actualDuration
            self.sessionType = sessionType
            self.sessionNumber = sessionNumber
            self.completed = completed
            self.project = project
            self.statusEntry = statusEntry
        }
    }

    @Model
    final class LinkedDocument {
        var id: UUID
        var type: DocumentType
        var label: String?
        var urlString: String?
        var bookmarkData: Data?
        var originalFilename: String
        var createdAt: Date
        var project: Project?

        init(id: UUID = UUID(), type: DocumentType = .file, label: String? = nil, urlString: String? = nil, bookmarkData: Data? = nil, originalFilename: String = "", createdAt: Date = .now, project: Project? = nil) {
            self.id = id
            self.type = type
            self.label = label
            self.urlString = urlString
            self.bookmarkData = bookmarkData
            self.originalFilename = originalFilename
            self.createdAt = createdAt
            self.project = project
        }
    }
}

enum BreadcrumbSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self]
    }

    // MARK: - Frozen Enums

    enum SessionType: String, Codable {
        case work
        case shortBreak
        case longBreak
    }

    enum DocumentType: String, Codable {
        case file
        case url
    }

    // MARK: - Frozen Models

    @Model
    final class Project {
        var id: UUID
        var name: String
        var icon: String
        var isActive: Bool
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \StatusEntry.project)
        var entries: [StatusEntry]

        @Relationship(deleteRule: .cascade, inverse: \PomodoroSession.project)
        var pomodoroSessions: [PomodoroSession]

        @Relationship(deleteRule: .cascade, inverse: \LinkedDocument.project)
        var linkedDocuments: [LinkedDocument] = []

        init(id: UUID = UUID(), name: String = "", icon: String = "doc.text", isActive: Bool = true, createdAt: Date = .now, entries: [StatusEntry] = [], pomodoroSessions: [PomodoroSession] = [], linkedDocuments: [LinkedDocument] = []) {
            self.id = id
            self.name = name
            self.icon = icon
            self.isActive = isActive
            self.createdAt = createdAt
            self.entries = entries
            self.pomodoroSessions = pomodoroSessions
            self.linkedDocuments = linkedDocuments
        }
    }

    @Model
    final class StatusEntry {
        var id: UUID
        var timestamp: Date
        var freeText: String
        var lastAction: String?
        var nextStep: String?
        var openQuestions: String?
        var project: Project?

        @Relationship(inverse: \PomodoroSession.statusEntry)
        var pomodoroSession: PomodoroSession?

        init(id: UUID = UUID(), timestamp: Date = .now, freeText: String = "", lastAction: String? = nil, nextStep: String? = nil, openQuestions: String? = nil, project: Project? = nil, pomodoroSession: PomodoroSession? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.freeText = freeText
            self.lastAction = lastAction
            self.nextStep = nextStep
            self.openQuestions = openQuestions
            self.project = project
            self.pomodoroSession = pomodoroSession
        }
    }

    @Model
    final class PomodoroSession {
        var id: UUID
        var startedAt: Date
        var endedAt: Date?
        var plannedDuration: TimeInterval
        var actualDuration: TimeInterval?
        var sessionType: SessionType
        var sessionNumber: Int
        var completed: Bool
        var isFocusMate: Bool = false
        var project: Project?
        var statusEntry: StatusEntry?

        init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, plannedDuration: TimeInterval = 0, actualDuration: TimeInterval? = nil, sessionType: SessionType = .work, sessionNumber: Int = 1, completed: Bool = false, isFocusMate: Bool = false, project: Project? = nil, statusEntry: StatusEntry? = nil) {
            self.id = id
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.plannedDuration = plannedDuration
            self.actualDuration = actualDuration
            self.sessionType = sessionType
            self.sessionNumber = sessionNumber
            self.completed = completed
            self.isFocusMate = isFocusMate
            self.project = project
            self.statusEntry = statusEntry
        }
    }

    @Model
    final class LinkedDocument {
        var id: UUID
        var type: DocumentType
        var label: String?
        var urlString: String?
        var bookmarkData: Data?
        var originalFilename: String
        var createdAt: Date
        var project: Project?

        init(id: UUID = UUID(), type: DocumentType = .file, label: String? = nil, urlString: String? = nil, bookmarkData: Data? = nil, originalFilename: String = "", createdAt: Date = .now, project: Project? = nil) {
            self.id = id
            self.type = type
            self.label = label
            self.urlString = urlString
            self.bookmarkData = bookmarkData
            self.originalFilename = originalFilename
            self.createdAt = createdAt
            self.project = project
        }
    }
}

enum BreadcrumbSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self]
    }

    // MARK: - Frozen Enums

    enum SessionType: String, Codable {
        case work
        case shortBreak
        case longBreak
    }

    enum DocumentType: String, Codable {
        case file
        case url
    }

    enum AIExtractionState: String, Codable {
        case notRequested
        case extracting
        case retrying
        case failed
        case completed
    }

    // MARK: - Frozen Models

    @Model
    final class Project {
        var id: UUID
        var name: String
        var icon: String
        var isActive: Bool
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \StatusEntry.project)
        var entries: [StatusEntry]

        @Relationship(deleteRule: .cascade, inverse: \PomodoroSession.project)
        var pomodoroSessions: [PomodoroSession]

        @Relationship(deleteRule: .cascade, inverse: \LinkedDocument.project)
        var linkedDocuments: [LinkedDocument] = []

        init(id: UUID = UUID(), name: String = "", icon: String = "doc.text", isActive: Bool = true, createdAt: Date = .now, entries: [StatusEntry] = [], pomodoroSessions: [PomodoroSession] = [], linkedDocuments: [LinkedDocument] = []) {
            self.id = id
            self.name = name
            self.icon = icon
            self.isActive = isActive
            self.createdAt = createdAt
            self.entries = entries
            self.pomodoroSessions = pomodoroSessions
            self.linkedDocuments = linkedDocuments
        }
    }

    @Model
    final class StatusEntry {
        var id: UUID
        var timestamp: Date
        var freeText: String
        var lastAction: String?
        var nextStep: String?
        var openQuestions: String?
        var aiExtractionStateRawValue: String?
        var aiExtractionAttemptCountValue: Int?
        var aiExtractionNextRetryAt: Date?
        var aiExtractionLastError: String?
        var aiExtractionSourceText: String?
        var aiExtractionLanguageRawValue: String?
        var project: Project?

        @Relationship(inverse: \PomodoroSession.statusEntry)
        var pomodoroSession: PomodoroSession?

        init(
            id: UUID = UUID(),
            timestamp: Date = .now,
            freeText: String = "",
            lastAction: String? = nil,
            nextStep: String? = nil,
            openQuestions: String? = nil,
            aiExtractionStateRawValue: String? = nil,
            aiExtractionAttemptCountValue: Int? = nil,
            aiExtractionNextRetryAt: Date? = nil,
            aiExtractionLastError: String? = nil,
            aiExtractionSourceText: String? = nil,
            aiExtractionLanguageRawValue: String? = nil,
            project: Project? = nil,
            pomodoroSession: PomodoroSession? = nil
        ) {
            self.id = id
            self.timestamp = timestamp
            self.freeText = freeText
            self.lastAction = lastAction
            self.nextStep = nextStep
            self.openQuestions = openQuestions
            self.aiExtractionStateRawValue = aiExtractionStateRawValue
            self.aiExtractionAttemptCountValue = aiExtractionAttemptCountValue
            self.aiExtractionNextRetryAt = aiExtractionNextRetryAt
            self.aiExtractionLastError = aiExtractionLastError
            self.aiExtractionSourceText = aiExtractionSourceText
            self.aiExtractionLanguageRawValue = aiExtractionLanguageRawValue
            self.project = project
            self.pomodoroSession = pomodoroSession
        }
    }

    @Model
    final class PomodoroSession {
        var id: UUID
        var startedAt: Date
        var endedAt: Date?
        var plannedDuration: TimeInterval
        var actualDuration: TimeInterval?
        var sessionType: SessionType
        var sessionNumber: Int
        var completed: Bool
        var isFocusMate: Bool = false
        var project: Project?
        var statusEntry: StatusEntry?

        init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, plannedDuration: TimeInterval = 0, actualDuration: TimeInterval? = nil, sessionType: SessionType = .work, sessionNumber: Int = 1, completed: Bool = false, isFocusMate: Bool = false, project: Project? = nil, statusEntry: StatusEntry? = nil) {
            self.id = id
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.plannedDuration = plannedDuration
            self.actualDuration = actualDuration
            self.sessionType = sessionType
            self.sessionNumber = sessionNumber
            self.completed = completed
            self.isFocusMate = isFocusMate
            self.project = project
            self.statusEntry = statusEntry
        }
    }

    @Model
    final class LinkedDocument {
        var id: UUID
        var type: DocumentType
        var label: String?
        var urlString: String?
        var bookmarkData: Data?
        var originalFilename: String
        var createdAt: Date
        var project: Project?

        init(id: UUID = UUID(), type: DocumentType = .file, label: String? = nil, urlString: String? = nil, bookmarkData: Data? = nil, originalFilename: String = "", createdAt: Date = .now, project: Project? = nil) {
            self.id = id
            self.type = type
            self.label = label
            self.urlString = urlString
            self.bookmarkData = bookmarkData
            self.originalFilename = originalFilename
            self.createdAt = createdAt
            self.project = project
        }
    }
}

enum BreadcrumbMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BreadcrumbSchemaV1.self, BreadcrumbSchemaV2.self, BreadcrumbSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: BreadcrumbSchemaV1.self,
        toVersion: BreadcrumbSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: BreadcrumbSchemaV2.self,
        toVersion: BreadcrumbSchemaV3.self
    )
}
