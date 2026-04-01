import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ProjectListView()
                .navigationDestination(for: Project.self) { project in
                    ProjectDetailView(project: project)
                }
        }
        .frame(width: 350, height: 450)
    }
}

// MARK: - Stub (replaced in Task 5)

struct ProjectDetailView: View {
    let project: Project
    var body: some View {
        Text("Detail: \(project.name)")
    }
}
