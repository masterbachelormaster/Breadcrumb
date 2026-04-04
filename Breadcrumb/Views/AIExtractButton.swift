import SwiftUI

struct AIExtractButton: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    @Binding var showOptionalFields: Bool

    @State private var errorMessage: String?
    @State private var extractionTask: Task<Void, Never>?
    @State private var errorDismissTask: Task<Void, Never>?

    var body: some View {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            extractionContent
                .onDisappear {
                    extractionTask?.cancel()
                    errorDismissTask?.cancel()
                }
        }
        #endif
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    @ViewBuilder
    private var extractionContent: some View {
        let l = languageManager.language
        if aiService.isAvailable && !freeText.trimmingCharacters(in: .whitespaces).isEmpty {
            VStack(spacing: 4) {
                Button {
                    extractionTask = Task { await extract() }
                } label: {
                    if aiService.isGenerating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text(Strings.AIExtraction.extracting(l))
                                .font(.caption)
                        }
                    } else {
                        Label(Strings.AIExtraction.buttonLabel(l), systemImage: "wand.and.stars")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(aiService.isGenerating)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @available(macOS 26, *)
    private func extract() async {
        errorMessage = nil
        let language = languageManager.language
        let instructions = Strings.AIExtraction.instructions(language)

        do {
            switch language {
            case .german:
                let result: ExtractedStatusDE = try await aiService.generate(
                    prompt: freeText,
                    instructions: instructions,
                    generating: ExtractedStatusDE.self
                )
                applyResult(lastAction: result.lastAction, nextStep: result.nextStep, openQuestions: result.openQuestions)
            case .english:
                let result: ExtractedStatusEN = try await aiService.generate(
                    prompt: freeText,
                    instructions: instructions,
                    generating: ExtractedStatusEN.self
                )
                applyResult(lastAction: result.lastAction, nextStep: result.nextStep, openQuestions: result.openQuestions)
            }
            showOptionalFields = true
        } catch is CancellationError {
            // Normal lifecycle event (view disappeared, task cancelled) — ignore.
        } catch {
            errorMessage = error.localizedDescription
            errorDismissTask = Task {
                try? await Task.sleep(for: .seconds(4))
                errorMessage = nil
            }
        }
    }

    private func applyResult(lastAction: String, nextStep: String, openQuestions: String) {
        if !lastAction.isEmpty {
            self.lastAction = lastAction
        }
        if !nextStep.isEmpty {
            self.nextStep = nextStep
        }
        if !openQuestions.isEmpty {
            self.openQuestions = openQuestions
        }
    }
    #endif
}
