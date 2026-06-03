import SwiftUI

struct PomodoroRunningView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    @Environment(WindowManager.self) private var windowManager
    var onFinished: () -> Void

    @AppStorage("pomodoro.sessionEndPresentation") private var sessionEndPresentation = SessionEndPresentation.window.rawValue

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

            if timer.isFocusMateSession && timer.focusMateEarlyEndSeconds > 0 && timer.currentPhase == .work {
                Text(Strings.Pomodoro.wrapUpBuffer(languageManager.language, seconds: timer.focusMateEarlyEndSeconds))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Project name + history
            if let project = timer.boundProject {
                HStack(spacing: 4) {
                    Image(systemName: project.icon)
                        .font(.caption)
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)

                Button(Strings.Status.history(languageManager.language)) {
                    windowManager.open(.history(project))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
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
        .overlay {
            if timer.pendingSessionEnd != nil && (sessionEndMode == .menuBar || timer.pendingSessionEnd == .stopped) {
                FormOverlay(onDismiss: {}) {
                    PomodoroSessionEndHostView(onFinished: onFinished)
                        .frame(width: 320)
                        .frame(maxHeight: 400)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .clipShape(.rect(cornerRadius: 10))
                        .shadow(radius: 10)
                }
                .transition(.opacity)
            }
        }
    }

    private var sessionEndMode: SessionEndPresentation {
        SessionEndPresentation(rawValue: sessionEndPresentation) ?? .window
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
        timer.requestStop()
    }

    private func skipBreak() {
        timer.clearPendingSessionEnd()
        if timer.isCycleComplete {
            timer.stop()
            onFinished()
        } else {
            timer.startNextWorkSession()
        }
    }
}
