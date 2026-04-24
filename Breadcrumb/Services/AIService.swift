import Foundation
import Observation

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
            return OpenRouterProvider(apiKey: apiKey, model: model)
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
