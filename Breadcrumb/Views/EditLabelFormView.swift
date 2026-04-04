import SwiftUI
import SwiftData

struct EditLabelFormView: View {
    let editingDocument: LinkedDocument?
    @Binding var draftLabel: String
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @FocusState private var isLabelFocused: Bool

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 16) {
            Text(Strings.Documents.editLabel(l))
                .font(.headline)

            TextField(Strings.Documents.labelPlaceholder(l), text: $draftLabel)
                .textFieldStyle(.roundedBorder)
                .focused($isLabelFocused)

            HStack {
                Button(Strings.General.cancel(l)) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(Strings.General.save(l)) {
                    let trimmedLabel = draftLabel.trimmingCharacters(in: .whitespaces)
                    editingDocument?.label = trimmedLabel.isEmpty ? nil : trimmedLabel
                    modelContext.saveWithLogging()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isLabelFocused = true
        }
    }
}
