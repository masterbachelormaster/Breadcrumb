import AppKit

extension Notification.Name {
    static let openPopover = Notification.Name("Breadcrumb.openPopover")
    static let pomodoroStartBreak = Notification.Name("Breadcrumb.pomodoroStartBreak")
    static let pomodoroNextSession = Notification.Name("Breadcrumb.pomodoroNextSession")
    static let pomodoroStop = Notification.Name("Breadcrumb.pomodoroStop")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventMonitor: Any?
    var windowManager: WindowManager?
    var pomodoroTimer: PomodoroTimer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            guard let window = event.window,
                  window.level == .statusBar else {
                return event
            }

            MainActor.assumeIsolated {
                let menu = NSMenu()

                let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
                let language = AppLanguage(rawValue: stored) ?? .german

                let settingsItem = NSMenuItem(
                    title: Strings.General.settingsEllipsis(language),
                    action: #selector(AppDelegate.openSettings),
                    keyEquivalent: ","
                )
                settingsItem.target = NSApp.delegate
                menu.addItem(settingsItem)

                let aboutItem = NSMenuItem(
                    title: Strings.General.about(language),
                    action: #selector(AppDelegate.openAbout),
                    keyEquivalent: ""
                )
                aboutItem.target = NSApp.delegate
                aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
                menu.addItem(aboutItem)

                menu.addItem(NSMenuItem.separator())

                let quitItem = NSMenuItem(
                    title: Strings.General.quit(language),
                    action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q"
                )
                menu.addItem(quitItem)

                if let view = window.contentView {
                    NSMenu.popUpContextMenu(menu, with: event, for: view)
                }
            }

            return nil
        }

        NotificationCenter.default.addObserver(
            forName: .openPopover,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                // Find the status bar window and simulate a click to open the MenuBarExtra popover
                if let button = NSApp.windows
                    .compactMap({ $0.contentView?.subviews })
                    .flatMap({ $0 })
                    .first(where: { $0 is NSStatusBarButton }) as? NSStatusBarButton {
                    button.performClick(nil)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .pomodoroStartBreak,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pomodoroTimer?.startBreak()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .pomodoroNextSession,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pomodoroTimer?.startNextWorkSession()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .pomodoroStop,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pomodoroTimer?.stop()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func openSettings() {
        windowManager?.open(.settings)
    }

    @objc private func openAbout() {
        windowManager?.open(.about)
    }
}
