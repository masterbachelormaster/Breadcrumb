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
        timer.startWork(project: nil, durationMinutes: 25)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds == 25 * 60)
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("Tick decrements remaining seconds")
    func tickDecrement() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.tick()
        #expect(timer.remainingSeconds == 25 * 60 - 1)
    }

    @Test("Tick at zero transitions to sessionEnded")
    func tickAtZeroEndsSession() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.remainingSeconds = 1
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("Entering overtime counts up")
    func overtimeCounting() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.remainingSeconds = 0
        timer.currentPhase = .sessionEnded
        timer.enterOvertime()
        #expect(timer.isOvertime == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.overtimeSeconds == 0)
        timer.tick()
        #expect(timer.overtimeSeconds == 1)
    }

    @Test("Starting break sets correct phase")
    func startBreak() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.currentSessionNumber = 1
        timer.startBreak(shortMinutes: 5, longMinutes: 15, sessionsBeforeLong: 4)
        #expect(timer.currentPhase == .shortBreak)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
    }

    @Test("Long break after configured sessions")
    func longBreakAfterFourSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.currentSessionNumber = 4
        timer.startBreak(shortMinutes: 5, longMinutes: 15, sessionsBeforeLong: 4)
        #expect(timer.currentPhase == .longBreak)
        #expect(timer.remainingSeconds == 15 * 60)
    }

    @Test("Pause and resume")
    func pauseResume() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
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
        timer.startWork(project: nil, durationMinutes: 25)
        timer.stop()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
    }

    @Test("Menu bar label reflects timer state")
    func menuBarLabel() {
        let timer = PomodoroTimer()
        #expect(timer.menuBarLabel == "Breadcrumb")
        timer.startWork(project: nil, durationMinutes: 25)
        #expect(timer.menuBarLabel.contains("🍅"))
        timer.currentPhase = .shortBreak
        timer.remainingSeconds = 195
        #expect(timer.menuBarLabel.contains("☕"))
        timer.currentPhase = .sessionEnded
        #expect(timer.menuBarLabel == "🍅 Fertig!")
    }

    @Test("Original duration is tracked")
    func originalDuration() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        #expect(timer.originalDurationSeconds == 1500)
        timer.stop()
        #expect(timer.originalDurationSeconds == 0)
    }

    @Test("Formatted time displays correctly")
    func formattedTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25)
        timer.remainingSeconds = 754
        #expect(timer.formattedTime == "12:34")
        timer.remainingSeconds = 60
        #expect(timer.formattedTime == "1:00")
        timer.remainingSeconds = 5
        #expect(timer.formattedTime == "0:05")
    }
}
