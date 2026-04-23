import Testing
import Foundation
@testable import Breadcrumb

@Suite("Session Duration Calculations")
@MainActor
struct SessionDurationTests {

    @Test("Timer tracks phase transition from break to sessionEnded")
    func breakToSessionEnded() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()
        let phaseBeforeTick = timer.currentPhase
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()
        #expect(phaseBeforeTick == .shortBreak)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("Duration formula: full session with overtime")
    func fullSessionWithOvertime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 0
        timer.overtimeSeconds = 120

        let completed = timer.remainingSeconds <= 0
        let actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)

        #expect(completed == true)
        #expect(actualDuration == 1620)
    }

    @Test("Duration formula: early stop with remaining time")
    func earlyStopWithRemainingTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 500
        timer.overtimeSeconds = 0

        let completed = timer.remainingSeconds <= 0
        let actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)

        #expect(completed == false)
        #expect(actualDuration == 1000)
    }

    @Test("Duration formula: exact completion no overtime")
    func exactCompletionNoOvertime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 0
        timer.overtimeSeconds = 0

        let completed = timer.remainingSeconds <= 0
        let actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)

        #expect(completed == true)
        #expect(actualDuration == 1500)
    }

    @Test("FocusMate late join: phaseDurationSeconds < originalDurationSeconds")
    func focusMateLateJoinDurationDifference() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(30 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)

        #expect(timer.originalDurationSeconds == 3000)
        #expect(abs(timer.phaseDurationSeconds - 1800) <= 1)
        #expect(timer.phaseDurationSeconds < timer.originalDurationSeconds)
    }

    @Test("FocusMate duration uses phase not original")
    func focusMateDurationUsesPhase() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(30 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)

        timer.remainingSeconds = 0

        let correctDuration = TimeInterval(timer.phaseDurationSeconds - timer.remainingSeconds)
        let wrongDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds)

        #expect(abs(correctDuration - 1800) <= 1)
        #expect(wrongDuration == 3000)
        #expect(correctDuration < wrongDuration)
    }

    @Test("FocusMate on-time join: phase equals original")
    func focusMateOnTimeJoinPhaseEqualsOriginal() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)

        #expect(abs(timer.phaseDurationSeconds - timer.originalDurationSeconds) <= 1)
    }
}
