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
    private var isSessionEndAutoOpenSuppressed = false

    func setOpenWindowAction(_ action: OpenWindowAction) {
        openWindowAction = action
    }

    // MARK: - Public Methods

    func open(_ content: BreakoutContent) {
        openGeneration += 1
        currentContent = content

        activateForWindowPresentation()

        openWindowAction?(id: "main")

        // SwiftUI mounts the window on the next run-loop tick. Wait a
        // frame, then explicitly make it the key window so its title bar
        // reflects the active state rather than the dimmed inactive state,
        // and so keyboard focus actually lands inside our content.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                window.makeKeyAndOrderFront(nil)
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
        activateForWindowPresentation()
        openWindowAction?(id: "session-end")

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "session-end" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func activateForWindowPresentation() {
        // Transition from menu-bar-only (.accessory) to a regular app so a
        // Dock icon and a proper window can appear.
        NSApp.setActivationPolicy(.regular)

        // Force this process to become the frontmost app. We explicitly do
        // NOT use cooperative `NSApp.activate()` here: on macOS 14+ the
        // cooperative call silently no-ops once the MenuBarExtra popover has
        // dismissed and transferred "user attention" back to whatever app was
        // previously front. The policy change succeeds, the window orders
        // forward, but the app itself never becomes frontmost — so the window
        // stays visible with a grayed-out title bar until the user clicks the
        // Dock icon. For a menu bar utility presenting its primary window in
        // direct response to an explicit user action, that's the wrong model.
        //
        // `NSRunningApplication.current.activate(options:)` with
        // `.activateAllWindows` is the modern, non-deprecated escape hatch:
        // it bypasses cooperative activation and brings every window of this
        // process to the front, which also makes the app frontmost.
        NSRunningApplication.current.activate(options: [.activateAllWindows])
    }

    private func hasVisibleRegularWindow(excluding identifier: String) -> Bool {
        NSApp.windows.contains { window in
            window.identifier?.rawValue != identifier
                && window.isVisible
                && !window.isMiniaturized
                && window.level == .normal
        }
    }
}
