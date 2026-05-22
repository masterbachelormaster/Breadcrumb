import SwiftData
import SwiftUI

struct PomodoroSessionEndHostView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(\.modelContext) private var modelContext

    var onFinished: () -> Void

    var body: some View {
        if let reason = timer.pendingSessionEnd {
            PomodoroSessionEndView(
                wasBreak: reason == .breakDone,
                isCycleComplete: timer.isCycleComplete,
                isFocusMate: reason == .focusMateDone || timer.isFocusMateSession,
                boundProjectID: timer.boundProjectID,
                onSaveWorkSession: handleSaveWorkSession,
                onContinueWorking: handleContinueWorking,
                onSkip: handleSkip,
                onStartNextSession: handleStartNextSession,
                onStopCompletely: { handleStopCompletely(wasBreak: reason == .breakDone) },
                onStopAfterSave: handleStopAfterSave,
                onSnooze: handleSnooze
            )
        }
    }

    private var boundProject: Project? {
        guard let boundProjectID = timer.boundProjectID else { return nil }
        return modelContext.model(for: boundProjectID) as? Project
    }

    private func handleSaveWorkSession(_ session: PomodoroSession) {
        modelContext.insert(session)
        modelContext.saveWithLogging()
        timer.clearPendingSessionEnd()

        if timer.isCycleComplete {
            timer.stop()
            onFinished()
        } else {
            timer.startBreak()
        }
    }

    private func handleContinueWorking() {
        timer.clearPendingSessionEnd()
    }

    private func handleSkip() {
        saveCurrentWorkSession()
        timer.clearPendingSessionEnd()

        if timer.isCycleComplete {
            timer.stop()
            onFinished()
        } else {
            timer.startBreak()
        }
    }

    private func handleStartNextSession() {
        timer.clearPendingSessionEnd()
        timer.startNextWorkSession()
    }

    private func handleStopCompletely(wasBreak: Bool) {
        if !wasBreak {
            saveCurrentWorkSession()
        }

        timer.clearPendingSessionEnd()
        timer.stop()
        onFinished()
    }

    private func handleStopAfterSave() {
        timer.clearPendingSessionEnd()
        timer.stop()
        onFinished()
    }

    private func handleSnooze(minutes: Int) {
        timer.clearPendingSessionEnd()
        timer.snooze(minutes: minutes)
    }

    private func saveCurrentWorkSession() {
        let session = PomodoroSession(
            plannedDuration: TimeInterval(timer.originalDurationSeconds),
            sessionType: .work,
            sessionNumber: timer.currentSessionNumber
        )
        session.completed = timer.remainingSeconds <= 0
        session.endedAt = .now
        session.actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)
        session.project = boundProject
        session.isFocusMate = timer.isFocusMateSession
        modelContext.insert(session)
        modelContext.saveWithLogging()
    }
}
