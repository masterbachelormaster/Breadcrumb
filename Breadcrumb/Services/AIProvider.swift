import Foundation

// MARK: - Shared Output Type

struct ExtractedStatus: Sendable {
    var lastAction: String
    var nextStep: String
    var openQuestions: String
}

// MARK: - Backend Selection

enum AIBackend: String, CaseIterable, Sendable {
    case local
    case openRouter
}

// MARK: - Provider Protocol

protocol AIProvider: Sendable {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus
}
