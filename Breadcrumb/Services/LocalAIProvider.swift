import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
struct LocalAIProvider: AIProvider {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        try await withThrowingTaskGroup(of: FieldResult.self) { group in
            group.addTask { try await extractField(.lastAction, from: text, language: language) }
            group.addTask { try await extractField(.nextStep, from: text, language: language) }

            var lastAction = ""
            var nextStep = ""

            for try await result in group {
                switch result.field {
                case .lastAction: lastAction = result.value
                case .nextStep: nextStep = result.value
                }
            }

            return ExtractedStatus(
                lastAction: lastAction,
                nextStep: nextStep
            )
        }
    }

    private enum Field: Sendable {
        case lastAction, nextStep
    }

    private struct FieldResult: Sendable {
        let field: Field
        let value: String
    }

    private func extractField(_ field: Field, from text: String, language: AppLanguage) async throws -> FieldResult {
        let instructions: String
        switch field {
        case .lastAction: instructions = Strings.AIExtraction.lastActionInstructions(language)
        case .nextStep: instructions = Strings.AIExtraction.nextStepInstructions(language)
        }

        let session = LanguageModelSession(instructions: Instructions(instructions))
        let options = GenerationOptions(sampling: .greedy)

        switch field {
        case .lastAction:
            let response = try await session.respond(to: text, generating: LastActionExtraction.self, options: options)
            return FieldResult(field: field, value: response.content.completedWork.trimmingCharacters(in: .whitespacesAndNewlines))
        case .nextStep:
            let response = try await session.respond(to: text, generating: NextStepExtraction.self, options: options)
            return FieldResult(field: field, value: response.content.plannedNext.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
#endif
