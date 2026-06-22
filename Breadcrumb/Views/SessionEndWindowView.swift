import SwiftUI

struct SessionEndWindowView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.dismissWindow) private var dismissWindow

    @AppStorage("pomodoro.showBreakQuote") private var showBreakQuote = true

    /// Window height floor. The break-over screen is short, so in compact mode
    /// (quote off) it collapses; the quote needs a little more room. All other
    /// session-end screens keep the full height for the status form.
    private var minWindowHeight: CGFloat {
        guard timer.pendingSessionEnd == .breakDone, !timer.isCycleComplete else { return 320 }
        return showBreakQuote ? 300 : 170
    }

    var body: some View {
        Group {
            if timer.pendingSessionEnd == nil {
                Color.clear
            } else {
                PomodoroSessionEndHostView {
                    dismissWindow(id: "session-end")
                }
            }
        }
        .frame(width: 360)
        .frame(minHeight: minWindowHeight)
        .onAppear(perform: dismissIfPromptIsGone)
        .onChange(of: timer.pendingSessionEnd) { _, newValue in
            if newValue == nil {
                dismissWindow(id: "session-end")
            }
        }
        .onDisappear {
            windowManager.sessionEndWindowClosed()
        }
    }

    private func dismissIfPromptIsGone() {
        if timer.pendingSessionEnd == nil {
            dismissWindow(id: "session-end")
        }
    }
}
