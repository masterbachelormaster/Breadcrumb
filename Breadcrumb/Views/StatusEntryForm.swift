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

    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.Status.updateStatus(languageManager.language))
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Status.whereAreYou(languageManager.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $freeText)
                    .font(.body)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
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
                    optionalField(label: Strings.Status.lastStep(languageManager.language), text: $lastAction)
                    optionalField(label: Strings.Status.nextStep(languageManager.language), text: $nextStep)
                    optionalField(label: Strings.Status.openQuestions(languageManager.language), text: $openQuestions)
                }
                .padding(.top, 8)
            }

            HStack {
                Button(Strings.General.cancel(languageManager.language)) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(Strings.General.save(languageManager.language)) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 10)
    }

    private func optionalField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
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
        try? modelContext.save()

        // Clear draft
        freeText = ""
        lastAction = ""
        nextStep = ""
        openQuestions = ""

        onDismiss()
    }
}
