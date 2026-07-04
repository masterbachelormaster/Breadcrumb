import Foundation
import SwiftData

enum AIExtractionState: String, Codable, CaseIterable, Sendable {
    case notRequested
    case extracting
    case retrying
    case failed
    case completed

    var showsInlineStatus: Bool {
        self == .extracting || self == .retrying || self == .failed
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
        freeText: String,
        lastAction: String? = nil,
        nextStep: String? = nil,
        openQuestions: String? = nil,
        aiExtractionState: AIExtractionState = .notRequested,
        aiExtractionAttemptCount: Int = 0,
        aiExtractionNextRetryAt: Date? = nil,
        aiExtractionLastError: String? = nil,
        aiExtractionSourceText: String? = nil,
        aiExtractionLanguageRawValue: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = .now
        self.freeText = freeText
        self.lastAction = lastAction
        self.nextStep = nextStep
        self.openQuestions = openQuestions
        self.aiExtractionStateRawValue = aiExtractionState.rawValue
        self.aiExtractionAttemptCountValue = aiExtractionAttemptCount
        self.aiExtractionNextRetryAt = aiExtractionNextRetryAt
        self.aiExtractionLastError = aiExtractionLastError
        self.aiExtractionSourceText = aiExtractionSourceText
        self.aiExtractionLanguageRawValue = aiExtractionLanguageRawValue
    }

    var aiExtractionState: AIExtractionState {
        get {
            guard let aiExtractionStateRawValue else { return .notRequested }
            return AIExtractionState(rawValue: aiExtractionStateRawValue) ?? .notRequested
        }
        set {
            aiExtractionStateRawValue = newValue.rawValue
        }
    }

    var aiExtractionAttemptCount: Int {
        get { aiExtractionAttemptCountValue ?? 0 }
        set { aiExtractionAttemptCountValue = newValue }
    }
}
