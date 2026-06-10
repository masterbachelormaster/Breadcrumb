import SwiftUI

struct MenuBarLabelView: View {
    @Environment(\.openWindow) private var openWindow

    let pomodoroTimer: PomodoroTimer
    let windowManager: WindowManager
    let languageManager: LanguageManager

    @AppStorage("pomodoro.sessionEndPresentation")
    private var sessionEndPresentation = SessionEndPresentation.window.rawValue

    var body: some View {
        Group {
            if pomodoroTimer.currentPhase == .idle {
                Image(systemName: "bookmark.fill")
            } else {
                let label = pomodoroTimer.menuBarLabel(languageManager.language)
                Image(nsImage: MenuBarLabelRenderer.image(for: label))
                    .accessibilityLabel(label)
            }
        }
        .task {
            windowManager.setOpenWindowAction(openWindow)
        }
        .onChange(of: pomodoroTimer.pendingSessionEnd) { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                windowManager.resetSessionEndWindowSuppression()
            } else if newValue == nil {
                windowManager.resetSessionEndWindowSuppression()
            }
            autoOpenSessionEndWindowIfNeeded()
        }
        .onChange(of: sessionEndPresentation) {
            autoOpenSessionEndWindowIfNeeded()
        }
    }

    private var sessionEndMode: SessionEndPresentation {
        SessionEndPresentation(rawValue: sessionEndPresentation) ?? .window
    }

    private func autoOpenSessionEndWindowIfNeeded() {
        guard let reason = pomodoroTimer.pendingSessionEnd,
              reason != .stopped,
              sessionEndMode == .window else { return }
        windowManager.autoOpenSessionEnd()
    }
}
