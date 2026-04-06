import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
struct LocalAIProvider: AIProvider {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        let instructions = Strings.AIExtraction.instructions(language)
        let session = LanguageModelSession(instructions: Instructions(instructions))

        switch language {
        case .german:
            let response = try await session.respond(to: text, generating: ExtractedStatusDE.self)
            let result = response.content
            return ExtractedStatus(
                lastAction: result.lastAction,
                nextStep: result.nextStep,
                openQuestions: result.openQuestions
            )
        case .english:
            let response = try await session.respond(to: text, generating: ExtractedStatusEN.self)
            let result = response.content
            return ExtractedStatus(
                lastAction: result.lastAction,
                nextStep: result.nextStep,
                openQuestions: result.openQuestions
            )
        }
    }
}
#endif
