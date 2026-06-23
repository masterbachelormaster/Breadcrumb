import SwiftUI

struct TimerSettingsTab: View {
    @Environment(LanguageManager.self) private var languageManager

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLongBreak = 4
    @AppStorage("pomodoro.totalSessions") private var totalSessions = 4
    @AppStorage("pomodoro.longBreaksEnabled") private var longBreaksEnabled = true
    @AppStorage("pomodoro.sessionEndPresentation") private var sessionEndPresentation
        = SessionEndPresentation.window.rawValue
    @AppStorage("pomodoro.showBreakQuote") private var showBreakQuote = true
    @AppStorage("pomodoro.focusMateEndEarlyMinutes") private var focusMateEndEarlyMinutes = 0
    @AppStorage("pomodoro.focusMateEndEarlySeconds") private var focusMateEndEarlySeconds = 0
    @AppStorage("feature.focusMateEnabled") private var focusMateEnabled = false

    private var hasBreaks: Bool { totalSessions > 1 }
    // Long breaks are only possible with 3+ sessions; the user can additionally turn them off.
    private var longBreaksPossible: Bool { totalSessions >= 3 }
    private var hasLongBreak: Bool { longBreaksPossible && longBreaksEnabled }

    /// Maximum early-end buffer: 10 minutes 50 seconds, in seconds.
    private static let maxBufferSeconds = 650

    var body: some View {
        let l = languageManager.language

        Form {
            pomodoroSection(l)
            sessionEndSection(l)
            focusMateSection(l)
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 560)
    }

    // breaks happen only BETWEEN sessions (none after the last)
    private var totalMinutes: Int {
        let breakCount = max(0, totalSessions - 1)
        // When long breaks are turned off (or impossible), every break is a short one.
        let longBreakCount = hasLongBreak ? breakCount / max(1, sessionsBeforeLongBreak) : 0
        let shortBreakCount = breakCount - longBreakCount
        return totalSessions * workMinutes
            + shortBreakCount * shortBreakMinutes
            + longBreakCount * longBreakMinutes
    }

    @ViewBuilder
    private func pomodoroSection(_ l: AppLanguage) -> some View {
        Section {
            Stepper(Strings.Pomodoro.totalSessionsLabel(l, count: totalSessions), value: $totalSessions, in: 1...8)
            Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 5...60)
            if hasBreaks {
                Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
            }
            // The long-breaks switch is always visible here in Settings so it's
            // easy to find; its detail controls only appear when long breaks can
            // actually occur (3+ sessions and the switch on).
            Toggle(Strings.Pomodoro.longBreaksToggle(l), isOn: $longBreaksEnabled)
            if hasLongBreak {
                Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLongBreak), value: $sessionsBeforeLongBreak, in: 2...(totalSessions - 1))
                Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 1...30)
            }
        } header: {
            Text(Strings.Pomodoro.pomodoro(l))
        } footer: {
            Text(Strings.Pomodoro.cycleSummary(l, sessions: totalSessions, workMinutes: workMinutes, totalMinutes: totalMinutes))
        }
        .animation(.default, value: totalSessions)
        .animation(.default, value: longBreaksEnabled)
        .onChange(of: totalSessions) {
            if sessionsBeforeLongBreak >= totalSessions {
                sessionsBeforeLongBreak = max(2, totalSessions - 1)
            }
        }
    }

    @ViewBuilder
    private func sessionEndSection(_ l: AppLanguage) -> some View {
        Section {
            Picker(Strings.Pomodoro.sessionEndAppears(l), selection: $sessionEndPresentation) {
                Text(Strings.Pomodoro.sessionEndModeWindow(l)).tag(SessionEndPresentation.window.rawValue)
                Text(Strings.Pomodoro.sessionEndModeMenuBar(l)).tag(SessionEndPresentation.menuBar.rawValue)
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $showBreakQuote) {
                HStack(spacing: 6) {
                    Text(Strings.Pomodoro.breakQuoteToggle(l))
                    InfoButton(text: Strings.Pomodoro.breakQuoteCaption(l))
                }
            }
        } header: {
            Text(Strings.Settings.sessionEndSection(l))
        } footer: {
            Text(sessionEndPresentation == SessionEndPresentation.window.rawValue
                ? Strings.Pomodoro.sessionEndModeWindowCaption(l)
                : Strings.Pomodoro.sessionEndModeMenuBarCaption(l))
        }
    }

    @ViewBuilder
    private func focusMateSection(_ l: AppLanguage) -> some View {
        Section {
            Toggle(isOn: $focusMateEnabled) {
                HStack(spacing: 6) {
                    Text(Strings.Settings.focusMateUser(l))
                    InfoButton(
                        text: Strings.Settings.focusMateUserCaption(l)
                            + "\n\n"
                            + Strings.Pomodoro.focusMateSectionFooter(l)
                    )
                }
            }
            if focusMateEnabled {
                Stepper {
                    HStack(spacing: 6) {
                        Text(Strings.Pomodoro.focusMateEndEarlyHeader(l))
                        InfoButton(text: Strings.Pomodoro.focusMateBufferCaption(l))
                        Spacer()
                        Text(Strings.Pomodoro.focusMateBufferValue(
                            l,
                            minutes: focusMateEndEarlyMinutes,
                            seconds: focusMateEndEarlySeconds
                        ))
                        .foregroundStyle(.secondary)
                    }
                } onIncrement: {
                    adjustBuffer(by: 10)
                } onDecrement: {
                    adjustBuffer(by: -10)
                }
            }
            Link(Strings.Settings.focusMateLink(l), destination: URL(string: "https://www.focusmate.com")!)
                .font(.caption)
        } header: {
            Text(Strings.Pomodoro.focusMateMode(l))
        }
        .animation(.default, value: focusMateEnabled)
    }

    private func adjustBuffer(by delta: Int) {
        let total = focusMateEndEarlyMinutes * 60 + focusMateEndEarlySeconds + delta
        let clamped = max(0, min(total, Self.maxBufferSeconds))
        focusMateEndEarlyMinutes = clamped / 60
        focusMateEndEarlySeconds = clamped % 60
    }
}
