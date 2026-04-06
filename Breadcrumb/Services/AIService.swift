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
    case invalidResponse
    case generationFailed(String)

    var errorDescription: String? {
        let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
        let language = AppLanguage(rawValue: stored) ?? .german
        return description(for: language)
    }

    func description(for language: AppLanguage) -> String {
        switch self {
        case .notAvailable(let reason):
            return reason
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
        case .invalidResponse:
            return Strings.Errors.invalidResponse(language)
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

    var availability: ServiceAvailability {
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

    var isAvailable: Bool {
        availability == .available
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
        if case .unavailable(let reason) = availability {
            return reason
        }
        return "unavailable"
    }

    func localizedUnavailableReason(for language: AppLanguage) -> String {
        if case .unavailable(let key) = availability {
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
