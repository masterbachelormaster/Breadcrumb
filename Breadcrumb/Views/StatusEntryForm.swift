import SwiftUI
import SwiftData

struct StatusEntryForm: View {
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
            Text("Status aktualisieren")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Wo stehst du gerade?")
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

            DisclosureGroup("Optionale Felder", isExpanded: $showOptionalFields) {
                VStack(spacing: 12) {
                    optionalField(label: "Letzter Schritt", text: $lastAction)
                    optionalField(label: "Nächster Schritt", text: $nextStep)
                    optionalField(label: "Offene Fragen", text: $openQuestions)
                }
                .padding(.top, 8)
            }

            HStack {
                Button("Abbrechen") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Speichern") { save() }
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

        // Clear draft
        freeText = ""
        lastAction = ""
        nextStep = ""
        openQuestions = ""

        onDismiss()
    }
}
