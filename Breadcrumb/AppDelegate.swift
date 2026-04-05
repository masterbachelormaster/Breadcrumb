import AppKit

extension Notification.Name {
    static let openSettings = Notification.Name("Breadcrumb.openSettings")
    static let openAbout = Notification.Name("Breadcrumb.openAbout")
    static let openPopover = Notification.Name("Breadcrumb.openPopover")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventMonitor: Any?

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
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func openAbout() {
        NotificationCenter.default.post(name: .openAbout, object: nil)
    }
}
