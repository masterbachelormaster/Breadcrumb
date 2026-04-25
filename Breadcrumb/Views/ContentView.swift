import SwiftUI

struct ContentView: View {
    @Environment(PomodoroTimer.self) private var pomodoroTimer
    @Environment(WindowManager.self) private var windowManager
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
                    WelcomeView(onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) { hasSeenWelcome = true }
                    })
                    .transition(.opacity)
                } else if pomodoroTimer.currentPhase != .idle {
                    PomodoroRunningView(onFinished: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            screen = .projectList
                            selectedProject = nil
                        }
                    })
                    .transition(.opacity)
                } else if let project = selectedProject {
                    ProjectDetailView(
                        project: project,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedProject = nil }
                        },
                        onStartPomodoro: { startPomodoro(project: project) }
                    )
                    .transition(.opacity)
                } else {
                    switch screen {
                    case .projectList:
                        ProjectListView(
                            onSelectProject: { project in
                                withAnimation(.easeInOut(duration: 0.2)) { selectedProject = project }
                            },
                            onNavigate: { newScreen in
                                withAnimation(.easeInOut(duration: 0.2)) { screen = newScreen }
                            },
                            onStartStandalonePomodoro: {
                                withAnimation(.easeInOut(duration: 0.2)) { screen = .projectPicker }
                            }
                        )
                        .transition(.opacity)
                    case .archivedProjects:
                        ArchivedProjectsView(onBack: {
                            withAnimation(.easeInOut(duration: 0.2)) { screen = .projectList }
                        })
                        .transition(.opacity)
                    case .projectPicker:
                        ProjectPickerView(
                            onSelect: { project in
                                startPomodoro(project: project)
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.2)) { screen = .projectList }
                            }
                        )
                        .transition(.opacity)
                    }
                }
            }

            if showingPomodoroConfig {
                FormOverlay(onDismiss: { withAnimation(.easeInOut(duration: 0.2)) { showingPomodoroConfig = false } }) {
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
                        onDismiss: { withAnimation(.easeInOut(duration: 0.2)) { showingPomodoroConfig = false } }
                    )
                }
                .transition(.opacity)
            }
        }
        .frame(width: 350, height: 450)
    }

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLong = 4
    @AppStorage("pomodoro.totalSessions") private var totalSessions = 4
    @AppStorage("pomodoro.focusMateEndEarlyMinutes") private var focusMateEndEarlyMinutes = 0

    private func startPomodoro(project: Project?) {
        pendingPomodoroProject = project
        configWorkMinutes = workMinutes
        configShortBreakMinutes = shortBreakMinutes
        configLongBreakMinutes = longBreakMinutes
        configSessionsBeforeLong = sessionsBeforeLong
        configTotalSessions = totalSessions
        screen = .projectList
        withAnimation(.easeInOut(duration: 0.2)) { showingPomodoroConfig = true }
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
                endTime: endTime,
                earlyEndMinutes: focusMateEndEarlyMinutes
            )
        }
        showingPomodoroConfig = false
    }
}
