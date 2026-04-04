import SwiftUI

struct PomodoroConfigView: View {
    @Environment(LanguageManager.self) private var languageManager

    let project: Project?

    @Binding var workMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var sessionsBeforeLong: Int

    var onStart: () -> Void
    var onDismiss: () -> Void

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

            Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 5...60)
            Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLong), value: $sessionsBeforeLong, in: 2...8)
            Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
            Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 5...30)

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
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
    }
}
