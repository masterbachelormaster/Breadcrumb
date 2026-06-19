import AppKit
import SwiftData

extension Notification.Name {
    static let openPopover = Notification.Name("Breadcrumb.openPopover")
    static let openSessionEnd = Notification.Name("Breadcrumb.openSessionEnd")
    static let pomodoroStartBreak = Notification.Name("Breadcrumb.pomodoroStartBreak")
    static let pomodoroNextSession = Notification.Name("Breadcrumb.pomodoroNextSession")
}

/// Owns the app's services, the SwiftData container, and the menu bar item.
///
/// Ownership lives here (not as `@State` on the `App`) because the menu bar
/// status item is created in `applicationDidFinishLaunching` — before any scene
/// appears — and needs the services ready at that point. The breakout window
/// scenes read these same instances from the delegate.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let languageManager = LanguageManager()
    let pomodoroTimer = PomodoroTimer()
    let windowManager = WindowManager()
    let aiService = AIService()
    let speechRecognizer = SpeechRecognizer()
    let notificationService = NotificationService()
    let modelContainer = BreadcrumbApp.createModelContainer()

    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        pomodoroTimer.notificationService = notificationService
        notificationService.requestAuthorization()

        let controller = MenuBarController(
            pomodoroTimer: pomodoroTimer,
            windowManager: windowManager,
            aiService: aiService,
            languageManager: languageManager,
            speechRecognizer: speechRecognizer,
            modelContainer: modelContainer
        )
        controller.install()
        menuBarController = controller

        NotificationCenter.default.addObserver(
            forName: .openPopover,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.menuBarController?.showPopover()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .openSessionEnd,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.openConfiguredSessionEndPrompt()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .pomodoroStartBreak,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pomodoroTimer.startBreak()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .pomodoroNextSession,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pomodoroTimer.startNextWorkSession()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func openConfiguredSessionEndPrompt() {
        let stored = UserDefaults.standard.string(forKey: "pomodoro.sessionEndPresentation") ?? SessionEndPresentation.window.rawValue
        let presentation = SessionEndPresentation(rawValue: stored) ?? .window

        switch presentation {
        case .window:
            windowManager.openSessionEnd()
        case .menuBar:
            menuBarController?.showPopover()
        }
    }
}
