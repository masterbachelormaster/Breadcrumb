import SwiftUI
import SwiftData

struct AddURLFormView: View {
    let project: Project
    @Binding var draftURL: String
    @Binding var draftLabel: String
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        let l = languageManager.language
        let trimmedURL = draftURL.trimmingCharacters(in: .whitespaces)
        let isValidURL = !trimmedURL.isEmpty && URL(string: trimmedURL) != nil

        VStack(spacing: 16) {
            Text(Strings.Documents.addURL(l))
                .font(.headline)

            TextField(Strings.Documents.urlPlaceholder(l), text: $draftURL)
                .textFieldStyle(.roundedBorder)

            TextField(Strings.Documents.labelPlaceholder(l), text: $draftLabel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button(Strings.General.cancel(l)) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(Strings.General.save(l)) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidURL)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
    }

    private func save() {
        let trimmed = draftURL.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed) else { return }
        let trimmedLabel = draftLabel.trimmingCharacters(in: .whitespaces)

        let doc = LinkedDocument(
            type: .url,
            originalFilename: url.host() ?? url.absoluteString,
            urlString: trimmed,
            label: trimmedLabel.isEmpty ? nil : trimmedLabel
        )
        doc.project = project
        modelContext.insert(doc)
        try? modelContext.save()

        onDismiss()
    }
}
