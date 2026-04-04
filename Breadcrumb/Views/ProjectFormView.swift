import SwiftUI
import SwiftData

struct ProjectFormView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

    var editingProject: Project?
    @Binding var name: String
    @Binding var selectedIcon: String
    var onDismiss: () -> Void = {}

    private let availableIcons = [
        "doc.text", "briefcase", "laptopcomputer", "book",
        "hammer", "cart", "graduationcap", "house",
        "heart", "star", "folder", "pencil"
    ]

    private var isEditing: Bool { editingProject != nil }
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? Strings.Projects.editProject(languageManager.language) : Strings.Projects.newProject(languageManager.language))
                .font(.headline)

            TextField(Strings.Projects.projectName(languageManager.language), text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)

            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Projects.icon(languageManager.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 6), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(IconPickerButtonStyle(isSelected: selectedIcon == icon))
                    }
                }
            }

            HStack {
                Button(Strings.General.cancel(languageManager.language)) { onDismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? Strings.General.save(languageManager.language) : Strings.General.create(languageManager.language)) { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isNameFocused = true
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let project = editingProject {
            project.name = trimmedName
            project.icon = selectedIcon
        } else {
            let project = Project(name: trimmedName, icon: selectedIcon)
            modelContext.insert(project)
        }
        modelContext.saveWithLogging()

        // Clear draft
        name = ""
        selectedIcon = "doc.text"

        onDismiss()
    }
}
