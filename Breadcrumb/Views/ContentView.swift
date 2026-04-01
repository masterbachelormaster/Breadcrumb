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
