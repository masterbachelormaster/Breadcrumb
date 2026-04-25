import SwiftUI
import SwiftData

struct StatusEntryForm: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SpeechRecognizer.self) private var speechRecognizer
    let project: Project

    @Environment(\.modelContext) private var modelContext

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    var onDismiss: () -> Void = {}
    @State private var showOptionalFields = false
    @State private var freeTextFocused = false

    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.Status.updateStatus(languageManager.language))
                .font(.headline)

            ZStack(alignment: .bottomTrailing) {
                PlaceholderTextView(
                    placeholder: Strings.Status.whereAreYou(languageManager.language),
                    text: $freeText,
                    focusOnAppear: true,
                    onFocusChange: { freeTextFocused = $0 }
                )
                .frame(minHeight: 60, maxHeight: 120)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(.rect(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

                DictationButton(text: $freeText, isFocused: freeTextFocused)
                    .padding(6)
            }

            AIExtractButton(
                freeText: $freeText,
                lastAction: $lastAction,
                nextStep: $nextStep,
                openQuestions: $openQuestions,
                showOptionalFields: $showOptionalFields
            )

            DisclosureGroup(Strings.Status.optionalFields(languageManager.language), isExpanded: $showOptionalFields) {
                VStack(spacing: 12) {
                    TextField(Strings.Status.lastStep(languageManager.language), text: $lastAction)
                    TextField(Strings.Status.nextStep(languageManager.language), text: $nextStep)
                    TextField(Strings.Status.openQuestions(languageManager.language), text: $openQuestions)
                }
                .padding(.top, 8)
            }

            HStack {
                Button(Strings.General.cancel(languageManager.language)) {
                    speechRecognizer.stopListening()
                    onDismiss()
                }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(Strings.General.save(languageManager.language)) { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help(Strings.General.saveHint(languageManager.language))
                    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
    }

    private func save() {
        speechRecognizer.stopListening()
        let trimmed = freeText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let entry = StatusEntry(
            freeText: trimmed,
            lastAction: lastAction.isEmpty ? nil : lastAction,
            nextStep: nextStep.isEmpty ? nil : nextStep,
            openQuestions: openQuestions.isEmpty ? nil : openQuestions
        )
        entry.project = project
        project.entries.append(entry)
        modelContext.insert(entry)
        modelContext.saveWithLogging()

        // Clear draft
        freeText = ""
        lastAction = ""
        nextStep = ""
        openQuestions = ""

        onDismiss()
    }
}
