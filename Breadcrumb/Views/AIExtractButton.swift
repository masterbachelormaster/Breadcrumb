import SwiftUI

@Observable
@MainActor
final class AIExtractionDraft {
    enum State {
        case idle
        case extracting
        case failed
        case completed
    }

    private(set) var state: State = .idle
    private(set) var sourceText: String?
    private(set) var result: ExtractedStatus?
    private(set) var resultRevision = 0
    private(set) var resultTask: Task<ExtractedStatus, Error>?
    var errorMessage: String?

    private var monitorTask: Task<Void, Never>?
    private var errorDismissTask: Task<Void, Never>?
    private var resultHandler: ((ExtractedStatus) -> Void)?

    var hasStarted: Bool {
        sourceText != nil
    }

    var isExtracting: Bool {
        state == .extracting
    }

    func start(from text: String, language: AppLanguage, aiService: AIService) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        monitorTask?.cancel()
        errorDismissTask?.cancel()
        resultTask?.cancel()

        sourceText = trimmed
        result = nil
        errorMessage = nil
        state = .extracting

        let task = Task {
            try await aiService.extractStatus(from: trimmed, language: language)
        }
        resultTask = task

        monitorTask = Task { @MainActor in
            do {
                let extracted = try await task.value
                result = extracted
                state = .completed
                resultRevision += 1
                resultHandler?(extracted)
            } catch is CancellationError {
                if state == .extracting {
                    state = .idle
                }
            } catch {
                errorMessage = error.localizedDescription
                state = .failed
                errorDismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    errorMessage = nil
                }
            }
        }
    }

    func setResultHandler(_ handler: @escaping (ExtractedStatus) -> Void) {
        resultHandler = handler
        if let result {
            handler(result)
        }
    }

    func clearResultHandler() {
        resultHandler = nil
    }
}

struct AIExtractButton: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var showOptionalFields: Bool
    let draft: AIExtractionDraft

    var body: some View {
        extractionContent
            .onAppear {
                draft.setResultHandler { result in
                    applyResult(lastAction: result.lastAction, nextStep: result.nextStep)
                    showOptionalFields = true
                }
            }
            .onDisappear {
                draft.clearResultHandler()
            }
    }

    @ViewBuilder
    private var extractionContent: some View {
        let l = languageManager.language
        if aiService.isAvailable {
            let hasText = !freeText.trimmingCharacters(in: .whitespaces).isEmpty
            VStack(spacing: 4) {
                Button {
                    draft.start(from: freeText, language: l, aiService: aiService)
                } label: {
                    if draft.isExtracting {
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
                .disabled(draft.isExtracting)

                if let errorMessage = draft.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .opacity(hasText ? 1 : 0)
            .allowsHitTesting(hasText)
        }
    }

    private func applyResult(lastAction: String, nextStep: String) {
        if !lastAction.isEmpty {
            self.lastAction = AIFillerStripper.cleanLines(lastAction)
        }
        if !nextStep.isEmpty {
            self.nextStep = AIFillerStripper.cleanLines(nextStep)
        }
    }
}
