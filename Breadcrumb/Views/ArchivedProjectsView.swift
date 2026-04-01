import SwiftUI
import SwiftData

struct ArchivedProjectsView: View {
    @Query(filter: #Predicate<Project> { !$0.isActive })
    private var archivedProjects: [Project]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if archivedProjects.isEmpty {
                ContentUnavailableView(
                    "Keine archivierten Projekte",
                    systemImage: "archivebox",
                    description: Text("Archivierte Projekte erscheinen hier")
                )
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
        .navigationTitle("Archiv")
    }
}
