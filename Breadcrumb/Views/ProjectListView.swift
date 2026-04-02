import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var onSelectProject: (Project) -> Void
    var onNavigate: (ContentView.Screen) -> Void

    @State private var showingNewProject = false

    // New project form drafts
    @State private var draftProjectName = ""
    @State private var draftProjectIcon = "doc.text"

    private var sortedProjects: [Project] {
        activeProjects.sorted { p1, p2 in
            let t1 = p1.latestEntry?.timestamp ?? p1.createdAt
            let t2 = p2.latestEntry?.timestamp ?? p2.createdAt
            return t1 > t2
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Breadcrumb")
                        .font(.headline)
                    Spacer()
                    Button(action: { showingNewProject = true }) {
                        Image(systemName: "plus")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
                if activeProjects.isEmpty {
                    ContentUnavailableView(
                        "Keine Projekte",
                        systemImage: "bookmark",
                        description: Text("Erstelle dein erstes Projekt mit dem + Button")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List(sortedProjects) { project in
                        Button(action: { onSelectProject(project) }) {
                            ProjectRowView(project: project)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Footer
                FooterView(onNavigate: onNavigate)
            }

            // Inline overlay for new project form
            if showingNewProject {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showingNewProject = false }
                ProjectFormView(
                    name: $draftProjectName,
                    selectedIcon: $draftProjectIcon,
                    onDismiss: { showingNewProject = false }
                )
            }
        }
    }
}

struct FooterView: View {
    var onNavigate: (ContentView.Screen) -> Void

    var body: some View {
        HStack {
            Button(action: { onNavigate(.archivedProjects) }) {
                Image(systemName: "archivebox")
                    .font(.callout)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { onNavigate(.settings) }) {
                Image(systemName: "gear")
                    .font(.callout)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Beenden") {
                NSApplication.shared.terminate(nil)
            }
            .font(.callout)
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
