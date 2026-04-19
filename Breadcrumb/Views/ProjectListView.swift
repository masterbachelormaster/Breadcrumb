import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var onSelectProject: (Project) -> Void
    var onNavigate: (ContentView.Screen) -> Void
    var onStartStandalonePomodoro: () -> Void

    @Environment(LanguageManager.self) private var languageManager

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
                    Button(Strings.Projects.newProject(languageManager.language), systemImage: "plus") {
                        draftProjectName = ""
                        draftProjectIcon = "doc.text"
                        showingNewProject = true
                    }
                    .labelStyle(.iconOnly)
                    .font(.body)
                    .buttonStyle(ToolbarButtonStyle())
                    .keyboardShortcut("n", modifiers: .command)
                    .help(Strings.Projects.newProjectHint(languageManager.language))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
                if activeProjects.isEmpty {
                    ContentUnavailableView(
                        Strings.Projects.noProjects(languageManager.language),
                        systemImage: "bookmark",
                        description: Text(Strings.Projects.noProjectsDescription(languageManager.language))
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List(sortedProjects) { project in
                        Button(action: { onSelectProject(project) }) {
                            ProjectRowView(project: project)
                        }
                        .buttonStyle(ListRowButtonStyle())
                    }
                }

                // Footer
                FooterView(onNavigate: onNavigate, onStartStandalonePomodoro: onStartStandalonePomodoro)
            }

            // Inline overlay for new project form
            if showingNewProject {
                Button { showingNewProject = false } label: {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                ProjectFormView(
                    name: $draftProjectName,
                    selectedIcon: $draftProjectIcon,
                    onDismiss: { showingNewProject = false }
                )
            }
        }
    }
}
