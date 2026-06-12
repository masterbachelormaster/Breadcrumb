import SwiftUI

struct ContentView: View {
    @Environment(PomodoroTimer.self) private var pomodoroTimer
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var selectedProject: Project?
    @State private var screen: Screen = .projectList
    @State private var showFullTimer = true
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
    @AppStorage("hasAnsweredFocusMateQuestion") private var hasAnsweredFocusMateQuestion = false
    @AppStorage("feature.focusMateEnabled") private var focusMateEnabled = false
    @AppStorage("pomodoro.sessionEndPresentation") private var sessionEndPresentation = SessionEndPresentation.window.rawValue

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
                } else if !hasAnsweredFocusMateQuestion {
                    FocusMateQuestionView(onAnswer: { isUser in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            focusMateEnabled = isUser
                            hasAnsweredFocusMateQuestion = true
                        }
                    })
                    .transition(.opacity)
                } else if shouldShowSessionEndSummary {
                    SessionEndPopoverSummaryView {
                        windowManager.openSessionEnd()
                    }
                    .transition(.opacity)
                } else if pomodoroTimer.currentPhase != .idle && showFullTimer {
                    PomodoroRunningView(
                        onCollapse: {
                            withAnimation(.easeInOut(duration: 0.2)) { showFullTimer = false }
                        },
                        onFinished: { finishTimer() }
                    )
                    .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        if showBanner {
                            TimerBanner(
                                onExpand: {
                                    withAnimation(.easeInOut(duration: 0.2)) { showFullTimer = true }
                                },
                                onSkipBreak: { skipBreakFromBanner() }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        routedContent
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

            if pomodoroTimer.pendingSessionEnd != nil
                && (sessionEndMode == .menuBar || pomodoroTimer.pendingSessionEnd == .stopped) {
                FormOverlay(onDismiss: {}) {
                    PomodoroSessionEndHostView(onFinished: { finishTimer() })
                        .frame(width: 320)
                        .frame(maxHeight: 400)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .clipShape(.rect(cornerRadius: 10))
                        .shadow(radius: 10)
                }
                .transition(.opacity)
            }
        }
        .frame(width: 350, height: 450)
        .task {
            windowManager.setOpenWindowAction(openWindow)
            windowManager.setOpenSettingsAction(openSettings)
        }
        .onChange(of: pomodoroTimer.currentPhase) { oldPhase, newPhase in
            if oldPhase == .idle && newPhase != .idle {
                showFullTimer = true
            }
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        if let project = selectedProject {
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

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLong = 4
    @AppStorage("pomodoro.totalSessions") private var totalSessions = 4
    @AppStorage("pomodoro.focusMateEndEarlyMinutes") private var focusMateEndEarlyMinutes = 0
    @AppStorage("pomodoro.focusMateEndEarlySeconds") private var focusMateEndEarlySeconds = 0

    private var sessionEndMode: SessionEndPresentation {
        SessionEndPresentation(rawValue: sessionEndPresentation) ?? .window
    }

    private var shouldShowSessionEndSummary: Bool {
        guard let reason = pomodoroTimer.pendingSessionEnd else { return false }
        if reason == .stopped { return false }
        return sessionEndMode == .window
    }

    private var showBanner: Bool {
        pomodoroTimer.currentPhase != .idle && !showFullTimer
    }

    private func finishTimer() {
        withAnimation(.easeInOut(duration: 0.2)) {
            screen = .projectList
            selectedProject = nil
            showFullTimer = true
        }
    }

    private func skipBreakFromBanner() {
        pomodoroTimer.clearPendingSessionEnd()
        if pomodoroTimer.isCycleComplete {
            pomodoroTimer.stop()
            finishTimer()
        } else {
            pomodoroTimer.startNextWorkSession()
        }
    }

    private func startPomodoro(project: Project?) {
        if !focusMateEnabled { configTimerMode = .pomodoro }
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
        showFullTimer = true
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
                earlyEndSeconds: focusMateEndEarlyMinutes * 60 + focusMateEndEarlySeconds
            )
        }
        showingPomodoroConfig = false
    }
}
