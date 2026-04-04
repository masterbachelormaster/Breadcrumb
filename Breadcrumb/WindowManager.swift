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

    // MARK: - Public Methods

    func open(_ content: BreakoutContent) {
        openGeneration += 1
        currentContent = content
        NSApp.setActivationPolicy(.regular)
        // Brief delay for activation policy to take effect before bringing app forward
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            NSApp.activate()
        }
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
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
