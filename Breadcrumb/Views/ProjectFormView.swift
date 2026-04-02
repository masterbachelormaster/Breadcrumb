import SwiftUI
import SwiftData

struct ProjectFormView: View {
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

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Projekt bearbeiten" : "Neues Projekt")
                .font(.headline)

            TextField("Projektname", text: $name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 6), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(
                                    selectedIcon == icon
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Abbrechen") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Speichern" : "Erstellen") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 10)
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

        // Clear draft
        name = ""
        selectedIcon = "doc.text"

        onDismiss()
    }
}
