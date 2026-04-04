import SwiftUI
import SwiftData

struct ArchivedProjectsView: View {
    @Environment(LanguageManager.self) private var languageManager
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
                        Text(Strings.General.back(languageManager.language))
                    }
                    .font(.body)
                }
                .buttonStyle(ToolbarButtonStyle())

                Spacer()

                Text(Strings.Projects.archiveTitle(languageManager.language))
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
                    Strings.Projects.noArchivedProjects(languageManager.language),
                    systemImage: "archivebox",
                    description: Text(Strings.Projects.archivedProjectsDescription(languageManager.language))
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
                        Button(Strings.Projects.reactivate(languageManager.language), systemImage: "arrow.uturn.left") {
                            project.isActive = true
                            try? modelContext.save()
                        }
                        Divider()
                        Button(Strings.Projects.permanentlyDelete(languageManager.language), systemImage: "trash", role: .destructive) {
                            modelContext.delete(project)
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
    }
}
