import SwiftUI
import SwiftData

struct StatusEntryForm: View {
    @Environment(LanguageManager.self) private var languageManager
    let project: Project

    @Environment(\.modelContext) private var modelContext

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    var onDismiss: () -> Void = {}
    @State private var showOptionalFields = false
    @FocusState private var isFreeTextFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.Status.updateStatus(languageManager.language))
                .font(.headline)

            TextField(Strings.Status.whereAreYou(languageManager.language), text: $freeText, axis: .vertical)
                .lineLimit(4...)
                .textFieldStyle(.roundedBorder)
                .focused($isFreeTextFocused)

            AIExtractButton(
                freeText: $freeText,
                lastAction: $lastAction,
                nextStep: $nextStep,
                openQuestions: $openQuestions,
                showOptionalFields: $showOptionalFields
            )

            DisclosureGroup(Strings.Status.optionalFields(languageManager.language), isExpanded: $showOptionalFields) {
                VStack(spacing: 12) {
                    OptionalFieldView(label: Strings.Status.lastStep(languageManager.language), text: $lastAction)
                    OptionalFieldView(label: Strings.Status.nextStep(languageManager.language), text: $nextStep)
                    OptionalFieldView(label: Strings.Status.openQuestions(languageManager.language), text: $openQuestions)
                }
                .padding(.top, 8)
            }

            HStack {
                Button(Strings.General.cancel(languageManager.language)) { onDismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(Strings.General.save(languageManager.language)) { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isFreeTextFocused = true
        }
    }

    private func save() {
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
