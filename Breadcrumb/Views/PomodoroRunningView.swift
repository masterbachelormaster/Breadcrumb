import SwiftUI
import SwiftData
import UserNotifications

struct PomodoroRunningView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLong = 4
    @AppStorage("pomodoro.playSound") private var playSound = true
    @AppStorage("pomodoro.showNotification") private var showNotification = true

    var onFinished: () -> Void

    @State private var showingSessionEnd = false
    @State private var wasBreakEnd = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Phase icon
            Text(phaseEmoji)
                .font(.system(size: 40))
                .padding(.bottom, 4)

            // Countdown
            Text(timer.formattedTime)
                .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(timer.isOvertime ? .orange : .primary)
                .contentTransition(.numericText())

            // Phase label
            Text(phaseLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            // Project name
            if let project = timer.boundProject {
                HStack(spacing: 4) {
                    Image(systemName: project.icon)
                        .font(.caption)
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }

            Spacer()

            // Controls
            HStack(spacing: 12) {
                switch timer.currentPhase {
                case .work:
                    if timer.isPaused {
                        Button(Strings.Pomodoro.resume(languageManager.language)) { timer.resume() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(Strings.Pomodoro.pause(languageManager.language)) { timer.pause() }
                            .buttonStyle(.bordered)
                    }
                    Button(Strings.Pomodoro.stop(languageManager.language)) { stopSession() }
                        .buttonStyle(.bordered)
                        .tint(.red)

                case .shortBreak, .longBreak:
                    Button(Strings.Pomodoro.skip(languageManager.language)) { skipBreak() }
                        .buttonStyle(.bordered)

                case .sessionEnded:
                    EmptyView()

                case .idle:
                    EmptyView()
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: timer.currentPhase) { oldPhase, newPhase in
            if newPhase == .sessionEnded {
                if oldPhase == .work {
                    wasBreakEnd = false
                    showingSessionEnd = true
                    sendNotification(title: Strings.Notifications.pomodoroFinishedTitle(languageManager.language), body: Strings.Notifications.pomodoroFinishedBody(languageManager.language))
                } else if oldPhase == .shortBreak || oldPhase == .longBreak {
                    wasBreakEnd = true
                    showingSessionEnd = true
                    sendNotification(title: Strings.Notifications.breakOverTitle(languageManager.language), body: Strings.Notifications.breakOverBody(languageManager.language))
                }
            }
        }
        .overlay {
            if showingSessionEnd {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                PomodoroSessionEndView(
                    wasBreak: wasBreakEnd,
                    onSaveAndBreak: { session in
                        saveSession(session)
                        showingSessionEnd = false
                        timer.startBreak(
                            shortMinutes: shortBreakMinutes,
                            longMinutes: longBreakMinutes,
                            sessionsBeforeLong: sessionsBeforeLong
                        )
                    },
                    onContinueWorking: {
                        showingSessionEnd = false
                        timer.enterOvertime()
                    },
                    onSkip: {
                        // Record the session even when skipping status entry
                        let session = PomodoroSession(
                            plannedDuration: TimeInterval(timer.originalDurationSeconds),
                            sessionType: .work,
                            sessionNumber: timer.currentSessionNumber
                        )
                        session.completed = true
                        session.endedAt = Date()
                        session.actualDuration = TimeInterval(timer.originalDurationSeconds + timer.overtimeSeconds)
                        session.project = timer.boundProject
                        modelContext.insert(session)

                        showingSessionEnd = false
                        timer.startBreak(
                            shortMinutes: shortBreakMinutes,
                            longMinutes: longBreakMinutes,
                            sessionsBeforeLong: sessionsBeforeLong
                        )
                    },
                    onStartNextSession: {
                        showingSessionEnd = false
                        timer.startNextWorkSession(durationMinutes: workMinutes, sessionsBeforeLong: sessionsBeforeLong)
                    },
                    onStopCompletely: {
                        // Record incomplete session
                        let session = PomodoroSession(
                            plannedDuration: TimeInterval(timer.originalDurationSeconds),
                            sessionType: .work,
                            sessionNumber: timer.currentSessionNumber
                        )
                        session.completed = false
                        session.endedAt = Date()
                        session.actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds)
                        session.project = timer.boundProject
                        modelContext.insert(session)

                        showingSessionEnd = false
                        timer.stop()
                        onFinished()
                    }
                )
            }
        }
    }

    private var phaseEmoji: String {
        switch timer.currentPhase {
        case .work, .sessionEnded: return "🍅"
        case .shortBreak, .longBreak: return "☕"
        case .idle: return "🔖"
        }
    }

    private var phaseLabel: String {
        let l = languageManager.language
        switch timer.currentPhase {
        case .idle: return ""
        case .work:
            if timer.isOvertime {
                return Strings.Pomodoro.overtimeSession(l, number: timer.currentSessionNumber)
            }
            return Strings.Pomodoro.focusTimeSession(l, number: timer.currentSessionNumber, total: sessionsBeforeLong)
        case .shortBreak: return Strings.Pomodoro.shortBreak(l)
        case .longBreak: return Strings.Pomodoro.longBreak(l)
        case .sessionEnded: return Strings.Pomodoro.sessionEnded(l)
        }
    }

    private func stopSession() {
        wasBreakEnd = false
        showingSessionEnd = true
        timer.pause()
    }

    private func skipBreak() {
        showingSessionEnd = false
        timer.startNextWorkSession(durationMinutes: workMinutes, sessionsBeforeLong: sessionsBeforeLong)
    }

    private func saveSession(_ session: PomodoroSession) {
        modelContext.insert(session)
    }

    private func sendNotification(title: String, body: String) {
        guard showNotification else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if playSound {
            content.sound = .default
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
