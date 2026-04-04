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
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds == 25 * 60)
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("Tick decrements remaining seconds")
    func tickDecrement() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        // Simulate 1 second elapsed by backdating phaseStartDate
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.remainingSeconds == 25 * 60 - 1)
    }

    @Test("Tick at zero transitions to sessionEnded")
    func tickAtZeroEndsSession() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        // Simulate full duration elapsed
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
    }

    @Test("Entering overtime counts up")
    func overtimeCounting() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        timer.remainingSeconds = 0
        timer.currentPhase = .sessionEnded
        timer.enterOvertime()
        #expect(timer.isOvertime == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.overtimeSeconds == 0)
        // Simulate 1 second of overtime elapsed
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.overtimeSeconds == 1)
    }

    @Test("Starting break sets correct phase")
    func startBreak() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        timer.currentSessionNumber = 1
        timer.startBreak()
        #expect(timer.currentPhase == .shortBreak)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
    }

    @Test("Long break after configured sessions")
    func longBreakAfterFourSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        timer.currentSessionNumber = 4
        timer.startBreak()
        #expect(timer.currentPhase == .longBreak)
        #expect(timer.remainingSeconds == 15 * 60)
    }

    @Test("Pause and resume")
    func pauseResume() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
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
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        timer.stop()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
    }

    @Test("Menu bar label reflects timer state and language")
    func menuBarLabel() {
        let timer = PomodoroTimer()
        #expect(timer.menuBarLabel(.german) == "Breadcrumb")
        #expect(timer.menuBarLabel(.english) == "Breadcrumb")
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
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
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
        #expect(timer.originalDurationSeconds == 1500)
        timer.stop()
        #expect(timer.originalDurationSeconds == 0)
    }

    @Test("Formatted time displays correctly")
    func formattedTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4)
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
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6)
        #expect(timer.sessionWorkMinutes == 30)
        #expect(timer.sessionShortBreakMinutes == 3)
        #expect(timer.sessionLongBreakMinutes == 20)
        #expect(timer.sessionSessionsBeforeLong == 6)
    }

    @Test("Stop resets session settings to defaults")
    func stopResetsSessionSettings() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6)
        timer.stop()
        #expect(timer.sessionWorkMinutes == 25)
        #expect(timer.sessionShortBreakMinutes == 5)
        #expect(timer.sessionLongBreakMinutes == 15)
        #expect(timer.sessionSessionsBeforeLong == 4)
    }
}
