import Testing
import Foundation
@testable import Breadcrumb

@Suite("PomodoroTimer Tests")
@MainActor
struct PomodoroTimerTests {

    @Test("Timer initializes in idle state")
    func idleState() {
        let timer = PomodoroTimer()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.isOvertime == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.boundProject == nil)
    }

    @Test("Starting work session sets correct state")
    func startWorkSession() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds == 25 * 60)
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("Tick decrements remaining seconds")
    func tickDecrement() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.remainingSeconds == 25 * 60 - 1)
    }

    // MARK: - Feature 1: Auto-continue overtime

    @Test("Work phase auto-continues into overtime at zero")
    func workAutoOvertimeAtZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.isOvertime == true)
        #expect(timer.didCrossZero == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
    }

    @Test("Break phase still ends at zero")
    func breakStillEndsAtZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
    }

    @Test("Overtime seconds count up after crossing zero")
    func overtimeSecondsCountUp() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60 + 10))
        timer.tick()
        #expect(timer.isOvertime == true)
        #expect(timer.overtimeSeconds == 10)
        #expect(timer.currentPhase == .work)
    }

    @Test("didCrossZero resets on stop")
    func didCrossZeroResetsOnStop() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.didCrossZero == true)
        timer.stop()
        #expect(timer.didCrossZero == false)
    }

    @Test("didCrossZero resets on startWork")
    func didCrossZeroResetsOnStartWork() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.didCrossZero == true)
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.didCrossZero == false)
    }

    // MARK: - Feature 2: Total sessions

    @Test("Cycle completes after total sessions")
    func cycleCompletesAfterTotalSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 2)
        #expect(timer.isCycleComplete == false)
        timer.currentSessionNumber = 2
        #expect(timer.isCycleComplete == true)
    }

    @Test("Single session cycle completes immediately")
    func singleSessionCycle() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        #expect(timer.isCycleComplete == true)
    }

    @Test("Total sessions stored on startWork")
    func totalSessionsStored() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 3)
        #expect(timer.sessionTotalSessions == 3)
    }

    @Test("startNextWorkSession guards cycle complete")
    func startNextGuardsCycleComplete() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        timer.startNextWorkSession()
        #expect(timer.currentSessionNumber == 1)
    }

    // MARK: - Feature 3: FocusMate

    @Test("FocusMate session starts correctly")
    func startFocusMateSession() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)
        #expect(timer.currentPhase == .work)
        #expect(timer.isFocusMateSession == true)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds > 0)
        #expect(timer.remainingSeconds <= 3000)
        #expect(timer.focusMateEndTime != nil)
    }

    @Test("FocusMate session ends at zero (no overtime)")
    func focusMateEndsAtZero() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
        #expect(timer.isOvertime == false)
    }

    @Test("FocusMate menu bar label shows people emoji")
    func focusMateMenuBarLabel() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)
        #expect(timer.menuBarLabel(.english).hasPrefix("👥"))
    }

    @Test("Stop resets FocusMate properties")
    func stopResetsFocusMateProperties() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)
        timer.stop()
        #expect(timer.isFocusMateSession == false)
        #expect(timer.focusMateEndTime == nil)
    }

    // MARK: - Existing tests

    @Test("Entering overtime counts up")
    func overtimeCounting() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 0
        timer.currentPhase = .sessionEnded
        timer.enterOvertime()
        #expect(timer.isOvertime == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.overtimeSeconds == 0)
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.overtimeSeconds == 1)
    }

    @Test("Starting break sets correct phase")
    func startBreak() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.currentSessionNumber = 1
        timer.startBreak()
        #expect(timer.currentPhase == .shortBreak)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
    }

    @Test("Long break after configured sessions")
    func longBreakAfterFourSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.currentSessionNumber = 4
        timer.startBreak()
        #expect(timer.currentPhase == .longBreak)
        #expect(timer.remainingSeconds == 15 * 60)
    }

    @Test("Pause and resume")
    func pauseResume() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.pause()
        #expect(timer.isPaused == true)
        #expect(timer.isRunning == true)
        timer.resume()
        #expect(timer.isPaused == false)
        #expect(timer.isRunning == true)
    }

    @Test("Stop resets to idle")
    func stopResetsToIdle() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.stop()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
        #expect(timer.sessionTotalSessions == 4)
    }

    @Test("Menu bar label reflects timer state and language")
    func menuBarLabel() {
        let timer = PomodoroTimer()
        #expect(timer.menuBarLabel(.german) == "Breadcrumb")
        #expect(timer.menuBarLabel(.english) == "Breadcrumb")
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.menuBarLabel(.german).contains("🍅"))
        timer.currentPhase = .shortBreak
        timer.remainingSeconds = 195
        #expect(timer.menuBarLabel(.german).contains("☕"))
        timer.currentPhase = .sessionEnded
        #expect(timer.menuBarLabel(.german) == "🍅 Fertig!")
        #expect(timer.menuBarLabel(.english) == "🍅 Done!")
    }

    @Test("Original duration is tracked")
    func originalDuration() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.originalDurationSeconds == 1500)
        timer.stop()
        #expect(timer.originalDurationSeconds == 0)
    }

    @Test("Formatted time displays correctly")
    func formattedTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 754
        #expect(timer.formattedTime == "12:34")
        timer.remainingSeconds = 60
        #expect(timer.formattedTime == "1:00")
        timer.remainingSeconds = 5
        #expect(timer.formattedTime == "0:05")
    }

    @Test("Session settings are stored on startWork")
    func sessionSettings() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6, totalSessions: 5)
        #expect(timer.sessionWorkMinutes == 30)
        #expect(timer.sessionShortBreakMinutes == 3)
        #expect(timer.sessionLongBreakMinutes == 20)
        #expect(timer.sessionSessionsBeforeLong == 6)
        #expect(timer.sessionTotalSessions == 5)
    }

    @Test("Stop resets session settings to defaults")
    func stopResetsSessionSettings() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6, totalSessions: 3)
        timer.stop()
        #expect(timer.sessionWorkMinutes == 25)
        #expect(timer.sessionShortBreakMinutes == 5)
        #expect(timer.sessionLongBreakMinutes == 15)
        #expect(timer.sessionSessionsBeforeLong == 4)
        #expect(timer.sessionTotalSessions == 4)
    }

    // MARK: - Snooze

    @Test("Snooze sets timer to given minutes and resumes work")
    func snoozeResumesWork() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        // Simulate reaching overtime
        timer.isOvertime = true
        timer.overtimeSeconds = 120
        timer.currentPhase = .sessionEnded

        timer.snooze(minutes: 5)

        #expect(timer.currentPhase == .work)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
        #expect(timer.isRunning == true)
        #expect(timer.isPaused == false)
    }

    @Test("Snooze resets didCrossZero")
    func snoozeResetsDidCrossZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.didCrossZero = true
        timer.snooze(minutes: 10)
        #expect(timer.didCrossZero == false)
    }
}
