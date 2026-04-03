import SwiftUI

struct ContentView: View {
    @Environment(PomodoroTimer.self) private var pomodoroTimer
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.openWindow) private var openWindow
    @State private var selectedProject: Project?
    @State private var screen: Screen = .projectList

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    enum Screen {
        case projectList
        case archivedProjects
        case pomodoroRunning
        case projectPicker
    }

    var body: some View {
        Group {
            if !hasSeenWelcome {
                WelcomeView(onDismiss: { hasSeenWelcome = true })
            } else if pomodoroTimer.currentPhase != .idle {
                PomodoroRunningView(onFinished: {
                    screen = .projectList
                    selectedProject = nil
                })
            } else if let project = selectedProject {
                ProjectDetailView(
                    project: project,
                    onBack: { selectedProject = nil },
                    onStartPomodoro: { startPomodoro(project: project) }
                )
            } else {
                switch screen {
                case .projectList:
                    ProjectListView(
                        onSelectProject: { selectedProject = $0 },
                        onNavigate: { screen = $0 },
                        onStartStandalonePomodoro: { screen = .projectPicker }
                    )
                case .archivedProjects:
                    ArchivedProjectsView(onBack: { screen = .projectList })
                case .projectPicker:
                    ProjectPickerView(
                        onSelect: { project in
                            startPomodoro(project: project)
                        },
                        onBack: { screen = .projectList }
                    )
                case .pomodoroRunning:
                    PomodoroRunningView(onFinished: {
                        screen = .projectList
                        selectedProject = nil
                    })
                }
            }
        }
        .frame(width: 350, height: 450)
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            windowManager.open(.settings)
            openWindow(id: "main")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAbout)) { _ in
            windowManager.open(.about)
            openWindow(id: "main")
        }
    }

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25

    private func startPomodoro(project: Project?) {
        pomodoroTimer.startWork(project: project, durationMinutes: workMinutes)
    }
}
