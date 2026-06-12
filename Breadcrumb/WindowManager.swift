import SwiftUI
import Observation

enum BreakoutContent: Equatable {
    case settings
    case about
    case history(Project)
    case stats(Project)

    static func == (lhs: BreakoutContent, rhs: BreakoutContent) -> Bool {
        switch (lhs, rhs) {
        case (.settings, .settings), (.about, .about):
            return true
        case let (.history(a), .history(b)):
            return a.id == b.id
        case let (.stats(a), .stats(b)):
            return a.id == b.id
        default:
            return false
        }
    }

    func windowTitle(for language: AppLanguage) -> String {
        switch self {
        case .settings: return Strings.General.settings(language)
        case .about: return Strings.General.about(language)
        case .history: return Strings.Status.history(language)
        case .stats: return Strings.Pomodoro.pomodoroStatistics(language)
        }
    }
}

@Observable
@MainActor
final class WindowManager {
    // MARK: - Properties

    private(set) var currentContent: BreakoutContent?

    /// Incremented on each `open()`. A stale `windowClosed()` (e.g. from an
    /// `onDisappear` that fires after a content swap) checks this to avoid
    /// undoing a newer `open()`.
    private var openGeneration: Int = 0

    private var openWindowAction: OpenWindowAction?
    private var openSettingsAction: OpenSettingsAction?
    private var isSessionEndAutoOpenSuppressed = false

    func setOpenWindowAction(_ action: OpenWindowAction) {
        openWindowAction = action
    }

    func setOpenSettingsAction(_ action: OpenSettingsAction) {
        openSettingsAction = action
    }

    // MARK: - Public Methods

    func open(_ content: BreakoutContent) {
        openGeneration += 1
        currentContent = content

        Task { @MainActor in
            await activateForWindowPresentation()
            openWindowAction?(id: "main")

            try? await Task.sleep(for: .milliseconds(200))
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func openSettings() {
        guard let openSettingsAction else { return }
        Task { @MainActor in
            await activateForWindowPresentation()
            openSettingsAction()

            try? await Task.sleep(for: .milliseconds(200))
            if let window = settingsWindow {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func settingsWindowClosed() {
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            if !self.hasVisibleRegularWindow(where: { $0.identifier?.rawValue.contains("Settings") != true }) {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    func openSessionEnd() {
        isSessionEndAutoOpenSuppressed = false
        presentSessionEndWindow()
    }

    func autoOpenSessionEnd() {
        guard !isSessionEndAutoOpenSuppressed else { return }
        presentSessionEndWindow()
    }

    func resetSessionEndWindowSuppression() {
        isSessionEndAutoOpenSuppressed = false
    }

    func windowClosed() {
        let generation = openGeneration
        // Short delay so a rapid open() that fires right after (e.g. content
        // swap causing onDisappear followed by a new open()) bumps the
        // generation before we act.
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            guard self.openGeneration == generation else { return }
            self.currentContent = nil
            if !self.hasVisibleRegularWindow(excluding: "main") {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    func sessionEndWindowClosed() {
        isSessionEndAutoOpenSuppressed = true

        Task {
            try? await Task.sleep(for: .milliseconds(50))
            if !self.hasVisibleRegularWindow(excluding: "session-end") {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    private func presentSessionEndWindow() {
        Task { @MainActor in
            await activateForWindowPresentation()
            openWindowAction?(id: "session-end")

            try? await Task.sleep(for: .milliseconds(200))
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "session-end" }) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func activateForWindowPresentation() async {
        NSApp.setActivationPolicy(.regular)
        try? await Task.sleep(for: .milliseconds(100))
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hasVisibleRegularWindow(excluding identifier: String) -> Bool {
        hasVisibleRegularWindow(where: { $0.identifier?.rawValue != identifier })
    }

    private func hasVisibleRegularWindow(where isIncluded: (NSWindow) -> Bool) -> Bool {
        NSApp.windows.contains { window in
            isIncluded(window)
                && window.isVisible
                && !window.isMiniaturized
                && window.level == .normal
        }
    }

    /// SwiftUI assigns the Settings scene window its own identifier
    /// (observed as "com_apple_SwiftUI_Settings_window"); match loosely
    /// so an OS rename doesn't break us.
    private var settingsWindow: NSWindow? {
        NSApp.windows.first { $0.identifier?.rawValue.contains("Settings") == true }
    }
}
