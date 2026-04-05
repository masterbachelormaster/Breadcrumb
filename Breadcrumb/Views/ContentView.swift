import SwiftUI

struct ContentView: View {
    @Environment(PomodoroTimer.self) private var pomodoroTimer
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.openWindow) private var openWindow
    @State private var selectedProject: Project?
    @State private var screen: Screen = .projectList
    @State private var showingPomodoroConfig = false
    @State private var pendingPomodoroProject: Project?
    @State private var configWorkMinutes: Int = 25
    @State private var configShortBreakMinutes: Int = 5
    @State private var configLongBreakMinutes: Int = 15
    @State private var configSessionsBeforeLong: Int = 4
    @State private var configTotalSessions: Int = 4
    @State private var configTimerMode: TimerMode = .pomodoro
    @State private var configFocusMateMinutes: Int = 50
    @State private var configFocusMateStartTime: Date = .now

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    enum Screen {
        case projectList
        case archivedProjects
        case projectPicker
    }

    var body: some View {
        ZStack {
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
                    }
                }
            }

            if showingPomodoroConfig {
                Button { showingPomodoroConfig = false } label: {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)

                PomodoroConfigView(
                    project: pendingPomodoroProject,
                    workMinutes: $configWorkMinutes,
                    shortBreakMinutes: $configShortBreakMinutes,
                    longBreakMinutes: $configLongBreakMinutes,
                    sessionsBeforeLong: $configSessionsBeforeLong,
                    totalSessions: $configTotalSessions,
                    timerMode: $configTimerMode,
                    focusMateMinutes: $configFocusMateMinutes,
                    focusMateStartTime: $configFocusMateStartTime,
                    onStart: { confirmStartPomodoro() },
                    onDismiss: { showingPomodoroConfig = false }
                )
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
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLong = 4
    @AppStorage("pomodoro.totalSessions") private var totalSessions = 4

    private func startPomodoro(project: Project?) {
        pendingPomodoroProject = project
        configWorkMinutes = workMinutes
        configShortBreakMinutes = shortBreakMinutes
        configLongBreakMinutes = longBreakMinutes
        configSessionsBeforeLong = sessionsBeforeLong
        configTotalSessions = totalSessions
        screen = .projectList
        showingPomodoroConfig = true
    }

    private func confirmStartPomodoro() {
        switch configTimerMode {
        case .pomodoro:
            pomodoroTimer.startWork(
                project: pendingPomodoroProject,
                durationMinutes: configWorkMinutes,
                shortBreakMinutes: configShortBreakMinutes,
                longBreakMinutes: configLongBreakMinutes,
                sessionsBeforeLong: configSessionsBeforeLong,
                totalSessions: configTotalSessions
            )
        case .focusMate:
            let endTime = configFocusMateStartTime.addingTimeInterval(Double(configFocusMateMinutes) * 60)
            pomodoroTimer.startFocusMate(
                project: pendingPomodoroProject,
                durationMinutes: configFocusMateMinutes,
                endTime: endTime
            )
        }
        showingPomodoroConfig = false
    }
}
