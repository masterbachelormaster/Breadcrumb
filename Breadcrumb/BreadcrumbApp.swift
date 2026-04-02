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
            BreadcrumbCommands(windowManager: windowManager)
        }
    }
}

struct BreadcrumbCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let windowManager: WindowManager

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("Über Breadcrumb") {
                windowManager.open(.about)
                openWindow(id: "main")
            }
        }
        CommandGroup(replacing: .appSettings) {
            Button("Einstellungen...") {
                windowManager.open(.settings)
                openWindow(id: "main")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
