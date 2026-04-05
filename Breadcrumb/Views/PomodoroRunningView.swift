import SwiftUI
import SwiftData

struct PomodoroRunningView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

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
                } else if oldPhase == .shortBreak || oldPhase == .longBreak {
                    wasBreakEnd = true
                    showingSessionEnd = true
                }
            }
        }
        .overlay {
            if showingSessionEnd {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                PomodoroSessionEndView(
                    wasBreak: wasBreakEnd,
                    isCycleComplete: timer.isCycleComplete,
                    isFocusMate: timer.isFocusMateSession,
                    onSaveAndBreak: { session in
                        saveSession(session)
                        showingSessionEnd = false
                        timer.startBreak()
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
                        session.endedAt = .now
                        session.actualDuration = TimeInterval(timer.originalDurationSeconds + timer.overtimeSeconds)
                        session.project = timer.boundProject
                        session.isFocusMate = timer.isFocusMateSession
                        modelContext.insert(session)
                        modelContext.saveWithLogging()

                        showingSessionEnd = false
                        timer.startBreak()
                    },
                    onStartNextSession: {
                        showingSessionEnd = false
                        timer.startNextWorkSession()
                    },
                    onStopCompletely: {
                        // Record session
                        let session = PomodoroSession(
                            plannedDuration: TimeInterval(timer.originalDurationSeconds),
                            sessionType: .work,
                            sessionNumber: timer.currentSessionNumber
                        )
                        session.completed = timer.remainingSeconds <= 0
                        session.endedAt = .now
                        session.actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)
                        session.project = timer.boundProject
                        session.isFocusMate = timer.isFocusMateSession
                        modelContext.insert(session)
                        modelContext.saveWithLogging()

                        showingSessionEnd = false
                        timer.stop()
                        onFinished()
                    }
                )
            }
        }
    }

    private var phaseEmoji: String {
        if timer.isFocusMateSession {
            return "👥"
        }
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
            if timer.isFocusMateSession {
                if let endTime = timer.focusMateEndTime {
                    return Strings.Pomodoro.focusMatePhaseLabel(l, time: endTime.formatted(date: .omitted, time: .shortened))
                }
                return Strings.Pomodoro.focusMateMode(l)
            }
            if timer.isOvertime {
                return Strings.Pomodoro.overtimeSession(l, number: timer.currentSessionNumber)
            }
            return Strings.Pomodoro.focusTimeSession(l, number: timer.currentSessionNumber, total: timer.sessionTotalSessions)
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
        if timer.isCycleComplete {
            timer.stop()
            onFinished()
        } else {
            timer.startNextWorkSession()
        }
    }

    private func saveSession(_ session: PomodoroSession) {
        modelContext.insert(session)
        modelContext.saveWithLogging()
    }

}
