import SwiftUI
import SwiftData
import UserNotifications

@main
struct BreadcrumbApp: App {
    @State private var pomodoroTimer = PomodoroTimer()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(pomodoroTimer)
        } label: {
            Text(pomodoroTimer.menuBarLabel)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: [Project.self, PomodoroSession.self])
    }
}
