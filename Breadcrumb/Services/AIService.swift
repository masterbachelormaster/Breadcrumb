import Foundation
import Observation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Error Types

enum AIServiceError: LocalizedError, Sendable {
    case notAvailable(String)
    case contextWindowExceeded
    case unsupportedLanguage
    case guardrailViolation
    case networkError(String)
    case authenticationFailed
    case invalidResponse(String)
    case generationFailed(String)

    var errorDescription: String? {
        let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
        let language = AppLanguage(rawValue: stored) ?? .german
        return description(for: language)
    }

    func description(for language: AppLanguage) -> String {
        switch self {
        case .notAvailable(let reason):
            switch reason {
            case "deviceNotEligible": return Strings.Errors.deviceNotSupported(language)
            case "appleIntelligenceNotEnabled": return Strings.Errors.enableAppleIntelligence(language)
            case "modelNotReady": return Strings.Errors.modelLoading(language)
            case "requiresMacOS26": return Strings.Errors.requiresMacOS26(language)
            case "notSupportedInVersion": return Strings.Errors.notSupportedInVersion(language)
            case "notConfigured": return Strings.Settings.aiNotConfigured(language)
            default: return Strings.Errors.notAvailable(language)
            }
        case .contextWindowExceeded:
            return Strings.Errors.textTooLong(language)
        case .unsupportedLanguage:
            return Strings.Errors.unsupportedLanguage(language)
        case .guardrailViolation:
            return Strings.Errors.contentNotProcessed(language)
        case .networkError(let message):
            return Strings.Errors.networkError(language, message: message)
        case .authenticationFailed:
            return Strings.Errors.authenticationFailed(language)
        case .invalidResponse(let detail):
            return Strings.Errors.invalidResponse(language, detail: detail)
        case .generationFailed(let message):
            return Strings.Errors.generationFailed(language, message: message)
        }
    }
}

@Observable
@MainActor
final class AIExtractionCoordinator {
    private let aiService: AIService
    private let modelContainer: ModelContainer
    private let maxAttempts: Int
    private let retryIntervalSeconds: Int64
    private var tasks: [PersistentIdentifier: Task<Void, Never>] = [:]

    init(
        aiService: AIService,
        modelContainer: ModelContainer,
        maxAttempts: Int = 6,
        retryIntervalSeconds: Int64 = 120
    ) {
        self.aiService = aiService
        self.modelContainer = modelContainer
        self.maxAttempts = maxAttempts
        self.retryIntervalSeconds = retryIntervalSeconds
    }

    func resumePendingExtractions(fallbackLanguage: AppLanguage) {
        let descriptor = FetchDescriptor<StatusEntry>()
        let entries: [StatusEntry]
        do {
            entries = try modelContext.fetch(descriptor)
        } catch {
            return
        }

        for entry in entries where entry.aiExtractionState == .extracting || entry.aiExtractionState == .retrying {
            guard let sourceText = entry.aiExtractionSourceText else {
                resetExtractionState(for: entry)
                continue
            }

            let language = language(for: entry, fallback: fallbackLanguage)
            if let nextRetryAt = entry.aiExtractionNextRetryAt, nextRetryAt > .now {
                scheduleRetry(
                    entryID: entry.persistentModelID,
                    sourceText: sourceText,
                    language: language,
                    at: nextRetryAt
                )
            } else {
                startAttempt(entryID: entry.persistentModelID, sourceText: sourceText, language: language)
            }
        }
    }

    func enqueueExtraction(for entry: StatusEntry, sourceText: String, language: AppLanguage) {
        entry.aiExtractionAttemptCount = 0
        entry.aiExtractionSourceText = sourceText
        entry.aiExtractionLanguageRawValue = language.rawValue
        entry.aiExtractionLastError = nil
        entry.aiExtractionNextRetryAt = nil
        entry.aiExtractionState = .extracting
        modelContext.saveWithLogging()

        startAttempt(entryID: entry.persistentModelID, sourceText: sourceText, language: language)
    }

    func continueExtraction(from draft: AIExtractionDraft, for entry: StatusEntry, language: AppLanguage) {
        guard draft.hasStarted, let sourceText = draft.sourceText else { return }

        entry.aiExtractionSourceText = sourceText
        entry.aiExtractionLanguageRawValue = language.rawValue
        entry.aiExtractionLastError = nil
        entry.aiExtractionNextRetryAt = nil

        if let result = draft.result {
            Self.applyResult(result, to: entry, sourceText: sourceText)
            modelContext.saveWithLogging()
            return
        }

        guard let resultTask = draft.resultTask else {
            enqueueExtraction(for: entry, sourceText: sourceText, language: language)
            return
        }

        entry.aiExtractionAttemptCount = max(entry.aiExtractionAttemptCount, 1)
        entry.aiExtractionState = .extracting
        modelContext.saveWithLogging()

        let entryID = entry.persistentModelID
        tasks[entryID]?.cancel()
        tasks[entryID] = Task { @MainActor in
            do {
                let result = try await resultTask.value
                finish(entryID: entryID, sourceText: sourceText, result: result)
            } catch is CancellationError {
                tasks[entryID] = nil
            } catch {
                handleFailure(entryID: entryID, sourceText: sourceText, language: language, error: error)
            }
        }
    }

    func retryExtraction(for entry: StatusEntry, language: AppLanguage) {
        enqueueExtraction(for: entry, sourceText: entry.freeText, language: language)
    }

    @discardableResult
    static func applyResult(_ result: ExtractedStatus, to entry: StatusEntry, sourceText: String) -> Bool {
        guard entry.freeText == sourceText else {
            resetExtractionState(for: entry)
            return false
        }

        var didApply = false
        let cleanedLastAction = AIFillerStripper.cleanLines(result.lastAction)
        let cleanedNextStep = AIFillerStripper.cleanLines(result.nextStep)

        if (entry.lastAction ?? "").isEmpty, !cleanedLastAction.isEmpty {
            entry.lastAction = cleanedLastAction
            didApply = true
        }
        if (entry.nextStep ?? "").isEmpty, !cleanedNextStep.isEmpty {
            entry.nextStep = cleanedNextStep
            didApply = true
        }

        entry.aiExtractionState = .completed
        entry.aiExtractionNextRetryAt = nil
        entry.aiExtractionLastError = nil
        entry.aiExtractionSourceText = nil
        entry.aiExtractionLanguageRawValue = nil
        return didApply
    }

    static func stateAfterFailure(attemptCount: Int, maxAttempts: Int) -> AIExtractionState {
        attemptCount < maxAttempts ? .retrying : .failed
    }

    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private func startAttempt(entryID: PersistentIdentifier, sourceText: String, language: AppLanguage) {
        guard let entry = modelContext.model(for: entryID) as? StatusEntry else { return }

        entry.aiExtractionAttemptCount += 1
        entry.aiExtractionState = entry.aiExtractionAttemptCount > 1 ? .retrying : .extracting
        entry.aiExtractionNextRetryAt = nil
        entry.aiExtractionLastError = nil
        entry.aiExtractionSourceText = sourceText
        entry.aiExtractionLanguageRawValue = language.rawValue
        modelContext.saveWithLogging()

        tasks[entryID]?.cancel()
        tasks[entryID] = Task { @MainActor in
            do {
                let result = try await aiService.extractStatus(from: sourceText, language: language)
                finish(entryID: entryID, sourceText: sourceText, result: result)
            } catch is CancellationError {
                tasks[entryID] = nil
            } catch {
                handleFailure(entryID: entryID, sourceText: sourceText, language: language, error: error)
            }
        }
    }

    private func finish(entryID: PersistentIdentifier, sourceText: String, result: ExtractedStatus) {
        defer { tasks[entryID] = nil }
        guard let entry = modelContext.model(for: entryID) as? StatusEntry else { return }
        Self.applyResult(result, to: entry, sourceText: sourceText)
        modelContext.saveWithLogging()
    }

    private func handleFailure(
        entryID: PersistentIdentifier,
        sourceText: String,
        language: AppLanguage,
        error: Error
    ) {
        guard let entry = modelContext.model(for: entryID) as? StatusEntry else {
            tasks[entryID] = nil
            return
        }

        guard entry.freeText == sourceText else {
            Self.resetExtractionState(for: entry)
            modelContext.saveWithLogging()
            tasks[entryID] = nil
            return
        }

        entry.aiExtractionLastError = error.localizedDescription

        let failureState = Self.stateAfterFailure(
            attemptCount: entry.aiExtractionAttemptCount,
            maxAttempts: maxAttempts
        )

        if failureState == .retrying {
            entry.aiExtractionState = failureState
            let nextRetryAt = Date.now.addingTimeInterval(TimeInterval(retryIntervalSeconds))
            entry.aiExtractionNextRetryAt = nextRetryAt
            modelContext.saveWithLogging()
            scheduleRetry(entryID: entryID, sourceText: sourceText, language: language, at: nextRetryAt)
        } else {
            entry.aiExtractionState = failureState
            entry.aiExtractionNextRetryAt = nil
            modelContext.saveWithLogging()
            tasks[entryID] = nil
        }
    }

    private func scheduleRetry(
        entryID: PersistentIdentifier,
        sourceText: String,
        language: AppLanguage,
        at retryDate: Date
    ) {
        let delay = max(Int64(retryDate.timeIntervalSinceNow.rounded(.up)), 0)
        tasks[entryID]?.cancel()
        tasks[entryID] = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(delay))
                try Task.checkCancellation()
                startAttempt(entryID: entryID, sourceText: sourceText, language: language)
            } catch {
                tasks[entryID] = nil
            }
        }
    }

    private func language(for entry: StatusEntry, fallback: AppLanguage) -> AppLanguage {
        guard let rawValue = entry.aiExtractionLanguageRawValue,
              let language = AppLanguage(rawValue: rawValue) else {
            return fallback
        }
        return language
    }

    private func resetExtractionState(for entry: StatusEntry) {
        Self.resetExtractionState(for: entry)
        modelContext.saveWithLogging()
    }

    private static func resetExtractionState(for entry: StatusEntry) {
        entry.aiExtractionState = .notRequested
        entry.aiExtractionAttemptCount = 0
        entry.aiExtractionNextRetryAt = nil
        entry.aiExtractionLastError = nil
        entry.aiExtractionSourceText = nil
        entry.aiExtractionLanguageRawValue = nil
    }
}

// MARK: - AI Service

@Observable
@MainActor
final class AIService {

    enum ServiceAvailability: Equatable {
        case available
        case unavailable(String)
    }

    private(set) var isGenerating = false
    private(set) var isAvailable = false

    private var localAvailability: ServiceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable("deviceNotEligible")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("appleIntelligenceNotEnabled")
            case .unavailable(.modelNotReady):
                return .unavailable("modelNotReady")
            case .unavailable:
                return .unavailable("unavailable")
            @unknown default:
                return .unavailable("unavailable")
            }
        } else {
            return .unavailable("requiresMacOS26")
        }
        #else
        return .unavailable("notSupportedInVersion")
        #endif
    }

    private var activeBackend: AIBackend {
        let stored = UserDefaults.standard.string(forKey: "ai.provider") ?? "local"
        return AIBackend(rawValue: stored) ?? .local
    }

    init() {
        refreshAvailability()
    }

    func refreshAvailability() {
        isAvailable = resolveProvider() != nil
    }

    private func resolveProvider() -> (any AIProvider)? {
        switch activeBackend {
        case .local:
            #if canImport(FoundationModels)
            if #available(macOS 26, *) {
                if case .available = localAvailability {
                    return LocalAIProvider()
                }
            }
            #endif
            return nil
        case .openRouter:
            guard let apiKey = KeychainHelper.read(key: "openrouter.apiKey"),
                  let model = UserDefaults.standard.string(forKey: "ai.openrouter.model"),
                  !apiKey.isEmpty, !model.isEmpty else { return nil }
            let customPrompt = UserDefaults.standard.string(forKey: "ai.openrouter.customSystemPrompt")
            return OpenRouterProvider(apiKey: apiKey, model: model, customSystemPrompt: customPrompt)
        }
    }

    // MARK: - Extraction

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        guard let provider = resolveProvider() else {
            throw AIServiceError.notAvailable(unavailableReason)
        }
        isGenerating = true
        defer { isGenerating = false }
        return try await provider.extractStatus(from: text, language: language)
    }

    // MARK: - Text Generation

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    func generate(prompt: String, instructions: String) async throws -> String {
        guard isAvailable else {
            throw AIServiceError.notAvailable(unavailableReason)
        }
        isGenerating = true
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: Instructions(instructions))
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            throw mapError(error)
        }
    }
    #endif

    // MARK: - Guided Generation

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    func generate<T: Generable>(
        prompt: String,
        instructions: String,
        generating type: T.Type
    ) async throws -> T {
        guard isAvailable else {
            throw AIServiceError.notAvailable(unavailableReason)
        }
        isGenerating = true
        defer { isGenerating = false }

        do {
            let session = LanguageModelSession(instructions: Instructions(instructions))
            let response = try await session.respond(to: prompt, generating: type)
            return response.content
        } catch {
            throw mapError(error)
        }
    }
    #endif

    // MARK: - Streaming Text

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    func stream(
        prompt: String,
        instructions: String
    ) -> AsyncThrowingStream<String, Error> {
        guard isAvailable else {
            return AsyncThrowingStream { $0.finish(throwing: AIServiceError.notAvailable(unavailableReason)) }
        }

        isGenerating = true
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: String.self)
        let task = Task {
            defer { self.isGenerating = false }

            do {
                let session = LanguageModelSession(instructions: Instructions(instructions))
                let response = session.streamResponse(to: prompt)
                for try await partial in response {
                    try Task.checkCancellation()
                    continuation.yield(partial.content)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: self.mapError(error))
            }
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }
    #endif

    // MARK: - Streaming Guided Generation

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    func stream<T: Generable>(
        prompt: String,
        instructions: String,
        generating type: T.Type
    ) -> AsyncThrowingStream<T.PartiallyGenerated, Error> where T.PartiallyGenerated: Sendable {
        guard isAvailable else {
            return AsyncThrowingStream { $0.finish(throwing: AIServiceError.notAvailable(unavailableReason)) }
        }

        isGenerating = true
        typealias Element = T.PartiallyGenerated
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: Element.self)
        let task = Task {
            defer { self.isGenerating = false }

            do {
                let session = LanguageModelSession(instructions: Instructions(instructions))
                let response = session.streamResponse(to: prompt, generating: type)
                for try await partial in response {
                    try Task.checkCancellation()
                    continuation.yield(partial.content)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: self.mapError(error))
            }
        }
        continuation.onTermination = { (_: AsyncThrowingStream<Element, Error>.Continuation.Termination) in task.cancel() }
        return stream
    }
    #endif

    // MARK: - Private Helpers

    private var unavailableReason: String {
        switch activeBackend {
        case .local:
            if case .unavailable(let reason) = localAvailability {
                return reason
            }
            return "unavailable"
        case .openRouter:
            return "notConfigured"
        }
    }

    func localizedUnavailableReason(for language: AppLanguage) -> String {
        switch activeBackend {
        case .local:
            if case .unavailable(let key) = localAvailability {
                switch key {
                case "deviceNotEligible": return Strings.Errors.deviceNotSupported(language)
                case "appleIntelligenceNotEnabled": return Strings.Errors.enableAppleIntelligence(language)
                case "modelNotReady": return Strings.Errors.modelLoading(language)
                case "requiresMacOS26": return Strings.Errors.requiresMacOS26(language)
                case "notSupportedInVersion": return Strings.Errors.notSupportedInVersion(language)
                default: return Strings.Errors.notAvailable(language)
                }
            }
            return Strings.Errors.notAvailable(language)
        case .openRouter:
            return Strings.Settings.aiNotConfigured(language)
        }
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    private func mapError(_ error: Error) -> AIServiceError {
        if let genError = error as? LanguageModelSession.GenerationError {
            switch genError {
            case .exceededContextWindowSize:
                return .contextWindowExceeded
            case .unsupportedLanguageOrLocale:
                return .unsupportedLanguage
            case .guardrailViolation:
                return .guardrailViolation
            @unknown default:
                return .generationFailed(error.localizedDescription)
            }
        }
        return .generationFailed(error.localizedDescription)
    }
    #endif

}
