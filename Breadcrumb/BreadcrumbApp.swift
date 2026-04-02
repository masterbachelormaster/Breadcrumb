import SwiftUI
import SwiftData
import UserNotifications

@main
struct BreadcrumbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pomodoroTimer = PomodoroTimer()
    @State private var windowManager = WindowManager()
    @State private var aiService = AIService()

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
        } label: {
            Text(pomodoroTimer.menuBarLabel)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: [Project.self, PomodoroSession.self])

        Window("Breadcrumb", id: "main") {
            BreakoutWindowView()
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
        }
        .modelContainer(for: [Project.self, PomodoroSession.self])
        .defaultSize(width: 500, height: 400)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("\u{00DC}ber Breadcrumb") {
                    windowManager.open(.about)
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Einstellungen...") {
                    windowManager.open(.settings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
