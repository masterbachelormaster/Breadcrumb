import SwiftUI

struct SessionEndWindowView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.dismissWindow) private var dismissWindow

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
        .frame(minHeight: 320)
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
