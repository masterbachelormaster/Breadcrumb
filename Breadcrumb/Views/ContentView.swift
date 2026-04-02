import SwiftUI

struct ContentView: View {
    @State private var selectedProject: Project?
    @State private var screen: Screen = .projectList

    enum Screen {
        case projectList
        case archivedProjects
        case settings
    }

    var body: some View {
        Group {
            if let project = selectedProject {
                ProjectDetailView(project: project, onBack: { selectedProject = nil })
            } else {
                switch screen {
                case .projectList:
                    ProjectListView(
                        onSelectProject: { selectedProject = $0 },
                        onNavigate: { screen = $0 }
                    )
                case .archivedProjects:
                    ArchivedProjectsView(onBack: { screen = .projectList })
                case .settings:
                    SettingsView(onBack: { screen = .projectList })
                }
            }
        }
        .frame(width: 350, height: 450)
    }
}
