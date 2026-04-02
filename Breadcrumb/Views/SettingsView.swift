import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLongBreak = 4
    @AppStorage("pomodoro.playSound") private var playSound = true
    @AppStorage("pomodoro.showNotification") private var showNotification = true

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.body)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Einstellungen")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            Form {
                Section("Allgemein") {
                    Toggle("Beim Login starten", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                }

                Section("Pomodoro") {
                    Stepper("Fokuszeit: \(workMinutes) Min.", value: $workMinutes, in: 5...60)
                    Stepper("Kurze Pause: \(shortBreakMinutes) Min.", value: $shortBreakMinutes, in: 1...15)
                    Stepper("Lange Pause: \(longBreakMinutes) Min.", value: $longBreakMinutes, in: 5...30)
                    Stepper("Sitzungen bis lange Pause: \(sessionsBeforeLongBreak)", value: $sessionsBeforeLongBreak, in: 2...8)
                }

                Section("Benachrichtigungen") {
                    Toggle("Ton abspielen", isOn: $playSound)
                    Toggle("Systembenachrichtigung", isOn: $showNotification)
                }
            }
            .formStyle(.grouped)
        }
    }
}
