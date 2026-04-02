import SwiftUI
import SwiftData

struct ArchivedProjectsView: View {
    @Query(filter: #Predicate<Project> { !$0.isActive })
    private var archivedProjects: [Project]

    @Environment(\.modelContext) private var modelContext

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.body)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Archiv")
                    .font(.headline)

                Spacer()

                // Spacer for symmetry
                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            if archivedProjects.isEmpty {
                ContentUnavailableView(
                    "Keine archivierten Projekte",
                    systemImage: "archivebox",
                    description: Text("Archivierte Projekte erscheinen hier")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(archivedProjects) { project in
                    HStack {
                        Image(systemName: project.icon)
                            .foregroundStyle(.secondary)
                        Text(project.name)
                        Spacer()
                    }
                    .contextMenu {
                        Button("Reaktivieren", systemImage: "arrow.uturn.left") {
                            project.isActive = true
                        }
                        Divider()
                        Button("Endgültig löschen", systemImage: "trash", role: .destructive) {
                            modelContext.delete(project)
                        }
                    }
                }
            }
        }
    }
}
