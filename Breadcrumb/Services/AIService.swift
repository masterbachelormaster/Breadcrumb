import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Error Types

enum AIServiceError: LocalizedError {
    case notAvailable(String)
    case contextWindowExceeded
    case unsupportedLanguage
    case guardrailViolation
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return reason
        case .contextWindowExceeded:
            return "Der Text ist zu lang für die Verarbeitung"
        case .unsupportedLanguage:
            return "Diese Sprache wird nicht unterstützt"
        case .guardrailViolation:
            return "Der Inhalt konnte nicht verarbeitet werden"
        case .generationFailed(let message):
            return "Fehler bei der Textgenerierung: \(message)"
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
                return .unavailable("Dieses Gerät unterstützt Apple Intelligence nicht")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("Bitte aktiviere Apple Intelligence in den Systemeinstellungen")
            case .unavailable(.modelNotReady):
                return .unavailable("Das KI-Modell wird noch geladen")
            case .unavailable:
                return .unavailable("Apple Intelligence ist nicht verfügbar")
            @unknown default:
                return .unavailable("Apple Intelligence ist nicht verfügbar")
            }
        } else {
            return .unavailable("Erfordert macOS 26 oder neuer")
        }
        #else
        return .unavailable("Apple Intelligence wird in dieser App-Version nicht unterstützt")
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

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                await self?.setGenerating(true)
                defer { Task { await self?.setGenerating(false) } }

                do {
                    let session = LanguageModelSession(instructions: Instructions(instructions))
                    let stream = session.streamResponse(to: prompt)
                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: self?.mapError(error) ?? error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
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

        return AsyncThrowingStream { [weak self] continuation in
            let task = Task {
                await self?.setGenerating(true)
                defer { Task { await self?.setGenerating(false) } }

                do {
                    let session = LanguageModelSession(instructions: Instructions(instructions))
                    let stream = session.streamResponse(to: prompt, generating: type)
                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: self?.mapError(error) ?? error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    #endif

    // MARK: - Prewarming

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    func prewarm() {
        guard isAvailable else { return }
        Task {
            let session = LanguageModelSession()
            session.prewarm()
        }
    }
    #endif

    // MARK: - Private Helpers

    private var unavailableReason: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return "Apple Intelligence ist nicht verfügbar"
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

    private func setGenerating(_ value: Bool) {
        isGenerating = value
    }
}
