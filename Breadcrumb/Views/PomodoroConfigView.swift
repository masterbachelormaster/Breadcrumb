import SwiftUI

enum TimerMode: String, CaseIterable {
    case pomodoro, focusMate
}

struct PomodoroConfigView: View {
    @Environment(LanguageManager.self) private var languageManager

    let project: Project?

    @Binding var workMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var sessionsBeforeLong: Int
    @Binding var totalSessions: Int
    @Binding var timerMode: TimerMode
    @Binding var focusMateMinutes: Int
    @Binding var focusMateStartTime: Date

    var onStart: () -> Void
    var onDismiss: () -> Void

    @State private var availableBoundaries: [Date] = []

    private var hasBreaks: Bool { totalSessions > 1 }
    private var hasLongBreak: Bool { totalSessions >= 3 }

    var body: some View {
        let l = languageManager.language
        VStack(spacing: 16) {
            Text(Strings.Pomodoro.configureSession(l))
                .font(.headline)

            if let project {
                HStack(spacing: 4) {
                    Image(systemName: project.icon)
                        .font(.caption)
                    Text(project.name)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }

            Picker("", selection: $timerMode) {
                Text(Strings.Pomodoro.pomodoroMode(l)).tag(TimerMode.pomodoro)
                Text(Strings.Pomodoro.focusMateMode(l)).tag(TimerMode.focusMate)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if timerMode == .pomodoro {
                Stepper(Strings.Pomodoro.totalSessionsLabel(l, count: totalSessions), value: $totalSessions, in: 1...8)
                Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 1...60)

                if hasBreaks {
                    Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
                    if hasLongBreak {
                        Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLong), value: $sessionsBeforeLong, in: 2...(totalSessions - 1))
                        Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 5...30)
                    }
                }
            } else {
                Picker(Strings.Pomodoro.focusMateLength(l), selection: $focusMateMinutes) {
                    Text(Strings.Pomodoro.focusMateMinutesOption(l, minutes: 25)).tag(25)
                    Text(Strings.Pomodoro.focusMateMinutesOption(l, minutes: 50)).tag(50)
                    Text(Strings.Pomodoro.focusMateMinutesOption(l, minutes: 75)).tag(75)
                }
                .pickerStyle(.segmented)

                Text(Strings.Pomodoro.focusMateSessionStart(l))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(availableBoundaries, id: \.self) { boundary in
                        startTimeButton(boundary: boundary)
                    }
                }

                let endTime = focusMateStartTime.addingTimeInterval(Double(focusMateMinutes) * 60)
                Text(Strings.Pomodoro.focusMateEndsAt(l, time: endTime.formatted(date: .omitted, time: .shortened)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(Strings.General.cancel(l)) { onDismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(Strings.Pomodoro.startSession(l)) { onStart() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .animation(.default, value: totalSessions)
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .onAppear {
            updateBoundaries()
        }
        .onChange(of: focusMateMinutes) {
            updateBoundaries()
        }
        .onChange(of: totalSessions) {
            if sessionsBeforeLong >= totalSessions {
                sessionsBeforeLong = max(2, totalSessions - 1)
            }
        }
    }

    @ViewBuilder
    private func startTimeButton(boundary: Date) -> some View {
        let isSelected = boundary == focusMateStartTime
        Button {
            focusMateStartTime = boundary
        } label: {
            Text(boundary.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
    }

    private func updateBoundaries() {
        availableBoundaries = computeAvailableBoundaries(durationMinutes: focusMateMinutes)
        if !availableBoundaries.contains(focusMateStartTime), let latest = availableBoundaries.last {
            focusMateStartTime = latest
        }
    }

    private func computeAvailableBoundaries(durationMinutes: Int) -> [Date] {
        let now = Date.now
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: now)
        let lastBoundaryMinute = (minute / 15) * 15
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        components.minute = lastBoundaryMinute
        components.second = 0
        let latestBoundary = calendar.date(from: components)!

        var boundaries: [Date] = []
        var boundary = latestBoundary
        while boundary.addingTimeInterval(Double(durationMinutes) * 60) > now {
            boundaries.append(boundary)
            boundary = boundary.addingTimeInterval(-15 * 60)
        }
        return boundaries.reversed()
    }
}
