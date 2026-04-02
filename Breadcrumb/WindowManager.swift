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

    var windowTitle: String {
        switch self {
        case .settings: return "Einstellungen"
        case .about: return "Über Breadcrumb"
        case .history: return "Historie"
        case .stats: return "Pomodoro-Statistiken"
        }
    }
}

@Observable
@MainActor
final class WindowManager {
    // MARK: - Properties

    private(set) var currentContent: BreakoutContent?

    // MARK: - Public Methods

    func open(_ content: BreakoutContent) {
        currentContent = content
        NSApp.setActivationPolicy(.regular)
        // Brief delay for activation policy to take effect before bringing app forward
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            NSApp.activate()
        }
    }

    func windowClosed() {
        currentContent = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
