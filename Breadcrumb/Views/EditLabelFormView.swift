import SwiftUI
import SwiftData

struct EditLabelFormView: View {
    let editingDocument: LinkedDocument?
    @Binding var draftLabel: String
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 16) {
            Text(Strings.Documents.editLabel(l))
                .font(.headline)

            TextField(Strings.Documents.labelPlaceholder(l), text: $draftLabel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button(Strings.General.cancel(l)) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(Strings.General.save(l)) {
                    let trimmedLabel = draftLabel.trimmingCharacters(in: .whitespaces)
                    editingDocument?.label = trimmedLabel.isEmpty ? nil : trimmedLabel
                    try? modelContext.save()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
    }
}
