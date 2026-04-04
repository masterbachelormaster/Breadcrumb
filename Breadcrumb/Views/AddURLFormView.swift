import SwiftUI
import SwiftData

struct AddURLFormView: View {
    let project: Project
    @Binding var draftURL: String
    @Binding var draftLabel: String
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @FocusState private var isURLFocused: Bool

    private var normalizedURL: URL? {
        let trimmed = draftURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host() != nil else { return nil }
        return url
    }

    private var showsValidationError: Bool {
        let trimmed = draftURL.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && normalizedURL == nil
    }

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 16) {
            Text(Strings.Documents.addURL(l))
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                TextField(Strings.Documents.urlPlaceholder(l), text: $draftURL)
                    .textFieldStyle(.roundedBorder)
                    .focused($isURLFocused)

                if showsValidationError {
                    Text(Strings.Documents.invalidURL(l))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            TextField(Strings.Documents.labelPlaceholder(l), text: $draftLabel)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button(Strings.General.cancel(l)) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(Strings.General.save(l)) {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(normalizedURL == nil)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isURLFocused = true
        }
    }

    private func save() {
        guard let url = normalizedURL else { return }
        let trimmedLabel = draftLabel.trimmingCharacters(in: .whitespaces)

        let doc = LinkedDocument(
            type: .url,
            originalFilename: url.host() ?? url.absoluteString,
            urlString: url.absoluteString,
            label: trimmedLabel.isEmpty ? nil : trimmedLabel
        )
        doc.project = project
        modelContext.insert(doc)
        modelContext.saveWithLogging()

        onDismiss()
    }
}
