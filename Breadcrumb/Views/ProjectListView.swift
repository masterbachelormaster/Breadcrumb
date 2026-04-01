import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    @State private var showingNewProject = false

    private var sortedProjects: [Project] {
        activeProjects.sorted { p1, p2 in
            let t1 = p1.latestEntry?.timestamp ?? p1.createdAt
            let t2 = p2.latestEntry?.timestamp ?? p2.createdAt
            return t1 > t2
        }
    }

    var body: some View {
        Group {
            if activeProjects.isEmpty {
                ContentUnavailableView(
                    "Keine Projekte",
                    systemImage: "bookmark",
                    description: Text("Erstelle dein erstes Projekt mit dem + Button")
                )
            } else {
                List(sortedProjects) { project in
                    NavigationLink(value: project) {
                        ProjectRowView(project: project)
                    }
                }
            }
        }
        .navigationTitle("Breadcrumb")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewProject = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            ProjectFormView()
        }
        .safeAreaInset(edge: .bottom) {
            FooterView()
        }
    }
}

struct FooterView: View {
    var body: some View {
        HStack {
            NavigationLink {
                ArchivedProjectsView()
            } label: {
                Image(systemName: "archivebox")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Spacer()

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gear")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Beenden") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
