import SwiftUI

struct TimerBanner: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    var onExpand: () -> Void
    var onSkipBreak: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onExpand) {
                HStack(spacing: 8) {
                    Text(timer.phaseEmoji)
                        .font(.title3)

                    Text(timer.formattedTime)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(timer.isOvertime ? .orange : .primary)
                        .contentTransition(.numericText())

                    Text(bannerLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(bannerLabel), \(timer.formattedTime)")
            .accessibilityHint(Strings.Pomodoro.showTimer(languageManager.language))

            controls
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private var controls: some View {
        let l = languageManager.language
        switch timer.currentPhase {
        case .work:
            // FocusMate sessions end at a fixed time — pausing would
            // desync the countdown, so only offer stop.
            if !timer.isFocusMateSession {
                if timer.isPaused {
                    Button(action: { timer.resume() }) {
                        Image(systemName: "play.fill")
                            .font(.callout)
                    }
                    .buttonStyle(ToolbarButtonStyle())
                    .help(Strings.Pomodoro.resume(l))
                    .accessibilityLabel(Strings.Pomodoro.resume(l))
                } else {
                    Button(action: { timer.pause() }) {
                        Image(systemName: "pause.fill")
                            .font(.callout)
                    }
                    .buttonStyle(ToolbarButtonStyle())
                    .help(Strings.Pomodoro.pause(l))
                    .accessibilityLabel(Strings.Pomodoro.pause(l))
                }
            }
            Button(action: { timer.requestStop() }) {
                Image(systemName: "stop.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            .buttonStyle(ToolbarButtonStyle())
            .help(Strings.Pomodoro.stop(l))
            .accessibilityLabel(Strings.Pomodoro.stop(l))

        case .shortBreak, .longBreak:
            Button(Strings.Pomodoro.skip(l)) { onSkipBreak() }
                .buttonStyle(.bordered)
                .controlSize(.small)

        case .sessionEnded, .idle:
            EmptyView()
        }
    }

    private var bannerLabel: String {
        let l = languageManager.language
        return timer.currentPhase == .sessionEnded
            ? Strings.Pomodoro.done(l)
            : timer.phaseLabel(l)
    }
}
