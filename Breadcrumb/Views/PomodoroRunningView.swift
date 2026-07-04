import SwiftUI

struct PomodoroRunningView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    var onCollapse: () -> Void
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Phase icon
            Text(timer.phaseEmoji)
                .font(.system(size: 40))
                .padding(.bottom, 4)

            // Countdown
            Text(timer.formattedTime)
                .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(timer.isOvertime ? .orange : .primary)
                .contentTransition(.numericText())

            // Phase label
            Text(timer.phaseLabel(languageManager.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            if timer.isFocusMateSession && timer.focusMateEarlyEndSeconds > 0 && timer.currentPhase == .work {
                Text(Strings.Pomodoro.wrapUpBuffer(languageManager.language, seconds: timer.focusMateEarlyEndSeconds))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

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

            // Latest saved status for the running project — read-only
            // context while you work (shown for work and break phases).
            if let entry = latestEntry,
               !(entry.lastAction ?? "").isEmpty || !(entry.nextStep ?? "").isEmpty || entry.aiExtractionState.showsInlineStatus {
                statusCard(entry)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Controls
            HStack(spacing: 12) {
                switch timer.currentPhase {
                case .work:
                    // FocusMate sessions end at a fixed time — pausing would
                    // desync the countdown, so only offer stop.
                    if !timer.isFocusMateSession {
                        if timer.isPaused {
                            Button(Strings.Pomodoro.resume(languageManager.language)) { timer.resume() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button(Strings.Pomodoro.pause(languageManager.language)) { timer.pause() }
                                .buttonStyle(.bordered)
                        }
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
        .overlay(alignment: .topTrailing) {
            Button(action: onCollapse) {
                Image(systemName: "chevron.up")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(ToolbarButtonStyle())
            .padding(8)
            .help(Strings.Pomodoro.collapseToBanner(languageManager.language))
            .accessibilityLabel(Strings.Pomodoro.collapseToBanner(languageManager.language))
        }
    }

    private var latestEntry: StatusEntry? {
        timer.boundProject?.latestEntry
    }

    @ViewBuilder
    private func statusCard(_ entry: StatusEntry) -> some View {
        ViewThatFits(in: .vertical) {
            statusFields(entry)                 // hugs content when short
            ScrollView { statusFields(entry) }  // scrolls when tall
        }
        .frame(maxHeight: 140)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func statusFields(_ entry: StatusEntry) -> some View {
        let l = languageManager.language
        VStack(alignment: .leading, spacing: 10) {
            if let lastAction = entry.lastAction, !lastAction.isEmpty {
                BulletDetailField(label: Strings.Status.lastStep(l), value: lastAction)
            }
            if let nextStep = entry.nextStep, !nextStep.isEmpty {
                BulletDetailField(label: Strings.Status.nextStep(l), value: nextStep)
            }
            AIExtractionStatusView(entry: entry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
