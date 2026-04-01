import SwiftUI
import SwiftData

struct StatusEntryForm: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var freeText = ""
    @State private var lastAction = ""
    @State private var nextStep = ""
    @State private var openQuestions = ""
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
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Speichern") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
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
        dismiss()
    }
}
